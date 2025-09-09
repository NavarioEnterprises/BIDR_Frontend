from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Review, ReviewHelpful, ReviewResponse, Ticket, TicketMessage


# serializers.py
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Review, ReviewHelpful


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model with minimal information"""
    display_name = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'display_name']
        read_only_fields = ['id', 'username', 'display_name']
    
    def get_display_name(self, obj):
        if obj.first_name:
            return f"{obj.first_name} {obj.last_name}".strip()
        return obj.username


class ReviewResponseSerializer(serializers.ModelSerializer):
    """Serializer for ReviewResponse model"""
    responder = UserSerializer(read_only=True)
    responder_display_name = serializers.SerializerMethodField()
    
    class Meta:
        model = ReviewResponse
        fields = ['id', 'responder', 'responder_display_name', 'response_text', 'created_at', 'updated_at']
        read_only_fields = ['id', 'responder', 'created_at', 'updated_at']
    
    def get_responder_display_name(self, obj):
        """Get the display name of the responder"""
        if obj.responder.first_name:
            return f"{obj.responder.first_name} {obj.responder.last_name}".strip()
        return obj.responder.username


class ReviewHelpfulSerializer(serializers.ModelSerializer):
    """Serializer for ReviewHelpful model"""
    user = UserSerializer(read_only=True)
    review_id = serializers.IntegerField(source='review.id', read_only=True)
    
    class Meta:
        model = ReviewHelpful
        fields = ['id', 'review_id', 'user', 'is_helpful', 'created_at']
        read_only_fields = ['id', 'created_at', 'user', 'review_id']


class ReviewSerializer(serializers.ModelSerializer):
    """Enhanced serializer for Review model with additional computed fields"""
    user = UserSerializer(read_only=True)
    user_display_name = serializers.SerializerMethodField()
    helpful_count = serializers.SerializerMethodField()
    not_helpful_count = serializers.SerializerMethodField()
    total_votes = serializers.SerializerMethodField()
    helpfulness_percentage = serializers.SerializerMethodField()
    current_user_vote = serializers.SerializerMethodField()
    seller_response = ReviewResponseSerializer(read_only=True)
    
    # Fields for Dart compatibility
    uuid = serializers.UUIDField(source='id', read_only=True)
    customerName = serializers.SerializerMethodField()
    description = serializers.CharField(source='content', read_only=True)
    comment = serializers.CharField(source='content', read_only=True)
    type = serializers.SerializerMethodField()
    
    class Meta:
        model = Review
        fields = [
            'id', 'uuid', 'user', 'user_display_name', 'customerName',
            'product_id', 'seller_id', 'title', 'content', 'description', 
            'comment', 'rating', 'is_approved', 'is_featured',
            'created_at', 'updated_at', 'helpful_count', 'not_helpful_count',
            'total_votes', 'helpfulness_percentage', 'current_user_vote',
            'seller_response', 'type'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at', 'is_approved', 'is_featured']
    
    def get_user_display_name(self, obj):
        """Get the display name of the review author"""
        if obj.user.first_name:
            return f"{obj.user.first_name} {obj.user.last_name}".strip()
        return obj.user.username
    
    def get_helpful_count(self, obj):
        """Count of users who found this review helpful"""
        return obj.helpful_votes.filter(is_helpful=True).count()
    
    def get_not_helpful_count(self, obj):
        """Count of users who found this review not helpful"""
        return obj.helpful_votes.filter(is_helpful=False).count()
    
    def get_total_votes(self, obj):
        """Total number of helpful/not helpful votes"""
        return obj.helpful_votes.count()
    
    def get_helpfulness_percentage(self, obj):
        """Percentage of users who found this review helpful"""
        total = obj.helpful_votes.count()
        if total == 0:
            return 0
        helpful = obj.helpful_votes.filter(is_helpful=True).count()
        return round((helpful / total) * 100, 1)
    
    def get_current_user_vote(self, obj):
        """Get the current user's vote on this review (if any)"""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            # Check if auth_user_uid is provided in the request
            auth_user_uid = None
            if request and hasattr(request, 'query_params'):
                auth_user_uid = request.query_params.get('auth_user_uid')
            elif request and hasattr(request, 'data'):
                auth_user_uid = request.data.get('auth_user_uid')
            
            if auth_user_uid:
                try:
                    user = User.objects.get(username=auth_user_uid)
                    vote = obj.helpful_votes.filter(user=user).first()
                    if vote:
                        return {
                            'voted': True,
                            'is_helpful': vote.is_helpful
                        }
                except User.DoesNotExist:
                    pass
            
            return {
                'voted': False,
                'is_helpful': None
            }
        
        # For authenticated users
        vote = obj.helpful_votes.filter(user=request.user).first()
        if vote:
            return {
                'voted': True,
                'is_helpful': vote.is_helpful
            }
        return {
            'voted': False,
            'is_helpful': None
        }
    
    def get_customerName(self, obj):
        """Get customer name for Dart compatibility"""
        return self.get_user_display_name(obj)
    
    def get_type(self, obj):
        """Get type field for Dart compatibility"""
        return 'review'


