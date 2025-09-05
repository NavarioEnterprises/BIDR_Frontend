from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.db.models import Sum, Count
from decimal import Decimal

from .models import (
    ReferralCode, Referral, RewardTransaction,
    UserRewardsSummary, RewardsCampaign
)


@admin.register(ReferralCode)
class ReferralCodeAdmin(admin.ModelAdmin):
    list_display = [
        'code', 'user_uuid_short', 'status', 'active_status', 
        'total_uses', 'referrer_reward_amount', 'referee_reward_amount', 
        'created_at'
    ]
    list_filter = ['status', 'created_at']
    search_fields = ['code', 'user_uuid']
    readonly_fields = ['id', 'code', 'created_at', 'updated_at', 'total_uses']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('id', 'code', 'user_uuid', 'status')
        }),
        ('Rewards', {
            'fields': ('referrer_reward_amount', 'referee_reward_amount')
        }),
        ('Usage Statistics', {
            'fields': ('total_uses', 'max_uses')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def user_uuid_short(self, obj):
        """Display shortened UUID"""
        return f"{str(obj.user_uuid)[:8]}..."
    user_uuid_short.short_description = 'User UUID'
    
    def active_status(self, obj):
        """Display whether referral code is active"""
        return obj.is_active
    active_status.short_description = 'Is Active'
    active_status.boolean = True
    
    def get_queryset(self, request):
        return super().get_queryset(request).annotate(
            referral_count=Count('referrals')
        )


@admin.register(Referral)
class ReferralAdmin(admin.ModelAdmin):
    list_display = [
        'id_short', 'referral_code', 'referrer_uuid_short', 
        'referee_uuid_short', 'status', 'referrer_rewarded', 
        'referee_rewarded', 'created_at'
    ]
    list_filter = [
        'status', 'referrer_rewarded', 'referee_rewarded', 
        'created_at', 'completed_at'
    ]
    search_fields = [
        'referral_code__code', 'referrer_uuid', 'referee_uuid'
    ]
    readonly_fields = [
        'id', 'created_at', 'completed_at',
        'referrer_reward_amount', 'referee_reward_amount'
    ]
    ordering = ['-created_at']
    
    fieldsets = (
        ('Referral Information', {
            'fields': ('id', 'referral_code', 'status')
        }),
        ('Participants', {
            'fields': ('referrer_uuid', 'referee_uuid')
        }),
        ('Rewards', {
            'fields': (
                'referrer_reward_amount', 'referee_reward_amount',
                'referrer_rewarded', 'referee_rewarded'
            )
        }),
        ('Timestamps', {
            'fields': ('created_at', 'completed_at'),
            'classes': ('collapse',)
        }),
    )
    
    def id_short(self, obj):
        """Display shortened ID"""
        return f"{str(obj.id)[:8]}..."
    id_short.short_description = 'ID'
    
    def referrer_uuid_short(self, obj):
        """Display shortened referrer UUID"""
        return f"{str(obj.referrer_uuid)[:8]}..."
    referrer_uuid_short.short_description = 'Referrer'
    
    def referee_uuid_short(self, obj):
        """Display shortened referee UUID"""
        return f"{str(obj.referee_uuid)[:8]}..."
    referee_uuid_short.short_description = 'Referee'
    
    actions = ['mark_as_completed']
    
    def mark_as_completed(self, request, queryset):
        """Mark selected referrals as completed"""
        updated = 0
        for referral in queryset:
            if referral.status != 'COMPLETED':
                referral.complete_referral()
                updated += 1
        
        self.message_user(
            request, 
            f'Successfully marked {updated} referrals as completed.'
        )
    mark_as_completed.short_description = "Mark selected referrals as completed"


@admin.register(RewardTransaction)
class RewardTransactionAdmin(admin.ModelAdmin):
    list_display = [
        'id_short', 'user_uuid_short', 'transaction_type', 
        'points_amount', 'status', 'created_at'
    ]
    list_filter = ['transaction_type', 'status', 'created_at']
    search_fields = ['user_uuid', 'description', 'transaction_type']
    readonly_fields = [
        'id', 'created_at', 'processed_at'
    ]
    ordering = ['-created_at']
    
    fieldsets = (
        ('Transaction Information', {
            'fields': (
                'id', 'user_uuid', 'transaction_type', 'status'
            )
        }),
        ('Details', {
            'fields': ('points_amount', 'description')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'processed_at'),
            'classes': ('collapse',)
        }),
    )
    
    def id_short(self, obj):
        """Display shortened ID"""
        return f"{str(obj.id)[:8]}..."
    id_short.short_description = 'ID'
    
    def user_uuid_short(self, obj):
        """Display shortened user UUID"""
        return f"{str(obj.user_uuid)[:8]}..."
    user_uuid_short.short_description = 'User UUID'
    
    def get_queryset(self, request):
        return super().get_queryset(request)


@admin.register(UserRewardsSummary)
class UserRewardsSummaryAdmin(admin.ModelAdmin):
    list_display = [
        'user_uuid_short', 'current_points_balance', 'total_points_earned',
        'total_points_spent', 'tier_level', 'tier_name', 'is_active'
    ]
    list_filter = ['tier_level', 'is_active', 'created_at']
    search_fields = ['user_uuid']
    readonly_fields = [
        'user_uuid', 'created_at', 'updated_at', 'tier_name',
        'total_referrals_made', 'successful_referrals'
    ]
    ordering = ['-current_points_balance']
    
    fieldsets = (
        ('User Information', {
            'fields': ('user_uuid', 'is_active')
        }),
        ('Points & Tier', {
            'fields': (
                'current_points_balance', 'total_points_earned', 
                'total_points_spent', 'tier_level', 'tier_name'
            )
        }),
        ('Referral Stats', {
            'fields': ('total_referrals_made', 'successful_referrals')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'last_activity_at'),
            'classes': ('collapse',)
        }),
    )
    
    def user_uuid_short(self, obj):
        """Display shortened user UUID"""
        return f"{str(obj.user_uuid)[:8]}..."
    user_uuid_short.short_description = 'User UUID'
    
    def tier_name(self, obj):
        """Display tier name"""
        from .services import RewardsService
        service = RewardsService()
        return service.get_user_tier_name(obj.tier_level)
    tier_name.short_description = 'Tier'
    
    def total_referrals_made(self, obj):
        """Display total referrals made by this user"""
        try:
            referral_code = obj.referralcode_set.first()
            return referral_code.referrals.count() if referral_code else 0
        except:
            return 0
    total_referrals_made.short_description = 'Total Referrals'
    
    def successful_referrals(self, obj):
        """Display successful referrals made by this user"""
        try:
            referral_code = obj.referralcode_set.first()
            return referral_code.referrals.filter(
                status='COMPLETED'
            ).count() if referral_code else 0
        except:
            return 0
    successful_referrals.short_description = 'Successful Referrals'
    
    actions = ['update_balances', 'recalculate_tiers']
    
    def update_balances(self, request, queryset):
        """Update balances for selected users"""
        updated = 0
        for summary in queryset:
            summary.update_balance()
            updated += 1
        
        self.message_user(
            request,
            f'Successfully updated balances for {updated} users.'
        )
    update_balances.short_description = "Update balances for selected users"
    
    def recalculate_tiers(self, request, queryset):
        """Recalculate tier levels for selected users"""
        from .services import RewardsService
        service = RewardsService()
        updated = 0
        
        for summary in queryset:
            old_tier = summary.tier_level
            summary.tier_level = service._calculate_tier_level(summary.total_points_earned)
            if old_tier != summary.tier_level:
                summary.save(update_fields=['tier_level'])
                updated += 1
        
        self.message_user(
            request,
            f'Successfully updated tiers for {updated} users.'
        )
    recalculate_tiers.short_description = "Recalculate tiers for selected users"


