from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from .models import (
    Conversation, ConversationParticipant, ConversationInvite,
    ConversationTag, ConversationTagAssignment, ConversationBookmark
)


@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = [
        'title', 'conversation_type', 'status', 'buyer', 'total_messages',
        'get_participant_count', 'last_message_at', 'created_at'
    ]
    list_filter = [
        'conversation_type', 'status', 'is_bidding_enabled', 'is_moderated',
        'created_at', 'last_message_at'
    ]
    search_fields = [
        'title', 'buyer__username', 'buyer__email', 'product_request_id', 'quote_id'
    ]
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'last_message_at', 'total_messages'
    ]
    
    fieldsets = [
        ('Basic Information', {
            'fields': ('title', 'conversation_type', 'status', 'buyer')
        }),
        ('External References', {
            'fields': ('product_request_id', 'quote_id'),
            'classes': ('collapse',)
        }),
        ('Settings', {
            'fields': ('allow_new_participants', 'is_bidding_enabled', 'auto_archive_after_hours')
        }),
        ('Moderation', {
            'fields': ('is_moderated', 'requires_approval')
        }),
        ('Security', {
            'fields': ('is_encrypted', 'access_code'),
            'classes': ('collapse',)
        }),
        ('Statistics', {
            'fields': ('total_messages', 'last_message_at'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    ]
    
    def get_participant_count(self, obj):
        return obj.get_active_participants().count()
    get_participant_count.short_description = 'Active Participants'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('buyer').prefetch_related('participants')


@admin.register(ConversationParticipant)
class ConversationParticipantAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'conversation_title', 'role', 'status', 'message_count',
        'last_active_at', 'get_unread_count'
    ]
    list_filter = [
        'role', 'status', 'can_send_messages', 'can_share_files',
        'notifications_enabled', 'joined_at'
    ]
    search_fields = [
        'user__username', 'user__email', 'conversation__title'
    ]
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'joined_at', 'last_read_at',
        'last_active_at', 'message_count'
    ]
    
    fieldsets = [
        ('Participant Information', {
            'fields': ('conversation', 'user', 'role', 'status')
        }),
        ('Permissions', {
            'fields': ('can_send_messages', 'can_share_files', 'can_invite_others', 'can_moderate_content')
        }),
        ('Notifications', {
            'fields': ('notifications_enabled', 'email_notifications')
        }),
        ('Activity', {
            'fields': ('joined_at', 'last_read_at', 'last_active_at', 'message_count'),
            'classes': ('collapse',)
        }),
        ('Moderation', {
            'fields': ('warning_count', 'banned_until', 'ban_reason'),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    ]
    
    def conversation_title(self, obj):
        return obj.conversation.title
    conversation_title.short_description = 'Conversation'
    
    def get_unread_count(self, obj):
        return obj.get_unread_count()
    get_unread_count.short_description = 'Unread Messages'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'conversation')


@admin.register(ConversationInvite)
class ConversationInviteAdmin(admin.ModelAdmin):
    list_display = [
        'invited_user', 'conversation_title', 'invited_by', 'status',
        'role', 'expires_at', 'responded_at'
    ]
    list_filter = [
        'status', 'role', 'expires_at', 'created_at', 'responded_at'
    ]
    search_fields = [
        'invited_user__username', 'invited_by__username', 'conversation__title'
    ]
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'responded_at'
    ]
    
    fieldsets = [
        ('Invitation Details', {
            'fields': ('conversation', 'invited_by', 'invited_user', 'role')
        }),
        ('Status', {
            'fields': ('status', 'expires_at', 'responded_at')
        }),
        ('Messages', {
            'fields': ('message', 'response_message')
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    ]
    
    def conversation_title(self, obj):
        return obj.conversation.title
    conversation_title.short_description = 'Conversation'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('invited_user', 'invited_by', 'conversation')


@admin.register(ConversationTag)
class ConversationTagAdmin(admin.ModelAdmin):
    list_display = ['name', 'color_display', 'is_system_tag', 'usage_count', 'created_at']
    list_filter = ['is_system_tag', 'created_at']
    search_fields = ['name', 'description']
    readonly_fields = ['id', 'created_at', 'updated_at', 'usage_count']
    
    def color_display(self, obj):
        return format_html(
            '<div style="width: 20px; height: 20px; background-color: {}; border: 1px solid #ddd; display: inline-block;"></div> {}',
            obj.color, obj.color
        )
    color_display.short_description = 'Color'


class ConversationTagAssignmentInline(admin.TabularInline):
    model = ConversationTagAssignment
    extra = 0
    readonly_fields = ['created_at', 'assigned_by']


@admin.register(ConversationTagAssignment)
class ConversationTagAssignmentAdmin(admin.ModelAdmin):
    list_display = ['conversation', 'tag', 'assigned_by', 'created_at']
    list_filter = ['tag', 'created_at']
    search_fields = ['conversation__title', 'tag__name', 'assigned_by__username']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('conversation', 'tag', 'assigned_by')


@admin.register(ConversationBookmark)
class ConversationBookmarkAdmin(admin.ModelAdmin):
    list_display = ['user', 'conversation', 'created_at']
    list_filter = ['created_at']
    search_fields = ['user__username', 'conversation__title', 'note']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'conversation')
