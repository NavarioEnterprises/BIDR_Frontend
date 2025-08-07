from datetime import timedelta
import uuid

from django.db import models
from django.utils.timezone import now

from user.models import AppUser


def default_expires_at():
    """Return a datetime 5 minutes from now."""
    return now() + timedelta(minutes=5)


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


class OTP(MetadataModel):
    id = models.BigAutoField(primary_key=True)
    uuid = models.UUIDField(default=uuid.uuid4, editable=False)
    user = models.ForeignKey(AppUser, on_delete=models.CASCADE, related_name="otps",
                             help_text="The user associated with this OTP.")
    otp = models.CharField(max_length=6, help_text="One-time password for authentication.")
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(default=default_expires_at, help_text="Expiration time for the OTP.")
    verified_at = models.DateTimeField(null=True, blank=True, default=None,
                                       help_text="Timestamp when the OTP was verified.")
    devices = models.JSONField(default=list, help_text="List of devices the OTP is valid for.")

    class Meta:
        db_table = "authentication_otp"
        indexes = [models.Index(fields=["otp"], name="otp_idx"),
                   models.Index(fields=["expires_at"], name="expires_at_idx"), ]
        verbose_name = "One-Time Password"
        verbose_name_plural = "One-Time Passwords"

    def is_expired(self):
        """
        Check if the OTP has expired.
        """
        return now() > self.expires_at

    def __str__(self):
        return f"OTP {self.otp} for {self.user.email} (Expires: {self.expires_at})"

    def validate_for_device(self, device_id):  # Device-specific validation
        return device_id in self.devices