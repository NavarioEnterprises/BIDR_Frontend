from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password

from user.models import AppUser
from .models import BuyersAddressDetails, Buyer


class BuyerRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for buyer registration"""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = AppUser
        fields = (
            'email', 'first_name', 'last_name', 'phone_number',
            'password', 'confirm_password', 'role'
        )
        extra_kwargs = {'role': {'read_only': True}}

    def validate(self, attrs):
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        attrs['role'] = 'buyer'
        return attrs

    def create(self, validated_data):
        validated_data.pop('confirm_password')
        user = AppUser.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', ''),
            phone_number=validated_data['phone_number'],
            role=validated_data['role']
        )
        return user


class BuyerSerializer(serializers.ModelSerializer):
    """Serializer for Buyer profile"""
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    user_phone = serializers.CharField(source='user.phone_number', read_only=True)

    class Meta:
        model = Buyer
        fields = [
            'uid', 'is_active', 'user_email', 'user_full_name',
            'user_phone', 'created_at', 'updated_at'
        ]
        read_only_fields = ['uid', 'created_at', 'updated_at']


class BuyersAddressDetailsSerializer(serializers.ModelSerializer):
    """Serializer for Buyer Address Details"""

    class Meta:
        model = BuyersAddressDetails
        fields = [
            'uid', 'postal_address', 'physical_address', 'location',
            'contact_person_name', 'contact_person_telephone',
            'contact_person_email_address', 'platform_workflow_email_address',
            'is_primary', 'created_at', 'updated_at'
        ]
        read_only_fields = ['uid', 'created_at', 'updated_at']

    def validate(self, attrs):
        """Validate address details"""
        user = self.context['request'].user
        is_primary = attrs.get('is_primary', False)

        # Check if another primary address exists (for create/update)
        if is_primary and self.instance is None:
            existing_primary = BuyersAddressDetails.objects.filter(
                user=user, is_primary=True
            ).exists()
            if existing_primary:
                raise serializers.ValidationError(
                    "A primary address already exists. Please unset the existing primary first."
                )

        return attrs


class BuyerCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating a buyer profile"""

    class Meta:
        model = Buyer
        fields = ['is_active']

    def create(self, validated_data):
        """Create buyer profile for the authenticated user"""
        user = self.context['request'].user
        buyer = Buyer.objects.create(user=user, **validated_data)
        return buyer


class BuyerAddressCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating buyer address"""

    class Meta:
        model = BuyersAddressDetails
        fields = [
            'postal_address', 'physical_address', 'location',
            'contact_person_name', 'contact_person_telephone',
            'contact_person_email_address', 'platform_workflow_email_address',
            'is_primary'
        ]

    def create(self, validated_data):
        """Create address for the authenticated user"""
        user = self.context['request'].user
        address = BuyersAddressDetails.objects.create(user=user, **validated_data)
        return address


class BuyerProfileDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for buyer profile with address"""
    addresses = BuyersAddressDetailsSerializer(source='user.address_details', many=True, read_only=True)
    primary_address = serializers.SerializerMethodField()
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    user_phone = serializers.CharField(source='user.phone_number', read_only=True)

    class Meta:
        model = Buyer
        fields = [
            'uid', 'is_active', 'user_email', 'user_full_name',
            'user_phone', 'addresses', 'primary_address',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['uid', 'created_at', 'updated_at']

    def get_primary_address(self, obj):
        """Get primary address for the buyer"""
        primary_address = obj.user.address_details.filter(is_primary=True).first()
        if primary_address:
            return BuyersAddressDetailsSerializer(primary_address).data
        return None