from rest_framework import serializers
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from decimal import Decimal, InvalidOperation

from .models import AppUser, Address


class UserLoginSerializer(serializers.Serializer):
    """Serializer for user login"""
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        if email and password:
            user = authenticate(email=email, password=password)
            if not user:
                raise serializers.ValidationError('Invalid credentials')
            if not user.is_active:
                raise serializers.ValidationError('User account is disabled')
            attrs['user'] = user
        else:
            raise serializers.ValidationError('Must include email and password')

        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    """Serializer for user profile information"""
    
    class Meta:
        model = AppUser
        fields = (
            'id', 'uid', 'email', 'first_name', 'last_name', 'phone_number',
            'email_verified', 'phone_verified', 'role', 'is_verified', 'is_suspended', 'created_at'
        )
        read_only_fields = (
            'id', 'uid', 'email', 'email_verified', 'phone_verified', 'role', 
            'is_verified', 'is_suspended', 'created_at'
        )


class PasswordResetRequestSerializer(serializers.Serializer):
    """Serializer for password reset request"""
    email = serializers.EmailField()

    def validate_email(self, value):
        try:
            user = AppUser.objects.get(email=value)
        except AppUser.DoesNotExist:
            raise serializers.ValidationError("User with this email does not exist")
        return value


class PasswordResetSerializer(serializers.Serializer):
    """Serializer for password reset"""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)
    token = serializers.CharField()

    def validate(self, attrs):
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Serializer for user registration"""
    password = serializers.CharField(write_only=True, validators=[validate_password])
    confirm_password = serializers.CharField(write_only=True)
    
    class Meta:
        model = AppUser
        fields = (
            'email', 'first_name', 'last_name', 'phone_number', 'role',
            'password', 'confirm_password'
        )
        
    def validate(self, attrs):
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Passwords don't match")
        return attrs
        
    def validate_role(self, value):
        if value not in ['buyer', 'seller']:
            raise serializers.ValidationError("Invalid role selected. Must be 'buyer' or 'seller'.")
        return value
        
    def create(self, validated_data):
        validated_data.pop('confirm_password')
        password = validated_data.pop('password')
        user = AppUser(**validated_data)
        user.set_password(password)
        user.save()
        return user


class RoleSelectionSerializer(serializers.Serializer):
    """Serializer for initial role selection"""
    role = serializers.ChoiceField(choices=AppUser.ROLE_CHOICES, required=True)

    def validate_role(self, value):
        if value not in ['buyer', 'seller']:
            raise serializers.ValidationError("Invalid role selected. Must be 'buyer' or 'seller'.")
        return value


class AddressSerializer(serializers.ModelSerializer):
    """Serializer for address management"""
    address_id = serializers.UUIDField(read_only=True)
    user_id = serializers.IntegerField(read_only=True)
    latitude = serializers.DecimalField(max_digits=10, decimal_places=8, required=False, allow_null=True)
    longitude = serializers.DecimalField(max_digits=11, decimal_places=8, required=False, allow_null=True)
    
    class Meta:
        model = Address
        fields = [
            'address_id', 'user_id', 'business_id', 'address_line_1', 'address_line_2',
            'city', 'state_province', 'postal_code', 'country', 'latitude', 'longitude',
            'address_type', 'is_primary', 'address_name', 'delivery_instructions',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['address_id', 'user_id', 'created_at', 'updated_at']
    
    def validate_latitude(self, value):
        """Validate latitude is within valid range"""
        if value is not None and (value < -90 or value > 90):
            raise serializers.ValidationError("Latitude must be between -90 and 90 degrees")
        return value
    
    def validate_longitude(self, value):
        """Validate longitude is within valid range"""
        if value is not None and (value < -180 or value > 180):
            raise serializers.ValidationError("Longitude must be between -180 and 180 degrees")
        return value
    
    def create(self, validated_data):
        """Create address with user from context"""
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
    
    def to_representation(self, instance):
        """Return decrypted address data"""
        return instance.get_decrypted_data()


class AddressCreateSerializer(AddressSerializer):
    """Serializer for creating new addresses"""
    
    def validate(self, attrs):
        """Validate address creation"""
        user = self.context['request'].user
        address_type = attrs.get('address_type', 'home')
        is_primary = attrs.get('is_primary', False)
        
        # If this is set as primary, check if user already has a primary address of this type
        if is_primary:
            existing_primary = Address.objects.filter(
                user=user,
                address_type=address_type,
                is_primary=True,
                is_deleted=False
            ).exists()
            
            if existing_primary:
                attrs['_will_replace_primary'] = True
        
        return attrs


class AddressUpdateSerializer(AddressSerializer):
    """Serializer for updating addresses"""
    
    def validate(self, attrs):
        """Validate address update"""
        instance = self.instance
        is_primary = attrs.get('is_primary')
        
        # If setting as primary, handle existing primary address
        if is_primary is True and not instance.is_primary:
            Address.objects.filter(
                user=instance.user,
                address_type=instance.address_type,
                is_primary=True,
                is_deleted=False
            ).exclude(address_id=instance.address_id).update(is_primary=False)
        
        return attrs


class ComprehensiveUserProfileSerializer(serializers.ModelSerializer):
    """Comprehensive serializer for complete user profile"""
    addresses = AddressSerializer(many=True, read_only=True)
    primary_address = serializers.SerializerMethodField()
    profile_completion_percentage = serializers.SerializerMethodField()
    full_name = serializers.SerializerMethodField()
    
    class Meta:
        model = AppUser
        fields = [
            # Basic information
            'id', 'uid', 'email', 'first_name', 'middle_name', 'last_name', 'full_name',
            'phone_number', 'alternative_phone', 'alternative_email', 'date_of_birth',
            
            # Profile information
            'gender', 'nationality', 'occupation', 'company_name', 'profile_picture',
            'bio', 'website', 'linkedin_profile',
            
            # Preferences
            'preferred_language', 'user_timezone', 'currency_preference',
            
            # Notification preferences
            'email_notifications', 'sms_notifications', 'push_notifications', 'marketing_emails',
            
            # Privacy settings
            'profile_visibility', 'show_email', 'show_phone',
            
            # Status and verification
            'email_verified', 'phone_verified', 'profile_status', 'role',
            'is_active', 'is_verified', 'is_suspended',
            
            # Metadata
            'date_joined', 'created_at', 'updated_at',
            
            # Computed fields
            'addresses', 'primary_address', 'profile_completion_percentage'
        ]
        read_only_fields = [
            'id', 'uid', 'email', 'email_verified', 'phone_verified', 'role',
            'is_active', 'is_verified', 'is_suspended', 'date_joined', 'created_at', 'updated_at',
            'addresses', 'primary_address', 'profile_completion_percentage', 'full_name'
        ]
    
    def get_primary_address(self, obj):
        """Get user's primary address"""
        primary_address = obj.addresses.filter(is_primary=True, is_deleted=False).first()
        if primary_address:
            return primary_address.get_decrypted_data()
        return None
    
    def get_profile_completion_percentage(self, obj):
        """Get profile completion percentage"""
        return obj.calculate_profile_completion()
    
    def get_full_name(self, obj):
        """Get user's full name"""
        return obj.get_full_name()
    
    def to_representation(self, instance):
        """Return decrypted user profile data"""
        data = instance.get_decrypted_data()
        
        # Add computed fields
        data['addresses'] = [addr.get_decrypted_data() for addr in instance.addresses.filter(is_deleted=False)]
        data['primary_address'] = self.get_primary_address(instance)
        data['profile_completion_percentage'] = self.get_profile_completion_percentage(instance)
        data['full_name'] = self.get_full_name(instance)
        
        return data


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating user profile information"""
    
    class Meta:
        model = AppUser
        fields = [
            'first_name', 'middle_name', 'last_name', 'alternative_phone', 'alternative_email',
            'date_of_birth', 'gender', 'nationality', 'occupation', 'company_name',
            'profile_picture', 'bio', 'website', 'linkedin_profile', 'preferred_language',
            'user_timezone', 'currency_preference', 'email_notifications', 'sms_notifications',
            'push_notifications', 'marketing_emails', 'profile_visibility', 'show_email', 'show_phone'
        ]
    
    def validate_date_of_birth(self, value):
        """Validate date of birth format"""
        if value:
            # Add any date format validation here if needed
            # For now, we accept any string since it will be encrypted
            pass
        return value
    
    def validate_gender(self, value):
        """Validate gender choice"""
        if value and value not in dict(AppUser.GENDER_CHOICES):
            raise serializers.ValidationError("Invalid gender choice")
        return value
    
    def validate_preferred_language(self, value):
        """Validate language code format"""
        if value and len(value) > 10:
            raise serializers.ValidationError("Language code too long")
        return value
    
    def validate_currency_preference(self, value):
        """Validate currency code format"""
        if value and len(value) != 3:
            raise serializers.ValidationError("Currency code must be 3 characters (ISO format)")
        return value


class UserPreferencesSerializer(serializers.ModelSerializer):
    """Serializer for user preferences only"""
    
    class Meta:
        model = AppUser
        fields = [
            'preferred_language', 'user_timezone', 'currency_preference',
            'email_notifications', 'sms_notifications', 'push_notifications',
            'marketing_emails', 'profile_visibility', 'show_email', 'show_phone'
        ]


class UserBasicInfoSerializer(serializers.ModelSerializer):
    """Serializer for basic user information (used in login response)"""
    full_name = serializers.SerializerMethodField()
    primary_address = serializers.SerializerMethodField()
    profile_completion_percentage = serializers.SerializerMethodField()
    
    class Meta:
        model = AppUser
        fields = [
            'id', 'uid', 'email', 'first_name', 'last_name', 'full_name',
            'phone_number', 'role', 'profile_picture', 'email_verified', 'phone_verified',
            'profile_status', 'is_active', 'is_verified', 'primary_address',
            'profile_completion_percentage', 'created_at'
        ]
    
    def get_full_name(self, obj):
        """Get user's full name"""
        return obj.get_full_name()
    
    def get_primary_address(self, obj):
        """Get user's primary address"""
        primary_address = obj.addresses.filter(is_primary=True, is_deleted=False).first()
        if primary_address:
            return primary_address.get_decrypted_data()
        return None
    
    def get_profile_completion_percentage(self, obj):
        """Get profile completion percentage"""
        return obj.calculate_profile_completion()
    
    def to_representation(self, instance):
        """Return basic decrypted user data"""
        data = {
            'id': instance.id,
            'uid': str(instance.uid),
            'email': instance.email,
            'first_name': instance.get_decrypted_first_name(),
            'last_name': instance.get_decrypted_last_name(),
            'full_name': instance.get_full_name(),
            'phone_number': instance.get_decrypted_phone_number(),
            'role': instance.role,
            'profile_picture': instance.profile_picture.url if instance.profile_picture else None,
            'email_verified': instance.email_verified,
            'phone_verified': instance.phone_verified,
            'profile_status': instance.profile_status,
            'is_active': instance.is_active,
            'is_verified': instance.is_verified,
            'primary_address': self.get_primary_address(instance),
            'profile_completion_percentage': self.get_profile_completion_percentage(instance),
            'created_at': instance.created_at,
        }
        return data
