from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, Group, Permission
from django.db import models
from django.utils import timezone
import uuid

from django.utils.timezone import now
from security.utils import security_utils
from django.contrib.auth.hashers import make_password, check_password

from .managers import AppUserManager


class AppUser(AbstractBaseUser, PermissionsMixin):
    ROLE_CHOICES = (
        ('administrator', 'Administrator'),
        ('buyer', 'Buyer'),
        ('seller', 'Seller'),
    )
    OTP_CHOICES = (
        ('sms', 'SMS'),
        ('email', 'EMAIL'),
    )
    GENDER_CHOICES = (
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
        ('prefer_not_to_say', 'Prefer not to say'),
    )
    PROFILE_STATUS_CHOICES = (
        ('incomplete', 'Incomplete'),
        ('complete', 'Complete'),
        ('verified', 'Verified'),
    )

    # Basic user information
    id = models.BigAutoField(primary_key=True)
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    email = models.EmailField(max_length=255, unique=True)
    first_name = models.CharField(max_length=150, blank=True)
    last_name = models.CharField(max_length=150, blank=True)
    phone_number = models.CharField(max_length=255, unique=True, help_text="User's primary contact number.")
    
    # Profile information (encrypted PII)
    middle_name = models.CharField(max_length=150, blank=True, null=True)
    date_of_birth = models.CharField(max_length=255, blank=True, null=True, help_text="Encrypted date of birth")
    gender = models.CharField(max_length=20, choices=GENDER_CHOICES, blank=True, null=True)
    nationality = models.CharField(max_length=100, blank=True, null=True)
    occupation = models.CharField(max_length=255, blank=True, null=True)
    company_name = models.CharField(max_length=255, blank=True, null=True)
    
    # Contact information
    alternative_phone = models.CharField(max_length=255, blank=True, null=True, help_text="Encrypted alternative phone")
    alternative_email = models.EmailField(max_length=255, blank=True, null=True)
    
    # Profile settings
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    bio = models.TextField(max_length=500, blank=True, null=True)
    website = models.URLField(max_length=255, blank=True, null=True)
    linkedin_profile = models.URLField(max_length=255, blank=True, null=True)
    
    # Preferences
    preferred_language = models.CharField(max_length=10, default='en', help_text="Language code (e.g., en, es, fr)")
    user_timezone = models.CharField(max_length=50, default='UTC', help_text="User's timezone")
    currency_preference = models.CharField(max_length=3, default='USD', help_text="ISO currency code")
    
    # Notifications preferences
    email_notifications = models.BooleanField(default=True)
    sms_notifications = models.BooleanField(default=False)
    push_notifications = models.BooleanField(default=True)
    marketing_emails = models.BooleanField(default=False)
    
    # Privacy settings
    profile_visibility = models.CharField(
        max_length=20,
        choices=[('public', 'Public'), ('private', 'Private'), ('friends', 'Friends Only')],
        default='public'
    )
    show_email = models.BooleanField(default=False)
    show_phone = models.BooleanField(default=False)
    
    # Status and verification
    email_verified = models.BooleanField(default=False)
    phone_verified = models.BooleanField(default=False)
    profile_status = models.CharField(max_length=20, choices=PROFILE_STATUS_CHOICES, default='incomplete')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    otp_type = models.CharField(max_length=20, choices=OTP_CHOICES, null=True, blank=True)
    user_permissions = models.ManyToManyField(Permission, blank=True, related_name="appuser_permissions",
                                              help_text="Specific permissions for this user.",
                                              verbose_name="user permissions")
    groups = models.ManyToManyField(Group, blank=True, related_name="appuser_groups",
                                    help_text="The groups this user belongs to.", verbose_name="groups")
    is_staff = models.BooleanField(default=True)
    is_superuser = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    is_verified = models.BooleanField(default=True, help_text="Whether the user has been successfully vetted.")
    is_suspended = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name', 'phone_number']

    objects = AppUserManager()

    def __str__(self):
        return self.email

    def save(self, *args, **kwargs):
        """Override save to encrypt PII fields before saving to database"""
        if not self.uid:
            self.uid = uuid.uuid4()
        
        # Normalize email to lowercase for case-insensitive operations
        if self.email:
            self.email = self.email.lower().strip()
        
        # Encrypt PII fields before saving (unless skipped for migration)
        if not getattr(self, '_skip_encryption', False):
            self._encrypt_pii_fields()
        
        super().save(*args, **kwargs)
    
    def _encrypt_pii_fields(self):
        """Encrypt personally identifiable information fields"""
        pii_fields = ['first_name', 'last_name', 'middle_name', 'phone_number', 'alternative_phone', 'date_of_birth']
        
        for field in pii_fields:
            value = getattr(self, field, None)
            if value and not self._is_encrypted(value):
                encrypted_value = security_utils.encryption.encrypt_pii(value)
                setattr(self, field, encrypted_value)
    
    def _is_encrypted(self, value):
        """Check if a value is already encrypted"""
        try:
            security_utils.encryption.decrypt_pii(value)
            return True
        except:
            return False
    
    def get_decrypted_first_name(self):
        """Get decrypted first name"""
        if not self.first_name or not self.first_name.strip():
            return ""
        try:
            decrypted = security_utils.encryption.decrypt_pii(self.first_name)
            # Don't return migration placeholders - return empty string instead
            if decrypted and decrypted.startswith("[Migrated"):
                return ""
            return decrypted
        except (ValueError, Exception) as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"Failed to decrypt first_name for user {self.id}: {str(e)}")
            # Check if it's already a migration placeholder
            if self.first_name.startswith("[Migrated"):
                return ""
            # If it looks like base64 encrypted data but can't be decrypted, return empty string
            import base64
            try:
                base64.urlsafe_b64decode(self.first_name)
                return ""  # It's encrypted but corrupted
            except:
                return self.first_name  # It's probably plain text, return as-is
    
    def get_decrypted_last_name(self):
        """Get decrypted last name"""
        if not self.last_name or not self.last_name.strip():
            return ""
        try:
            decrypted = security_utils.encryption.decrypt_pii(self.last_name)
            # Don't return migration placeholders - return empty string instead
            if decrypted and decrypted.startswith("[Migrated"):
                return ""
            return decrypted
        except (ValueError, Exception) as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"Failed to decrypt last_name for user {self.id}: {str(e)}")
            # Check if it's already a migration placeholder
            if self.last_name.startswith("[Migrated"):
                return ""
            # If it looks like base64 encrypted data but can't be decrypted, return empty string
            import base64
            try:
                base64.urlsafe_b64decode(self.last_name)
                return ""  # It's encrypted but corrupted
            except:
                return self.last_name  # It's probably plain text, return as-is
    
    def get_decrypted_phone_number(self):
        """Get decrypted phone number with improved error handling"""
        if not self.phone_number or not self.phone_number.strip():
            return ""
        
        try:
            decrypted = security_utils.encryption.decrypt_pii(self.phone_number)
            # Don't return migration placeholders - return empty string instead
            if decrypted and decrypted.startswith("[Migrated"):
                return ""
            return decrypted
        except Exception as e:
            import base64
            import logging
            logger = logging.getLogger(__name__)
            # Check if it's already a migration placeholder
            if self.phone_number.startswith("[Migrated"):
                return ""
            # Check if it's a corrupted encrypted value (base64 encoded but not decryptable)
            try:
                base64.urlsafe_b64decode(self.phone_number.encode())
                # It's base64 encoded but corrupted - log warning and return empty string
                logger.warning(f"Corrupted encrypted phone number detected for user {self.id}: {str(e)}")
                return ""  # Return empty string instead of error message
            except:
                # It's likely plain text, return as-is
                logger.warning(f"Phone number appears to be plain text for user {self.id}: {str(e)}")
                return self.phone_number
    
    def get_decrypted_middle_name(self):
        """Get decrypted middle name"""
        if not self.middle_name or not self.middle_name.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.middle_name)
        except (ValueError, Exception):
            return self.middle_name  # Return as-is if not encrypted
    
    def get_decrypted_date_of_birth(self):
        """Get decrypted date of birth"""
        if not self.date_of_birth or not self.date_of_birth.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.date_of_birth)
        except (ValueError, Exception):
            return self.date_of_birth  # Return as-is if not encrypted
    
    def get_decrypted_alternative_phone(self):
        """Get decrypted alternative phone"""
        if not self.alternative_phone or not self.alternative_phone.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.alternative_phone)
        except (ValueError, Exception):
            return self.alternative_phone  # Return as-is if not encrypted
    
    def set_password(self, raw_password):
        """Set password using Django's secure password hashing"""
        if not raw_password:
            raise ValueError("Password cannot be empty")
        
        # Validate password strength
        validation_result = security_utils.validate_password_strength(raw_password)
        if not validation_result['is_valid']:
            raise ValueError(f"Password validation failed: {', '.join(validation_result['errors'])}")
        
        self.password = make_password(raw_password)
    
    def set_password_for_testing(self, raw_password):
        """Set password without validation for testing purposes"""
        if not raw_password:
            raise ValueError("Password cannot be empty")
        self.password = make_password(raw_password)
    
    def check_password(self, raw_password):
        """Check password against stored hash"""
        if not raw_password or not self.password:
            return False
        return check_password(raw_password, self.password)
    
    def get_decrypted_data(self):
        """Get user data with PII fields decrypted for display/processing"""
        return {
            'id': self.id,
            'uid': str(self.uid),
            'email': self.email,
            'first_name': self.get_decrypted_first_name(),
            'middle_name': self.get_decrypted_middle_name(),
            'last_name': self.get_decrypted_last_name(),
            'phone_number': self.get_decrypted_phone_number(),
            'alternative_phone': self.get_decrypted_alternative_phone(),
            'alternative_email': self.alternative_email,
            'date_of_birth': self.get_decrypted_date_of_birth(),
            'gender': self.gender,
            'nationality': self.nationality,
            'occupation': self.occupation,
            'company_name': self.company_name,
            'profile_picture': self.profile_picture.url if self.profile_picture else None,
            'bio': self.bio,
            'website': self.website,
            'linkedin_profile': self.linkedin_profile,
            'preferred_language': self.preferred_language,
            'timezone': self.user_timezone,
            'currency_preference': self.currency_preference,
            'email_notifications': self.email_notifications,
            'sms_notifications': self.sms_notifications,
            'push_notifications': self.push_notifications,
            'marketing_emails': self.marketing_emails,
            'profile_visibility': self.profile_visibility,
            'show_email': self.show_email,
            'show_phone': self.show_phone,
            'email_verified': self.email_verified,
            'phone_verified': self.phone_verified,
            'profile_status': self.profile_status,
            'role': self.role,
            'is_active': self.is_active,
            'is_verified': self.is_verified,
            'is_suspended': self.is_suspended,
            'date_joined': self.date_joined,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
        }
    
    def get_complete_profile_data(self):
        """Get complete user profile data including addresses"""
        profile_data = self.get_decrypted_data()
        profile_data['addresses'] = [address.get_decrypted_data() for address in self.addresses.filter(is_deleted=False)]
        profile_data['primary_address'] = None
        
        # Get primary address
        primary_address = self.addresses.filter(is_primary=True, is_deleted=False).first()
        if primary_address:
            profile_data['primary_address'] = primary_address.get_decrypted_data()
        
        return profile_data
    
    def calculate_profile_completion(self):
        """Calculate profile completion percentage"""
        fields_to_check = [
            'first_name', 'last_name', 'phone_number', 'date_of_birth', 'gender',
            'nationality', 'occupation', 'bio', 'profile_picture'
        ]
        
        completed_fields = 0
        total_fields = len(fields_to_check)
        
        for field in fields_to_check:
            if field == 'profile_picture':
                if self.profile_picture:
                    completed_fields += 1
            else:
                decrypted_value = getattr(self, f'get_decrypted_{field}', lambda: getattr(self, field, None))()
                if decrypted_value:
                    completed_fields += 1
        
        # Check if user has at least one address
        if self.addresses.filter(is_deleted=False).exists():
            completed_fields += 1
            total_fields += 1
        
        return round((completed_fields / total_fields) * 100, 2)

    def has_perm(self, perm, obj=None):
        """Does the user have a specific permission?"""
        return self.is_superuser

    def has_module_perms(self, app_label):
        """Does the user have permissions to view the app `app_label`?"""
        return self.is_superuser

    def get_full_name(self):
        """Return the full name of the user."""
        first_name = self.get_decrypted_first_name()
        last_name = self.get_decrypted_last_name()
        
        return f"{first_name} {last_name}".strip() or self.email

    class Meta:
        db_table = "app_user"
        verbose_name = "App User"
        verbose_name_plural = "App Users"


