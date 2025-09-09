from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.utils import timezone
import logging

from .models import Referral, RewardTransaction, UserRewardsSummary

logger = logging.getLogger(__name__)


@receiver(post_save, sender=RewardTransaction)
def update_user_summary_on_transaction(sender, instance, created, **kwargs):
    """
    Update user rewards summary when a new reward transaction is created.
    This ensures the summary is always up-to-date with the latest transactions.
    """
    if created and instance.status == 'COMPLETED':
        try:
            # Get or create user summary
            summary, summary_created = UserRewardsSummary.objects.get_or_create(
                user_uuid=instance.user_uuid,
                defaults={
                    'current_points_balance': 0,
                    'total_points_earned': 0,
                    'total_points_spent': 0,
                    'tier_level': 1,
                    'is_active': True
                }
            )
            
            # Update summary based on transaction
            if instance.points_amount > 0:
                # Points earned
                summary.current_points_balance += instance.points_amount
                summary.total_points_earned += instance.points_amount
            else:
                # Points spent/deducted
                summary.current_points_balance += instance.points_amount  # instance.points_amount is negative
                summary.total_points_spent += abs(instance.points_amount)
            
            # Update tier level based on total earned points
            from .services import RewardsService
            service = RewardsService()
            summary.tier_level = service._calculate_tier_level(summary.total_points_earned)
            
            # Update last activity
            summary.last_activity_at = timezone.now()
            
            summary.save(update_fields=[
                'current_points_balance', 'total_points_earned',
                'total_points_spent', 'tier_level', 'last_activity_at'
            ])
            
            logger.info(f"Updated summary for user {instance.user_uuid} after transaction {instance.id}")
            
        except Exception as e:
            logger.error(f"Failed to update user summary for transaction {instance.id}: {str(e)}")


@receiver(post_save, sender=Referral)
def handle_referral_completion(sender, instance, created, **kwargs):
    """
    Handle referral completion and ensure rewards are processed.
    """
    if not created and instance.status == 'COMPLETED':
        # Check if rewards have been processed
        if not instance.referrer_rewarded or not instance.referee_rewarded:
            try:
                from .services import RewardsService
                service = RewardsService()
                
                # Award rewards if not already done
                if not instance.referrer_rewarded:
                    service.award_referral_reward(
                        referral=instance,
                        user_uuid=instance.referrer_uuid,
                        is_referrer=True
                    )
                    instance.referrer_rewarded = True
                
                if not instance.referee_rewarded:
                    service.award_referral_reward(
                        referral=instance,
                        user_uuid=instance.referee_uuid,
                        is_referrer=False
                    )
                    instance.referee_rewarded = True
                
                instance.save(update_fields=['referrer_rewarded', 'referee_rewarded'])
                logger.info(f"Processed rewards for completed referral {instance.id}")
                
            except Exception as e:
                logger.error(f"Failed to process rewards for referral {instance.id}: {str(e)}")


@receiver(pre_save, sender=UserRewardsSummary)
def validate_user_summary(sender, instance, **kwargs):
    """
    Validate user summary before saving to ensure data integrity.
    """
    # Ensure points balance is never negative
    if instance.current_points_balance < 0:
        logger.warning(f"Negative points balance detected for user {instance.user_uuid}: {instance.current_points_balance}")
        instance.current_points_balance = 0
    
    # Ensure tier level is within valid range
    if instance.tier_level < 1:
        instance.tier_level = 1
    elif instance.tier_level > 5:
        instance.tier_level = 5
    
    # Update last activity timestamp if balance changed
    if hasattr(instance, '_state') and not instance._state.adding:
        try:
            old_instance = UserRewardsSummary.objects.get(pk=instance.pk)
            if old_instance.current_points_balance != instance.current_points_balance:
                instance.last_activity_at = timezone.now()
        except UserRewardsSummary.DoesNotExist:
            pass


@receiver(post_save, sender=UserRewardsSummary)
def log_tier_changes(sender, instance, created, **kwargs):
    """
    Log tier level changes for user engagement tracking.
    """
    if not created and hasattr(instance, '_original_tier'):
        if instance._original_tier != instance.tier_level:
            from .services import RewardsService
            service = RewardsService()
            old_tier_name = service.get_user_tier_name(instance._original_tier)
            new_tier_name = service.get_user_tier_name(instance.tier_level)
            
            logger.info(
                f"User {instance.user_uuid} tier changed from "
                f"{old_tier_name} (Level {instance._original_tier}) to "
                f"{new_tier_name} (Level {instance.tier_level})"
            )


# Add a method to track original tier level before save
def __init__(self, *args, **kwargs):
    super(UserRewardsSummary, self).__init__(*args, **kwargs)
    self._original_tier = self.tier_level

# Monkey patch to add tier tracking
UserRewardsSummary.__init__ = __init__
