from rest_framework import serializers

from .models import SecurityPolicy, SecurityAuditLog, BlockedIP, SecurityQuestion, UserSecurityQuestion, \
    TwoFactorMethod, APIKey


class SecurityPolicySerializer(serializers.ModelSerializer):
    """
    Serializer for SecurityPolicy model
    """
    created_by_name = serializers.CharField(source='created_by.get_full_name', read_only=True)

    class Meta:
        model = SecurityPolicy
        fields = '__all__'
        read_only_fields = ('uid', 'created_at', 'updated_at')

    def validate(self, data):
        """
        Validate security policy data
        """
        # Validate policy data based on policy type
        if 'policy_type' in data and 'policy_data' in data:
            policy_type = data['policy_type']
            policy_data = data['policy_data']

            if policy_type == 'password':
                required_fields = ['min_length', 'require_uppercase', 'require_lowercase',
                                   'require_numbers', 'require_special_chars', 'password_history']
                for field in required_fields:
                    if field not in policy_data:
                        raise serializers.ValidationError({
                            'policy_data': f"'{field}' is required for password policies"
                        })

            elif policy_type == 'session':
                required_fields = ['session_timeout_minutes', 'max_concurrent_sessions']
                for field in required_fields:
                    if field not in policy_data:
                        raise serializers.ValidationError({
                            'policy_data': f"'{field}' is required for session policies"
                        })

        # Validate effective dates
        if 'effective_from' in data and 'effective_to' in data and data['effective_to']:
            if data['effective_from'] >= data['effective_to']:
                raise serializers.ValidationError({
                    'effective_to': 'Effective to date must be after effective from date'
                })

        return data


class SecurityAuditLogSerializer(serializers.ModelSerializer):
    """
    Serializer for SecurityAuditLog model
    """
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = SecurityAuditLog
        fields = '__all__'
        read_only_fields = ('uid', 'timestamp')


class BlockedIPSerializer(serializers.ModelSerializer):
    """
    Serializer for BlockedIP model
    """
    blocked_by_name = serializers.CharField(source='blocked_by.get_full_name', read_only=True)
    is_currently_active = serializers.SerializerMethodField()

    class Meta:
        model = BlockedIP
        fields = '__all__'
        read_only_fields = ('uid', 'blocked_at')

    def get_is_currently_active(self, obj):
        return obj.is_active()

    def validate(self, data):
        """
        Validate blocked IP data
        """
        # Validate blocked_until for non-permanent blocks
        if 'is_permanent' in data and not data['is_permanent'] and 'blocked_until' not in data:
            raise serializers.ValidationError({
                'blocked_until': 'Blocked until date is required for non-permanent blocks'
            })

        return data


class SecurityQuestionSerializer(serializers.ModelSerializer):
    """
    Serializer for SecurityQuestion model
    """

    class Meta:
        model = SecurityQuestion
        fields = '__all__'
        read_only_fields = ('uid', 'created_at', 'updated_at')


class UserSecurityQuestionSerializer(serializers.ModelSerializer):
    """
    Serializer for UserSecurityQuestion model
    """
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    question_text = serializers.CharField(source='question.question_text', read_only=True)

    class Meta:
        model = UserSecurityQuestion
        fields = '__all__'
        read_only_fields = ('uid', 'created_at', 'updated_at')
        extra_kwargs = {
            'answer_hash': {'write_only': True}
        }

    def validate(self, data):
        """
        Validate user security question data
        """
        # Prevent duplicate questions for the same user
        if 'user' in data and 'question' in data:
            # Skip this validation if we're updating
            if self.instance:
                return data

            existing = UserSecurityQuestion.objects.filter(
                user=data['user'],
                question=data['question']
            ).exists()

            if existing:
                raise serializers.ValidationError({
                    'question': 'This user has already answered this security question'
                })

        return data


class TwoFactorMethodSerializer(serializers.ModelSerializer):
    """
    Serializer for TwoFactorMethod model
    """
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = TwoFactorMethod
        fields = '__all__'
        read_only_fields = ('uid', 'created_at', 'updated_at', 'last_used')
        extra_kwargs = {
            'secret_key': {'write_only': True},
            'backup_codes': {'write_only': True}
        }

    def validate(self, data):
        """
        Validate two-factor method data
        """
        # Validate method-specific fields
        if 'method_type' in data:
            method_type = data['method_type']

            if method_type == 'sms' and not data.get('identifier'):
                raise serializers.ValidationError({
                    'identifier': 'Phone number is required for SMS two-factor authentication'
                })

            elif method_type == 'email' and not data.get('identifier'):
                raise serializers.ValidationError({
                    'identifier': 'Email is required for email two-factor authentication'
                })

            elif method_type == 'authenticator_app' and not data.get('secret_key'):
                raise serializers.ValidationError({
                    'secret_key': 'Secret key is required for authenticator app two-factor authentication'
                })

            elif method_type == 'backup_codes' and not data.get('backup_codes'):
                raise serializers.ValidationError({
                    'backup_codes': 'Backup codes are required for backup codes two-factor authentication'
                })

        # Ensure only one primary method per user
        if 'is_primary' in data and data['is_primary'] and 'user' in data:
            # Skip this validation if we're updating and not changing is_primary
            if self.instance and self.instance.is_primary and self.instance.user == data['user']:
                return data

            existing = TwoFactorMethod.objects.filter(
                user=data['user'],
                is_primary=True
            ).exists()

            if existing:
                raise serializers.ValidationError({
                    'is_primary': 'This user already has a primary two-factor method'
                })

        return data


class APIKeySerializer(serializers.ModelSerializer):
    """
    Serializer for APIKey model
    """
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    is_expired = serializers.SerializerMethodField()

    class Meta:
        model = APIKey
        fields = '__all__'
        read_only_fields = ('uid', 'key_prefix', 'key_hash', 'created_at', 'updated_at', 'last_used')

    def get_is_expired(self, obj):
        return obj.is_expired()

    def validate(self, data):
        """
        Validate API key data
        """
        # Validate permissions format
        if 'permissions' in data:
            if not isinstance(data['permissions'], dict):
                raise serializers.ValidationError({
                    'permissions': 'Permissions must be a JSON object'
                })

        return data
