from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from chat_core.models import BaseModel
from chat_conversations.models import Conversation
from chat_messaging.models import Message
import re
import json


class PIIDetectionRule(BaseModel):
    """Rules for detecting personally identifiable information."""
    
    PII_TYPES = [
        ('email', 'Email Address'),
        ('phone', 'Phone Number'),
        ('ssn', 'Social Security Number'),
        ('credit_card', 'Credit Card Number'),
        ('bank_account', 'Bank Account Number'),
        ('address', 'Physical Address'),
        ('passport', 'Passport Number'),
        ('drivers_license', 'Driver\'s License'),
        ('tax_id', 'Tax ID'),
        ('date_of_birth', 'Date of Birth'),
        ('custom', 'Custom PII Type'),
    ]
    
    ACTION_TYPES = [
        ('mask', 'Mask with Asterisks'),
        ('redact', 'Remove Completely'),
        ('tokenize', 'Replace with Token'),
        ('encrypt', 'Encrypt'),
        ('flag', 'Flag for Review'),
        ('block', 'Block Message'),
    ]
    
    name = models.CharField(max_length=100)
    pii_type = models.CharField(max_length=30, choices=PII_TYPES)
    description = models.TextField(blank=True)
    
    # Detection patterns
    regex_pattern = models.TextField(help_text="Regex pattern for detection")
    context_keywords = models.JSONField(default=list, help_text="Keywords that indicate PII context")
    exclusion_patterns = models.JSONField(default=list, help_text="Patterns to exclude from detection")
    
    # Actions
    action = models.CharField(max_length=20, choices=ACTION_TYPES, default='mask')
    replacement_text = models.CharField(max_length=50, default='[REDACTED]')
    
    # Configuration
    is_enabled = models.BooleanField(default=True)
    sensitivity_level = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ], default='medium')
    
    # Regional settings
    applicable_regions = models.JSONField(default=list, help_text="Regions where this rule applies")
    language_codes = models.JSONField(default=list, help_text="Languages this rule applies to")
    
    # Statistics
    detection_count = models.PositiveIntegerField(default=0)
    false_positive_count = models.PositiveIntegerField(default=0)
    last_triggered = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = "PII Detection Rule"
        verbose_name_plural = "PII Detection Rules"
        indexes = [
            models.Index(fields=['pii_type']),
            models.Index(fields=['is_enabled']),
            models.Index(fields=['sensitivity_level']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.get_pii_type_display()})"
    
    def detect_pii(self, text):
        """Detect PII in text using this rule."""
        if not self.is_enabled:
            return []
        
        matches = []
        try:
            pattern_matches = re.finditer(self.regex_pattern, text, re.IGNORECASE)
            for match in pattern_matches:
                # Check exclusion patterns
                is_excluded = False
                for exclusion in self.exclusion_patterns:
                    if re.search(exclusion, match.group(), re.IGNORECASE):
                        is_excluded = True
                        break
                
                if not is_excluded:
                    matches.append({
                        'type': self.pii_type,
                        'match': match.group(),
                        'start': match.start(),
                        'end': match.end(),
                        'confidence': self.calculate_confidence(text, match)
                    })
        except re.error:
            pass
        
        return matches
    
    def calculate_confidence(self, text, match):
        """Calculate confidence score based on context."""
        confidence = 0.7  # Base confidence
        
        # Check for context keywords around the match
        window_start = max(0, match.start() - 50)
        window_end = min(len(text), match.end() + 50)
        context = text[window_start:window_end].lower()
        
        keyword_matches = sum(1 for keyword in self.context_keywords if keyword.lower() in context)
        confidence += keyword_matches * 0.1
        
        return min(1.0, confidence)
    
    def apply_action(self, text, matches):
        """Apply the configured action to detected PII."""
        if not matches:
            return text
        
        # Sort matches by position (reverse order to maintain positions)
        sorted_matches = sorted(matches, key=lambda x: x['start'], reverse=True)
        
        result_text = text
        for match in sorted_matches:
            start, end = match['start'], match['end']
            original = match['match']
            
            if self.action == 'mask':
                replacement = '*' * len(original)
            elif self.action == 'redact':
                replacement = ''
            elif self.action == 'tokenize':
                replacement = f"[{self.pii_type.upper()}_TOKEN]"
            else:
                replacement = self.replacement_text
            
            result_text = result_text[:start] + replacement + result_text[end:]
        
        return result_text


