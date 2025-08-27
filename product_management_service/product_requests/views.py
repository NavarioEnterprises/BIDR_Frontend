from django.shortcuts import render
from django.utils import timezone
from django.db.models import F, Q
from django.http import JsonResponse
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAuthenticatedOrReadOnly, AllowAny
from django.contrib.auth.models import User
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from decimal import Decimal
from core.cors_decorators import CORSMixin

from .models import (
    ConsumerElectronics, VehicleSpares, VehicleTyresRims, 
    ProductRequest, RequestImage, RequestSpecification, 
    RequestMessage, RequestWatchlist, Order
)
from .serializers import (
    ConsumerElectronicsSerializer, VehicleSparesSerializer, VehicleTyresRimsSerializer,
    ProductRequestListSerializer, ProductRequestDetailSerializer, ProductRequestCreateSerializer,
    RequestImageSerializer, RequestSpecificationSerializer, 
    RequestMessageSerializer, RequestWatchlistSerializer,
    OrderListSerializer, OrderDetailSerializer, OrderCreateSerializer,
    OrderUpdateSerializer, OrderStatusUpdateSerializer
)


class ProductRequestViewSet(CORSMixin, viewsets.ModelViewSet):
    """
    ViewSet for ProductRequest model.
    
    Provides CRUD operations for product requests with category-specific handling.
    Includes CORS support for Flutter web compatibility.
    """
    
    queryset = ProductRequest.objects.all().select_related(
        'buyer_id', 'consumer_electronics', 'vehicle_spares', 'vehicle_tyres_rims'
    ).prefetch_related('images', 'specifications', 'messages')
    
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    # Filter fields
    filterset_fields = {
        'category': ['exact', 'in'],
        'status': ['exact', 'in'],
        'urgency_timeline': ['exact', 'in'],
        'condition_preference': ['exact', 'in'],
        'buyer_id': ['exact'],
        'created_at': ['gte', 'lte', 'exact'],
        'max_budget': ['gte', 'lte'],
    }
    
    # Search fields
    search_fields = ['title', 'description', 'buyer_id__username', 'buyer_id__email']
    
    # Ordering fields
    ordering_fields = ['created_at', 'updated_at', 'urgency_timeline', 'max_budget', 'view_count']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        """Return different serializers based on the action."""
        if self.action == 'create':
            return ProductRequestCreateSerializer
        elif self.action in ['retrieve', 'update', 'partial_update']:
            return ProductRequestDetailSerializer
        else:
            return ProductRequestListSerializer
    
    def perform_create(self, serializer):
        """Set the buyer to the current user when creating a request."""
        # If buyer_id is not provided and user is authenticated, use the current user
        # For anonymous submissions, buyer_id must be provided in the request data
        if 'buyer_id' not in serializer.validated_data:
            if self.request.user.is_authenticated:
                instance = serializer.save(buyer_id=self.request.user)
            else:
                # For anonymous submissions, buyer_id should be provided or will be null
                instance = serializer.save()
        else:
            instance = serializer.save()
        
        # Update analytics for new request creation
        self._update_analytics_for_new_request(instance)
    
    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to increment view count."""
        instance = self.get_object()
        # Increment view count if it's not the owner viewing
        if request.user.is_authenticated and request.user != instance.buyer_id:
            instance.mark_as_viewed()
        elif not request.user.is_authenticated:
            # Always increment for anonymous users
            instance.mark_as_viewed()
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def close(self, request, pk=None):
        """Close a product request."""
        product_request = self.get_object()
        
        # Only the owner can close their request
        if request.user != product_request.buyer_id:
            return Response(
                {'error': 'You can only close your own requests.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        product_request.close_request()
        return Response({'message': 'Request closed successfully.'})
    
    @action(detail=False, methods=['get'], permission_classes=[IsAuthenticated])
    def my_requests(self, request):
        """Get current user's product requests."""
        queryset = self.get_queryset().filter(buyer_id=request.user)
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def categories(self, request):
        """Get available categories with their counts."""
        from django.db.models import Count
        
        categories = ProductRequest.objects.values('category').annotate(
            count=Count('category')
        ).order_by('category')
        
        category_data = []
        for category in categories:
            category_data.append({
                'code': category['category'],
                'name': dict(ProductRequest.CATEGORY_CHOICES)[category['category']],
                'count': category['count']
            })
        
        return Response(category_data)
    
    @action(detail=False, methods=['get'])
    def urgent_requests(self, request):
        """Get urgent requests (ASAP and 12_HOURS)."""
        queryset = self.get_queryset().filter(
            urgency_timeline__in=['ASAP', '12_HOURS'],
            status='ACTIVE'
        )
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def track_click(self, request, pk=None):
        """Track clicks on product requests from search results or listings."""
        product_request = self.get_object()
        source = request.data.get('source', 'unknown')  # search, listing, etc.
        
        # Update click analytics
        self._update_analytics_for_click(product_request, source)
        
        return Response({
            'message': 'Click tracked successfully',
            'request_id': product_request.request_id,
            'source': source
        })
    
    @action(detail=True, methods=['post'])
    def track_search_appearance(self, request, pk=None):
        """Track when a product request appears in search results."""
        product_request = self.get_object()
        query = request.data.get('query', '')
        position = request.data.get('position', 0)
        
        # Update search appearance analytics
        self._update_analytics_for_search_appearance(product_request, query, position)
        
        return Response({
            'message': 'Search appearance tracked successfully',
            'request_id': product_request.request_id,
            'query': query,
            'position': position
        })
    
    def _update_analytics_for_new_request(self, product_request):
        """Update analytics when a new product request is created."""
        from analytics.models import ProductRequestAnalytics, CategoryAnalytics
        from categories.models import Category
        
        today = timezone.now().date()
        
        # Update ProductRequestAnalytics
        analytics, created = ProductRequestAnalytics.objects.get_or_create(
            request=product_request,
            date=today,
            timeframe='daily',
            defaults={
                'views': 0,
                'unique_views': 0,
                'search_appearances': 0,
                'search_clicks': 0,
                'quote_responses': 0,
                'messages_sent': 0,
                'watchlist_additions': 0,
                'supplier_interest_score': Decimal('0.00')
            }
        )
        
        # Update CategoryAnalytics
        try:
            category_name = dict(ProductRequest.CATEGORY_CHOICES)[product_request.category]
            category = Category.objects.filter(name=category_name).first()
            if category:
                cat_analytics, created = CategoryAnalytics.objects.get_or_create(
                    category=category,
                    date=today,
                    timeframe='daily',
                    defaults={
                        'total_requests': 0,
                        'active_requests': 0,
                        'new_requests': 0,
                        'closed_requests': 0,
                        'total_views': 0,
                        'total_quote_requests': 0,
                        'total_quotes': 0,
                        'total_orders': 0,
                        'total_revenue': Decimal('0.00'),
                        'average_price': Decimal('0.00'),
                        'average_rating': Decimal('0.00')
                    }
                )
                
                # Increment counters
                cat_analytics.total_requests = F('total_requests') + 1
                cat_analytics.new_requests = F('new_requests') + 1
                if product_request.status == 'ACTIVE':
                    cat_analytics.active_requests = F('active_requests') + 1
                cat_analytics.save(update_fields=['total_requests', 'new_requests', 'active_requests'])
        except Exception as e:
            # Log error but don't fail the request creation
            print(f"Error updating category analytics: {e}")
    
    def _update_analytics_for_click(self, product_request, source):
        """Update analytics when a product request is clicked."""
        from analytics.models import ProductRequestAnalytics
        
        today = timezone.now().date()
        
        analytics, created = ProductRequestAnalytics.objects.get_or_create(
            request=product_request,
            date=today,
            timeframe='daily',
            defaults={
                'views': 0,
                'unique_views': 0,
                'search_appearances': 0,
                'search_clicks': 0,
                'quote_responses': 0,
                'messages_sent': 0,
                'watchlist_additions': 0,
                'supplier_interest_score': Decimal('0.00')
            }
        )
        
        if source == 'search':
            analytics.search_clicks = F('search_clicks') + 1
        analytics.views = F('views') + 1
        analytics.save(update_fields=['search_clicks', 'views'])
    
    def _update_analytics_for_search_appearance(self, product_request, query, position):
        """Update analytics when a product request appears in search results."""
        from analytics.models import ProductRequestAnalytics, SearchAnalytics
        import hashlib
        
        today = timezone.now().date()
        
        # Update ProductRequestAnalytics
        analytics, created = ProductRequestAnalytics.objects.get_or_create(
            request=product_request,
            date=today,
            timeframe='daily',
            defaults={
                'views': 0,
                'unique_views': 0,
                'search_appearances': 0,
                'search_clicks': 0,
                'quote_responses': 0,
                'messages_sent': 0,
                'watchlist_additions': 0,
                'supplier_interest_score': Decimal('0.00')
            }
        )
        analytics.search_appearances = F('search_appearances') + 1
        analytics.save(update_fields=['search_appearances'])
        
        # Update SearchAnalytics
        if query:
            query_hash = hashlib.md5(query.encode()).hexdigest()
            search_analytics, created = SearchAnalytics.objects.get_or_create(
                query=query,
                query_hash=query_hash,
                date=today,
                defaults={
                    'search_count': 0,
                    'results_count': 1,
                    'clicks': 0,
                    'average_position_clicked': Decimal('0.00'),
                    'zero_results': False
                }
            )
            if created:
                search_analytics.search_count = 1
                search_analytics.save(update_fields=['search_count'])


