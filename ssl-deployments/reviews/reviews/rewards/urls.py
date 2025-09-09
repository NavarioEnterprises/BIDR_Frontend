from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone

from . import views
from .models import UserRewardsSummary, ReferralCode, RewardsCampaign
from .serializers import (
    FlutterRewardsSummarySerializer, 
    FlutterReferralCodeSerializer, 
    RewardsCampaignSerializer
)

# Create router for ViewSets
router = DefaultRouter()
router.register(r'referral-codes', views.ReferralCodeViewSet, basename='referralcode')
router.register(r'referrals', views.ReferralViewSet, basename='referral')
router.register(r'transactions', views.RewardTransactionViewSet, basename='rewardtransaction')
router.register(r'summaries', views.UserRewardsSummaryViewSet, basename='userrewardssummary')
router.register(r'campaigns', views.RewardsCampaignViewSet, basename='rewardscampaign')


@api_view(['GET'])
@permission_classes([AllowAny])
def flutter_rewards_dashboard(request):
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
        from .models import RewardTransaction
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
        
        # Calculate tier progress
        from .services import RewardsService
        rewards_service = RewardsService()
        points_to_next_tier = rewards_service.calculate_points_to_next_tier(summary)
        tier_name = rewards_service.get_user_tier_name(summary.tier_level)
        
        return Response({
            'summary': {
                **FlutterRewardsSummarySerializer(summary).data,
                'tier_name': tier_name,
                'points_to_next_tier': points_to_next_tier
            },
            'referral_code': FlutterReferralCodeSerializer(referral_code).data,
            'recent_transactions': [
                {
                    'id': str(t.id),
                    'transaction_type': t.transaction_type,
                    'points_amount': float(t.points_amount),
                    'description': t.description,
                    'created_at': t.created_at.isoformat(),
                    'status': t.status
                } for t in recent_transactions
            ],
            'active_campaigns': RewardsCampaignSerializer(active_campaigns, many=True).data,
        })
        
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['POST'])
@permission_classes([AllowAny])
def flutter_process_referral(request):
    """
    Process a new user signup via referral code.
    Simplified endpoint for Flutter app.
    """
    referral_code_str = request.data.get('referral_code')
    referee_uuid = request.data.get('user_uuid')  # New user's UUID
    
    if not referral_code_str or not referee_uuid:
        return Response(
            {'error': 'referral_code and user_uuid are required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        from django.db import transaction
        from .services import RewardsService
        from .models import Referral
        
        rewards_service = RewardsService()
        
        # Validate referral code
        referral_code = rewards_service.validate_referral_code(referral_code_str)
        if not referral_code:
            return Response(
                {'error': 'Invalid or inactive referral code'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if user can be referred
        if not rewards_service.can_user_be_referred(referee_uuid):
            return Response(
                {'error': 'User has already been referred'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Prevent self-referral
        if str(referral_code.user_uuid) == str(referee_uuid):
            return Response(
                {'error': 'Users cannot refer themselves'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
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
                'success': True,
                'message': 'Referral processed successfully! You both earned points!',
                'referrer_reward': float(referral.referrer_reward_amount),
                'referee_reward': float(referral.referee_reward_amount),
                'referral_id': str(referral.id)
            }, status=status.HTTP_201_CREATED)
                
    except Exception as e:
        return Response(
            {'error': f'Failed to process referral: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

@api_view(['GET'])
@permission_classes([AllowAny])
def flutter_validate_referral_code(request):
    """
    Validate a referral code without processing it.
    Used by Flutter app to check code validity before signup.
    """
    referral_code_str = request.query_params.get('code')
    
    if not referral_code_str:
        return Response(
            {'error': 'code parameter is required'}, 
            status=status.HTTP_400_BAD_REQUEST
        )
    
    try:
        from .services import RewardsService
        
        rewards_service = RewardsService()
        referral_code = rewards_service.validate_referral_code(referral_code_str)
        
        if referral_code:
            return Response({
                'valid': True,
                'referrer_reward': float(referral_code.referrer_reward_amount),
                'referee_reward': float(referral_code.referee_reward_amount),
                'message': f'Valid referral code! You will earn {float(referral_code.referee_reward_amount)} points when you sign up!'
            })
        else:
            return Response({
                'valid': False,
                'message': 'Invalid or expired referral code'
            })
            
    except Exception as e:
        return Response(
            {'error': str(e)}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )

# URL patterns
urlpatterns = [
    # Include router URLs
    path('api/', include(router.urls)),
    
    # Flutter-optimized endpoints
    path('api/dashboard/', flutter_rewards_dashboard, name='flutter_rewards_dashboard'),
    path('api/process-referral/', flutter_process_referral, name='flutter_process_referral'),
    path('api/validate-code/', flutter_validate_referral_code, name='flutter_validate_referral_code'),
    
    # Additional convenience endpoints
    path('api/my-code/', views.ReferralCodeViewSet.as_view({'get': 'by_user'}), name=''),
    path('api/my-referrals/', views.ReferralViewSet.as_view({'get': 'my_referrals'}), name=''),
    path('api/my-transactions/', views.RewardTransactionViewSet.as_view({'get': 'by_user'}), name=''),
    path('api/my-summary/', views.UserRewardsSummaryViewSet.as_view({'get': 'by_user'}), name=''),
    path('api/leaderboard/', views.UserRewardsSummaryViewSet.as_view({'get': 'leaderboard'}), name=''),
    path('api/active-campaigns/', views.RewardsCampaignViewSet.as_view({'get': 'active'}), name=''),
]
