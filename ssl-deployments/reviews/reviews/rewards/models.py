from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from decimal import Decimal
import uuid
import random
import string


class ReferralCode(models.Model):
    """
    Model for managing user referral codes and tracking referrals.
    Integrates with external authentication service using UUIDs.
    """
    
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('EXPIRED', 'Expired'),
        ('SUSPENDED', 'Suspended'),
    ]
    
    # Primary key and user reference
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_uuid = models.UUIDField(
        help_text="UUID of the user from authentication service"
    )
    
    # Referral code details
    code = models.CharField(
        max_length=20, 
        unique=True, 
        help_text="Unique referral code like BIDR12345678"
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    
    # Usage tracking
    total_uses = models.IntegerField(default=0)
    max_uses = models.IntegerField(default=100, help_text="Maximum number of uses allowed")
    
    # Reward settings
    referrer_reward_amount = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=Decimal('50.00'),
        help_text="Amount rewarded to referrer when someone signs up"
    )
    referee_reward_amount = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=Decimal('25.00'),
        help_text="Amount rewarded to new user who signs up"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user_uuid']),
            models.Index(fields=['code']),
            models.Index(fields=['status']),
        ]
    
    def save(self, *args, **kwargs):
        if not self.code:
            self.code = self.generate_referral_code()
        super().save(*args, **kwargs)
    
    def generate_referral_code(self):
        """Generate a unique referral code like BIDR12345678"""
        while True:
            # Generate 8-digit number
            random_number = random.randint(10000000, 99999999)
            code = f'BIDR{random_number}'
            
            # Check if code already exists
            if not ReferralCode.objects.filter(code=code).exists():
                return code
    
    @property
    def is_active(self):
        """Check if referral code is active and not expired"""
        if self.status != 'ACTIVE':
            return False
        if self.expires_at and self.expires_at < timezone.now():
            return False
        if self.total_uses >= self.max_uses:
            return False
        return True
    
    @property
    def referral_url(self):
        """Generate referral URL for sharing"""
        return f"https://bidr.co.za/referral?code={self.code}"
    
    def increment_usage(self):
        """Increment the usage count for this referral code"""
        self.total_uses += 1
        self.save(update_fields=['total_uses'])
    
    def __str__(self):
        return f"{self.code} - User {self.user_uuid}"


class Referral(models.Model):
    """
    Model to track successful referrals and reward distribution.
    """
    
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]
    
    # Primary key
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # Referral details
    referral_code = models.ForeignKey(
        ReferralCode, 
        on_delete=models.CASCADE, 
        related_name='referrals'
    )
    referrer_uuid = models.UUIDField(help_text="UUID of the user who referred")
    referee_uuid = models.UUIDField(help_text="UUID of the new user who was referred")
    
    # Status and rewards
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    referrer_rewarded = models.BooleanField(default=False)
    referee_rewarded = models.BooleanField(default=False)
    
    # Reward amounts (captured at time of referral)
    referrer_reward_amount = models.DecimalField(max_digits=10, decimal_places=2)
    referee_reward_amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['referral_code', 'referee_uuid']  # Prevent duplicate referrals
        indexes = [
            models.Index(fields=['referrer_uuid']),
            models.Index(fields=['referee_uuid']),
            models.Index(fields=['status']),
        ]
    
    def complete_referral(self):
        """Mark referral as completed and update timestamps"""
        self.status = 'COMPLETED'
        self.completed_at = timezone.now()
        self.save(update_fields=['status', 'completed_at'])
        
        # Update referral code usage count
        self.referral_code.total_uses += 1
        self.referral_code.save(update_fields=['total_uses'])
    
    def __str__(self):
        return f"Referral: {self.referral_code.code} -> User {self.referee_uuid}"


class RewardTransaction(models.Model):
    """
    Model to track all reward transactions and points.
    """
    
    TRANSACTION_TYPES = [
        ('REFERRAL_REFERRER', 'Referral Reward (Referrer)'),
        ('REFERRAL_REFEREE', 'Referral Reward (Referee)'),
        ('REVIEW_BONUS', 'Review Writing Bonus'),
        ('RATING_BONUS', 'Rating Bonus'),
        ('LOYALTY_BONUS', 'Loyalty Bonus'),
        ('ADMIN_ADJUSTMENT', 'Admin Adjustment'),
        ('REDEMPTION', 'Points Redemption'),
    ]
    
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
        ('EXPIRED', 'Expired'),
    ]
    
    # Primary key
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    
    # User reference
    user_uuid = models.UUIDField(help_text="UUID of the user receiving the reward")
    
    # Transaction details
    transaction_type = models.CharField(max_length=30, choices=TRANSACTION_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    
    # Amounts
    points_amount = models.DecimalField(
        max_digits=10, 
        decimal_places=2,
        help_text="Points awarded (can be negative for redemptions)"
    )
    cash_equivalent = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=Decimal('0.00'),
        help_text="Cash value equivalent"
    )
    
    # References
    referral = models.ForeignKey(
        Referral, 
        on_delete=models.CASCADE, 
        null=True, 
        blank=True,
        help_text="Related referral if this is a referral reward"
    )
    reference_id = models.CharField(
        max_length=100, 
        blank=True,
        help_text="External reference (e.g., review_id, product_id)"
    )
    
    # Description and notes
    description = models.TextField(blank=True)
    admin_notes = models.TextField(blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    processed_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user_uuid']),
            models.Index(fields=['transaction_type']),
            models.Index(fields=['status']),
            models.Index(fields=['created_at']),
        ]
    
    def process_transaction(self):
        """Mark transaction as processed"""
        self.status = 'COMPLETED'
        self.processed_at = timezone.now()
        self.save(update_fields=['status', 'processed_at'])
    
    def __str__(self):
        return f"{self.get_transaction_type_display()} - {self.points_amount} pts - User {self.user_uuid}"


