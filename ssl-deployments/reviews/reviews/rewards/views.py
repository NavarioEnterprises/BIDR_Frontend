from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import SearchFilter, OrderingFilter
from django.utils import timezone
from django.db import transaction

from .models import (
    ReferralCode, Referral, RewardTransaction, 
    UserRewardsSummary, RewardsCampaign
)
from .serializers import (
    ReferralCodeSerializer, ReferralCodeCreateSerializer,
    ReferralSerializer, ReferralCreateSerializer,
    RewardTransactionSerializer, UserRewardsSummarySerializer,
    RewardsCampaignSerializer,
    FlutterReferralCodeSerializer, FlutterRewardsSummarySerializer,
    FlutterRewardTransactionSerializer
)
from .services import RewardsService
from decimal import Decimal


class ReferralCodeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing referral codes.
    Supports creating, retrieving, and managing user referral codes.
    """
    
    queryset = ReferralCode.objects.all()
    serializer_class = ReferralCodeSerializer
    permission_classes = [AllowAny]  # Adjust as needed
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    
    filterset_fields = ['user_uuid', 'status', 'is_active']
    search_fields = ['code']
    ordering_fields = ['created_at', 'total_uses']
    ordering = ['-created_at']
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ReferralCodeCreateSerializer
        return ReferralCodeSerializer
    
    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """Get referral codes for a specific user"""
        user_uuid = request.query_params.get('user_uuid')
        
        if not user_uuid:
            return Response(
                {'error': 'user_uuid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Get or create user's referral code
            referral_code, created = ReferralCode.objects.get_or_create(
                user_uuid=user_uuid,
                defaults={'status': 'ACTIVE'}
            )
            
            serializer = FlutterReferralCodeSerializer(referral_code)
            return Response(serializer.data)
            
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=True, methods=['post'])
    def regenerate(self, request, pk=None):
        """Regenerate a referral code"""
        referral_code = self.get_object()
        
        # Only allow user to regenerate their own code
        user_uuid = request.data.get('user_uuid')
        if str(referral_code.user_uuid) != str(user_uuid):
            return Response(
                {'error': 'You can only regenerate your own referral code'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Generate new code
        old_code = referral_code.code
        referral_code.code = referral_code.generate_referral_code()
        referral_code.save(update_fields=['code'])
        
        return Response({
            'message': 'Referral code regenerated successfully',
            'old_code': old_code,
            'new_code': referral_code.code,
            'referral_url': referral_code.referral_url
        })


class ReferralViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing referrals and processing new signups via referral codes.
    """
    
    queryset = Referral.objects.all()
    serializer_class = ReferralSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    
    filterset_fields = ['referrer_uuid', 'referee_uuid', 'status']
    ordering_fields = ['created_at', 'completed_at']
    ordering = ['-created_at']
    
    @action(detail=False, methods=['post'])
    def process_referral(self, request):
        """
        Process a new user signup via referral code.
        This endpoint is called when someone signs up using a referral link.
        """
        serializer = ReferralCreateSerializer(data=request.data)
        
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        referral_code = serializer.validated_data['referral_code']
        referee_uuid = serializer.validated_data['referee_uuid']
        
        try:
            with transaction.atomic():
                # Create the referral record
                referral = Referral.objects.create(
                    referral_code=referral_code,
                    referrer_uuid=referral_code.user_uuid,
                    referee_uuid=referee_uuid,
                    referrer_reward_amount=referral_code.referrer_reward_amount,
                    referee_reward_amount=referral_code.referee_reward_amount,
                    status='PENDING'
                )
                
                # Process rewards using the service
                rewards_service = RewardsService()
                
                # Award points to both users
                referrer_transaction = rewards_service.award_referral_reward(
                    referral=referral,
                    user_uuid=referral_code.user_uuid,
                    is_referrer=True
                )
                
                referee_transaction = rewards_service.award_referral_reward(
                    referral=referral,
                    user_uuid=referee_uuid,
                    is_referrer=False
                )
                
                # Mark referral as completed
                referral.complete_referral()
                
                # Update reward flags
                referral.referrer_rewarded = True
                referral.referee_rewarded = True
                referral.save(update_fields=['referrer_rewarded', 'referee_rewarded'])
                
                return Response({
                    'message': 'Referral processed successfully',
                    'referral_id': str(referral.id),
                    'referrer_reward': float(referral.referrer_reward_amount),
                    'referee_reward': float(referral.referee_reward_amount),
                    'referrer_transaction_id': str(referrer_transaction.id),
                    'referee_transaction_id': str(referee_transaction.id)
                }, status=status.HTTP_201_CREATED)
                
        except Exception as e:
            return Response(
                {'error': f'Failed to process referral: {str(e)}'}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def my_referrals(self, request):
        """Get referrals made by a specific user"""
        user_uuid = request.query_params.get('user_uuid')
        
        if not user_uuid:
            return Response(
                {'error': 'user_uuid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        referrals = Referral.objects.filter(referrer_uuid=user_uuid).order_by('-created_at')
        page = self.paginate_queryset(referrals)
        
        if page is not None:
            serializer = ReferralSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = ReferralSerializer(referrals, many=True)
        return Response(serializer.data)


class RewardTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing reward transactions.
    Read-only as transactions are created by the system.
    """
    
    queryset = RewardTransaction.objects.all()
    serializer_class = RewardTransactionSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    
    filterset_fields = ['user_uuid', 'transaction_type', 'status']
    ordering_fields = ['created_at', 'processed_at', 'points_amount']
    ordering = ['-created_at']
    
    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """Get transactions for a specific user"""
        user_uuid = request.query_params.get('user_uuid')
        
        if not user_uuid:
            return Response(
                {'error': 'user_uuid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        transactions = RewardTransaction.objects.filter(user_uuid=user_uuid).order_by('-created_at')
        page = self.paginate_queryset(transactions)
        
        if page is not None:
            serializer = FlutterRewardTransactionSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = FlutterRewardTransactionSerializer(transactions, many=True)
        return Response(serializer.data)


class UserRewardsSummaryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing user rewards summaries.
    """
    
    queryset = UserRewardsSummary.objects.all()
    serializer_class = UserRewardsSummarySerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    
    filterset_fields = ['tier_level', 'is_active']
    ordering_fields = ['current_points_balance', 'total_points_earned', 'created_at']
    ordering = ['-current_points_balance']
    
    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """Get rewards summary for a specific user"""
        user_uuid = request.query_params.get('user_uuid')
        
        if not user_uuid:
            return Response(
                {'error': 'user_uuid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Get or create user summary
            summary, created = UserRewardsSummary.objects.get_or_create(
                user_uuid=user_uuid
            )
            
            # Update balance if needed
            if not created:
                summary.update_balance()
            
            serializer = FlutterRewardsSummarySerializer(summary)
            return Response(serializer.data)
            
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    @action(detail=False, methods=['get'])
    def leaderboard(self, request):
        """Get top users by points for leaderboard"""
        limit = min(int(request.query_params.get('limit', 10)), 100)
        
        top_users = UserRewardsSummary.objects.filter(
            is_active=True
        ).order_by('-current_points_balance')[:limit]
        
        serializer = UserRewardsSummarySerializer(top_users, many=True)
        return Response(serializer.data)


class RewardsCampaignViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing active rewards campaigns.
    """
    
    queryset = RewardsCampaign.objects.all()
    serializer_class = RewardsCampaignSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    
    filterset_fields = ['status', 'campaign_type']
    ordering_fields = ['starts_at', 'ends_at', 'created_at']
    ordering = ['-created_at']
    
    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get currently active campaigns"""
        now = timezone.now()
        active_campaigns = RewardsCampaign.objects.filter(
            status='ACTIVE',
            starts_at__lte=now,
            ends_at__gte=now
        )
        
        serializer = RewardsCampaignSerializer(active_campaigns, many=True)
        return Response(serializer.data)


# Additional utility views for Flutter integration

class FlutterRewardsAPIView:
    """
    Consolidated API view for Flutter app integration.
    Provides simplified endpoints optimized for mobile app usage.
    """
    
    @action(detail=False, methods=['get'])
    def dashboard(self, request):
        """
        Get complete rewards dashboard data for a user.
        Optimized for Flutter app home screen.
        """
        user_uuid = request.query_params.get('user_uuid')
        
        if not user_uuid:
            return Response(
                {'error': 'user_uuid parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            # Get or create user summary
            summary, _ = UserRewardsSummary.objects.get_or_create(user_uuid=user_uuid)
            summary.update_balance()
            
            # Get or create referral code
            referral_code, _ = ReferralCode.objects.get_or_create(
                user_uuid=user_uuid,
                defaults={'status': 'ACTIVE'}
            )
            
            # Get recent transactions
            recent_transactions = RewardTransaction.objects.filter(
                user_uuid=user_uuid
            ).order_by('-created_at')[:5]
            
            # Get active campaigns
            now = timezone.now()
            active_campaigns = RewardsCampaign.objects.filter(
                status='ACTIVE',
                starts_at__lte=now,
                ends_at__gte=now
            )
            
            return Response({
                'summary': FlutterRewardsSummarySerializer(summary).data,
                'referral_code': FlutterReferralCodeSerializer(referral_code).data,
                'recent_transactions': FlutterRewardTransactionSerializer(recent_transactions, many=True).data,
                'active_campaigns': RewardsCampaignSerializer(active_campaigns, many=True).data,
            })
            
        except Exception as e:
            return Response(
                {'error': str(e)}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