class ConsumerElectronicsViewSet(viewsets.ModelViewSet):
    """ViewSet for ConsumerElectronics model."""
    
    queryset = ConsumerElectronics.objects.all()
    serializer_class = ConsumerElectronicsSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    filterset_fields = {
        'electronics_type': ['exact', 'in'],
        'brand_preference': ['icontains'],
        'condition_preference': ['exact', 'in'],
        'urgency': ['exact', 'in'],
        'purpose_of_purchase': ['exact', 'in'],
    }
    
    search_fields = ['brand_preference', 'model_series', 'required_features']
    ordering_fields = ['created_at', 'quantity_needed', 'max_price']
    ordering = ['-created_at']


class VehicleSparesViewSet(viewsets.ModelViewSet):
    """ViewSet for VehicleSpares model."""
    
    queryset = VehicleSpares.objects.all()
    serializer_class = VehicleSparesSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    filterset_fields = {
        'vehicle_make': ['icontains'],
        'vehicle_model': ['icontains'],
        'vehicle_type': ['exact', 'in'],
        'part_category': ['exact', 'in'],
        'condition_preference': ['exact', 'in'],
        'urgency': ['exact', 'in'],
    }
    
    search_fields = ['vehicle_make', 'vehicle_model', 'part_name', 'part_number', 'preferred_brand']
    ordering_fields = ['created_at', 'vehicle_year', 'quantity', 'max_budget']
    ordering = ['-created_at']


