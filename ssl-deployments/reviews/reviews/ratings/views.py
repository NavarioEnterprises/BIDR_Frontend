from django.shortcuts import render, get_object_or_404
from rest_framework import generics, status, filters
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticatedOrReadOnly, AllowAny
from django.contrib.auth.models import User
from django.db.models import Q, Avg, Count
from django_filters.rest_framework import DjangoFilterBackend

from .models import Rating, AverageRating
from .serializers import RatingSerializer, RatingCreateSerializer, AverageRatingSerializer
from reviews.models import Review
from reviews.serializers import ReviewSerializer


class RatingListCreateView(generics.ListCreateAPIView):
    """
    List all ratings or create a new rating
    """
    queryset = Rating.objects.all()
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product_id', 'seller_id', 'overall_rating']
    ordering_fields = ['created_at', 'overall_rating']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return RatingCreateSerializer
        return RatingSerializer


class RatingDetailView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update or delete a rating
    """
    queryset = Rating.objects.all()
    serializer_class = RatingSerializer
    permission_classes = [AllowAny]


class AverageRatingListView(generics.ListAPIView):
    """
    List average ratings
    """
    queryset = AverageRating.objects.all()
    serializer_class = AverageRatingSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['product_id', 'seller_id']
    ordering_fields = ['overall_avg', 'total_ratings']
    ordering = ['-overall_avg']


@api_view(['GET'])
def seller_reviews_and_ratings(request, seller_id):
    """
    Get all reviews and ratings for a specific seller
    Matches the format expected by the Dart frontend
    """
    # Get all reviews for this seller
    reviews = Review.objects.filter(
        seller_id=seller_id,
        is_approved=True
    ).select_related('user').order_by('-created_at')
    
    # Get all ratings for this seller
    ratings = Rating.objects.filter(
        seller_id=seller_id
    ).select_related('user').order_by('-created_at')
    
    # Get average ratings
    avg_ratings = AverageRating.objects.filter(seller_id=seller_id)
    
    # Format data for the frontend (matching ReviewItem structure)
    formatted_reviews = []
    
    # Add reviews to the list
    for review in reviews:
        formatted_reviews.append({
            'uuid': str(review.id).zfill(6),  # Format as 6-digit string
            'customerName': f"{review.user.first_name} {review.user.last_name}".strip() or review.user.username,
            'description': review.title,
            'rating': review.rating,
            'comment': review.content,
            'created_at': review.created_at.isoformat(),
            'type': 'review'
        })
    
    # Add quick ratings (without full reviews) to the list
    # Get ratings that don't have corresponding reviews
    review_product_ids = set(reviews.values_list('product_id', flat=True))
    standalone_ratings = ratings.exclude(product_id__in=review_product_ids)
    
    for rating in standalone_ratings:
        # Try to get product info (this would come from product service in real app)
        product_description = f"Product {rating.product_id}"  # Placeholder
        
        formatted_reviews.append({
            'uuid': str(rating.id).zfill(6),
            'customerName': f"{rating.user.first_name} {rating.user.last_name}".strip() or rating.user.username,
            'description': product_description,
            'rating': rating.overall_rating,
            'comment': 'Quick rating - no detailed review provided',
            'created_at': rating.created_at.isoformat(),
            'type': 'rating'
        })
    
    # Sort all items by creation date (newest first)
    formatted_reviews.sort(key=lambda x: x['created_at'], reverse=True)
    
    # Get summary statistics
    total_reviews = reviews.count()
    total_ratings = ratings.count()
    overall_avg = avg_ratings.aggregate(avg=Avg('overall_avg'))['avg'] or 0
    
    return Response({
        'seller_id': seller_id,
        'reviews': formatted_reviews,
        'summary': {
            'total_reviews': total_reviews,
            'total_ratings': total_ratings,
            'total_items': len(formatted_reviews),
            'average_rating': round(overall_avg, 2),
        }
    })


@api_view(['GET'])
def product_reviews_and_ratings(request, product_id):
    """
    Get all reviews and ratings for a specific product
    """
    # Get all reviews for this product
    reviews = Review.objects.filter(
        product_id=product_id,
        is_approved=True
    ).select_related('user').order_by('-created_at')
    
    # Get all ratings for this product
    ratings = Rating.objects.filter(
        product_id=product_id
    ).select_related('user').order_by('-created_at')
    
    # Serialize the data
    review_data = ReviewSerializer(reviews, many=True).data
    rating_data = RatingSerializer(ratings, many=True).data
    
    # Get average rating for this product
    avg_rating = AverageRating.objects.filter(product_id=product_id).first()
    avg_data = AverageRatingSerializer(avg_rating).data if avg_rating else None
    
    return Response({
        'product_id': product_id,
        'reviews': review_data,
        'ratings': rating_data,
        'average_rating': avg_data
    })


@api_view(['POST'])
def respond_to_review(request):
    """
    Handle seller response to a review
    Expected payload: {'uuid': 'review_id', 'response': 'response_text'}
    """
    uuid = request.data.get('uuid')
    response_text = request.data.get('response')
    
    if not uuid or not response_text:
        return Response(
            {'error': 'UUID and response are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Try to find the review by ID
        review = Review.objects.get(id=int(uuid))
        
        # In a real app, you'd save the response to a SellerResponse model
        # For now, we'll just return success
        return Response({
            'success': True,
            'message': f'Response recorded for review {uuid}',
            'review_id': uuid,
            'response': response_text
        })
        
    except (Review.DoesNotExist, ValueError):
        return Response(
            {'error': 'Review not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['POST'])
def report_review(request):
    """
    Handle reporting a review
    Expected payload: {'uuid': 'review_id', 'reportType': 'type', 'details': 'details'}
    """
    uuid = request.data.get('uuid')
    report_type = request.data.get('reportType')
    details = request.data.get('details', '')
    
    if not uuid or not report_type:
        return Response(
            {'error': 'UUID and report type are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        # Try to find the review by ID
        review = Review.objects.get(id=int(uuid))
        
        # In a real app, you'd save the report to a ReviewReport model
        # For now, we'll just return success
        return Response({
            'success': True,
            'message': f'Report submitted for review {uuid}',
            'review_id': uuid,
            'report_type': report_type,
            'details': details
        })
        
    except (Review.DoesNotExist, ValueError):
        return Response(
            {'error': 'Review not found'}, 
            status=status.HTTP_404_NOT_FOUND
        )
