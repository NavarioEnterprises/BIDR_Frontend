from rest_framework import serializers
from .models import PaymentAnalytics


class PaymentAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for PaymentAnalytics model
    """
    
    class Meta:
        model = PaymentAnalytics
        fields = [
            'id', 'date', 'total_transactions', 'total_amount',
            'successful_transactions', 'failed_transactions',
            'average_amount', 'currency', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class AnalyticsSummarySerializer(serializers.Serializer):
    """
    Serializer for analytics summary data
    """
    period = serializers.CharField()
    total_transactions = serializers.IntegerField()
    total_amount = serializers.DecimalField(max_digits=15, decimal_places=2)
    successful_transactions = serializers.IntegerField()
    failed_transactions = serializers.IntegerField()
    success_rate = serializers.FloatField()
    average_amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    growth_rate = serializers.FloatField(required=False)


class DateRangeFilterSerializer(serializers.Serializer):
    """
    Serializer for date range filtering
    """
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    
    def validate(self, data):
        if data['start_date'] > data['end_date']:
            raise serializers.ValidationError("Start date must be before end date")
        return data
