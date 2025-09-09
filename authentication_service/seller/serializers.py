from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password

from user.models import AppUser
from .models import (
    Seller, SellersAddressDetails, SellerBankAccount, SellerVettingLog, SellerProfile,
    CompanyInfo, CompanyContactInfo, BankingInfo, BusinessRegistration
)


class SellerRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for seller registration (initial user creation)"""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)
    fullname = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = AppUser
        fields = (
            'email', 'fullname', 'phone_number',
            'password', 'confirm_password', 'role'
        )
        extra_kwargs = {'role': {'read_only': True}}

    def validate(self, attrs):
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        attrs['role'] = 'seller'
        return attrs

    def create(self, validated_data):
        validated_data.pop('confirm_password')
        fullname = validated_data.pop('fullname')
        first_name, last_name = self._split_fullname(fullname)

        user = AppUser.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=first_name,
            last_name=last_name,
            phone_number=validated_data['phone_number'],
            role=validated_data['role']
        )
        return user

    def _split_fullname(self, fullname):
        parts = fullname.split(' ', 1)
        first_name = parts[0] if parts else ''
        last_name = parts[1] if len(parts) > 1 else ''
        return first_name, last_name



class SellerBusinessRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for seller business registration (continuation after user creation)"""
    class Meta:
        model = Seller
        fields = (
            'registered_company_name', 'trading_name', 'registration_number',
            'vat_number', 'website_url', 'product_category', 'product_subcategory'
        )


class SellerAddressSerializer(serializers.ModelSerializer):
    """Serializer for seller address details"""
    class Meta:
        model = SellersAddressDetails
        fields = (
            'postal_address', 'physical_address', 'location_address', 'contact_person_name',
            'contact_person_telephone', 'contact_person_email_address',
            'platform_workflow_email_address', 'is_primary', 'city', 'province', 'postal_code', 'country',
            'latitude', 'longitude'
        )


class SellerBankAccountSerializer(serializers.ModelSerializer):
    """Serializer for seller bank account"""
    class Meta:
        model = SellerBankAccount
        fields = (
            'bank_account_type', 'bank_name', 'bank_account_number', 'bank_branch_code'
        )


class SellerVettingSerializer(serializers.ModelSerializer):
    """Serializer for seller document vetting"""
    class Meta:
        model = SellerVettingLog
        fields = (
            'certificate_of_incorporation', 'certificate_of_incorporation_status',
            'company_extract', 'company_extract_status'
        )
        read_only_fields = (
            'certificate_of_incorporation_status', 'company_extract_status'
        )


class SellerProfileSerializer(serializers.ModelSerializer):
    """Comprehensive serializer for seller profiles."""

    seller_email = serializers.CharField(source='seller.user.email', read_only=True)
    display_name = serializers.ReadOnlyField()
    completion_rate = serializers.ReadOnlyField()

    class Meta:
        model = SellerProfile
        fields = [
            'id', 'seller', 'seller_email', 'approval_status', 'vendor_id',
            'display_name_preference', 'display_name', 'background_check_authorized',
            'background_check_completed', 'background_check_passed',
            'notification_preferences', 'auto_respond_enabled', 'minimum_order_value',
            'response_time_hours', 'total_quotes_submitted', 'total_deals_won',
            'total_deals_completed', 'average_rating', 'response_rate_percentage',
            'completion_rate', 'application_submitted_at', 'approved_at',
            'last_active_at', 'created_at', 'is_active'
        ]
        read_only_fields = [
            'id', 'vendor_id', 'display_name', 'completion_rate',
            'total_quotes_submitted', 'total_deals_won', 'total_deals_completed',
            'average_rating', 'response_rate_percentage', 'created_at'
        ]

    def validate_minimum_order_value(self, value):
        """Validate minimum order value if provided."""
        if value is not None and value < 0:
            raise serializers.ValidationError("Minimum order value cannot be negative.")
        return value


class BulkSellerApprovalSerializer(serializers.Serializer):
    """Serializer for bulk seller approval operations."""

    seller_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1
    )
    action = serializers.ChoiceField(
        choices=['approve', 'reject', 'suspend']
    )
    reason = serializers.CharField(max_length=500, required=False)


class CompanyInfoSerializer(serializers.ModelSerializer):
    """Serializer for CompanyInfo model"""
    class Meta:
        model = CompanyInfo
        fields = ['company_name', 'trading_name', 'registration_number', 'vat_number',
                  'website_url', 'cipc_document_path']


class CompanyContactInfoSerializer(serializers.ModelSerializer):
    """Serializer for CompanyContactInfo model"""
    class Meta:
        model = CompanyContactInfo
        fields = ['postal_address', 'physical_address', 'contact_person_name',
                  'contact_person_telephone', 'contact_person_email',
                  'platform_workflow_email', 'latitude', 'longitude']


class BankingInfoSerializer(serializers.ModelSerializer):
    """Serializer for BankingInfo model"""
    class Meta:
        model = BankingInfo
        fields = ['bank_name', 'account_number', 'branch_code', 'account_holder']


class BusinessRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for BusinessRegistration model"""
    company_info = CompanyInfoSerializer()
    contact_info = CompanyContactInfoSerializer()
    banking_info = BankingInfoSerializer()

    class Meta:
        model = BusinessRegistration
        fields = ['seller', 'company_info', 'contact_info', 'banking_info', 'product_categories']
    
    def create(self, validated_data):
        company_info_data = validated_data.pop('company_info')
        contact_info_data = validated_data.pop('contact_info')
        banking_info_data = validated_data.pop('banking_info')

        company_info = CompanyInfo.objects.create(**company_info_data)
        contact_info = CompanyContactInfo.objects.create(**contact_info_data)
        banking_info = BankingInfo.objects.create(**banking_info_data)

        business_registration = BusinessRegistration.objects.create(
            company_info=company_info,
            contact_info=contact_info,
            banking_info=banking_info,
            **validated_data
        )

        return business_registration
    
    def update(self, instance, validated_data):
        company_info_data = validated_data.pop('company_info', {})
        contact_info_data = validated_data.pop('contact_info', {})
        banking_info_data = validated_data.pop('banking_info', {})

        if company_info_data:
            for attr, value in company_info_data.items():
                setattr(instance.company_info, attr, value)
            instance.company_info.save()

        if contact_info_data:
            for attr, value in contact_info_data.items():
                setattr(instance.contact_info, attr, value)
            instance.contact_info.save()

        if banking_info_data:
            for attr, value in banking_info_data.items():
                setattr(instance.banking_info, attr, value)
            instance.banking_info.save()

        instance.product_categories = validated_data.get('product_categories', instance.product_categories)
        instance.save()

        return instance
