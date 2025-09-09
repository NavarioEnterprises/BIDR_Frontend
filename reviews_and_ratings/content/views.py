from rest_framework import viewsets, status, filters, mixins
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth.models import User

from .models import FAQ, Blog, BlogComment, Policy, ContactSubmission, NewsletterSubscription
from .serializers import (
    FAQSerializer, BlogSerializer, BlogListSerializer, BlogCommentSerializer,
    PolicySerializer, ContactSubmissionSerializer, NewsletterSubscriptionSerializer
)


class FAQViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for FAQs - Read only for public access"""
    queryset = FAQ.objects.filter(is_active=True)
    serializer_class = FAQSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['category']
    search_fields = ['question', 'answer']
    ordering = ['category', 'order']

    @action(detail=False, methods=['get'])
    def categories(self, request):
        """Get all available FAQ categories"""
        categories = FAQ.CATEGORY_CHOICES
        return Response([{'value': cat[0], 'label': cat[1]} for cat in categories])


class BlogViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for Blogs - Read only for public access"""
    queryset = Blog.objects.filter(is_published=True)
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['section', 'is_featured', 'author']
    search_fields = ['title', 'description', 'content', 'tags']
    ordering_fields = ['created_at', 'published_at', 'likes', 'views']
    ordering = ['-published_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return BlogListSerializer
        return BlogSerializer

    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to increment view count"""
        instance = self.get_object()
        # Increment views
        instance.views += 1
        instance.save(update_fields=['views'])
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        """Like or unlike a blog post"""
        blog = self.get_object()
        action = request.data.get('action', 'like')  # 'like' or 'unlike'
        
        if action == 'like':
            blog.likes += 1
        elif action == 'unlike' and blog.likes > 0:
            blog.likes -= 1
        
        blog.save(update_fields=['likes'])
        return Response({'likes': blog.likes})

    @action(detail=True, methods=['post'])
    def add_comment(self, request, pk=None):
        """Add a comment to a blog post"""
        blog = self.get_object()
        content = request.data.get('content')
        auth_user_uid = request.data.get('auth_user_uid')
        
        if not content or not auth_user_uid:
            return Response(
                {'error': 'content and auth_user_uid are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user, created = User.objects.get_or_create(
            username=auth_user_uid,
            defaults={'email': f'{auth_user_uid}@bidr.com'}
        )
        
        comment = BlogComment.objects.create(
            blog=blog,
            user=user,
            content=content
        )
        
        serializer = BlogCommentSerializer(comment)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get featured blog posts"""
        featured_blogs = self.queryset.filter(is_featured=True)[:5]
        serializer = BlogListSerializer(featured_blogs, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def sections(self, request):
        """Get all available blog sections"""
        sections = Blog.SECTION_CHOICES
        return Response([{'value': sec[0], 'label': sec[1]} for sec in sections])


class PolicyViewSet(viewsets.ReadOnlyModelViewSet):
    """ViewSet for Policies - Read only for public access"""
    queryset = Policy.objects.filter(is_active=True)
    serializer_class = PolicySerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['policy_type']
    ordering = ['policy_type']

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """Get policy by type"""
        policy_type = request.query_params.get('type')
        if not policy_type:
            return Response(
                {'error': 'type parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            policy = self.queryset.get(policy_type=policy_type)
            serializer = self.get_serializer(policy)
            return Response(serializer.data)
        except Policy.DoesNotExist:
            return Response(
                {'error': 'Policy not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )


class ContactSubmissionViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    """ViewSet for Contact form submissions - Create only for public access"""
    queryset = ContactSubmission.objects.all()
    serializer_class = ContactSubmissionSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        """Create a contact submission"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        return Response(
            {'message': 'Your message has been sent successfully. We will get back to you soon.'},
            status=status.HTTP_201_CREATED
        )


class NewsletterSubscriptionViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    """ViewSet for Newsletter subscriptions - Create only for public access"""
    queryset = NewsletterSubscription.objects.all()
    serializer_class = NewsletterSubscriptionSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        """Subscribe to newsletter"""
        email = request.data.get('email')
        if not email:
            return Response(
                {'error': 'Email is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if already subscribed
        existing = NewsletterSubscription.objects.filter(email=email).first()
        if existing:
            if existing.is_active:
                return Response(
                    {'message': 'You are already subscribed to our newsletter.'}
                )
            else:
                # Reactivate subscription
                existing.is_active = True
                existing.save()
                return Response(
                    {'message': 'Your newsletter subscription has been reactivated.'}
                )
        
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        return Response(
            {'message': 'Thank you for subscribing to our newsletter!'},
            status=status.HTTP_201_CREATED
        )

    @action(detail=False, methods=['post'])
    def unsubscribe(self, request):
        """Unsubscribe from newsletter"""
        email = request.data.get('email')
        if not email:
            return Response(
                {'error': 'Email is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            subscription = NewsletterSubscription.objects.get(email=email)
            subscription.is_active = False
            from django.utils import timezone
            subscription.unsubscribed_at = timezone.now()
            subscription.save()
            
            return Response(
                {'message': 'You have been successfully unsubscribed from our newsletter.'}
            )
        except NewsletterSubscription.DoesNotExist:
            return Response(
                {'error': 'Email not found in our newsletter list.'}, 
                status=status.HTTP_404_NOT_FOUND
            )
