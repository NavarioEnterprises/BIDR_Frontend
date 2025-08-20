import uuid
from decimal import Decimal

# from django.contrib.gis.db import models as gis_models
from django.db import models
from django.utils import timezone
from django.core.validators import RegexValidator

from import_helper import setup_imports
setup_imports()
from user.models import MetadataModel, AppUser
from security.utils import security_utils


class Seller(MetadataModel):
    CHOICES = [
        ('engine_parts', 'Engine Parts'),
        ('body_parts', 'Body Parts'),
        ('suspension_parts', 'Suspension Parts'),
        ('transmission_parts', 'Transmission Parts'),
        ('batteries', 'Batteries'),
    ]

    user = models.OneToOneField(AppUser, on_delete=models.CASCADE, related_name='sellers_profile')
    registered_company_name = models.CharField(max_length=255, null=True, blank=True)
    trading_name = models.CharField(max_length=255, null=True, blank=True)
    registration_number = models.CharField(max_length=100, null=True, blank=True)
    vat_number = models.CharField(max_length=100, null=True, blank=True)
    website_url = models.URLField(null=True, blank=True)
    product_category = models.CharField(max_length=255, null=True, blank=True)
    product_subcategory = models.CharField(max_length=255, choices=CHOICES, null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Seller Profile for {self.user.email}"

    class Meta:
        db_table = "seller"
        verbose_name = "Seller"
        verbose_name_plural = "Sellers"


class SellerProfile(MetadataModel):
    """
    Enhanced seller profile integrating with existing Seller model.
    """
    APPROVAL_STATUS_CHOICES = [
        ('pending', 'Application Pending'),
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('suspended', 'Suspended'),
        ('deactivated', 'Deactivated'),
    ]

    DISPLAY_NAME_CHOICES = [
        ('registered', 'Registered Company Name'),
        ('trading', 'Trading Name'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    is_active = models.BooleanField(default=True)
    # Link to existing Seller model from the provided context
    seller = models.OneToOneField(
        'Seller',
        on_delete=models.CASCADE,
        related_name='profile'
    )

    # Enhanced business information
    approval_status = models.CharField(
        max_length=20,
        choices=APPROVAL_STATUS_CHOICES,
        default='pending',
        db_index=True
    )
    vendor_id = models.CharField(max_length=20, unique=True, editable=False)
    display_name_preference = models.CharField(
        max_length=20,
        choices=DISPLAY_NAME_CHOICES,
        default='trading'
    )

    # Business verification
    background_check_authorized = models.BooleanField(default=False)
    background_check_completed = models.BooleanField(default=False)
    background_check_passed = models.BooleanField(default=False)

    # Platform settings
    notification_preferences = models.JSONField(default=dict)
    auto_respond_enabled = models.BooleanField(default=False)
    minimum_order_value = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True
    )
    response_time_hours = models.PositiveIntegerField(default=24)

    # Performance metrics
    total_quotes_submitted = models.PositiveIntegerField(default=0)
    total_deals_won = models.PositiveIntegerField(default=0)
    total_deals_completed = models.PositiveIntegerField(default=0)
    average_rating = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        null=True,
        blank=True
    )
    response_rate_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00')
    )

    # Timestamps
    application_submitted_at = models.DateTimeField(null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    last_active_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['approval_status', 'created_at']),
            models.Index(fields=['vendor_id']),
            models.Index(fields=['average_rating']),
            models.Index(fields=['last_active_at']),
        ]

    def save(self, *args, **kwargs):
        if not self.vendor_id:
            self.vendor_id = f"V{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Profile for {self.seller.user.email} ({self.vendor_id})"

    @property
    def display_name(self):
        """Return the preferred display name."""
        if self.display_name_preference == 'registered':
            return self.seller.registered_company_name or self.seller.trading_name
        return self.seller.trading_name or self.seller.registered_company_name

    @property
    def completion_rate(self):
        """Calculate deal completion rate."""
        if self.total_deals_won == 0:
            return Decimal('0.00')
        return (Decimal(self.total_deals_completed) / Decimal(self.total_deals_won)) * 100

    def update_performance_metrics(self):
        """Update performance metrics from related data."""
        from django.db.models import Avg

        # Update ratings
        ratings = self.seller.user.ratings_received.filter(
            rating_type='buyer_to_seller'
        )
        if ratings.exists():
            self.average_rating = ratings.aggregate(
                avg=Avg('overall_rating')
            )['avg']

        # Update other metrics would be calculated from related models
        self.save()


