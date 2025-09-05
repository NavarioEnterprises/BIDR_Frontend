from rest_framework import viewsets, status, filters
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from django.contrib.auth.models import User
from django.shortcuts import get_object_or_404

from .models import Review, ReviewHelpful, ReviewResponse, Ticket, TicketMessage
from .serializers import (
    ReviewSerializer, ReviewHelpfulSerializer, TicketSerializer,
    TicketCreateSerializer, TicketMessageSerializer
)


# views.py - Updated ViewSet with proper serializer usage
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticatedOrReadOnly
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import filters
from django.db import transaction, models
from django.shortcuts import get_object_or_404
from .models import Review, ReviewHelpful, User
from .serializers import (
    ReviewSerializer, 
    ReviewHelpfulSerializer, 
    ReviewCreateSerializer,
    ReviewListSerializer,
    ReviewStatisticsSerializer
)


class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.filter(is_approved=True)
    serializer_class = ReviewSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['product_id', 'seller_id', 'rating', 'is_featured']
    search_fields = ['title', 'content', 'user__username']
    ordering_fields = ['created_at', 'rating', 'helpful_votes']
    ordering = ['-created_at']

    def get_serializer_class(self):
        """Use different serializers for different actions"""
        if self.action == 'create':
            return ReviewCreateSerializer
        elif self.action == 'list':
            return ReviewListSerializer
        return ReviewSerializer

    def get_serializer_context(self):
        """Pass request context to serializers"""
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

    def create(self, request, *args, **kwargs):
        """Override create to handle review submission with validation"""
        # Extract data from request
        auth_user_uid = request.data.get('auth_user_uid')
        product_id = request.data.get('product_id', '').strip()
        seller_id = request.data.get('seller_id', '').strip() or None  # Convert empty string to None
        rating = request.data.get('rating')
        content = request.data.get('content', '').strip()
        title = request.data.get('title', '').strip()
        customer_name = request.data.get('customer_name', '').strip()

        # Validation
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not product_id:
            return Response(
                {'error': 'product_id is required and cannot be empty'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if not rating or not isinstance(rating, int) or rating < 1 or rating > 5:
            return Response(
                {'error': 'rating must be an integer between 1 and 5'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if len(content) < 10:
            return Response(
                {'error': 'content must be at least 10 characters long'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        # Generate title if not provided
        if not title:
            title = f'Review by {customer_name}' if customer_name else f'Review by User {auth_user_uid[:8]}'

        try:
            with transaction.atomic():
                # Create or get user
                user, created = User.objects.get_or_create(
                    username=auth_user_uid,
                    defaults={
                        'email': f'{auth_user_uid}@bidr.com',
                        'first_name': customer_name.split()[0] if customer_name else '',
                        'last_name': ' '.join(customer_name.split()[1:]) if customer_name and len(customer_name.split()) > 1 else ''
                    }
                )

                # Check if user already reviewed this product
                existing_review = Review.objects.filter(
                    user=user,
                    product_id=product_id
                ).first()

                # Prepare clean data for serializer
                review_data = {
                    'product_id': product_id,
                    'seller_id': seller_id,
                    'title': title,
                    'content': content,
                    'rating': rating
                }

                if existing_review:
                    # Update existing review
                    serializer = ReviewCreateSerializer(
                        existing_review, 
                        data=review_data, 
                        partial=True
                    )
                    serializer.is_valid(raise_exception=True)
                    review = serializer.save()
                    
                    # Return full review data
                    output_serializer = ReviewSerializer(review, context={'request': request})
                    return Response(
                        {
                            'message': 'Review updated successfully',
                            'review': output_serializer.data
                        },
                        status=status.HTTP_200_OK
                    )
                else:
                    # Create new review
                    serializer = ReviewCreateSerializer(data=review_data)
                    serializer.is_valid(raise_exception=True)
                    review = serializer.save(user=user)
                    
                    # Return full review data
                    output_serializer = ReviewSerializer(review, context={'request': request})
                    return Response(
                        {
                            'message': 'Review submitted successfully',
                            'review': output_serializer.data
                        },
                        status=status.HTTP_201_CREATED
                    )
                    
        except Exception as e:
            return Response(
                {'error': f'Failed to submit review: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def mark_helpful(self, request, pk=None):
        """Mark a review as helpful or not helpful"""
        review = self.get_object()
        is_helpful = request.data.get('is_helpful', True)
        auth_user_uid = request.data.get('auth_user_uid')
        
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user, created = User.objects.get_or_create(
                username=auth_user_uid,
                defaults={'email': f'{auth_user_uid}@bidr.com'}
            )
            
            helpful_vote, created = ReviewHelpful.objects.update_or_create(
                review=review,
                user=user,
                defaults={'is_helpful': is_helpful}
            )
            
            # Return updated review data with new vote counts
            review_serializer = ReviewSerializer(review, context={'request': request})
            return Response({
                'vote': ReviewHelpfulSerializer(helpful_vote).data,
                'review': review_serializer.data,
                'message': 'Vote recorded successfully'
            })
            
        except Exception as e:
            return Response(
                {'error': f'Failed to record vote: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def by_product(self, request):
        """Get reviews for a specific product with statistics"""
        product_id = request.query_params.get('product_id')
        if not product_id:
            return Response(
                {'error': 'product_id parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Get reviews with optional filtering
        reviews = self.queryset.filter(product_id=product_id)
        
        # Apply additional filters if provided
        rating_filter = request.query_params.get('rating')
        if rating_filter:
            reviews = reviews.filter(rating=rating_filter)
        
        featured_only = request.query_params.get('featured_only', 'false').lower() == 'true'
        if featured_only:
            reviews = reviews.filter(is_featured=True)
        
        # Sort by helpfulness if requested
        sort_by = request.query_params.get('sort_by', 'recent')
        if sort_by == 'helpful':
            reviews = reviews.annotate(
                helpful_count=models.Count(
                    'helpful_votes',
                    filter=models.Q(helpful_votes__is_helpful=True)
                )
            ).order_by('-helpful_count', '-created_at')
        elif sort_by == 'rating_high':
            reviews = reviews.order_by('-rating', '-created_at')
        elif sort_by == 'rating_low':
            reviews = reviews.order_by('rating', '-created_at')
        else:  # recent
            reviews = reviews.order_by('-created_at')
        
        # Calculate statistics
        all_reviews = self.queryset.filter(product_id=product_id)
        total_reviews = all_reviews.count()
        
        if total_reviews > 0:
            avg_rating = all_reviews.aggregate(models.Avg('rating'))['rating__avg']
            rating_distribution = {
                str(i): all_reviews.filter(rating=i).count() 
                for i in range(1, 6)
            }
        else:
            avg_rating = 0
            rating_distribution = {str(i): 0 for i in range(1, 6)}
        
        # Paginate results
        page = self.paginate_queryset(reviews)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response({
                'reviews': serializer.data,
                'statistics': {
                    'total_reviews': total_reviews,
                    'average_rating': round(avg_rating, 2) if avg_rating else 0,
                    'rating_distribution': rating_distribution
                }
            })
        
        serializer = self.get_serializer(reviews, many=True)
        statistics_data = {
            'total_reviews': total_reviews,
            'average_rating': round(avg_rating, 2) if avg_rating else 0,
            'rating_distribution': rating_distribution
        }
        
        return Response({
            'reviews': serializer.data,
            'statistics': ReviewStatisticsSerializer(statistics_data).data
        })

    @action(detail=False, methods=['get'])
    def my_reviews(self, request):
        """Get reviews by the current user"""
        auth_user_uid = request.query_params.get('auth_user_uid')
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = User.objects.get(username=auth_user_uid)
            reviews = Review.objects.filter(user=user).order_by('-created_at')
            
            page = self.paginate_queryset(reviews)
            if page is not None:
                serializer = self.get_serializer(page, many=True)
                return self.get_paginated_response(serializer.data)
            
            serializer = self.get_serializer(reviews, many=True)
            return Response({
                'reviews': serializer.data,
                'total_count': reviews.count()
            })
            
        except User.DoesNotExist:
            return Response({
                'reviews': [],
                'total_count': 0
            })

    @action(detail=True, methods=['delete'])
    def remove_vote(self, request, pk=None):
        """Remove a user's helpful vote"""
        review = self.get_object()
        auth_user_uid = request.data.get('auth_user_uid')
        
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = User.objects.get(username=auth_user_uid)
            ReviewHelpful.objects.filter(review=review, user=user).delete()
            
            # Return updated review data
            review_serializer = ReviewSerializer(review, context={'request': request})
            return Response({
                'review': review_serializer.data,
                'message': 'Vote removed successfully'
            })
            
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Failed to remove vote: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['post'], url_path='respond')
    def respond_to_review(self, request):
        """Allow sellers to respond to reviews"""
        # Get request data
        uuid = request.data.get('uuid')  # This is the review ID
        response_text = request.data.get('response')
        auth_user_uid = request.data.get('auth_user_uid')
        
        # Validation
        if not uuid:
            return Response(
                {'error': 'uuid (review ID) is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not response_text:
            return Response(
                {'error': 'response text is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Get the review
            review = Review.objects.get(pk=uuid)
            
            # Get or create the user (seller)
            if auth_user_uid:
                user, created = User.objects.get_or_create(
                    username=auth_user_uid,
                    defaults={'email': f'{auth_user_uid}@bidr.com'}
                )
            else:
                # If no auth_user_uid, use the authenticated user
                if not request.user.is_authenticated:
                    return Response(
                        {'error': 'Authentication required or auth_user_uid must be provided'}, 
                        status=status.HTTP_401_UNAUTHORIZED
                    )
                user = request.user
            
            # Check if a response already exists
            existing_response = ReviewResponse.objects.filter(review=review).first()
            
            if existing_response:
                # Update existing response
                existing_response.response_text = response_text
                existing_response.responder = user
                existing_response.save()
                
                message = 'Response updated successfully'
            else:
                # Create new response
                ReviewResponse.objects.create(
                    review=review,
                    responder=user,
                    response_text=response_text
                )
                message = 'Response created successfully'
            
            # Return updated review data with response
            review_serializer = ReviewSerializer(review, context={'request': request})
            return Response({
                'success': True,
                'message': message,
                'review': review_serializer.data
            }, status=status.HTTP_200_OK)
            
        except Review.DoesNotExist:
            return Response(
                {'error': 'Review not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            return Response(
                {'error': f'Failed to save response: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class TicketViewSet(viewsets.ModelViewSet):
    queryset = Ticket.objects.all()
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'priority', 'auth_user_uid']
    search_fields = ['ticket_id', 'subject', 'description']
    ordering_fields = ['created_at', 'updated_at']
    ordering = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'create':
            return TicketCreateSerializer
        return TicketSerializer

    @action(detail=False, methods=['get'])
    def user_tickets(self, request):
        """Get tickets for a specific user by auth_user_uid"""
        auth_user_uid = request.query_params.get('auth_user_uid')
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        tickets = self.queryset.filter(auth_user_uid=auth_user_uid)
        serializer = self.get_serializer(tickets, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def add_message(self, request, pk=None):
        """Add a message to a ticket"""
        ticket = self.get_object()
        auth_user_uid = request.data.get('auth_user_uid')
        message_text = request.data.get('message')
        
        if not auth_user_uid or not message_text:
            return Response(
                {'error': 'auth_user_uid and message are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        user, created = User.objects.get_or_create(
            username=auth_user_uid,
            defaults={'email': f'{auth_user_uid}@bidr.com'}
        )
        
        message = TicketMessage.objects.create(
            ticket=ticket,
            sender=user,
            message=message_text,
            is_from_staff=user.is_staff
        )
        
        # Update ticket status if it was resolved/closed
        if ticket.status in ['resolved', 'closed']:
            ticket.status = 'open'
            ticket.save()
        
        serializer = TicketMessageSerializer(message)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """Update ticket status"""
        ticket = self.get_object()
        new_status = request.data.get('status')
        
        if new_status not in ['open', 'in_progress', 'resolved', 'closed']:
            return Response(
                {'error': 'Invalid status'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        ticket.status = new_status
        if new_status == 'resolved':
            from django.utils import timezone
            ticket.resolved_at = timezone.now()
        
        ticket.save()
        serializer = self.get_serializer(ticket)
        return Response(serializer.data)


# Custom function-based view for direct /api/reviews/ access
@api_view(['GET', 'POST'])
@permission_classes([AllowAny])
def reviews_endpoint(request):
    """
    Custom view to handle both GET and POST requests at /api/reviews/
    - GET: List reviews with optional filtering
    - POST: Create or update a review
    """
    if request.method == 'GET':
        return list_reviews(request)
    elif request.method == 'POST':
        return create_review(request)


@api_view(['POST'])
@permission_classes([AllowAny])
def create_review(request):
    """
    Custom view to handle POST requests directly at /api/reviews/
    Removes authentication requirements and provides a simple endpoint
    """
    # Extract data from request
    auth_user_uid = request.data.get('auth_user_uid')
    product_id = request.data.get('product_id', '').strip()
    seller_id = request.data.get('seller_id', '').strip() or None
    rating = request.data.get('rating')
    content = request.data.get('content', '').strip()
    title = request.data.get('title', '').strip()
    customer_name = request.data.get('customer_name', '').strip()

    # Validation
    if not auth_user_uid:
        return Response(
            {'error': 'auth_user_uid is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if not product_id:
        return Response(
            {'error': 'product_id is required and cannot be empty'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
        
    if not rating or not isinstance(rating, int) or rating < 1 or rating > 5:
        return Response(
            {'error': 'rating must be an integer between 1 and 5'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
        
    if len(content) < 10:
        return Response(
            {'error': 'content must be at least 10 characters long'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
        
    # Generate title if not provided
    if not title:
        title = f'Review by {customer_name}' if customer_name else f'Review by User {auth_user_uid[:8]}'

    try:
        from django.db import transaction
        
        with transaction.atomic():
            # Create or get user
            user, created = User.objects.get_or_create(
                username=auth_user_uid,
                defaults={
                    'email': f'{auth_user_uid}@bidr.com',
                    'first_name': customer_name.split()[0] if customer_name else '',
                    'last_name': ' '.join(customer_name.split()[1:]) if customer_name and len(customer_name.split()) > 1 else ''
                }
            )

            # Check if user already reviewed this product
            existing_review = Review.objects.filter(
                user=user,
                product_id=product_id
            ).first()

            # Prepare clean data for serializer
            review_data = {
                'product_id': product_id,
                'seller_id': seller_id,
                'title': title,
                'content': content,
                'rating': rating
            }

            if existing_review:
                # Update existing review
                from .serializers import ReviewCreateSerializer
                serializer = ReviewCreateSerializer(
                    existing_review, 
                    data=review_data, 
                    partial=True
                )
                serializer.is_valid(raise_exception=True)
                review = serializer.save()
                
                # Return full review data
                output_serializer = ReviewSerializer(review)
                return Response(
                    {
                        'success': True,
                        'message': 'Review updated successfully',
                        'review': output_serializer.data
                    },
                    status=status.HTTP_200_OK
                )
            else:
                # Create new review
                from .serializers import ReviewCreateSerializer
                serializer = ReviewCreateSerializer(data=review_data)
                serializer.is_valid(raise_exception=True)
                review = serializer.save(user=user)
                
                # Return full review data
                output_serializer = ReviewSerializer(review)
                return Response(
                    {
                        'success': True,
                        'message': 'Review submitted successfully',
                        'review': output_serializer.data
                    },
                    status=status.HTTP_201_CREATED
                )
                
    except Exception as e:
        return Response(
            {'success': False, 'error': f'Failed to submit review: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([AllowAny])
def list_reviews(request):
    """
    Custom view to handle GET requests at /api/reviews/
    Returns a list of approved reviews with optional filtering
    """
    try:
        # Get query parameters
        product_id = request.query_params.get('product_id')
        seller_id = request.query_params.get('seller_id')
        rating = request.query_params.get('rating')
        
        # Start with approved reviews
        reviews = Review.objects.filter(is_approved=True)
        
        # Apply filters if provided
        if product_id:
            reviews = reviews.filter(product_id=product_id)
        if seller_id:
            reviews = reviews.filter(seller_id=seller_id)
        if rating:
            try:
                rating_int = int(rating)
                if 1 <= rating_int <= 5:
                    reviews = reviews.filter(rating=rating_int)
            except ValueError:
                pass
        
        # Order by creation date (newest first)
        reviews = reviews.order_by('-created_at')
        
        # Serialize the data
        serializer = ReviewSerializer(reviews, many=True, context={'request': request})
        
        return Response(
            {
                'success': True,
                'count': reviews.count(),
                'reviews': serializer.data
            },
            status=status.HTTP_200_OK
        )
        
    except Exception as e:
        return Response(
            {'success': False, 'error': f'Failed to retrieve reviews: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
