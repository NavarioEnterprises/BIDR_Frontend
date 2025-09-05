from rest_framework import serializers
from .models import PaymentGateway


class PaymentGatewaySerializer(serializers.ModelSerializer):
    """
    Serializer for PaymentGateway model
    """
    
    class Meta:
        model = PaymentGateway
        fields = [
            'id', 'name', 'slug', 'is_active', 'config',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def validate_config(self, value):
        """
        Validate payment gateway configuration
        """
        if not isinstance(value, dict):
            raise serializers.ValidationError("Config must be a valid JSON object")
        
        # Basic validation for required fields based on gateway type
        if self.instance and self.instance.slug == 'paystack':
            required_fields = ['public_key', 'secret_key']
            for field in required_fields:
                if field not in value:
                    raise serializers.ValidationError(f"Paystack config requires '{field}' field")
        
        return value
