from rest_framework import serializers
from django.contrib.auth.models import User
from .models import FAQ, Blog, BlogComment, Policy, ContactSubmission, NewsletterSubscription


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name']


class FAQSerializer(serializers.ModelSerializer):
    category_display = serializers.CharField(source='get_category_display', read_only=True)
    
    class Meta:
        model = FAQ
        fields = ['id', 'question', 'answer', 'category', 'category_display', 'order', 'is_active']


class BlogCommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = BlogComment
        fields = ['id', 'user', 'content', 'is_approved', 'created_at']
        read_only_fields = ['user', 'created_at']


class BlogSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    section_display = serializers.CharField(source='get_section_display', read_only=True)
    image = serializers.SerializerMethodField()
    comments = BlogCommentSerializer(many=True, read_only=True)
    comments_count = serializers.SerializerMethodField()
    tags_list = serializers.SerializerMethodField()
    
    class Meta:
        model = Blog
        fields = [
            'id', 'title', 'description', 'content', 'image', 'image_url',
            'section', 'section_display', 'author', 'tags', 'tags_list',
            'likes', 'views', 'is_published', 'is_featured',
            'created_at', 'updated_at', 'published_at',
            'comments', 'comments_count'
        ]
        read_only_fields = ['author', 'created_at', 'updated_at', 'published_at', 'views']
    
    def get_image(self, obj):
        request = self.context.get('request')
        if obj.image:
            if request:
                return request.build_absolute_uri(obj.image)
            return obj.image
        return None
    
    def get_comments_count(self, obj):
        return obj.comments.filter(is_approved=True).count()
    
    def get_tags_list(self, obj):
        if obj.tags:
            return [tag.strip() for tag in obj.tags.split(',')]
        return []


class BlogListSerializer(serializers.ModelSerializer):
    """Simplified serializer for blog list views"""
    author = UserSerializer(read_only=True)
    section_display = serializers.CharField(source='get_section_display', read_only=True)
    image = serializers.SerializerMethodField()
    comments_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Blog
        fields = [
            'id', 'title', 'description', 'image', 'section', 'section_display',
            'author', 'likes', 'views', 'created_at', 'published_at', 'comments_count'
        ]
    
    def get_image(self, obj):
        request = self.context.get('request')
        if obj.image:
            if request:
                return request.build_absolute_uri(obj.image)
            return obj.image
        return None
    
    def get_comments_count(self, obj):
        return obj.comments.filter(is_approved=True).count()


class PolicySerializer(serializers.ModelSerializer):
    policy_type_display = serializers.CharField(source='get_policy_type_display', read_only=True)
    
    class Meta:
        model = Policy
        fields = [
            'id', 'title', 'policy_type', 'policy_type_display', 'content',
            'version', 'is_active', 'effective_date', 'created_at', 'updated_at'
        ]


class ContactSubmissionSerializer(serializers.ModelSerializer):
    subject_display = serializers.CharField(source='get_subject_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = ContactSubmission
        fields = [
            'id', 'name', 'email', 'phone', 'company', 'subject', 'subject_display',
            'message', 'status', 'status_display', 'created_at'
        ]
        read_only_fields = ['status', 'created_at']


class NewsletterSubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsletterSubscription
        fields = [
            'id', 'email', 'name', 'is_active', 'marketing_emails',
            'product_updates', 'weekly_digest', 'subscribed_at'
        ]
        read_only_fields = ['subscribed_at']
        
    def create(self, validated_data):
        # Set is_active to True when subscribing
        validated_data['is_active'] = True
        return super().create(validated_data)
