from rest_framework import serializers
from .models import ReferralCode, Referral, RewardTransaction, UserRewardsSummary, RewardsCampaign
from decimal import Decimal


class ReferralCodeSerializer(serializers.ModelSerializer):
    """Serializer for ReferralCode model"""
    
    referral_url = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    
    class Meta:
        model = ReferralCode
        fields = [
            'id', 'user_uuid', 'code', 'status', 'total_uses', 'max_uses',
            'referrer_reward_amount', 'referee_reward_amount', 'referral_url',
            'is_active', 'created_at', 'updated_at', 'expires_at'
        ]
        read_only_fields = ['id', 'code', 'total_uses', 'created_at', 'updated_at']


class ReferralCodeCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating referral codes"""
    
    class Meta:
        model = ReferralCode
        fields = ['user_uuid', 'max_uses', 'referrer_reward_amount', 'referee_reward_amount', 'expires_at']


class ReferralSerializer(serializers.ModelSerializer):
    """Serializer for Referral model"""
    
    referral_code_text = serializers.CharField(source='referral_code.code', read_only=True)
    
    class Meta:
        model = Referral
        fields = [
            'id', 'referral_code', 'referral_code_text', 'referrer_uuid', 'referee_uuid',
            'status', 'referrer_rewarded', 'referee_rewarded', 'referrer_reward_amount',
            'referee_reward_amount', 'created_at', 'completed_at'
        ]
        read_only_fields = ['id', 'referrer_uuid', 'created_at', 'completed_at']


class ReferralCreateSerializer(serializers.Serializer):
    """Serializer for processing a new referral signup"""
    
    referral_code = serializers.CharField(max_length=20)
    referee_uuid = serializers.UUIDField()
    
    def validate_referral_code(self, value):
        """Validate that referral code exists and is active"""
        try:
            referral_code = ReferralCode.objects.get(code=value)
            if not referral_code.is_active:
                raise serializers.ValidationError("Referral code is not active or has expired.")
            return referral_code
        except ReferralCode.DoesNotExist:
            raise serializers.ValidationError("Invalid referral code.")
    
    def validate(self, data):
        """Validate that the referee hasn't already used this referral code"""
        referral_code = data['referral_code']
        referee_uuid = data['referee_uuid']
        
        # Check if referral already exists
        if Referral.objects.filter(referral_code=referral_code, referee_uuid=referee_uuid).exists():
            raise serializers.ValidationError("This user has already used this referral code.")
        
        # Check if user is trying to refer themselves
        if referral_code.user_uuid == referee_uuid:
            raise serializers.ValidationError("You cannot refer yourself.")
        
        return data


class RewardTransactionSerializer(serializers.ModelSerializer):
    """Serializer for RewardTransaction model"""
    
    transaction_type_display = serializers.CharField(source='get_transaction_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = RewardTransaction
        fields = [
            'id', 'user_uuid', 'transaction_type', 'transaction_type_display',
            'status', 'status_display', 'points_amount', 'cash_equivalent',
            'description', 'reference_id', 'created_at', 'processed_at', 'expires_at'
        ]
        read_only_fields = ['id', 'created_at', 'processed_at']


class UserRewardsSummarySerializer(serializers.ModelSerializer):
    """Serializer for UserRewardsSummary model"""
    
    tier_level_display = serializers.CharField(source='get_tier_level_display', read_only=True)
    
    class Meta:
        model = UserRewardsSummary
        fields = [
            'user_uuid', 'total_points_earned', 'total_points_redeemed', 
            'current_points_balance', 'total_referrals_made', 'successful_referrals',
            'total_referral_earnings', 'total_reviews_written', 'total_ratings_given',
            'review_bonus_earned', 'is_active', 'tier_level', 'tier_level_display',
            'created_at', 'updated_at', 'last_activity_at'
        ]
        read_only_fields = [
            'total_points_earned', 'total_points_redeemed', 'current_points_balance',
            'total_referrals_made', 'successful_referrals', 'total_referral_earnings',
            'total_reviews_written', 'total_ratings_given', 'review_bonus_earned',
            'created_at', 'updated_at', 'last_activity_at'
        ]


class RewardsCampaignSerializer(serializers.ModelSerializer):
    """Serializer for RewardsCampaign model"""
    
    is_active = serializers.ReadOnlyField()
    campaign_type_display = serializers.CharField(source='get_campaign_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = RewardsCampaign
        fields = [
            'id', 'name', 'description', 'status', 'status_display', 
            'campaign_type', 'campaign_type_display', 'points_multiplier', 
            'bonus_points', 'starts_at', 'ends_at', 'max_participants', 
            'current_participants', 'is_active', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'current_participants', 'created_at', 'updated_at']


# Specialized serializers for the Flutter app integration

class FlutterReferralCodeSerializer(serializers.ModelSerializer):
    """Simplified serializer for Flutter app - referral codes"""
    
    class Meta:
        model = ReferralCode
        fields = ['code', 'referral_url', 'is_active', 'total_uses', 'max_uses']


class FlutterRewardsSummarySerializer(serializers.ModelSerializer):
    """Simplified serializer for Flutter app - user rewards summary"""
    
    class Meta:
        model = UserRewardsSummary
        fields = [
            'current_points_balance', 'total_referrals_made', 'successful_referrals',
            'tier_level', 'total_reviews_written', 'total_ratings_given'
        ]


class FlutterRewardTransactionSerializer(serializers.ModelSerializer):
    """Simplified serializer for Flutter app - recent transactions"""
    
    class Meta:
        model = RewardTransaction
        fields = [
            'transaction_type', 'points_amount', 'description', 'status', 'created_at'
        ]