class PIIDetectionResult(BaseModel):
    """Results of PII detection on content."""
    
    # Content reference
    content_type = models.CharField(max_length=20, choices=[
        ('message', 'Message'),
        ('profile', 'User Profile'),
        ('file', 'File Content'),
    ])
    content_id = models.CharField(max_length=100)
    
    # Detection details
    rule = models.ForeignKey(PIIDetectionRule, on_delete=models.CASCADE, related_name='detection_results')
    detected_text = models.TextField(help_text="The actual PII text detected")
    context = models.TextField(help_text="Surrounding context")
    
    # Position and metadata
    start_position = models.PositiveIntegerField()
    end_position = models.PositiveIntegerField()
    confidence_score = models.DecimalField(max_digits=5, decimal_places=4)
    
    # Processing
    action_taken = models.CharField(max_length=20, choices=PIIDetectionRule.ACTION_TYPES)
    processed_content = models.TextField(blank=True, help_text="Content after processing")
    
    # Review status
    is_reviewed = models.BooleanField(default=False)
    is_false_positive = models.BooleanField(default=False)
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='reviewed_pii')
    reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewer_notes = models.TextField(blank=True)
    
    # User and system info
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='pii_detections')
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    class Meta:
        verbose_name = "PII Detection Result"
        verbose_name_plural = "PII Detection Results"
        indexes = [
            models.Index(fields=['content_type', 'content_id']),
            models.Index(fields=['user']),
            models.Index(fields=['rule']),
            models.Index(fields=['is_reviewed']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.rule.pii_type} detected in {self.content_type} - {self.confidence_score}"


class DataMaskingProfile(BaseModel):
    """User-specific data masking preferences."""
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='data_masking_profile')
    
    # Global settings
    auto_masking_enabled = models.BooleanField(default=True)
    strict_mode = models.BooleanField(default=False, help_text="More aggressive PII detection")
    
    # PII type preferences
    mask_email = models.BooleanField(default=True)
    mask_phone = models.BooleanField(default=True)
    mask_ssn = models.BooleanField(default=True)
    mask_credit_card = models.BooleanField(default=True)
    mask_bank_account = models.BooleanField(default=True)
    mask_address = models.BooleanField(default=True)
    mask_date_of_birth = models.BooleanField(default=True)
    
    # Business context exceptions
    allow_business_info_sharing = models.BooleanField(default=False)
    trusted_domains = models.JSONField(default=list, help_text="Domains allowed for info sharing")
    
    # Custom masking rules
    custom_patterns = models.JSONField(default=list, help_text="User-defined patterns to mask")
    whitelist_patterns = models.JSONField(default=list, help_text="Patterns to never mask")
    
    # Notification preferences
    notify_on_detection = models.BooleanField(default=True)
    notify_on_sharing = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = "Data Masking Profile"
        verbose_name_plural = "Data Masking Profiles"
    
    def __str__(self):
        return f"Data masking profile for {self.user.username}"
    
    def should_mask_pii_type(self, pii_type):
        """Check if a specific PII type should be masked."""
        type_mapping = {
            'email': self.mask_email,
            'phone': self.mask_phone,
            'ssn': self.mask_ssn,
            'credit_card': self.mask_credit_card,
            'bank_account': self.mask_bank_account,
            'address': self.mask_address,
            'date_of_birth': self.mask_date_of_birth,
        }
        return type_mapping.get(pii_type, True)


