from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from django.db.models import Sum, Avg, Count, Q
from datetime import datetime, timedelta, date
from .models import PaymentAnalytics
from payments.models import Payment
from transactions.models import Transaction
from escrow.models import EscrowAccount
from .serializers import (
    PaymentAnalyticsSerializer, AnalyticsSummarySerializer,
    DateRangeFilterSerializer
)


class PaymentAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for payment analytics (read-only)
    """
    queryset = PaymentAnalytics.objects.all().order_by('-date')
    serializer_class = PaymentAnalyticsSerializer
    
    def get_queryset(self):
        queryset = PaymentAnalytics.objects.all().order_by('-date')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        currency = self.request.query_params.get('currency')
        
        if start_date:
            queryset = queryset.filter(date__gte=start_date)
        if end_date:
            queryset = queryset.filter(date__lte=end_date)
        if currency:
            queryset = queryset.filter(currency=currency)
        
        return queryset
    
    @action(detail=False, methods=['get'])
    def daily_summary(self, request):
        """
        Get daily analytics summary
        """
        today = timezone.now().date()
        yesterday = today - timedelta(days=1)
        
        # Today's data
        today_payments = Payment.objects.filter(
            created_at__date=today
        ).aggregate(
            total_count=Count('id'),
            total_amount=Sum('amount'),
            successful_count=Count('id', filter=Q(status='completed')),
            failed_count=Count('id', filter=Q(status='failed')),
            avg_amount=Avg('amount')
        )
        
        # Yesterday's data for comparison
        yesterday_payments = Payment.objects.filter(
            created_at__date=yesterday
        ).aggregate(
            total_count=Count('id'),
            total_amount=Sum('amount')
        )
        
        # Calculate growth rate
        growth_rate = 0
        if yesterday_payments['total_count'] and yesterday_payments['total_count'] > 0:
            growth_rate = (
                (today_payments['total_count'] - yesterday_payments['total_count']) /
                yesterday_payments['total_count'] * 100
            )
        
        # Calculate success rate
        success_rate = 0
        if today_payments['total_count'] and today_payments['total_count'] > 0:
            success_rate = (
                today_payments['successful_count'] / today_payments['total_count'] * 100
            )
        
        summary_data = {
            'period': 'today',
            'total_transactions': today_payments['total_count'] or 0,
            'total_amount': today_payments['total_amount'] or 0,
            'successful_transactions': today_payments['successful_count'] or 0,
            'failed_transactions': today_payments['failed_count'] or 0,
            'success_rate': round(success_rate, 2),
            'average_amount': today_payments['avg_amount'] or 0,
            'growth_rate': round(growth_rate, 2)
        }
        
        serializer = AnalyticsSummarySerializer(summary_data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def weekly_summary(self, request):
        """
        Get weekly analytics summary
        """
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=7)
        
        weekly_data = Payment.objects.filter(
            created_at__date__range=[start_date, end_date]
        ).aggregate(
            total_count=Count('id'),
            total_amount=Sum('amount'),
            successful_count=Count('id', filter=Q(status='completed')),
            failed_count=Count('id', filter=Q(status='failed')),
            avg_amount=Avg('amount')
        )
        
        # Calculate success rate
        success_rate = 0
        if weekly_data['total_count'] and weekly_data['total_count'] > 0:
            success_rate = (
                weekly_data['successful_count'] / weekly_data['total_count'] * 100
            )
        
        summary_data = {
            'period': 'last_7_days',
            'total_transactions': weekly_data['total_count'] or 0,
            'total_amount': weekly_data['total_amount'] or 0,
            'successful_transactions': weekly_data['successful_count'] or 0,
            'failed_transactions': weekly_data['failed_count'] or 0,
            'success_rate': round(success_rate, 2),
            'average_amount': weekly_data['avg_amount'] or 0
        }
        
        serializer = AnalyticsSummarySerializer(summary_data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def monthly_summary(self, request):
        """
        Get monthly analytics summary
        """
        end_date = timezone.now().date()
        start_date = end_date.replace(day=1)  # First day of current month
        
        monthly_data = Payment.objects.filter(
            created_at__date__range=[start_date, end_date]
        ).aggregate(
            total_count=Count('id'),
            total_amount=Sum('amount'),
            successful_count=Count('id', filter=Q(status='completed')),
            failed_count=Count('id', filter=Q(status='failed')),
            avg_amount=Avg('amount')
        )
        
        # Calculate success rate
        success_rate = 0
        if monthly_data['total_count'] and monthly_data['total_count'] > 0:
            success_rate = (
                monthly_data['successful_count'] / monthly_data['total_count'] * 100
            )
        
        summary_data = {
            'period': 'current_month',
            'total_transactions': monthly_data['total_count'] or 0,
            'total_amount': monthly_data['total_amount'] or 0,
            'successful_transactions': monthly_data['successful_count'] or 0,
            'failed_transactions': monthly_data['failed_count'] or 0,
            'success_rate': round(success_rate, 2),
            'average_amount': monthly_data['avg_amount'] or 0
        }
        
        serializer = AnalyticsSummarySerializer(summary_data)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def transaction_analytics(self, request):
        """
        Get transaction-specific analytics
        """
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=30)  # Last 30 days
        
        transactions_data = Transaction.objects.filter(
            created_at__date__range=[start_date, end_date]
        ).aggregate(
            total_count=Count('id'),
            total_amount=Sum('amount'),
            completed_count=Count('id', filter=Q(status='completed')),
            pending_count=Count('id', filter=Q(status='pending')),
            failed_count=Count('id', filter=Q(status='failed')),
            escrow_count=Count('id', filter=Q(transaction_type='escrow')),
            direct_count=Count('id', filter=Q(transaction_type='direct')),
            avg_amount=Avg('amount')
        )
        
        return Response({
            'period': 'last_30_days',
            'total_transactions': transactions_data['total_count'] or 0,
            'total_amount': transactions_data['total_amount'] or 0,
            'completed_transactions': transactions_data['completed_count'] or 0,
            'pending_transactions': transactions_data['pending_count'] or 0,
            'failed_transactions': transactions_data['failed_count'] or 0,
            'escrow_transactions': transactions_data['escrow_count'] or 0,
            'direct_transactions': transactions_data['direct_count'] or 0,
            'average_amount': transactions_data['avg_amount'] or 0
        })
    
    @action(detail=False, methods=['get'])
    def escrow_analytics(self, request):
        """
        Get escrow-specific analytics
        """
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=30)  # Last 30 days
        
        escrow_data = EscrowAccount.objects.filter(
            created_at__date__range=[start_date, end_date]
        ).aggregate(
            total_count=Count('id'),
            total_amount=Sum('amount'),
            active_count=Count('id', filter=Q(status='active')),
            released_count=Count('id', filter=Q(status='released')),
            disputed_count=Count('id', filter=Q(status='disputed')),
            refunded_count=Count('id', filter=Q(status='refunded')),
            early_release_count=Count('id', filter=Q(early_release_requested=True)),
            avg_amount=Avg('amount')
        )
        
        # Get category breakdown
        category_breakdown = EscrowAccount.objects.filter(
            created_at__date__range=[start_date, end_date]
        ).values('category').annotate(
            count=Count('id'),
            total_amount=Sum('amount')
        ).order_by('-count')
        
        return Response({
            'period': 'last_30_days',
            'total_escrow_accounts': escrow_data['total_count'] or 0,
            'total_escrow_amount': escrow_data['total_amount'] or 0,
            'active_escrows': escrow_data['active_count'] or 0,
            'released_escrows': escrow_data['released_count'] or 0,
            'disputed_escrows': escrow_data['disputed_count'] or 0,
            'refunded_escrows': escrow_data['refunded_count'] or 0,
            'early_release_requests': escrow_data['early_release_count'] or 0,
            'average_escrow_amount': escrow_data['avg_amount'] or 0,
            'category_breakdown': list(category_breakdown)
        })
    
    @action(detail=False, methods=['post'])
    def custom_range(self, request):
        """
        Get analytics for custom date range
        """
        serializer = DateRangeFilterSerializer(data=request.data)
        if serializer.is_valid():
            start_date = serializer.validated_data['start_date']
            end_date = serializer.validated_data['end_date']
            
            custom_data = Payment.objects.filter(
                created_at__date__range=[start_date, end_date]
            ).aggregate(
                total_count=Count('id'),
                total_amount=Sum('amount'),
                successful_count=Count('id', filter=Q(status='completed')),
                failed_count=Count('id', filter=Q(status='failed')),
                avg_amount=Avg('amount')
            )
            
            # Calculate success rate
            success_rate = 0
            if custom_data['total_count'] and custom_data['total_count'] > 0:
                success_rate = (
                    custom_data['successful_count'] / custom_data['total_count'] * 100
                )
            
            summary_data = {
                'period': f'{start_date} to {end_date}',
                'total_transactions': custom_data['total_count'] or 0,
                'total_amount': custom_data['total_amount'] or 0,
                'successful_transactions': custom_data['successful_count'] or 0,
                'failed_transactions': custom_data['failed_count'] or 0,
                'success_rate': round(success_rate, 2),
                'average_amount': custom_data['avg_amount'] or 0
            }
            
            response_serializer = AnalyticsSummarySerializer(summary_data)
            return Response(response_serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