class VehicleTyresRimsViewSet(viewsets.ModelViewSet):
    """ViewSet for VehicleTyresRims model."""
    
    queryset = VehicleTyresRims.objects.all()
    serializer_class = VehicleTyresRimsSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    filterset_fields = {
        'select_tyres_rims': ['exact', 'in'],
        'vehicle_type': ['exact', 'in'],
        'tyre_width': ['exact', 'gte', 'lte'],
        'sidewall_profile': ['exact'],
        'wheel_rim_diameter': ['exact'],
        'urgency': ['exact', 'in'],
    }
    
    search_fields = ['preferred_brand', 'description', 'pitch_circle_diameter']
    ordering_fields = ['created_at', 'tyre_width', 'quantity']
    ordering = ['-created_at']


class RequestMessageViewSet(viewsets.ModelViewSet):
    """ViewSet for RequestMessage model."""
    
    queryset = RequestMessage.objects.all().select_related('request', 'sender')
    serializer_class = RequestMessageSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    filterset_fields = {
        'request': ['exact'],
        'sender': ['exact'],
        'message_type': ['exact', 'in'],
        'is_internal': ['exact'],
    }
    
    search_fields = ['subject', 'message']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def perform_create(self, serializer):
        """Set the sender to the current user when creating a message."""
        serializer.save(sender=self.request.user)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a message as read."""
        message = self.get_object()
        message.mark_as_read()
        return Response({'message': 'Message marked as read.'})


class RequestWatchlistViewSet(viewsets.ModelViewSet):
    """ViewSet for RequestWatchlist model."""
    
    serializer_class = RequestWatchlistSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Return only the current user's watchlist items."""
        return RequestWatchlist.objects.filter(user=self.request.user).select_related('request', 'user')
    
    def perform_create(self, serializer):
        """Set the user to the current user when creating a watchlist item."""
        instance = serializer.save(user=self.request.user)
        
        # Update analytics for watchlist addition
        self._update_analytics_for_watchlist_addition(instance.request)
    
    def _update_analytics_for_watchlist_addition(self, product_request):
        """Update analytics when a product request is added to watchlist."""
        from analytics.models import ProductRequestAnalytics
        
        today = timezone.now().date()
        
        analytics, created = ProductRequestAnalytics.objects.get_or_create(
            request=product_request,
            date=today,
            timeframe='daily',
            defaults={
                'views': 0,
                'unique_views': 0,
                'search_appearances': 0,
                'search_clicks': 0,
                'quote_responses': 0,
                'messages_sent': 0,
                'watchlist_additions': 0,
                'supplier_interest_score': Decimal('0.00')
            }
        )
        analytics.watchlist_additions = F('watchlist_additions') + 1
        analytics.save(update_fields=['watchlist_additions'])


