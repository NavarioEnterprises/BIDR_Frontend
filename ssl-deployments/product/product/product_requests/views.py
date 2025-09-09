from django.shortcuts import render
from django.utils import timezone
from django.db.models import F, Q
from django.http import JsonResponse
from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.contrib.auth.models import User
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from decimal import Decimal

from analytics.models import SalesAnalytics
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
        'consumer_electronics', 'vehicle_spares', 'vehicle_tyres_rims'
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
        'auth_user_uid': ['exact'],
        'created_at': ['gte', 'lte', 'exact'],
        'max_budget': ['gte', 'lte'],
    }
    
    # Search fields
    search_fields = ['title', 'description']
    
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
    
    def create(self, request, *args, **kwargs):
        """Override create to add better error handling."""
        print("=== DEBUG CREATE METHOD ===")
        print(f"Request data keys: {list(request.data.keys())}")
        for key, value in request.data.items():
            if isinstance(value, str) and len(str(value)) > 200:
                print(f"{key}: {str(value)[:200]}...")
            else:
                print(f"{key}: {value}")
        print("=== END DEBUG CREATE ===")
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"Serializer validation failed: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def perform_create(self, serializer):
        """Create the product request using the serializer's logic."""
        print("=== DEBUG PERFORM_CREATE ===")
        print(f"Request data: {self.request.data}")
        print(f"User authenticated: {self.request.user.is_authenticated}")
        print(f"Serializer valid: {serializer.is_valid()}")
        print("=== END DEBUG PERFORM_CREATE ===")
        
        # Let the serializer handle the buyer_id logic
        instance = serializer.save()
        
        # Update analytics for new request creation
        self._update_analytics_for_new_request(instance)
    
    def retrieve(self, request, *args, **kwargs):
        """Override retrieve to increment view count."""
        instance = self.get_object()
        # Increment view count if it's not the owner viewing
        if request.user.is_authenticated and request.user.id != instance.buyer_id:
            instance.mark_as_viewed()
        elif not request.user.is_authenticated:
            # Always increment for anonymous users
            instance.mark_as_viewed()
        
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'], permission_classes=[AllowAny])
    def close(self, request, pk=None):
        """Close a product request."""
        product_request = self.get_object()
        
        # Only the owner can close their request
        if request.user.id != product_request.buyer_id:
            return Response(
                {'error': 'You can only close your own requests.'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        product_request.close_request()
        return Response({'message': 'Request closed successfully.'})
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def my_requests(self, request):
        """Get current user's product requests."""
        queryset = self.get_queryset().filter(buyer_id=request.user.id)
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def by_auth_user(self, request):
        """Get requests by auth_user_uid parameter."""
        auth_user_uid = request.query_params.get('auth_user_uid')
        
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Filter by auth_user_uid and exclude requests that have orders
        from product_requests.models import Order
        queryset = self.get_queryset().filter(auth_user_uid=auth_user_uid).exclude(
            request_id__in=Order.objects.values_list('request_id', flat=True)
        )
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'], permission_classes=[AllowAny])
    def by_seller(self, request):
        """Get requests for sellers based on location and bid status."""
        try:
            from core.utils import calculate_distance_km
            from django.contrib.auth import get_user_model
            from django.db.models import Exists, OuterRef, Q
            import requests as http_requests
            
            User = get_user_model()
            
            # Get required parameters
            auth_user_uid = request.query_params.get('auth_user_uid')
            seller_lat = request.query_params.get('lat')
            seller_lng = request.query_params.get('lng')
            
            # Validate required parameters
            if not all([auth_user_uid, seller_lat, seller_lng]):
                return Response(
                    {
                        'error': 'auth_user_uid, lat, and lng parameters are required',
                        'required_params': ['auth_user_uid', 'lat', 'lng']
                    }, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            try:
                seller_lat = float(seller_lat)
                seller_lng = float(seller_lng)
            except ValueError:
                return Response(
                    {'error': 'lat and lng must be valid numbers'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate that auth_user_uid is a valid UUID
            try:
                import uuid
                uuid.UUID(auth_user_uid)
            except ValueError:
                return Response(
                    {
                        'error': 'Invalid auth_user_uid format',
                        'detail': 'auth_user_uid must be a valid UUID'
                    }, 
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get all active product requests
            base_queryset = self.get_queryset().filter(
                status='ACTIVE'
            )
            
            # Filter requests within 60km radius
            nearby_requests = []
            for product_request in base_queryset:
                buyer_location = product_request.buyer_location
                if isinstance(buyer_location, dict) and 'lat' in buyer_location and 'lng' in buyer_location:
                    try:
                        buyer_lat = float(buyer_location['lat'])
                        buyer_lng = float(buyer_location['lng'])
                        
                        distance = calculate_distance_km(
                            seller_lat, seller_lng,
                            buyer_lat, buyer_lng
                        )
                        
                        # Include requests within 60km
                        if distance <= 60:
                            nearby_requests.append(product_request)
                            
                    except (ValueError, TypeError, KeyError):
                        # Skip requests with invalid location data
                        continue
            
            # Get seller information from authentication service
            seller_info = None
            seller_email = None
            try:
                # Make API call to authentication service to get seller details
                auth_service_url = 'http://localhost:8001'  # Authentication service URL
                response = http_requests.get(
                    f'{auth_service_url}/api/seller/profiles/by-auth-user-uid/{auth_user_uid}/',
                    timeout=5
                )
                if response.status_code == 200:
                    seller_info = response.json()
                    seller_email = seller_info.get('email')
                elif response.status_code == 404:
                    print(f"Seller not found for auth_user_uid: {auth_user_uid}")
                else:
                    print(f"Auth service returned status {response.status_code}: {response.text}")
            except Exception as e:
                # If auth service call fails, continue without quote matching
                print(f"Failed to get seller info from auth service: {e}")
            
            # Try to find quotes by this seller using email matching or seller_id
            seller_quote_request_ids = []
            if seller_email:
                try:
                    from quotes.models import Quote
                    # Find quotes by sellers with matching email
                    seller_quotes = Quote.objects.filter(
                        seller_id__email=seller_email
                    ).values_list('request_id', flat=True)
                    seller_quote_request_ids = list(seller_quotes)
                except Exception as e:
                    print(f"Error querying quotes: {e}")
            
            # Separate into new requests and processed requests
            new_requests = []
            processed_requests = []
            
            for product_request in nearby_requests:
                # Check if this seller has quoted on this request
                has_quoted = product_request.request_id in seller_quote_request_ids
                
                if has_quoted:
                    # This seller has bid on this request
                    try:
                        from quotes.models import Quote
                        seller_quote = None
                        if seller_email:
                            seller_quote = Quote.objects.filter(
                                request_id=product_request,
                                serateller_id__email=seller_email
                            ).first()
                        
                        # Add the quote status to the request data
                        reratequest_data = self.get_serializer(product_request).data
                        request_data['bid_status'] = seller_quote.status if seller_quote else 'QUOTED'
                        request_data['quote_id'] = str(seller_quote.quote_id) if seller_quote else None
                        processed_requests.append(request_data)
                    except Exception as e:
                        print(f"Error getting quote details: {e}")
                        # Fallback: add without quote details
                        processed_requests.append(self.get_serializer(product_request).data)
                else:
                    # New request for this seller
                    request_data = self.get_serializer(product_request).data
                    # Add seller information if available
                    if seller_info:
                        request_data['seller_info'] = {
                            'company_name': seller_info.get('registered_company_name'),
                            'trading_name': seller_info.get('trading_name'),
                            'email': seller_info.get('email'),
                            'phone': seller_info.get('contact_person_telephone'),
                            'location': seller_info.get('physical_address')
                        }
                    new_requests.append(request_data)
            
            # Return only new requests (filter out ones seller has already quoted on)
            return Response({
                'results': new_requests,  # Only return requests without quotes from this seller
                'count': len(new_requests),
                'seller_location': {
                    'lat': seller_lat,
                    'lng': seller_lng
                },
                'search_radius_km': 60,
                'total_available_requests': len(new_requests),
                'total_already_quoted': len(processed_requests)
            })
        
        except Exception as e:
            return Response(
                {
                    'error': 'An error occurred while processing your request',
                    'detail': str(e)
                }, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
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
    
    @action(detail=True, methods=['post'], permission_classes=[AllowAny])
    def flag_request(self, request, pk=None):
        """Flag a product request with a reason."""
        product_request = self.get_object()
        
        # Get flag data from request
        flag_reason = request.data.get('reason', '')
        auth_user_uid = request.data.get('auth_user_uid', '')
        
        # Validate required fields
        if not flag_reason or not auth_user_uid:
            return Response(
                {'error': 'Both reason and auth_user_uid are required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user has already flagged this request
        existing_flags = product_request.flags or []
        user_already_flagged = any(flag.get('uid') == auth_user_uid for flag in existing_flags)
        
        if user_already_flagged:
            return Response(
                {'error': 'You have already flagged this request'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Add new flag
        new_flag = {
            'uid': auth_user_uid,
            'reason': flag_reason,
            'timestamp': timezone.now().isoformat()
        }
        
        # Update flags list
        updated_flags = list(existing_flags)
        updated_flags.append(new_flag)
        
        # Update the product request
        product_request.flags = updated_flags
        product_request.is_flagged = True
        product_request.save(update_fields=['flags', 'is_flagged', 'updated_at'])
        
        return Response({
            'message': 'Request flagged successfully',
            'request_id': str(product_request.request_id),
            'is_flagged': product_request.is_flagged,
            'flag_count': len(updated_flags)
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


class ConsumerElectronicsViewSet(CORSMixin, viewsets.ModelViewSet):
    """ViewSet for ConsumerElectronics model with enhanced features."""
    
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
    
    def create(self, request, *args, **kwargs):
        """Override create to add better error handling and debugging."""
        print("=== DEBUG ELECTRONICS CREATE ===")
        print(f"Request data keys: {list(request.data.keys())}")
        for key, value in request.data.items():
            if isinstance(value, str) and len(str(value)) > 200:
                print(f"{key}: {str(value)[:200]}...")
            else:
                print(f"{key}: {value}")
        print("=== END DEBUG ===")
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"Serializer validation failed: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


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


class VehicleTyresRimsViewSet(CORSMixin, viewsets.ModelViewSet):
    """ViewSet for VehicleTyresRims model with enhanced features."""
    
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
    
    def create(self, request, *args, **kwargs):
        """Override create to add better error handling and debugging."""
        print("=== DEBUG TYRES/RIMS CREATE ===")
        print(f"Request data keys: {list(request.data.keys())}")
        for key, value in request.data.items():
            if isinstance(value, str) and len(str(value)) > 200:
                print(f"{key}: {str(value)[:200]}...")
            else:
                print(f"{key}: {value}")
        print("=== END DEBUG ===")
        
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print(f"Serializer validation failed: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)


class RequestMessageViewSet(viewsets.ModelViewSet):
    """ViewSet for RequestMessage model."""
    
    queryset = RequestMessage.objects.all().select_related('request')
    serializer_class = RequestMessageSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    filterset_fields = {
        'request': ['exact'],
        'sender_id': ['exact'],
        'message_type': ['exact', 'in'],
        'is_internal': ['exact'],
    }
    
    search_fields = ['subject', 'message']
    ordering_fields = ['created_at']
    ordering = ['-created_at']
    
    def perform_create(self, serializer):
        """Set the sender to the current user when creating a message."""
        serializer.save(sender_id=self.request.user.id)
    
    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        """Mark a message as read."""
        message = self.get_object()
        message.mark_as_read()
        return Response({'message': 'Message marked as read.'})


class RequestWatchlistViewSet(viewsets.ModelViewSet):
    """ViewSet for RequestWatchlist model."""
    
    serializer_class = RequestWatchlistSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        """Return only the current user's watchlist items."""
        return RequestWatchlist.objects.filter(user_id=self.request.user.id).select_related('request')
    
    def perform_create(self, serializer):
        """Set the user to the current user when creating a watchlist item."""
        instance = serializer.save(user_id=self.request.user.id)
        
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
        'request_id', 'quote_id'
    )
    
    # Use dynamic permissions - require authentication for create/update actions
    def get_permissions(self):
        """
        Return permissions based on action.
        Creating/updating orders requires authentication.
        """
        if self.action in ['create', 'update', 'partial_update', 'destroy', 'update_status', 'mark_as_paid']:
            permission_classes = [AllowAny]
        else:
            permission_classes = [AllowAny]
        return [permission() for permission in permission_classes]
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
        'order_number', 'request_id__title', 'tracking_number'
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
            return queryset.filter(buyer_id=user.id)
        elif role == 'seller':
            return queryset.filter(seller_id=user.id)
        else:
            # Default: show orders where user is either buyer or seller
            return queryset.filter(
                Q(buyer_id=user.id) | Q(seller_id=user.id)
            )
    
    def perform_create(self, serializer):
        """Create order and handle business logic."""
        order = serializer.save()
        
        # Update analytics for new order creation
        self._update_analytics_for_new_order(order)
    
    @action(detail=False, methods=['get'])
    def my_purchases(self, request):
        """Get current user's orders as a buyer."""
        queryset = self.get_queryset().filter(buyer_id=request.user.id)
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def my_sales(self, request):
        """Get current user's orders as a seller."""
        queryset = self.get_queryset().filter(seller_id=request.user.id)
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
        
        # Permission checks based on status
        status_to_update = request.data.get('status', '')
        user_id = request.data.get('user_id')  # User identifier from request
        
        # Convert UUIDs to strings for comparison
        buyer_id_str = str(order.buyer_id)
        seller_id_str = str(order.seller_id)
        
        # Buyers can update to PAID (when making payment) or CANCELLED
        # Sellers can update to any status except PAID (which buyers set)
        if user_id == buyer_id_str:
            # Buyers can only set PAID or CANCELLED status
            if status_to_update not in ['PAID', 'CANCELLED']:
                return Response(
                    {'error': 'Buyers can only update order status to PAID or CANCELLED.'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
        elif user_id == seller_id_str:
            # Sellers can update to any status except PAID
            if status_to_update == 'PAID':
                return Response(
                    {'error': 'Only buyers can mark orders as PAID.'}, 
                    status=status.HTTP_403_FORBIDDEN
                )
        elif not user_id:
            # No user_id provided, allow for backwards compatibility but log warning
            print(f"Warning: No user_id provided for order status update on order {order.order_id}")
        else:
            # Neither buyer nor seller
            return Response(
                {'error': 'Only the buyer or seller can update order status.'}, 
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
        if request.user.id != order.seller_id:
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
        if request.user.id not in [order.buyer_id, order.seller_id]:
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
            'onGoingOrders': ['PENDING', 'PROCESSING', 'SHIPPED'],
            'purchasedOrders': ['PAID', 'DELIVERED', 'COMPLETED'],
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
                    'orderId': str(order.order_id),
                    'productId': str(order.request_id.request_id),
                    'sellerId': str(order.seller_id),
                    'buyerId': str(order.buyer_id),
                    'quoteId': str(order.quote_id.quote_id) if order.quote_id else None,
                    'vendorName': f'Seller {order.seller_id}',
                    'product': order.request_id.title,
                    'vehicle': self._get_product_summary(order.request_id),
                    'orderNumber': order.order_number,
                    'status': order.get_status_display(),
                    'dateTime': order.created_at.isoformat(),
                    'price': float(order.total_amount),
                    'currency': order.currency,
                    'paymentStatus': order.payment_status,
                    'paymentMethod': order.payment_method,
                    'trackingNumber': order.tracking_number,
                    'estimatedDeliveryDate': order.estimated_delivery_date.isoformat() if order.estimated_delivery_date else None,
                    'actualDeliveryDate': order.actual_delivery_date.isoformat() if order.actual_delivery_date else None,
                    'rating': 0.0,  # TODO: Get actual rating when ratings are implemented
                    'distanceInKm': 25,  # TODO: Calculate actual distance
                    'location': self._get_seller_location(order.seller_id),
                    'deliveryAddress': order.delivery_address,
                    'specialInstructions': order.special_instructions,
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
        buyer_stats = Order.objects.filter(buyer_id=user.id).aggregate(
            total_orders=Count('order_id'),
            total_spent=Sum('total_amount'),
            avg_order_value=Avg('total_amount'),
            completed_orders=Count('order_id', filter=Q(status='COMPLETED')),
            pending_orders=Count('order_id', filter=Q(status__in=['PENDING', 'PAID', 'PROCESSING', 'SHIPPED']))
        )
        
        # Get seller statistics
        seller_stats = Order.objects.filter(seller_id=user.id).aggregate(
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
            from analytics.models import SalesAnalytics, CategoryAnalytics
            
            today = timezone.now().date()
            
            # Update OrderAnalytics
            order_analytics, created = SalesAnalytics.objects.get_or_create(
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