class UserRewardsSummary(models.Model):
    """
    Model to maintain user reward summaries for quick access.
    Updated via signals when transactions are processed.
    """
    
    # User reference (acts as primary key)
    user_uuid = models.UUIDField(primary_key=True, help_text="UUID of the user")
    
    # Points summary
    current_points_balance = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    total_points_earned = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    total_points_spent = models.DecimalField(max_digits=15, decimal_places=2, default=Decimal('0.00'))
    
    # Referral statistics
    total_referrals_made = models.IntegerField(default=0)
    successful_referrals = models.IntegerField(default=0)
    total_referral_earnings = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    
    # Activity statistics
    total_reviews_written = models.IntegerField(default=0)
    total_ratings_given = models.IntegerField(default=0)
    review_bonus_earned = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    
    # Account status
    is_active = models.BooleanField(default=True)
    tier_level = models.IntegerField(
        default=1,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Tier level: 1=Basic, 2=Bronze, 3=Silver, 4=Gold, 5=Platinum"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_activity_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-current_points_balance']
        indexes = [
            models.Index(fields=['current_points_balance']),
            models.Index(fields=['tier_level']),
            models.Index(fields=['is_active']),
        ]
    
    def update_balance(self):
        """Recalculate points balance from transactions"""
        from django.db.models import Sum
        
        earned = RewardTransaction.objects.filter(
            user_uuid=self.user_uuid,
            status='COMPLETED',
            points_amount__gt=0
        ).aggregate(
            total=Sum('points_amount')
        )['total'] or Decimal('0.00')
        
        redeemed = RewardTransaction.objects.filter(
            user_uuid=self.user_uuid,
            status='COMPLETED',
            points_amount__lt=0
        ).aggregate(
            total=Sum('points_amount')
        )['total'] or Decimal('0.00')
        
        self.total_points_earned = earned
        self.total_points_redeemed = abs(redeemed)
        self.current_points_balance = earned + redeemed  # redeemed is negative
        self.save(update_fields=['total_points_earned', 'total_points_redeemed', 'current_points_balance'])
    
    def calculate_tier(self):
        """Calculate user tier based on points earned"""
        if self.total_points_earned >= Decimal('10000.00'):
            return 'PLATINUM'
        elif self.total_points_earned >= Decimal('5000.00'):
            return 'GOLD'
        elif self.total_points_earned >= Decimal('1000.00'):
            return 'SILVER'
        else:
            return 'BRONZE'
    
    def __str__(self):
        return f"User {self.user_uuid} - {self.current_points_balance} pts ({self.tier_level})"


class RewardsCampaign(models.Model):
    """
    Model for managing special rewards campaigns and promotions.
    """
    
    STATUS_CHOICES = [
        ('DRAFT', 'Draft'),
        ('ACTIVE', 'Active'),
        ('PAUSED', 'Paused'),
        ('ENDED', 'Ended'),
    ]
    
    # Campaign details
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField()
    
    # Campaign settings
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    campaign_type = models.CharField(
        max_length=30,
        choices=[
            ('REFERRAL_BONUS', 'Referral Bonus'),
            ('REVIEW_BONUS', 'Review Bonus'), 
            ('FIRST_TIME_BONUS', 'First Time Bonus'),
            ('LOYALTY_BONUS', 'Loyalty Bonus'),
        ]
    )
    
    # Reward settings
    reward_points = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=Decimal('0.00'),
        help_text="Points awarded for this campaign"
    )
    points_multiplier = models.DecimalField(
        max_digits=5, 
        decimal_places=2, 
        default=Decimal('1.00'),
        help_text="Multiply standard rewards by this amount"
    )
    bonus_points = models.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        default=Decimal('0.00'),
        help_text="Additional bonus points to award"
    )
    
    # Time constraints
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    
    # Usage limits
    max_participants = models.IntegerField(null=True, blank=True)
    current_participants = models.IntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'starts_at', 'ends_at']),
            models.Index(fields=['campaign_type']),
        ]
    
    @property
    def is_active(self):
        """Check if campaign is currently active"""
        now = timezone.now()
        return (
            self.status == 'ACTIVE' 
            and self.starts_at <= now 
            and self.ends_at >= now
            and (self.max_participants is None or self.current_participants < self.max_participants)
        )
    
    def __str__(self):
        return f"{self.name} ({self.status})"