class PrivacyConsent(BaseModel):
    """User consent for data processing and sharing."""
    
    CONSENT_TYPES = [
        ('data_processing', 'Data Processing'),
        ('pii_sharing', 'PII Sharing'),
        ('analytics', 'Analytics'),
        ('marketing', 'Marketing'),
        ('third_party_sharing', 'Third Party Sharing'),
        ('data_retention', 'Data Retention'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='privacy_consents')
    consent_type = models.CharField(max_length=30, choices=CONSENT_TYPES)
    
    # Consent details
    is_granted = models.BooleanField()
    consent_text = models.TextField(help_text="Full text of what user consented to")
    version = models.CharField(max_length=10, help_text="Version of consent form")
    
    # Context
    granted_at = models.DateTimeField(default=timezone.now)
    expires_at = models.DateTimeField(null=True, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Tracking
    revoked_at = models.DateTimeField(null=True, blank=True)
    revocation_reason = models.TextField(blank=True)
    
    class Meta:
        verbose_name = "Privacy Consent"
        verbose_name_plural = "Privacy Consents"
        unique_together = ['user', 'consent_type', 'version']
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['consent_type']),
            models.Index(fields=['is_granted']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self):
        status = "Granted" if self.is_granted else "Denied"
        return f"{self.user.username} - {self.get_consent_type_display()} - {status}"
    
    def is_valid(self):
        """Check if consent is still valid."""
        if not self.is_granted:
            return False
        
        if self.revoked_at:
            return False
        
        if self.expires_at and timezone.now() > self.expires_at:
            return False
        
        return True
    
    def revoke(self, reason=""):
        """Revoke the consent."""
        self.revoked_at = timezone.now()
        self.revocation_reason = reason
        self.save(update_fields=['revoked_at', 'revocation_reason'])


class DataRetentionPolicy(BaseModel):
    """Policies for data retention and deletion."""
    
    DATA_TYPES = [
        ('messages', 'Chat Messages'),
        ('files', 'File Uploads'),
        ('metadata', 'User Metadata'),
        ('logs', 'System Logs'),
        ('analytics', 'Analytics Data'),
    ]
    
    name = models.CharField(max_length=100)
    data_type = models.CharField(max_length=30, choices=DATA_TYPES)
    description = models.TextField(blank=True)
    
    # Retention settings
    retention_period_days = models.PositiveIntegerField(help_text="Days to retain data")
    auto_deletion_enabled = models.BooleanField(default=True)
    
    # Conditions
    conditions = models.JSONField(default=dict, help_text="Conditions for applying this policy")
    exceptions = models.JSONField(default=dict, help_text="Exceptions to this policy")
    
    # Legal requirements
    legal_basis = models.CharField(max_length=100, blank=True)
    jurisdiction = models.CharField(max_length=50, default='US')
    
    # Status
    is_active = models.BooleanField(default=True)
    effective_date = models.DateTimeField(default=timezone.now)
    
    class Meta:
        verbose_name = "Data Retention Policy"
        verbose_name_plural = "Data Retention Policies"
        indexes = [
            models.Index(fields=['data_type']),
            models.Index(fields=['is_active']),
        ]
    
    def __str__(self):
        return f"{self.name} - {self.retention_period_days} days"


class DataDeletionRequest(BaseModel):
    """User requests for data deletion (Right to be Forgotten)."""
    
    REQUEST_TYPES = [
        ('full_account', 'Full Account Deletion'),
        ('specific_data', 'Specific Data Types'),
        ('conversation', 'Specific Conversation'),
        ('time_range', 'Time Range'),
    ]
    
    STATUS_CHOICES = [
        ('submitted', 'Submitted'),
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('partially_completed', 'Partially Completed'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='deletion_requests')
    request_type = models.CharField(max_length=30, choices=REQUEST_TYPES)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='submitted')
    
    # Request details
    reason = models.TextField(help_text="Reason for deletion request")
    data_types = models.JSONField(default=list, help_text="Specific data types to delete")
    date_range_start = models.DateTimeField(null=True, blank=True)
    date_range_end = models.DateTimeField(null=True, blank=True)
    
    # Processing
    processed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='processed_deletions')
    processed_at = models.DateTimeField(null=True, blank=True)
    completion_notes = models.TextField(blank=True)
    
    # Legal compliance
    legal_basis = models.CharField(max_length=100, blank=True, help_text="GDPR Article, CCPA Section, etc.")
    verification_method = models.CharField(max_length=50, blank=True)
    verification_completed = models.BooleanField(default=False)
    
    # Results
    items_deleted = models.PositiveIntegerField(default=0)
    items_retained = models.PositiveIntegerField(default=0)
    retention_reasons = models.JSONField(default=dict, help_text="Reasons for retaining specific items")
    
    class Meta:
        verbose_name = "Data Deletion Request"
        verbose_name_plural = "Data Deletion Requests"
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['status']),
            models.Index(fields=['request_type']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"Deletion request by {self.user.username} - {self.get_status_display()}"


class PrivacyAuditLog(BaseModel):
    """Audit trail for privacy-related actions."""
    
    ACTION_TYPES = [
        ('pii_detected', 'PII Detected'),
        ('pii_masked', 'PII Masked'),
        ('consent_granted', 'Consent Granted'),
        ('consent_revoked', 'Consent Revoked'),
        ('data_accessed', 'Data Accessed'),
        ('data_exported', 'Data Exported'),
        ('data_deleted', 'Data Deleted'),
        ('policy_applied', 'Policy Applied'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='privacy_audit_logs')
    action_type = models.CharField(max_length=30, choices=ACTION_TYPES)
    
    # Action details
    description = models.TextField()
    data_types_involved = models.JSONField(default=list)
    legal_basis = models.CharField(max_length=100, blank=True)
    
    # Technical details
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Context
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='performed_privacy_actions')
    automated = models.BooleanField(default=False)
    
    class Meta:
        verbose_name = "Privacy Audit Log"
        verbose_name_plural = "Privacy Audit Logs"
        indexes = [
            models.Index(fields=['user']),
            models.Index(fields=['action_type']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.get_action_type_display()}"