class OrderViewSet(CORSMixin, viewsets.ModelViewSet):
    """
    ViewSet for Order model.
    
    Provides CRUD operations for orders with buyer/seller filtering.
    Includes CORS support for Flutter web compatibility.
    """
    
    queryset = Order.objects.all().select_related(
        'buyer_id', 'seller_id', 'request_id', 'quote_id'
    )
    
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    # Filter fields
    filterset_fields = {
        'status': ['exact', 'in'],
        'payment_status': ['exact', 'in'],
        'buyer_id': ['exact'],
        'seller_id': ['exact'],
        'created_at': ['gte', 'lte', 'exact'],
        'total_amount': ['gte', 'lte'],
        'currency': ['exact'],
        'order_number': ['exact'],
    }
    
    # Search fields
    search_fields = [
        'order_number', 'request_id__title', 'buyer_id__username',
        'seller_id__username', 'tracking_number'
    ]
    
    # Ordering fields
    ordering_fields = [
        'created_at', 'updated_at', 'total_amount', 'payment_date',
        'estimated_delivery_date', 'actual_delivery_date'
    ]
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        """Return different serializers based on the action."""
        if self.action == 'create':
            return OrderCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return OrderUpdateSerializer
        elif self.action in ['retrieve', 'update_status']:
            return OrderDetailSerializer
        else:
            return OrderListSerializer
    
    def get_queryset(self):
        """Filter orders based on user role (buyer or seller)."""
        queryset = super().get_queryset()
        
        # Skip user filtering for anonymous users
        if not self.request.user.is_authenticated:
            return queryset
            
        user = self.request.user
        
        # Filter by user role if query parameter is provided
        role = self.request.query_params.get('role')
        
        if role == 'buyer':
            return queryset.filter(buyer_id=user)
        elif role == 'seller':
            return queryset.filter(seller_id=user)
        else:
            # Default: show orders where user is either buyer or seller
            return queryset.filter(
                Q(buyer_id=user) | Q(seller_id=user)
            )
    
    def perform_create(self, serializer):
        """Create order and handle business logic."""
        order = serializer.save()
        
        # Update analytics for new order creation
        self._update_analytics_for_new_order(order)
    
    @action(detail=False, methods=['get'])
    def my_purchases(self, request):
        """Get current user's orders as a buyer."""
        queryset = self.get_queryset().filter(buyer_id=request.user)
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def my_sales(self, request):
        """Get current user's orders as a seller."""
        queryset = self.get_queryset().filter(seller_id=request.user)
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def update_status(self, request, pk=None):
        """Update order status with validation."""
        order = self.get_object()
        
        # Only seller can update order status (except for cancellation)
        if request.user != order.seller_id and 'CANCELLED' not in request.data.get('status', ''):
            return Response(
                {'error': 'Only the seller can update order status.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Buyers can cancel their own orders
        if request.data.get('status') == 'CANCELLED' and request.user not in [order.buyer_id, order.seller_id]:
            return Response(
                {'error': 'Only buyer or seller can cancel the order.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = OrderStatusUpdateSerializer(
            data=request.data,
            context={'order': order}
        )
        
        if serializer.is_valid():
            validated_data = serializer.validated_data
            new_status = validated_data['status']
            
            # Update order status based on the new status
            if new_status == 'PAID':
                order.mark_as_paid(
                    payment_method=validated_data.get('payment_method'),
                    payment_reference=validated_data.get('payment_reference')
                )
            elif new_status == 'SHIPPED':
                order.mark_as_shipped(
                    tracking_number=validated_data.get('tracking_number')
                )
            elif new_status == 'DELIVERED':
                order.mark_as_delivered()
            elif new_status == 'CANCELLED':
                order.cancel_order(reason=validated_data.get('reason'))
            else:
                # General status update
                order.status = new_status
                if validated_data.get('tracking_number'):
                    order.tracking_number = validated_data['tracking_number']
                order.save(update_fields=['status', 'tracking_number'])
            
            # Return updated order data
            order.refresh_from_db()
            response_serializer = OrderDetailSerializer(order)
            return Response(response_serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def mark_as_paid(self, request, pk=None):
        """Mark order as paid."""
        order = self.get_object()
        
        # Only seller can mark as paid
        if request.user != order.seller_id:
            return Response(
                {'error': 'Only the seller can mark orders as paid.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        payment_method = request.data.get('payment_method')
        payment_reference = request.data.get('payment_reference')
        
        try:
            order.mark_as_paid(
                payment_method=payment_method,
                payment_reference=payment_reference
            )
            return Response({
                'message': 'Order marked as paid successfully.',
                'order_id': str(order.order_id),
                'status': order.status
            })
        except ValueError as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancel an order."""
        order = self.get_object()
        
        # Only buyer or seller can cancel
        if request.user not in [order.buyer_id, order.seller_id]:
            return Response(
                {'error': 'Only buyer or seller can cancel the order.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        reason = request.data.get('reason', '')
        
        try:
            order.cancel_order(reason=reason)
            return Response({
                'message': 'Order cancelled successfully.',
                'order_id': str(order.order_id),
                'status': order.status
            })
        except ValueError as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_400_BAD_REQUEST
            )
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def by_status_categories(self, request):
        """Get orders grouped by Flutter app status categories."""
        # Status mappings for Flutter app categories
        status_mappings = {
            'onGoingOrders': ['PENDING', 'PAID', 'PROCESSING', 'SHIPPED'],
            'purchasedOrders': ['DELIVERED', 'COMPLETED'],
            'returnsRefundsOrders': ['REFUNDED'],
            'cancelledOrders': ['CANCELLED'],
        }
        
        result = {}
        
        for category, statuses in status_mappings.items():
            queryset = Order.objects.filter(status__in=statuses)
            
            # Convert to list of dictionaries with required fields for Flutter
            orders = []
            for order in queryset:
                order_data = {
                    'vendorName': order.seller_id.get_full_name() or order.seller_id.username,
                    'product': order.request_id.title,
                    'vehicle': self._get_product_summary(order.request_id),
                    'orderNumber': order.order_number,
                    'status': order.get_status_display(),
                    'dateTime': order.created_at.isoformat(),
                    'price': float(order.total_amount),
                    'rating': 0.0,  # TODO: Get actual rating when ratings are implemented
                    'distanceInKm': 25,  # TODO: Calculate actual distance
                    'location': self._get_seller_location(order.seller_id),
                    'comments': [{
                        'commentId': '1',
                        'description': order.special_instructions or order.notes or 'No comments'
                    }]
                }
                orders.append(order_data)
            
            result[category] = orders
        
        return Response(result)
    
    def _get_product_summary(self, product_request):
        """Get a summary description of the product."""
        if product_request.tyres_rims_summary:
            return product_request.tyres_rims_summary
        elif product_request.vehicle_spares_summary:
            return product_request.vehicle_spares_summary
        elif product_request.consumer_electronics_summary:
            return product_request.consumer_electronics_summary
        return product_request.description or 'Product details'
    
    def _get_seller_location(self, seller):
        """Get seller location or return default."""
        # TODO: Get actual seller location from profile
        return "Location not specified"
    
    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """Get order statistics for the current user."""
        user = request.user
        from django.db.models import Count, Sum, Avg
        
        # Get buyer statistics
        buyer_stats = Order.objects.filter(buyer_id=user).aggregate(
            total_orders=Count('order_id'),
            total_spent=Sum('total_amount'),
            avg_order_value=Avg('total_amount'),
            completed_orders=Count('order_id', filter=Q(status='COMPLETED')),
            pending_orders=Count('order_id', filter=Q(status__in=['PENDING', 'PAID', 'PROCESSING', 'SHIPPED']))
        )
        
        # Get seller statistics
        seller_stats = Order.objects.filter(seller_id=user).aggregate(
            total_sales=Count('order_id'),
            total_revenue=Sum('total_amount'),
            avg_sale_value=Avg('total_amount'),
            completed_sales=Count('order_id', filter=Q(status='COMPLETED')),
            pending_sales=Count('order_id', filter=Q(status__in=['PENDING', 'PAID', 'PROCESSING', 'SHIPPED']))
        )
        
        return Response({
            'buyer_statistics': buyer_stats,
            'seller_statistics': seller_stats
        })
    
    def _update_analytics_for_new_order(self, order):
        """Update analytics when a new order is created."""
        try:
            from analytics.models import OrderAnalytics, CategoryAnalytics
            
            today = timezone.now().date()
            
            # Update OrderAnalytics
            order_analytics, created = OrderAnalytics.objects.get_or_create(
                date=today,
                timeframe='daily',
                defaults={
                    'total_orders': 0,
                    'total_revenue': Decimal('0.00'),
                    'average_order_value': Decimal('0.00'),
                    'completed_orders': 0,
                    'cancelled_orders': 0,
                    'conversion_rate': Decimal('0.00')
                }
            )
            order_analytics.total_orders = F('total_orders') + 1
            order_analytics.total_revenue = F('total_revenue') + order.total_amount
            order_analytics.save(update_fields=['total_orders', 'total_revenue'])
            
            # Update CategoryAnalytics
            category_analytics, created = CategoryAnalytics.objects.get_or_create(
                category=order.request_id.category,
                date=today,
                timeframe='daily',
                defaults={
                    'requests_created': 0,
                    'quotes_submitted': 0,
                    'orders_completed': 0,
                    'total_value': Decimal('0.00'),
                    'average_fulfillment_time': Decimal('0.00'),
                    'supplier_participation_rate': Decimal('0.00')
                }
            )
            category_analytics.total_value = F('total_value') + order.total_amount
            category_analytics.save(update_fields=['total_value'])
            
        except Exception as e:
            print(f"Error updating order analytics: {e}")