class ReviewCreateSerializer(serializers.ModelSerializer):
    """Serializer specifically for creating reviews"""
    seller_id = serializers.CharField(required=False, allow_blank=True)
    
    class Meta:
        model = Review
        fields = ['product_id', 'seller_id', 'title', 'content', 'rating']
        
    def validate_rating(self, value):
        """Ensure rating is between 1 and 5"""
        if value < 1 or value > 5:
            raise serializers.ValidationError("Rating must be between 1 and 5")
        return value
    
    def validate_product_id(self, value):
        """Ensure product_id is not empty"""
        if not value or value.strip() == '':
            raise serializers.ValidationError("Product ID is required and cannot be empty")
        return value.strip()
    
    def validate_content(self, value):
        """Ensure review content meets minimum requirements"""
        if len(value.strip()) < 10:
            raise serializers.ValidationError("Review content must be at least 10 characters long")
        return value.strip()


class ReviewStatisticsSerializer(serializers.Serializer):
    """Serializer for review statistics"""
    total_reviews = serializers.IntegerField()
    average_rating = serializers.FloatField()
    rating_distribution = serializers.DictField(
        child=serializers.IntegerField()
    )
    
    # Additional statistics
    one_star = serializers.SerializerMethodField()
    two_star = serializers.SerializerMethodField()
    three_star = serializers.SerializerMethodField()
    four_star = serializers.SerializerMethodField()
    five_star = serializers.SerializerMethodField()
    
    def get_one_star(self, obj):
        return obj.get('rating_distribution', {}).get('1', 0)
    
    def get_two_star(self, obj):
        return obj.get('rating_distribution', {}).get('2', 0)
    
    def get_three_star(self, obj):
        return obj.get('rating_distribution', {}).get('3', 0)
    
    def get_four_star(self, obj):
        return obj.get('rating_distribution', {}).get('4', 0)
    
    def get_five_star(self, obj):
        return obj.get('rating_distribution', {}).get('5', 0)


class ReviewListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing reviews"""
    user_display_name = serializers.SerializerMethodField()
    helpful_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Review
        fields = [
            'id', 'user_display_name', 'title', 'rating', 
            'created_at', 'helpful_count', 'is_featured'
        ]
        
    def get_user_display_name(self, obj):
        if obj.user.first_name:
            return f"{obj.user.first_name} {obj.user.last_name}".strip()
        return obj.user.username
    
    def get_helpful_count(self, obj):
        return obj.helpful_votes.filter(is_helpful=True).count()


# For nested serialization in other models
class ReviewSummarySerializer(serializers.ModelSerializer):
    """Ultra-light serializer for review summaries"""
    user_name = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = Review
        fields = ['id', 'user_name', 'rating', 'title', 'created_at']
        read_only_fields = fields
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
