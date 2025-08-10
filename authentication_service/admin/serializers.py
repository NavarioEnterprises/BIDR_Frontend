from rest_framework import serializers

from .models import AdminProfile, AdminActivityLog, AdminNotification


class AdminProfileSerializer(serializers.ModelSerializer):
    """Serializer for AdminProfile"""
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    subordinates_count = serializers.IntegerField(source='get_subordinates_count', read_only=True)
    permissions_summary = serializers.JSONField(source='get_permissions_summary', read_only=True)
    is_account_locked = serializers.BooleanField(read_only=True)

    class Meta:
        model = AdminProfile
        fields = [
            'uid', 'user_email', 'user_full_name', 'employee_id',
            'department', 'access_level', 'job_title', 'manager',
            'hire_date', 'office_location', 'phone_extension',
            'emergency_contact_name', 'emergency_contact_phone',
            'emergency_contact_relationship', 'can_approve_sellers',
            'can_manage_users', 'can_access_financial_data',
            'can_moderate_content', 'last_login_ip', 'failed_login_attempts',
            'account_locked_until', 'notes', 'subordinates_count',
            'permissions_summary', 'is_account_locked',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'uid', 'user_email', 'user_full_name', 'subordinates_count',
            'permissions_summary', 'is_account_locked', 'failed_login_attempts',
            'account_locked_until', 'last_login_ip', 'created_at', 'updated_at'
        ]


class AdminActivityLogSerializer(serializers.ModelSerializer):
    """Serializer for AdminActivityLog"""
    admin_name = serializers.CharField(source='admin.user.get_full_name', read_only=True)
    admin_employee_id = serializers.CharField(source='admin.employee_id', read_only=True)
    target_user_name = serializers.CharField(source='target_user.get_full_name', read_only=True)

    class Meta:
        model = AdminActivityLog
        fields = [
            'id', 'admin', 'admin_name', 'admin_employee_id',
            'action', 'target_user', 'target_user_name',
            'description', 'ip_address', 'user_agent',
            'additional_data', 'created_at'
        ]
        read_only_fields = ['id', 'admin_name', 'admin_employee_id', 'target_user_name', 'created_at']


class AdminNotificationSerializer(serializers.ModelSerializer):
    """Serializer for AdminNotification"""
    admin_name = serializers.CharField(source='admin.user.get_full_name', read_only=True)
    is_expired = serializers.BooleanField(read_only=True)

    class Meta:
        model = AdminNotification
        fields = [
            'id', 'admin', 'admin_name', 'title', 'message',
            'notification_type', 'priority', 'is_read', 'read_at',
            'action_url', 'action_label', 'expires_at', 'is_expired',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'id', 'admin_name', 'is_expired', 'read_at',
            'created_at', 'updated_at'
        ]


class AdminCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating an admin profile"""

    class Meta:
        model = AdminProfile
        fields = [
            'employee_id', 'department', 'access_level', 'job_title',
            'manager', 'hire_date', 'office_location', 'phone_extension',
            'emergency_contact_name', 'emergency_contact_phone',
            'emergency_contact_relationship', 'can_approve_sellers',
            'can_manage_users', 'can_access_financial_data',
            'can_moderate_content', 'notes'
        ]

    def create(self, validated_data):
        """Create admin profile for the authenticated user"""
        user = self.context['request'].user
        admin_profile = AdminProfile.objects.create(user=user, **validated_data)
        return admin_profile


class AdminActivityLogCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating admin activity logs"""

    class Meta:
        model = AdminActivityLog
        fields = [
            'action', 'target_user', 'description',
            'ip_address', 'user_agent', 'additional_data'
        ]

    def create(self, validated_data):
        """Create activity log for current admin"""
        admin = self.context['admin']
        activity_log = AdminActivityLog.objects.create(admin=admin, **validated_data)
        return activity_log


class AdminNotificationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating admin notifications"""

    class Meta:
        model = AdminNotification
        fields = [
            'admin', 'title', 'message', 'notification_type',
            'priority', 'action_url', 'action_label', 'expires_at'
        ]
