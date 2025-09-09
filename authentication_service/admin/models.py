import uuid
from datetime import timedelta

from django.db import models
from django.utils import timezone

from import_helper import setup_imports
setup_imports()
from user.models import MetadataModel, AppUser


class AdminProfile(MetadataModel):
    """
    Extended profile for administrator user
    """
    DEPARTMENT_CHOICES = [
        ('operations', 'Operations'),
        ('finance', 'Finance'),
        ('customer_service', 'Customer Service'),
        ('technical', 'Technical'),
        ('legal', 'Legal'),
        ('marketing', 'Marketing'),
    ]

    ACCESS_LEVEL_CHOICES = [
        ('super_admin', 'Super Administrator'),
        ('admin', 'Administrator'),
        ('moderator', 'Moderator'),
        ('viewer', 'Viewer'),
    ]

    uid = models.UUIDField(default=uuid.uuid4, editable=False, unique=True)
    user = models.OneToOneField(
        AppUser,
        on_delete=models.CASCADE,
        related_name='admin_profile',
        help_text="The user associated with this admin profile"
    )
    employee_id = models.CharField(
        max_length=50,
        unique=True,
        help_text="Unique employee identification number"
    )
    department = models.CharField(
        max_length=50,
        choices=DEPARTMENT_CHOICES,
        help_text="Department the admin belongs to"
    )
    access_level = models.CharField(
        max_length=20,
        choices=ACCESS_LEVEL_CHOICES,
        default='admin',
        help_text="Access level for administrative functions"
    )
    job_title = models.CharField(
        max_length=100,
        help_text="Official job title"
    )
    manager = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='subordinates',
        help_text="Direct manager/supervisor"
    )
    hire_date = models.DateField(
        help_text="Date when the admin was hired"
    )
    office_location = models.CharField(
        max_length=100,
        help_text="Physical office location"
    )
    phone_extension = models.CharField(
        max_length=10,
        null=True,
        blank=True,
        help_text="Office phone extension"
    )
    emergency_contact_name = models.CharField(
        max_length=100,
        help_text="Emergency contact person name"
    )
    emergency_contact_phone = models.CharField(
        max_length=20,
        help_text="Emergency contact phone number"
    )
    emergency_contact_relationship = models.CharField(
        max_length=50,
        help_text="Relationship to emergency contact"
    )
    can_approve_sellers = models.BooleanField(
        default=False,
        help_text="Can approve seller applications"
    )
    can_manage_users = models.BooleanField(
        default=False,
        help_text="Can manage user accounts"
    )
    can_access_financial_data = models.BooleanField(
        default=False,
        help_text="Can access financial reports and data"
    )
    can_moderate_content = models.BooleanField(
        default=False,
        help_text="Can moderate platform content"
    )
    last_login_ip = models.GenericIPAddressField(
        null=True,
        blank=True,
        help_text="Last known login IP address"
    )
    failed_login_attempts = models.PositiveIntegerField(
        default=0,
        help_text="Number of consecutive failed login attempts"
    )
    account_locked_until = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Account locked until this timestamp"
    )
    notes = models.TextField(
        blank=True,
        help_text="Additional notes about the admin"
    )

    class Meta:
        db_table = "admin_profile"
        verbose_name = "Admin Profile"
        verbose_name_plural = "Admin Profiles"
        indexes = [
            models.Index(fields=['employee_id'], name='admin_employee_id_idx'),
            models.Index(fields=['department'], name='admin_department_idx'),
            models.Index(fields=['access_level'], name='admin_access_level_idx'),
        ]

    def __str__(self):
        return f"Admin Profile: {self.user.first_name} {self.user.last_name} ({self.employee_id})"

    def save(self, *args, **kwargs):
        if not self.uid:
            self.uid = uuid.uuid4()
        super().save(*args, **kwargs)

    def is_account_locked(self):
        """Check if the admin account is currently locked"""
        if self.account_locked_until:
            return timezone.now() < self.account_locked_until
        return False

    def unlock_account(self):
        """Unlock the admin account"""
        self.account_locked_until = None
        self.failed_login_attempts = 0
        self.save(update_fields=['account_locked_until', 'failed_login_attempts'])

    def increment_failed_login(self):
        """Increment failed login attempts and lock account if necessary"""
        self.failed_login_attempts += 1

        # Lock account after 5 failed attempts for 30 minutes
        if self.failed_login_attempts >= 5:
            self.account_locked_until = timezone.now() + timedelta(minutes=30)

        self.save(update_fields=['failed_login_attempts', 'account_locked_until'])

    def reset_failed_login_attempts(self):
        """Reset failed login attempts on successful login"""
        if self.failed_login_attempts > 0:
            self.failed_login_attempts = 0
            self.save(update_fields=['failed_login_attempts'])

    def get_permissions_summary(self):
        """Get a summary of admin permissions"""
        return {
            'can_approve_sellers': self.can_approve_sellers,
            'can_manage_users': self.can_manage_users,
            'can_access_financial_data': self.can_access_financial_data,
            'can_moderate_content': self.can_moderate_content,
        }

    def get_subordinates_count(self):
        """Get count of direct subordinates"""
        return self.subordinates.count()


