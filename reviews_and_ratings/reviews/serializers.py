from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Review, ReviewHelpful, Ticket, TicketMessage


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email']


class ReviewSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    helpful_count = serializers.SerializerMethodField()
    not_helpful_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Review
        fields = [
            'id', 'user', 'product_id', 'seller_id', 'title', 'content',
            'rating', 'is_approved', 'is_featured', 'created_at', 'updated_at',
            'helpful_count', 'not_helpful_count'
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']
    
    def get_helpful_count(self, obj):
        return obj.helpful_votes.filter(is_helpful=True).count()
    
    def get_not_helpful_count(self, obj):
        return obj.helpful_votes.filter(is_helpful=False).count()


class ReviewHelpfulSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = ReviewHelpful
        fields = ['id', 'review', 'user', 'is_helpful', 'created_at']
        read_only_fields = ['user', 'created_at']


class TicketMessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    
    class Meta:
        model = TicketMessage
        fields = ['id', 'sender', 'message', 'is_from_staff', 'created_at']
        read_only_fields = ['sender', 'is_from_staff', 'created_at']


class TicketSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    assignee = UserSerializer(read_only=True)
    messages = TicketMessageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Ticket
        fields = [
            'id', 'ticket_id', 'user', 'auth_user_uid', 'subject', 'description',
            'status', 'priority', 'assignee', 'created_at', 'updated_at',
            'resolved_at', 'messages'
        ]
        read_only_fields = ['user', 'ticket_id', 'created_at', 'updated_at', 'messages']


class TicketCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ticket
        fields = ['auth_user_uid', 'subject', 'description', 'priority']
        
    def create(self, validated_data):
        # Get or create user based on auth_user_uid
        auth_user_uid = validated_data.get('auth_user_uid')
        user, created = User.objects.get_or_create(
            username=auth_user_uid,
            defaults={'email': f'{auth_user_uid}@bidr.com'}
        )
        validated_data['user'] = user
        return super().create(validated_data)
