from django.db.models.functions import TruncDate
from django.shortcuts import render
from django.db.models import Q, Sum, Avg, Count
from django.utils import timezone
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from datetime import datetime, timedelta

from .models import (
    ProductRequestAnalytics, CategoryAnalytics, UserBehaviorAnalytics,
    SearchAnalytics, SalesAnalytics, InventoryAnalytics, AnalyticsReport
)
from .serializers import (
    ProductRequestAnalyticsSerializer, CategoryAnalyticsSerializer,
    UserBehaviorAnalyticsSerializer, SearchAnalyticsSerializer,
    SalesAnalyticsSerializer, InventoryAnalyticsSerializer,
    AnalyticsReportSerializer
)
from product_requests.models import ProductRequest
from categories.models import Category


class ProductRequestAnalyticsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for ProductRequestAnalytics.
    """
    queryset = ProductRequestAnalytics.objects.all()
    serializer_class = ProductRequestAnalyticsSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['timeframe', 'date', 'request__category', 'request__status']
    search_fields = ['request__title', 'request__description']
    ordering_fields = ['date', 'views', 'quote_responses', 'supplier_interest_score']
    ordering = ['-date']

    def get_queryset(self):
        return super().get_queryset().select_related('request', 'request__category')

    @action(detail=False, methods=['get'])
    def top_performing_requests(self, request):
        """Get top performing product requests by various metrics."""
        timeframe = request.query_params.get('timeframe', 'weekly')
        limit = int(request.query_params.get('limit', 10))
        metric = request.query_params.get('metric', 'views')  # views, quote_responses, supplier_interest_score
        
        # Filter by date range based on timeframe
        end_date = timezone.now().date()
        if timeframe == 'daily':
            start_date = end_date - timedelta(days=1)
        elif timeframe == 'weekly':
            start_date = end_date - timedelta(weeks=1)
        elif timeframe == 'monthly':
            start_date = end_date - timedelta(days=30)
        else:
            start_date = end_date - timedelta(weeks=1)
        
        analytics = self.get_queryset().filter(
            date__range=[start_date, end_date]
        ).order_by(f'-{metric}')[:limit]
        
        serializer = self.get_serializer(analytics, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def category_performance(self, request):
        """Get analytics summary by category."""
        timeframe = request.query_params.get('timeframe', 'weekly')
        
        # Calculate date range
        end_date = timezone.now().date()
        if timeframe == 'daily':
            start_date = end_date - timedelta(days=1)
        elif timeframe == 'weekly':
            start_date = end_date - timedelta(weeks=1)
        elif timeframe == 'monthly':
            start_date = end_date - timedelta(days=30)
        else:
            start_date = end_date - timedelta(weeks=1)
        
        # Aggregate by category
        category_stats = self.get_queryset().filter(
            date__range=[start_date, end_date]
        ).values(
            'request__category__name'
        ).annotate(
            total_views=Sum('views'),
            total_quotes=Sum('quote_responses'),
            avg_interest_score=Avg('supplier_interest_score'),
            request_count=Count('request', distinct=True)
        ).order_by('-total_views')
        
        return Response(list(category_stats))


class CategoryAnalyticsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for CategoryAnalytics.
    """
    queryset = CategoryAnalytics.objects.all()
    serializer_class = CategoryAnalyticsSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['timeframe', 'date', 'category']
    search_fields = ['category__name']
    ordering_fields = ['date', 'total_requests', 'total_views', 'total_revenue']
    ordering = ['-date']

    def get_queryset(self):
        return super().get_queryset().select_related('category')

    @action(detail=False, methods=['get'])
    def top_categories(self, request):
        """Get top performing categories."""
        timeframe = request.query_params.get('timeframe', 'weekly')
        limit = int(request.query_params.get('limit', 10))
        metric = request.query_params.get('metric', 'total_requests')
        
        analytics = self.get_queryset().filter(
            timeframe=timeframe
        ).order_by(f'-{metric}')[:limit]
        
        serializer = self.get_serializer(analytics, many=True)
        return Response(serializer.data)


class UserBehaviorAnalyticsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for UserBehaviorAnalytics.
    """
    queryset = UserBehaviorAnalytics.objects.all()
    serializer_class = UserBehaviorAnalyticsSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['timeframe', 'date']
    ordering_fields = ['date', 'total_users', 'active_users']
    ordering = ['-date']

    @action(detail=False, methods=['get'])
    def user_trends(self, request):
        """Get user behavior trends over time."""
        timeframe = request.query_params.get('timeframe', 'daily')
        days = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        analytics = self.get_queryset().filter(
            timeframe=timeframe,
            date__range=[start_date, end_date]
        ).order_by('date')
        
        serializer = self.get_serializer(analytics, many=True)
        return Response(serializer.data)


class SearchAnalyticsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for SearchAnalytics.
    """
    queryset = SearchAnalytics.objects.all()
    serializer_class = SearchAnalyticsSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['zero_results', 'date']
    search_fields = ['query']
    ordering_fields = ['date', 'search_count', 'clicks']
    ordering = ['-search_count']

    @action(detail=False, methods=['get'])
    def top_queries(self, request):
        """Get top search queries."""
        days = int(request.query_params.get('days', 7))
        limit = int(request.query_params.get('limit', 20))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        analytics = self.get_queryset().filter(
            date__range=[start_date, end_date]
        ).order_by('-search_count')[:limit]
        
        serializer = self.get_serializer(analytics, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def zero_result_queries(self, request):
        """Get queries that returned zero results."""
        days = int(request.query_params.get('days', 7))
        limit = int(request.query_params.get('limit', 20))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        analytics = self.get_queryset().filter(
            date__range=[start_date, end_date],
            zero_results=True
        ).order_by('-search_count')[:limit]
        
        serializer = self.get_serializer(analytics, many=True)
        return Response(serializer.data)


class SalesAnalyticsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for SalesAnalytics.
    """
    queryset = SalesAnalytics.objects.all()
    serializer_class = SalesAnalyticsSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['timeframe', 'date']
    ordering_fields = ['date', 'total_revenue', 'total_orders']
    ordering = ['-date']

    @action(detail=False, methods=['get'])
    def revenue_trends(self, request):
        """Get revenue trends over time."""
        timeframe = request.query_params.get('timeframe', 'daily')
        days = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        analytics = self.get_queryset().filter(
            timeframe=timeframe,
            date__range=[start_date, end_date]
        ).order_by('date')
        
        serializer = self.get_serializer(analytics, many=True)
        return Response(serializer.data)


class InventoryAnalyticsViewSet(viewsets.ModelViewSet):
    """
    ViewSet for InventoryAnalytics.
    """
    queryset = InventoryAnalytics.objects.all()
    serializer_class = InventoryAnalyticsSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['timeframe', 'date']
    ordering_fields = ['date', 'total_inventory_value', 'inventory_turnover']
    ordering = ['-date']

    @action(detail=False, methods=['get'])
    def inventory_trends(self, request):
        """Get inventory trends over time."""
        timeframe = request.query_params.get('timeframe', 'daily')
        days = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        analytics = self.get_queryset().filter(
            timeframe=timeframe,
            date__range=[start_date, end_date]
        ).order_by('date')
        
        serializer = self.get_serializer(analytics, many=True)
        return Response(serializer.data)


class AnalyticsReportViewSet(viewsets.ModelViewSet):
    """
    ViewSet for AnalyticsReport.
    """
    queryset = AnalyticsReport.objects.all()
    serializer_class = AnalyticsReportSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['report_type', 'status', 'file_format']
    search_fields = ['name', 'description']
    ordering_fields = ['created_at', 'start_date', 'end_date']
    ordering = ['-created_at']

    def get_queryset(self):
        return super().get_queryset().select_related('generated_by')

    def perform_create(self, serializer):
        serializer.save(generated_by=self.request.user)

    @action(detail=True, methods=['post'])
    def generate(self, request, pk=None):
        """Generate the report data."""
        report = self.get_object()
        
        if report.status != 'pending':
            return Response(
                {'error': 'Report can only be generated when status is pending'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Here you would implement the actual report generation logic
        # For now, we'll just mark it as completed with sample data
        report.status = 'completed'
        report.report_data = {
            'generated_at': timezone.now().isoformat(),
            'summary': 'Report generated successfully',
            'data': []
        }
        report.save()
        
        serializer = self.get_serializer(report)
        return Response(serializer.data)


class AnalyticsDashboardViewSet(viewsets.ViewSet):
    """
    Combined analytics dashboard endpoints.
    """
    permission_classes = [AllowAny]

    @action(detail=False, methods=['get'])
    def overview(self, request):
        """Get overall analytics overview."""
        timeframe = request.query_params.get('timeframe', 'weekly')
        
        # Calculate date range
        end_date = timezone.now().date()
        if timeframe == 'daily':
            start_date = end_date - timedelta(days=1)
        elif timeframe == 'weekly':
            start_date = end_date - timedelta(weeks=1)
        elif timeframe == 'monthly':
            start_date = end_date - timedelta(days=30)
        else:
            start_date = end_date - timedelta(weeks=1)
        
        # Get key metrics
        total_requests = ProductRequest.objects.filter(
            created_at__date__range=[start_date, end_date]
        ).count()
        
        active_requests = ProductRequest.objects.filter(
            status='open',
            created_at__date__range=[start_date, end_date]
        ).count()
        
        categories_with_requests = Category.objects.filter(
            product_requests__created_at__date__range=[start_date, end_date]
        ).distinct().count()
        
        # Get analytics summary
        request_analytics = ProductRequestAnalytics.objects.filter(
            date__range=[start_date, end_date]
        ).aggregate(
            total_views=Sum('views'),
            total_quotes=Sum('quote_responses'),
            avg_interest_score=Avg('supplier_interest_score')
        )
        
        category_analytics = CategoryAnalytics.objects.filter(
            date__range=[start_date, end_date]
        ).aggregate(
            total_revenue=Sum('total_revenue'),
            avg_rating=Avg('average_rating')
        )
        
        return Response({
            'timeframe': timeframe,
            'date_range': {
                'start': start_date,
                'end': end_date
            },
            'summary': {
                'total_requests': total_requests,
                'active_requests': active_requests,
                'categories_with_requests': categories_with_requests,
                'total_views': request_analytics.get('total_views', 0) or 0,
                'total_quotes': request_analytics.get('total_quotes', 0) or 0,
                'avg_interest_score': round(request_analytics.get('avg_interest_score', 0) or 0, 2),
                'total_revenue': float(category_analytics.get('total_revenue', 0) or 0),
                'avg_rating': round(category_analytics.get('avg_rating', 0) or 0, 2)
            }
        })

    @action(detail=False, methods=['get'])
    def trends(self, request):
        """Get trending data over time."""
        days = int(request.query_params.get('days', 30))
        
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days)
        
        # Get daily request counts
        daily_requests = ProductRequest.objects.filter(
            created_at__date__range=[start_date, end_date]
        ).annotate(
            day=TruncDate('created_at')
        ).values('day').annotate(
            count=Count('id')
        ).order_by('day')
        
        # Get daily analytics if available
        daily_analytics = ProductRequestAnalytics.objects.filter(
            date__range=[start_date, end_date],
            timeframe='daily'
        ).values('date').annotate(
            total_views=Sum('views'),
            total_quotes=Sum('quote_responses')
        ).order_by('date')
        
        return Response({
            'date_range': {
                'start': start_date,
                'end': end_date
            },
            'daily_requests': list(daily_requests),
            'daily_analytics': list(daily_analytics)
        })
    
    @action(detail=False, methods=['get'])
    def seller_orders_summary(self, request):
        """Get orders summary for a specific seller."""
        auth_user_uid = request.query_params.get('auth_user_uid')
        timeframe = request.query_params.get('timeframe', 'monthly')
        
        if not auth_user_uid:
            return Response(
                {'error': 'auth_user_uid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Import here to avoid circular imports
        from product_requests.models import Order
        
        # Calculate date range
        end_date = timezone.now().date()
        if timeframe == 'daily':
            start_date = end_date - timedelta(days=1)
        elif timeframe == 'weekly':
            start_date = end_date - timedelta(weeks=1)
        elif timeframe == 'monthly':
            start_date = end_date - timedelta(days=30)
        elif timeframe == 'yearly':
            start_date = end_date - timedelta(days=365)
        else:
            start_date = end_date - timedelta(days=30)
        
        # Get seller orders in the timeframe
        seller_orders = Order.objects.filter(
            seller_id=auth_user_uid,
            created_at__date__range=[start_date, end_date]
        )
        
        # Calculate metrics
        total_orders = seller_orders.count()
        total_revenue = seller_orders.aggregate(
            revenue=Sum('total_amount')
        )['revenue'] or 0
        
        # Get orders by status
        orders_by_status = seller_orders.values('status').annotate(
            count=Count('order_id'),
            revenue=Sum('total_amount')
        ).order_by('status')
        
        # Get chart data based on timeframe
        chart_data = []
        chart_end_date = timezone.now().date()
        
        if timeframe == 'daily':
            # Show all days of current month
            from calendar import monthrange
            year = chart_end_date.year
            month = chart_end_date.month
            days_in_month = monthrange(year, month)[1]
            chart_start_date = chart_end_date.replace(day=1)
            
            daily_revenue = seller_orders.filter(
                created_at__date__range=[chart_start_date, chart_end_date]
            ).annotate(
                day=TruncDate('created_at')
            ).values('day').annotate(
                revenue=Sum('total_amount')
            ).order_by('day')
            
            daily_revenue_dict = {item['day'].strftime('%Y-%m-%d'): float(item['revenue']) for item in daily_revenue}
            
            for day in range(1, days_in_month + 1):
                date = chart_end_date.replace(day=day)
                date_str = date.strftime('%Y-%m-%d')
                chart_data.append({
                    'period': str(day),
                    'period_name': str(day),
                    'revenue': daily_revenue_dict.get(date_str, 0)
                })
                
        elif timeframe == 'weekly':
            # Show 4 weeks
            chart_start_date = chart_end_date - timedelta(weeks=3)  # 4 weeks including current week
            
            weekly_revenue = seller_orders.filter(
                created_at__date__range=[chart_start_date, chart_end_date]
            ).annotate(
                week=TruncDate('created_at', lookup='week')
            ).values('week').annotate(
                revenue=Sum('total_amount')
            ).order_by('week')
            
            weekly_revenue_dict = {item['week'].strftime('%Y-%m-%d'): float(item['revenue']) for item in weekly_revenue}
            
            for week in range(4):
                week_start = chart_start_date + timedelta(weeks=week)
                # Adjust to start of week (Monday)
                week_start = week_start - timedelta(days=week_start.weekday())
                week_str = week_start.strftime('%Y-%m-%d')
                chart_data.append({
                    'period': f'W{week + 1}',
                    'period_name': f'Week {week + 1}',
                    'revenue': weekly_revenue_dict.get(week_str, 0)
                })
                
        elif timeframe == 'yearly':
            # Show multiple years if needed, for now just current year by months
            chart_start_date = chart_end_date.replace(month=1, day=1)
            
            monthly_revenue = seller_orders.filter(
                created_at__date__range=[chart_start_date, chart_end_date]
            ).annotate(
                month=TruncDate('created_at', lookup='month')
            ).values('month').annotate(
                revenue=Sum('total_amount')
            ).order_by('month')
            
            monthly_revenue_dict = {item['month'].strftime('%Y-%m'): float(item['revenue']) for item in monthly_revenue}
            
            for month in range(1, 13):  # 12 months
                date = chart_end_date.replace(month=month, day=1)
                month_str = date.strftime('%Y-%m')
                chart_data.append({
                    'period': date.strftime('%b'),
                    'period_name': date.strftime('%B'),
                    'revenue': monthly_revenue_dict.get(month_str, 0)
                })
                
        else:  # monthly (default)
            # Show 12 months of current year
            chart_start_date = chart_end_date.replace(month=1, day=1)
            
            monthly_revenue = seller_orders.filter(
                created_at__date__range=[chart_start_date, chart_end_date]
            ).annotate(
                month=TruncDate('created_at', lookup='month')
            ).values('month').annotate(
                revenue=Sum('total_amount')
            ).order_by('month')
            
            monthly_revenue_dict = {item['month'].strftime('%Y-%m'): float(item['revenue']) for item in monthly_revenue}
            
            for month in range(1, 13):  # 12 months
                date = chart_end_date.replace(month=month, day=1)
                month_str = date.strftime('%Y-%m')
                chart_data.append({
                    'period': date.strftime('%b'),
                    'period_name': date.strftime('%B'),
                    'revenue': monthly_revenue_dict.get(month_str, 0)
                })
        
        # Average order value
        avg_order_value = float(total_revenue / total_orders) if total_orders > 0 else 0
        
        return Response({
            'timeframe': timeframe,
            'date_range': {
                'start': start_date,
                'end': end_date
            },
            'summary': {
                'total_orders': total_orders,
                'total_revenue': float(total_revenue),
                'average_order_value': round(avg_order_value, 2),
                'orders_by_status': list(orders_by_status),
                'chart_data': chart_data
            }
        })