class AdminActivityLog(MetadataModel):
    """
    Log of admin activities for audit purposes
    """
    ACTION_CHOICES = [
        ('login', 'Login'),
        ('logout', 'Logout'),
        ('user_created', 'User Created'),
        ('user_updated', 'User Updated'),
        ('user_deleted', 'User Deleted'),
        ('seller_approved', 'Seller Approved'),
        ('seller_rejected', 'Seller Rejected'),
        ('document_reviewed', 'Document Reviewed'),
        ('content_moderated', 'Content Moderated'),
        ('financial_data_accessed', 'Financial Data Accessed'),
        ('settings_changed', 'Settings Changed'),
    ]

    admin = models.ForeignKey(
        AdminProfile,
        on_delete=models.CASCADE,
        related_name='activity_logs',
        help_text="Admin who performed the action"
    )
    action = models.CharField(
        max_length=50,
        choices=ACTION_CHOICES,
        help_text="Type of action performed"
    )
    target_user = models.ForeignKey(
        AppUser,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='admin_actions_received',
        help_text="User who was the target of the action (if applicable)"
    )
    description = models.TextField(
        help_text="Detailed description of the action"
    )
    ip_address = models.GenericIPAddressField(
        help_text="IP address from which the action was performed"
    )
    user_agent = models.TextField(
        blank=True,
        help_text="User agent string of the browser/client"
    )
    additional_data = models.JSONField(
        default=dict,
        blank=True,
        help_text="Additional data related to the action"
    )

    class Meta:
        db_table = "admin_activity_log"
        verbose_name = "Admin Activity Log"
        verbose_name_plural = "Admin Activity Logs"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['admin', 'created_at'], name='admin_activity_admin_date_idx'),
            models.Index(fields=['action'], name='admin_activity_action_idx'),
            models.Index(fields=['target_user'], name='admin_activity_target_idx'),
        ]

    def __str__(self):
        return f"{self.admin.user.first_name} {self.admin.user.last_name} - {self.action} at {self.created_at}"


class AdminNotification(MetadataModel):
    """
    Notifications for admin user
    """
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]

    TYPE_CHOICES = [
        ('system', 'System'),
        ('user_action', 'User Action'),
        ('security', 'Security'),
        ('business', 'Business'),
        ('technical', 'Technical'),
    ]

    admin = models.ForeignKey(
        AdminProfile,
        on_delete=models.CASCADE,
        related_name='notifications_service',
        help_text="Admin who should receive this notification"
    )
    title = models.CharField(
        max_length=200,
        help_text="Notification title"
    )
    message = models.TextField(
        help_text="Notification message content"
    )
    notification_type = models.CharField(
        max_length=20,
        choices=TYPE_CHOICES,
        help_text="Type of notification"
    )
    priority = models.CharField(
        max_length=10,
        choices=PRIORITY_CHOICES,
        default='medium',
        help_text="Priority level of the notification"
    )
    is_read = models.BooleanField(
        default=False,
        help_text="Whether the notification has been read"
    )
    read_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When the notification was read"
    )
    action_url = models.URLField(
        blank=True,
        help_text="URL for action related to this notification"
    )
    action_label = models.CharField(
        max_length=50,
        blank=True,
        help_text="Label for the action button"
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When this notification expires"
    )

    class Meta:
        db_table = "admin_notification"
        verbose_name = "Admin Notification"
        verbose_name_plural = "Admin Notifications"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['admin', 'is_read'], name='admin_notif_read_idx'),
            models.Index(fields=['priority'], name='admin_notif_priority_idx'),
            models.Index(fields=['notification_type'], name='admin_notif_type_idx'),
        ]

    def __str__(self):
        return f"Notification for {self.admin.user.first_name} {self.admin.user.last_name}: {self.title}"

    def mark_as_read(self):
        """Mark notification as read"""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])

    def is_expired(self):
        """Check if notification has expired"""
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False