class MetadataModel(models.Model):
    is_visible = models.BooleanField(default=True)
    is_hidden = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True)
    restored_at = models.DateTimeField(null=True, blank=True)
    last_updated_by = models.ForeignKey(
        AppUser,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="%(class)s_updated_by",
        help_text="User who last updated this record."
    )

    class Meta:
        abstract = True
        ordering = ['-created_at']
        get_latest_by = 'created_at'

    def soft_delete(self):
        """
        Mark the instance as deleted without removing it from the database.
        """
        self.is_deleted = True
        self.deleted_at = now()
        self.save(update_fields=['is_deleted', 'deleted_at'])

    def restore(self):
        """
        Restore a soft-deleted instance by unmarking it as deleted.
        """
        self.is_deleted = False
        self.deleted_at = None
        self.restored_at = now()
        self.save(update_fields=['is_deleted', 'deleted_at', 'restored_at'])

    def toggle_visibility(self):
        """
        Toggle the visibility of the instance.
        """
        self.is_visible = not self.is_visible
        self.save(update_fields=['is_visible'])

    def hide(self):
        """
        Mark the instance as hidden.
        """
        self.is_hidden = True
        self.save(update_fields=['is_hidden'])

    def unhide(self):
        """
        Unmark the instance as hidden.
        """
        self.is_hidden = False
        self.save(update_fields=['is_hidden'])

    def save(self, *args, **kwargs):
        """
        Override save to log last_updated_by if provided.
        """
        user = kwargs.pop('user', None)
        if user:
            self.last_updated_by = user
        super().save(*args, **kwargs)

    def delete(self, *args, **kwargs):
        """
        Override delete to prevent signature mismatch with the base method.
        """
        if kwargs.pop('soft', True):
            self.soft_delete()
        else:
            super().delete(*args, **kwargs)

    def __str__(self):
        return f"{self.__class__.__name__} - ID {self.pk} (Visible: {self.is_visible}, Deleted: {self.is_deleted})"