@admin.register(RewardsCampaign)
class RewardsCampaignAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'campaign_type', 'status', 'reward_points',
        'starts_at', 'ends_at', 'is_active_display'
    ]
    list_filter = [
        'campaign_type', 'status', 'starts_at', 'ends_at', 'created_at'
    ]
    search_fields = ['name', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at', 'is_active_display']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Campaign Information', {
            'fields': ('id', 'name', 'description', 'campaign_type', 'status')
        }),
        ('Rewards', {
            'fields': ('reward_points', 'max_participants')
        }),
        ('Schedule', {
            'fields': ('starts_at', 'ends_at', 'is_active_display')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def is_active_display(self, obj):
        """Display if campaign is currently active"""
        is_active = obj.is_active()
        color = 'green' if is_active else 'red'
        return format_html(
            '<span style="color: {};">{}</span>',
            color,
            'Active' if is_active else 'Inactive'
        )
    is_active_display.short_description = 'Currently Active'
    
    actions = ['activate_campaigns', 'deactivate_campaigns']
    
    def activate_campaigns(self, request, queryset):
        """Activate selected campaigns"""
        updated = queryset.update(status='ACTIVE')
        self.message_user(
            request,
            f'Successfully activated {updated} campaigns.'
        )
    activate_campaigns.short_description = "Activate selected campaigns"
    
    def deactivate_campaigns(self, request, queryset):
        """Deactivate selected campaigns"""
        updated = queryset.update(status='INACTIVE')
        self.message_user(
            request,
            f'Successfully deactivated {updated} campaigns.'
        )
    deactivate_campaigns.short_description = "Deactivate selected campaigns"


# Custom admin site configuration
admin.site.site_header = 'BIDR Rewards Administration'
admin.site.site_title = 'BIDR Rewards Admin'
admin.site.index_title = 'Welcome to BIDR Rewards Administration'