class CompanyInfo(MetadataModel):
    company_name = models.CharField(max_length=255)
    trading_name = models.CharField(max_length=255)
    registration_number = models.CharField(max_length=100, validators=[RegexValidator(r'^\d+$', 'Enter a valid registration number.')])
    vat_number = models.CharField(max_length=100, validators=[RegexValidator(r'^\d+$', 'Enter a valid VAT number.')])
    website_url = models.URLField(blank=True, null=True)
    cipc_document_path = models.FileField(upload_to='documents/cipc/', blank=True, null=True)

    def __str__(self):
        return f"{self.company_name} ({self.registration_number})"


class CompanyContactInfo(MetadataModel):
    postal_address = models.TextField(max_length=500)
    physical_address = models.TextField(max_length=500)
    contact_person_name = models.CharField(max_length=100)
    contact_person_telephone = models.CharField(max_length=20)
    contact_person_email = models.EmailField()
    platform_workflow_email = models.EmailField()
    latitude = models.DecimalField(max_digits=10, decimal_places=8, null=True, blank=True)
    longitude = models.DecimalField(max_digits=11, decimal_places=8, null=True, blank=True)

    def __str__(self):
        return f"Contact Info for {self.contact_person_name}"


class BankingInfo(MetadataModel):
    bank_name = models.CharField(max_length=255)
    account_number = models.CharField(max_length=100)
    branch_code = models.CharField(max_length=100)
    account_holder = models.CharField(max_length=255)

    def __str__(self):
        return f"{self.bank_name} - {self.account_holder}"    


class BusinessRegistration(MetadataModel):
    seller = models.OneToOneField(Seller, on_delete=models.CASCADE, related_name='business_registration')
    company_info = models.OneToOneField(CompanyInfo, on_delete=models.CASCADE, related_name='business_registration')
    contact_info = models.OneToOneField(CompanyContactInfo, on_delete=models.CASCADE, related_name='business_registration')
    banking_info = models.OneToOneField(BankingInfo, on_delete=models.CASCADE, related_name='business_registration')
    product_categories = models.JSONField(default=list)

    def __str__(self):
        return f"Business Registration for {self.seller.user.email}"


class SellerVettingLog(MetadataModel):
    CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('declined', 'Declined')
    ]

    seller = models.ForeignKey(
        Seller,
        on_delete=models.CASCADE,
        related_name='sellers_documents',
        help_text="The seller associated with this vetting log."
    )
    certificate_of_incorporation = models.FileField(
        upload_to='media/seller_documents/certificate_of_incors/', blank=True, null=True,
        help_text="Uploaded certificate of incorporation document of the seller. Shows the company registration number, date of incorporation, and company type (PTY LTD, etc.)."
    )
    certificate_of_incorporation_status = models.CharField(
        max_length=20,
        choices=CHOICES,
        default='pending',
        help_text="Status of the certificate of incorporation document approval."
    )
    company_extract = models.FileField(
        upload_to='media/seller_documents/company_extracts/', blank=True, null=True,
        help_text="Uploaded company extract for the seller. A snapshot of all current CIPC-held particulars (directors, shareholding, address)."
    )
    company_extract_status = models.CharField(
        max_length=20,
        choices=CHOICES,
        default='pending',
        help_text="Status of the company extract approval."
    )

    def all_documents_approved(self):
        """
        Check if all document statuses are approved.
        """
        document_statuses = [
            self.certificate_of_incorporation_status,
            self.company_extract_status,
        ]
        return all(status == 'approved' for status in document_statuses)

    def document_status_summary(self):
        """
        Provide a summary of document statuses.
        """
        return {
            "Certificate of Incorporation": self.certificate_of_incorporation_status,
            "Company Extract": self.company_extract_status,
        }

    def __str__(self):
        return f"Vetting Log for {self.seller.user.email}"