class Address(MetadataModel):
    """User address model with encrypted PII fields"""
    
    ADDRESS_TYPE_CHOICES = (
        ('home', 'Home'),
        ('business', 'Business'),
        ('shipping', 'Shipping'),
        ('billing', 'Billing'),
    )
    
    # Primary keys and relationships
    address_id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        AppUser, 
        on_delete=models.CASCADE, 
        related_name='addresses',
        help_text="User who owns this address"
    )
    business_id = models.UUIDField(
        null=True, 
        blank=True, 
        help_text="Optional business ID for business addresses"
    )
    
    # Address information (encrypted PII)
    address_line_1 = models.CharField(max_length=500, help_text="Encrypted address line 1")
    address_line_2 = models.CharField(max_length=500, blank=True, null=True, help_text="Encrypted address line 2")
    city = models.CharField(max_length=255, help_text="Encrypted city")
    state_province = models.CharField(max_length=255, help_text="Encrypted state/province")
    postal_code = models.CharField(max_length=50, help_text="Encrypted postal code")
    country = models.CharField(max_length=100, help_text="Encrypted country")
    
    # Geographic coordinates (optional)
    latitude = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)
    
    # Address metadata
    address_type = models.CharField(max_length=20, choices=ADDRESS_TYPE_CHOICES, default='home')
    is_primary = models.BooleanField(default=False, help_text="Is this the primary address for the user?")
    
    # Additional fields
    address_name = models.CharField(
        max_length=100, 
        blank=True, 
        null=True, 
        help_text="Optional name for the address (e.g., 'Home', 'Office')"
    )
    delivery_instructions = models.TextField(
        max_length=500, 
        blank=True, 
        null=True,
        help_text="Special delivery instructions"
    )
    
    class Meta:
        db_table = "user_address"
        verbose_name = "User Address"
        verbose_name_plural = "User Addresses"
        indexes = [
            models.Index(fields=['user', 'address_type']),
            models.Index(fields=['user', 'is_primary']),
            models.Index(fields=['is_primary', 'is_deleted']),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['user', 'address_type'],
                condition=models.Q(is_primary=True, is_deleted=False),
                name='unique_primary_address_per_type'
            )
        ]
    
    def save(self, *args, **kwargs):
        """Override save to encrypt PII fields and handle primary address logic"""
        # Encrypt PII fields before saving
        self._encrypt_address_fields()
        
        # Handle primary address logic
        if self.is_primary:
            # Ensure only one primary address per user per type
            Address.objects.filter(
                user=self.user,
                address_type=self.address_type,
                is_primary=True,
                is_deleted=False
            ).exclude(address_id=self.address_id).update(is_primary=False)
        
        super().save(*args, **kwargs)
    
    def _encrypt_address_fields(self):
        """Encrypt address PII fields"""
        pii_fields = ['address_line_1', 'address_line_2', 'city', 'state_province', 'postal_code', 'country']
        
        for field in pii_fields:
            value = getattr(self, field, None)
            if value and not self._is_encrypted(value):
                encrypted_value = security_utils.encryption.encrypt_pii(value)
                setattr(self, field, encrypted_value)
    
    def _is_encrypted(self, value):
        """Check if a value is already encrypted"""
        try:
            security_utils.encryption.decrypt_pii(value)
            return True
        except:
            return False
    
    def get_decrypted_address_line_1(self):
        """Get decrypted address line 1"""
        if not self.address_line_1 or not self.address_line_1.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.address_line_1)
        except (ValueError, Exception):
            return self.address_line_1
    
    def get_decrypted_address_line_2(self):
        """Get decrypted address line 2"""
        if not self.address_line_2 or not self.address_line_2.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.address_line_2)
        except (ValueError, Exception):
            return self.address_line_2
    
    def get_decrypted_city(self):
        """Get decrypted city"""
        if not self.city or not self.city.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.city)
        except (ValueError, Exception):
            return self.city
    
    def get_decrypted_state_province(self):
        """Get decrypted state/province"""
        if not self.state_province or not self.state_province.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.state_province)
        except (ValueError, Exception):
            return self.state_province
    
    def get_decrypted_postal_code(self):
        """Get decrypted postal code"""
        if not self.postal_code or not self.postal_code.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.postal_code)
        except (ValueError, Exception):
            return self.postal_code
    
    def get_decrypted_country(self):
        """Get decrypted country"""
        if not self.country or not self.country.strip():
            return ""
        try:
            return security_utils.encryption.decrypt_pii(self.country)
        except (ValueError, Exception):
            return self.country
    
    def get_decrypted_data(self):
        """Get address data with PII fields decrypted"""
        return {
            'address_id': str(self.address_id),
            'user_id': self.user.id,
            'business_id': str(self.business_id) if self.business_id else None,
            'address_line_1': self.get_decrypted_address_line_1(),
            'address_line_2': self.get_decrypted_address_line_2(),
            'city': self.get_decrypted_city(),
            'state_province': self.get_decrypted_state_province(),
            'postal_code': self.get_decrypted_postal_code(),
            'country': self.get_decrypted_country(),
            'latitude': str(self.latitude) if self.latitude else None,
            'longitude': str(self.longitude) if self.longitude else None,
            'address_type': self.address_type,
            'is_primary': self.is_primary,
            'address_name': self.address_name,
            'delivery_instructions': self.delivery_instructions,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
        }
    
    def get_formatted_address(self):
        """Get a formatted address string"""
        address_parts = [
            self.get_decrypted_address_line_1(),
            self.get_decrypted_address_line_2(),
            self.get_decrypted_city(),
            self.get_decrypted_state_province(),
            self.get_decrypted_postal_code(),
            self.get_decrypted_country()
        ]
        
        # Filter out empty parts and join with appropriate separators
        filtered_parts = [part for part in address_parts if part and part.strip()]
        
        if len(filtered_parts) >= 4:  # Has at least city, state, postal, country
            # Format: Line1, Line2, City, State Postal, Country
            formatted = ', '.join(filtered_parts[:-3])  # Address lines
            formatted += f", {filtered_parts[-3]}"  # City
            formatted += f", {filtered_parts[-2]} {filtered_parts[-1]}"  # State Postal
            if len(filtered_parts) > 4:  # Has country
                formatted += f", {filtered_parts[-1]}"
        else:
            formatted = ', '.join(filtered_parts)
        
        return formatted
    
    def set_as_primary(self):
        """Set this address as the primary address for its type"""
        # Remove primary status from other addresses of the same type
        Address.objects.filter(
            user=self.user,
            address_type=self.address_type,
            is_primary=True,
            is_deleted=False
        ).exclude(address_id=self.address_id).update(is_primary=False)
        
        # Set this address as primary
        self.is_primary = True
        self.save()
    
    def __str__(self):
        address_name = self.address_name or f"{self.address_type.title()} Address"
        return f"{address_name} - {self.user.email} ({'Primary' if self.is_primary else 'Secondary'})"
