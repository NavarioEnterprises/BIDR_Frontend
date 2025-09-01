from rest_framework import serializers
from .models import SMSPortalConfig, SMSMessage, SMSUsageStats, SMSTemplate


class SMSPortalConfigSerializer(serializers.ModelSerializer):
    """Serializer for SMS Portal configuration"""
    success_rate = serializers.SerializerMethodField()
    
    class Meta:
        model = SMSPortalConfig
        fields = [
            'id', 'name', 'api_url', 'default_sender_id', 'is_active',
            'rate_limit_per_minute', 'last_used', 'success_rate',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'last_used', 'created_at', 'updated_at']
        extra_kwargs = {
            'api_key': {'write_only': True},
            'api_secret': {'write_only': True},
        }
    
    def get_success_rate(self, obj):
        """Calculate success rate from recent messages"""
        from django.utils import timezone
        from datetime import timedelta
        
        last_30_days = timezone.now() - timedelta(days=30)
        recent_messages = SMSMessage.objects.filter(
            created_at__gte=last_30_days
        )
        
        total = recent_messages.count()
        if total == 0:
            return 100.0
        
        successful = recent_messages.filter(status__in=['sent', 'delivered']).count()
        return round((successful / total) * 100, 1)


class SMSMessageSerializer(serializers.ModelSerializer):
    """Serializer for SMS messages"""
    
    class Meta:
        model = SMSMessage
        fields = [
            'id', 'recipient_phone', 'message_content', 'sender_id',
            'external_message_id', 'external_status', 'status',
            'message_type', 'cost', 'credits_used',
            'queued_at', 'sent_at', 'delivered_at',
            'retry_count', 'max_retries', 'next_retry_at',
            'notification_id', 'error_message', 'error_code',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'external_message_id', 'external_status', 'status',
            'cost', 'credits_used', 'queued_at', 'sent_at', 'delivered_at',
            'retry_count', 'error_message', 'error_code', 'response_data',
            'created_at', 'updated_at'
        ]


class SendSMSSerializer(serializers.Serializer):
    """Serializer for sending SMS requests"""
    phone_number = serializers.CharField(max_length=20)
    message = serializers.CharField(max_length=1000)
    sender_id = serializers.CharField(max_length=20, required=False)
    message_type = serializers.ChoiceField(
        choices=[
            ('otp', 'OTP Verification'),
            ('notification', 'General Notification'),
            ('alert', 'Alert Message'),
            ('marketing', 'Marketing Message'),
            ('system', 'System Message'),
        ],
        default='notification'
    )
    notification_id = serializers.UUIDField(required=False)
    
    def validate_phone_number(self, value):
        """Validate phone number format"""
        import re
        # Allow South African numbers starting with 0, and international format
        phone_pattern = r'^\+?[0-9]\d{7,14}$'  # Allow 0 as first digit, 8-15 total digits
        clean_phone = value.replace(' ', '').replace('-', '').replace('(', '').replace(')', '')
        if not re.match(phone_pattern, clean_phone):
            raise serializers.ValidationError("Invalid phone number format. Must be 8-15 digits.")
        return clean_phone


class SendOTPSMSSerializer(serializers.Serializer):
    """Serializer for sending OTP SMS"""
    phone_number = serializers.CharField(max_length=20)
    otp_code = serializers.CharField(max_length=10)
    template_name = serializers.CharField(max_length=100, default='otp_verification')
    context = serializers.JSONField(required=False, default=dict)
    
    def validate_phone_number(self, value):
        """Validate phone number format"""
        import re
        # Allow South African numbers starting with 0, and international format
        phone_pattern = r'^\+?[0-9]\d{7,14}$'  # Allow 0 as first digit, 8-15 total digits
        clean_phone = value.replace(' ', '').replace('-', '').replace('(', '').replace(')', '')
        if not re.match(phone_pattern, clean_phone):
            raise serializers.ValidationError("Invalid phone number format. Must be 8-15 digits.")
        return clean_phone
    
    def validate_otp_code(self, value):
        """Validate OTP code"""
        if not value.isdigit():
            raise serializers.ValidationError("OTP code must contain only digits")
        if len(value) < 4 or len(value) > 8:
            raise serializers.ValidationError("OTP code must be between 4 and 8 digits")
        return value


class SMSUsageStatsSerializer(serializers.ModelSerializer):
    """Serializer for SMS usage statistics"""
    delivery_rate = serializers.ReadOnlyField()
    success_rate = serializers.ReadOnlyField()
    
    class Meta:
        model = SMSUsageStats
        fields = [
            'id', 'date', 'total_sent', 'total_delivered', 'total_failed',
            'total_bounced', 'total_cost', 'total_credits_used',
            'otp_count', 'notification_count', 'alert_count',
            'marketing_count', 'system_count', 'delivery_rate',
            'success_rate', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class SMSTemplateSerializer(serializers.ModelSerializer):
    """Serializer for SMS templates"""
    
    class Meta:
        model = SMSTemplate
        fields = [
            'id', 'name', 'content', 'message_type', 'is_active',
            'sender_id', 'usage_count', 'last_used',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'usage_count', 'last_used', 'created_at', 'updated_at']
    
    def validate_content(self, value):
        """Validate template content for common placeholders"""
        import re
        # Check for balanced braces
        open_braces = value.count('{')
        close_braces = value.count('}')
        
        if open_braces != close_braces:
            raise serializers.ValidationError("Template has unmatched braces")
        
        # Extract placeholders
        placeholders = re.findall(r'\{(\w+)\}', value)
        
        # For OTP templates, ensure 'code' or 'otp' placeholder exists
        if self.initial_data.get('message_type') == 'otp':
            if not any(placeholder in ['code', 'otp'] for placeholder in placeholders):
                raise serializers.ValidationError(
                    "OTP templates must contain {code} or {otp} placeholder"
                )
        
        return value


class MessageStatusUpdateSerializer(serializers.Serializer):
    """Serializer for bulk message status updates"""
    message_ids = serializers.ListField(
        child=serializers.UUIDField(),
        min_length=1,
        max_length=100
    )


class BulkSMSSerializer(serializers.Serializer):
    """Serializer for bulk SMS sending"""
    recipients = serializers.ListField(
        child=serializers.CharField(max_length=20),
        min_length=1,
        max_length=1000
    )
    message = serializers.CharField(max_length=1000)
    sender_id = serializers.CharField(max_length=20, required=False)
    message_type = serializers.ChoiceField(
        choices=[
            ('notification', 'General Notification'),
            ('alert', 'Alert Message'),
            ('marketing', 'Marketing Message'),
            ('system', 'System Message'),
        ],
        default='notification'
    )
    template_name = serializers.CharField(max_length=100, required=False)
    context = serializers.JSONField(required=False, default=dict)
    
    def validate_recipients(self, value):
        """Validate all phone numbers in recipients list"""
        import re
        # Allow South African numbers starting with 0, and international format
        phone_pattern = r'^\+?[0-9]\d{7,14}$'  # Allow 0 as first digit, 8-15 total digits
        
        invalid_numbers = []
        clean_numbers = []
        for phone in value:
            clean_phone = phone.replace(' ', '').replace('-', '').replace('(', '').replace(')', '')
            if not re.match(phone_pattern, clean_phone):
                invalid_numbers.append(phone)
            else:
                clean_numbers.append(clean_phone)
        
        if invalid_numbers:
            raise serializers.ValidationError(
                f"Invalid phone numbers: {', '.join(invalid_numbers)}"
            )
        
        return clean_numbers