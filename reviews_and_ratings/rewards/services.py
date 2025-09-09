from django.db import transaction
from django.utils import timezone
from decimal import Decimal
import logging

from .models import (
    ReferralCode, Referral, RewardTransaction, 
    UserRewardsSummary, RewardsCampaign
)

logger = logging.getLogger(__name__)


class RewardsService:
    """
    Service class handling rewards business logic and transactions.
    """
    
    def __init__(self):
        self.default_referrer_reward = Decimal('100.00')  # 100 points for referrer
        self.default_referee_reward = Decimal('50.00')    # 50 points for referee
    
    def award_referral_reward(self, referral, user_uuid, is_referrer=False):
        """
        Award referral reward to a user.
        
        Args:
            referral: Referral instance
            user_uuid: UUID of the user receiving reward
            is_referrer: Whether this user is the referrer (True) or referee (False)
            
        Returns:
            RewardTransaction instance
        """
        try:
            with transaction.atomic():
                # Determine reward amount
                if is_referrer:
                    points_amount = referral.referrer_reward_amount
                    description = f"Referral reward for inviting user {str(referral.referee_uuid)[:8]}"
                    transaction_type = "REFERRAL_BONUS"
                else:
                    points_amount = referral.referee_reward_amount
                    description = f"Welcome reward for signing up via referral {referral.referral_code.code}"
                    transaction_type = "SIGNUP_BONUS"
                
                # Create reward transaction
                reward_transaction = RewardTransaction.objects.create(
                    user_uuid=user_uuid,
                    transaction_type=transaction_type,
                    points_amount=points_amount,
                    description=description,
                    metadata={
                        'referral_id': str(referral.id),
                        'referral_code': referral.referral_code.code,
                        'is_referrer': is_referrer
                    },
                    status='COMPLETED',
                    processed_at=timezone.now()
                )
                
                # Update user rewards summary
                self._update_user_summary(user_uuid, points_amount)
                
                # Update referral code usage
                if is_referrer:
                    referral.referral_code.increment_usage()
                
                logger.info(f"Awarded {points_amount} points to user {user_uuid} for referral {referral.id}")
                return reward_transaction
                
        except Exception as e:
            logger.error(f"Failed to award referral reward: {str(e)}")
            raise
    
    def award_action_reward(self, user_uuid, action_type, points_amount, description=None, metadata=None):
        """
        Award points for specific user actions (reviews, purchases, etc.).
        
        Args:
            user_uuid: UUID of the user receiving reward
            action_type: Type of action (REVIEW_WRITTEN, PURCHASE_MADE, etc.)
            points_amount: Amount of points to award
            description: Optional description
            metadata: Optional metadata dict
            
        Returns:
            RewardTransaction instance
        """
        try:
            with transaction.atomic():
                if not description:
                    description = f"Points earned for {action_type.lower().replace('_', ' ')}"
                
                reward_transaction = RewardTransaction.objects.create(
                    user_uuid=user_uuid,
                    transaction_type=action_type,
                    points_amount=Decimal(str(points_amount)),
                    description=description,
                    metadata=metadata or {},
                    status='COMPLETED',
                    processed_at=timezone.now()
                )
                
                # Update user rewards summary
                self._update_user_summary(user_uuid, Decimal(str(points_amount)))
                
                logger.info(f"Awarded {points_amount} points to user {user_uuid} for {action_type}")
                return reward_transaction
                
        except Exception as e:
            logger.error(f"Failed to award action reward: {str(e)}")
            raise
    
    def deduct_points(self, user_uuid, points_amount, reason, metadata=None):
        """
        Deduct points from user's balance.
        
        Args:
            user_uuid: UUID of the user
            points_amount: Amount of points to deduct
            reason: Reason for deduction
            metadata: Optional metadata dict
            
        Returns:
            RewardTransaction instance
        """
        try:
            with transaction.atomic():
                # Check if user has sufficient balance
                summary = UserRewardsSummary.objects.get(user_uuid=user_uuid)
                if summary.current_points_balance < Decimal(str(points_amount)):
                    raise ValueError("Insufficient points balance")
                
                reward_transaction = RewardTransaction.objects.create(
                    user_uuid=user_uuid,
                    transaction_type='POINTS_DEDUCTION',
                    points_amount=-Decimal(str(points_amount)),  # Negative for deduction
                    description=reason,
                    metadata=metadata or {},
                    status='COMPLETED',
                    processed_at=timezone.now()
                )
                
                # Update user rewards summary
                self._update_user_summary(user_uuid, -Decimal(str(points_amount)))
                
                logger.info(f"Deducted {points_amount} points from user {user_uuid}: {reason}")
                return reward_transaction
                
        except Exception as e:
            logger.error(f"Failed to deduct points: {str(e)}")
            raise
    
    def process_campaign_reward(self, user_uuid, campaign, action_data=None):
        """
        Process reward for a specific campaign.
        
        Args:
            user_uuid: UUID of the user
            campaign: RewardsCampaign instance
            action_data: Optional data about the qualifying action
            
        Returns:
            RewardTransaction instance or None
        """
        try:
            if not campaign.is_active():
                logger.warning(f"Campaign {campaign.id} is not active")
                return None
            
            # Check if user already received this campaign reward
            existing_transaction = RewardTransaction.objects.filter(
                user_uuid=user_uuid,
                metadata__campaign_id=str(campaign.id)
            ).first()
            
            if existing_transaction:
                logger.info(f"User {user_uuid} already received reward for campaign {campaign.id}")
                return existing_transaction
            
            with transaction.atomic():
                reward_transaction = RewardTransaction.objects.create(
                    user_uuid=user_uuid,
                    transaction_type='CAMPAIGN_REWARD',
                    points_amount=campaign.reward_points,
                    description=f"Campaign reward: {campaign.name}",
                    metadata={
                        'campaign_id': str(campaign.id),
                        'campaign_name': campaign.name,
                        'action_data': action_data or {}
                    },
                    status='COMPLETED',
                    processed_at=timezone.now()
                )
                
                # Update user rewards summary
                self._update_user_summary(user_uuid, campaign.reward_points)
                
                logger.info(f"Awarded campaign reward {campaign.reward_points} points to user {user_uuid}")
                return reward_transaction
                
        except Exception as e:
            logger.error(f"Failed to process campaign reward: {str(e)}")
            raise
    
    def _update_user_summary(self, user_uuid, points_delta):
        """
        Update or create user rewards summary with points delta.
        
        Args:
            user_uuid: UUID of the user
            points_delta: Change in points (can be positive or negative)
        """
        summary, created = UserRewardsSummary.objects.get_or_create(
            user_uuid=user_uuid,
            defaults={
                'current_points_balance': Decimal('0.00'),
                'total_points_earned': Decimal('0.00'),
                'total_points_spent': Decimal('0.00'),
                'tier_level': 1,
                'is_active': True
            }
        )
        
        # Update balances
        if points_delta > 0:
            summary.total_points_earned += points_delta
            summary.current_points_balance += points_delta
        else:
            summary.total_points_spent += abs(points_delta)
            summary.current_points_balance += points_delta  # points_delta is negative
        
        # Update tier level based on total earned points
        summary.tier_level = self._calculate_tier_level(summary.total_points_earned)
        
        # Update last activity
        summary.last_activity_at = timezone.now()
        
        summary.save(update_fields=[
            'current_points_balance', 'total_points_earned', 
            'total_points_spent', 'tier_level', 'last_activity_at'
        ])
    
    def _calculate_tier_level(self, total_points_earned):
        """
        Calculate user tier level based on total points earned.
        
        Args:
            total_points_earned: Total points earned by user
            
        Returns:
            int: Tier level (1-5)
        """
        if total_points_earned >= 10000:
            return 5  # Platinum
        elif total_points_earned >= 5000:
            return 4  # Gold
        elif total_points_earned >= 2000:
            return 3  # Silver
        elif total_points_earned >= 500:
            return 2  # Bronze
        else:
            return 1  # Basic
    
    def get_user_tier_name(self, tier_level):
        """Get tier name from tier level."""
        tier_names = {
            1: 'Basic',
            2: 'Bronze', 
            3: 'Silver',
            4: 'Gold',
            5: 'Platinum'
        }
        return tier_names.get(tier_level, 'Basic')
    
    def calculate_points_to_next_tier(self, user_summary):
        """
        Calculate points needed to reach next tier.
        
        Args:
            user_summary: UserRewardsSummary instance
            
        Returns:
            int: Points needed for next tier, or 0 if at max tier
        """
        tier_thresholds = {
            1: 500,   # Basic -> Bronze
            2: 2000,  # Bronze -> Silver  
            3: 5000,  # Silver -> Gold
            4: 10000, # Gold -> Platinum
            5: 0      # Platinum (max tier)
        }
        
        current_tier = user_summary.tier_level
        next_threshold = tier_thresholds.get(current_tier, 0)
        
        if next_threshold == 0:
            return 0  # Already at max tier
        
        points_needed = next_threshold - user_summary.total_points_earned
        return max(0, int(points_needed))
    
    def get_referral_leaderboard(self, limit=10):
        """
        Get top users by successful referrals.
        
        Args:
            limit: Number of top users to return
            
        Returns:
            QuerySet of user summaries with referral counts
        """
        from django.db.models import Count, Q
        
        # Get users with most successful referrals
        top_referrers = UserRewardsSummary.objects.filter(
            is_active=True
        ).annotate(
            successful_referrals=Count(
                'referralcode__referrals',
                filter=Q(referralcode__referrals__status='COMPLETED')
            )
        ).order_by('-successful_referrals', '-current_points_balance')[:limit]
        
        return top_referrers
    
    def validate_referral_code(self, referral_code_str):
        """
        Validate if a referral code exists and is active.
        
        Args:
            referral_code_str: The referral code string
            
        Returns:
            ReferralCode instance or None
        """
        try:
            referral_code = ReferralCode.objects.get(
                code=referral_code_str,
                status='ACTIVE',
                is_active=True
            )
            return referral_code
        except ReferralCode.DoesNotExist:
            return None
    
    def can_user_be_referred(self, user_uuid):
        """
        Check if a user can be referred (hasn't been referred before).
        
        Args:
            user_uuid: UUID of the potential referee
            
        Returns:
            bool: True if user can be referred
        """
        # Check if user has already been referred
        existing_referral = Referral.objects.filter(referee_uuid=user_uuid).first()
        return existing_referral is None
