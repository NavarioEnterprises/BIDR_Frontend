import uuid

from django.db import models

from user.models import MetadataModel, User


class Buyer(MetadataModel):
    uid = models.UUIDField(default=uuid.uuid4, editable=False)
    is_active = models.BooleanField(default=True)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='buyers_profile')

    def __str__(self):
        return f"Buyer Profile for {self.user.email}"

    class Meta:
        db_table = "buyer"
        verbose_name = "Buyer"
        verbose_name_plural = "Buyers"


class BuyersAddressDetails(MetadataModel):
    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='address_details',
        help_text="The user or account this address belongs to."
    )
    postal_address = models.TextField(
        max_length=10, null=True, blank=True, help_text="Street number of the address."
    )
    physical_address = models.TextField(
        max_length=255, null=False, blank=False, help_text="Street name of the address."
    )
    location = models.CharField(
        max_length=100, null=True, blank=True, help_text="Suburb or neighborhood of the address."
    )
    contact_person_name = models.CharField(
        max_length=100, null=False, blank=False, help_text="City of the address."
    )
    contact_person_telephone = models.CharField(
        max_length=100, null=False, blank=False, help_text="Province or state of the address."
    )
    contact_person_email_address = models.CharField(
        max_length=10, null=False, blank=False, help_text="Postal code or ZIP code of the address."
    )
    platform_workflow_email_address = models.CharField(
        max_length=100, null=False, blank=False, default="South Africa", help_text="Country of the address."
    )
    is_primary = models.BooleanField(
        default=False, help_text="Indicates the primary address."
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['user'],
                condition=models.Q(is_primary=True),
                name='unique_primary_address_per_buyerr',
            )
        ]
        db_table = "buyers_address_details"
        verbose_name = "Buyers Address Detail"
        verbose_name_plural = "Buyers Address Details"

    def save(self, *args, **kwargs):
        # If this address is marked as primary, update other addresses for the user
        if self.is_primary:
            BuyersAddressDetails.objects.filter(user=self.user, is_primary=True).update(is_primary=False)
        super().save(*args, **kwargs)

    def __str__(self):
        parts = [self.physical_address, self.location, self.contact_person_name, self.contact_person_telephone, self.contact_person_email_address]
        return ", ".join(filter(None, parts))