class SellersAddressDetails(MetadataModel):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(
        Seller,
        on_delete=models.CASCADE,
        related_name='sellers_address_details',
        help_text="The seller this address belongs to."
    )
    postal_address = models.TextField(
        max_length=500, null=True, blank=True, help_text="Postal address of the business."
    )
    physical_address = models.TextField(
        max_length=500, null=False, blank=False, help_text="Physical address of the business."
    )
    latitude = models.DecimalField(
        max_digits=10, decimal_places=8, null=True, blank=True,
        help_text="Latitude coordinate of the business location."
    )
    longitude = models.DecimalField(
        max_digits=11, decimal_places=8, null=True, blank=True,
        help_text="Longitude coordinate of the business location."
    )
    location_address = models.CharField(
        max_length=500, null=True, blank=True,
        help_text="Human-readable address corresponding to the geographic location."
    )
    city = models.CharField(
        max_length=100, null=True, blank=True, help_text="City of the address."
    )
    province = models.CharField(
        max_length=100, null=True, blank=True, help_text="Province or state of the address."
    )
    postal_code = models.CharField(
        max_length=20, null=True, blank=True, help_text="Postal code or ZIP code of the address."
    )
    country = models.CharField(
        max_length=100, null=False, blank=False, default="South Africa",
        help_text="Country of the address."
    )
    contact_person_name = models.CharField(
        max_length=100, null=False, blank=False, help_text="Name of the contact person at this address."
    )
    contact_person_telephone = models.CharField(
        max_length=20, null=False, blank=False, help_text="Telephone number of the contact person."
    )
    contact_person_email_address = models.EmailField(
        max_length=255, null=False, blank=False, help_text="Email address of the contact person."
    )
    platform_workflow_email_address = models.EmailField(
        max_length=255, null=False, blank=False,
        help_text="Email address for platform workflow notifications_service."
    )
    is_primary = models.BooleanField(
        default=False, help_text="Indicates if this is the primary business address."
    )
    is_billing_address = models.BooleanField(
        default=False, help_text="Indicates if this address is used for billing purposes."
    )
    is_shipping_address = models.BooleanField(
        default=False, help_text="Indicates if this address is used for shipping purposes."
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['user'],
                condition=models.Q(is_primary=True),
                name='unique_primary_address_per_seller',
            )
        ]
        db_table = "sellers_address_details"
        verbose_name = "Sellers Address Detail"
        verbose_name_plural = "Sellers Address Details"
        indexes = [
            models.Index(fields=['user', 'is_primary'], name='seller_address_primary_idx'),
            models.Index(fields=['city'], name='seller_address_city_idx'),
            models.Index(fields=['province'], name='seller_address_province_idx'),
            models.Index(fields=['country'], name='seller_address_country_idx'),
        ]

    def save(self, *args, **kwargs):
        # If this address is marked as primary, update other addresses for the user
        if self.is_primary:
            SellersAddressDetails.objects.filter(user=self.user, is_primary=True).update(is_primary=False)
        super().save(*args, **kwargs)

    def __str__(self):
        parts = [self.physical_address, self.city, self.province, self.country]
        return ", ".join(filter(None, parts))

    def get_coordinates(self):
        """
        Get latitude and longitude as a tuple
        """
        if self.latitude and self.longitude:
            return (float(self.latitude), float(self.longitude))
        return None

    def set_coordinates(self, latitude, longitude):
        """
        Set latitude and longitude coordinates
        """
        self.latitude = latitude
        self.longitude = longitude

    def get_distance_to(self, other_latitude, other_longitude):
        """
        Calculate distance to another location in kilometers using Haversine formula
        """
        if self.latitude and self.longitude and other_latitude and other_longitude:
            import math
            
            # Convert to radians
            lat1, lon1 = math.radians(float(self.latitude)), math.radians(float(self.longitude))
            lat2, lon2 = math.radians(other_latitude), math.radians(other_longitude)
            
            # Haversine formula
            dlat = lat2 - lat1
            dlon = lon2 - lon1
            a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
            c = 2 * math.asin(math.sqrt(a))
            r = 6371  # Earth's radius in kilometers
            
            return c * r
        return None

    def get_full_address(self):
        """
        Get formatted full address
        """
        parts = []
        if self.physical_address:
            parts.append(self.physical_address)
        if self.city:
            parts.append(self.city)
        if self.province:
            parts.append(self.province)
        if self.postal_code:
            parts.append(self.postal_code)
        if self.country:
            parts.append(self.country)
        return ", ".join(parts)


class SellerBankAccount(MetadataModel):
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, related_name='sellers_bank_accounts')
    bank_account_type = models.CharField(max_length=255, null=True, blank=True)
    bank_name = models.CharField(max_length=255, null=True, blank=True)
    bank_account_number = models.CharField(max_length=100, null=True, blank=True)
    bank_branch_code = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Seller Bank Account for {self.user.email}"

    class Meta:
        db_table = "seller_bank_accounts"
        verbose_name = "Seller Bank Account"
        verbose_name_plural = "Seller Bank Accounts"
