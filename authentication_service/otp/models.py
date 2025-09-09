from datetime import timedelta
import uuid

from django.db import models
from django.utils.timezone import now

from import_helper import setup_imports
setup_imports()
from user.models import AppUser, MetadataModel


def default_expires_at():
    """Return a datetime 15 minutes from now."""
    return now() + timedelta(minutes=15)


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
