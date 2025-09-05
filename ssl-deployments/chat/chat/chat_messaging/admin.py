from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from .models import (
    Message, MessageAttachment, MessageReaction, MessageReadReceipt,
    MessageDeletion, MessageTranslation, MessageMention, TypingIndicator
)


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = [
        'content_preview', 'sender', 'conversation_title', 'message_type',
        'delivery_status', 'is_flagged', 'reaction_count', 'created_at'
    ]
    list_filter = [
        'message_type', 'delivery_status', 'is_flagged', 'is_auto_moderated',
        'is_edited', 'created_at'
    ]
    search_fields = [
        'content', 'sender__username', 'conversation__title', 'client_message_id'
    ]
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'message_hash', 'reaction_count'
    ]
    
    fieldsets = [
        ('Message Information', {
            'fields': ('conversation', 'sender', 'message_type', 'content')
        }),
        ('Threading', {
            'fields': ('reply_to', 'thread_id'),
            'classes': ('collapse',)
        }),
        ('Status', {
            'fields': ('delivery_status', 'is_edited', 'edited_at')
        }),
        ('Moderation', {
            'fields': ('is_flagged', 'flagged_reason', 'is_auto_moderated', 'moderation_action', 'original_content'),
            'classes': ('collapse',)
        }),
        ('Security', {
            'fields': ('is_encrypted', 'encryption_key_id'),
            'classes': ('collapse',)
        }),
        ('Technical', {
            'fields': ('client_message_id', 'message_hash', 'external_reference', 'metadata'),
            'classes': ('collapse',)
        }),
        ('Statistics', {
            'fields': ('reaction_count',),
            'classes': ('collapse',)
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    ]
    
    def content_preview(self, obj):
        preview = obj.content[:100] + '...' if len(obj.content) > 100 else obj.content
        if obj.is_flagged:
            return format_html('<span style="color: red; font-weight: bold;">🚩 {}</span>', preview)
        return preview
    content_preview.short_description = 'Content'
    
    def conversation_title(self, obj):
        return obj.conversation.title
    conversation_title.short_description = 'Conversation'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('sender', 'conversation')


@admin.register(MessageAttachment)
class MessageAttachmentAdmin(admin.ModelAdmin):
    list_display = [
        'filename', 'file_type', 'file_size_display', 'message_sender',
        'is_scanned', 'scan_result', 'download_count', 'created_at'
    ]
    list_filter = [
        'file_type', 'is_scanned', 'scan_result', 'is_public', 'created_at'
    ]
    search_fields = [
        'filename', 'message__sender__username', 'message__conversation__title'
    ]
    readonly_fields = [
        'id', 'created_at', 'updated_at', 'file_size', 'file_hash', 'download_count'
    ]
    
    fieldsets = [
        ('File Information', {
            'fields': ('message', 'file', 'filename', 'file_type', 'mime_type')
        }),
        ('File Properties', {
            'fields': ('file_size', 'width', 'height', 'duration', 'thumbnail')
        }),
        ('Security', {
            'fields': ('is_scanned', 'scan_result', 'file_hash')
        }),
        ('Access', {
            'fields': ('is_public', 'download_count')
        }),
        ('Metadata', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    ]
    
    def message_sender(self, obj):
        return obj.message.sender.username
    message_sender.short_description = 'Sender'
    
    def file_size_display(self, obj):
        return obj.get_file_size_display()
    file_size_display.short_description = 'File Size'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('message__sender')


@admin.register(MessageReaction)
class MessageReactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'reaction_display', 'message_preview', 'created_at']
    list_filter = ['reaction_type', 'created_at']
    search_fields = ['user__username', 'message__content', 'message__sender__username']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def reaction_display(self, obj):
        return f"{obj.get_reaction_type_display()} {dict(obj.REACTION_TYPES)[obj.reaction_type]}"
    reaction_display.short_description = 'Reaction'
    
    def message_preview(self, obj):
        preview = obj.message.content[:50] + '...' if len(obj.message.content) > 50 else obj.message.content
        return preview
    message_preview.short_description = 'Message'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'message')


@admin.register(MessageReadReceipt)
class MessageReadReceiptAdmin(admin.ModelAdmin):
    list_display = ['user', 'message_preview', 'read_at']
    list_filter = ['read_at']
    search_fields = ['user__username', 'message__content', 'message__sender__username']
    readonly_fields = ['id', 'created_at', 'updated_at', 'read_at']
    
    def message_preview(self, obj):
        preview = obj.message.content[:50] + '...' if len(obj.message.content) > 50 else obj.message.content
        return preview
    message_preview.short_description = 'Message'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'message')


@admin.register(MessageDeletion)
class MessageDeletionAdmin(admin.ModelAdmin):
    list_display = [
        'message_id', 'deleted_by', 'deletion_reason', 'content_preview', 'created_at'
    ]
    list_filter = ['deletion_reason', 'created_at']
    search_fields = [
        'deleted_by__username', 'content_snapshot', 'deletion_details'
    ]
    readonly_fields = ['id', 'created_at', 'updated_at', 'content_snapshot', 'metadata_snapshot']
    
    def message_id(self, obj):
        return str(obj.message.id)[:8] + '...'
    message_id.short_description = 'Message ID'
    
    def content_preview(self, obj):
        preview = obj.content_snapshot[:50] + '...' if len(obj.content_snapshot) > 50 else obj.content_snapshot
        return preview
    content_preview.short_description = 'Deleted Content'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('message', 'deleted_by')


@admin.register(MessageTranslation)
class MessageTranslationAdmin(admin.ModelAdmin):
    list_display = [
        'message_preview', 'source_language', 'target_language',
        'translation_service', 'confidence_score', 'human_reviewed', 'created_at'
    ]
    list_filter = [
        'source_language', 'target_language', 'translation_service',
        'is_auto_translation', 'human_reviewed', 'created_at'
    ]
    search_fields = [
        'message__content', 'translated_content', 'message__sender__username'
    ]
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def message_preview(self, obj):
        preview = obj.message.content[:50] + '...' if len(obj.message.content) > 50 else obj.message.content
        return preview
    message_preview.short_description = 'Original Message'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('message')


@admin.register(MessageMention)
class MessageMentionAdmin(admin.ModelAdmin):
    list_display = [
        'mentioned_user', 'mention_text', 'message_preview',
        'notification_sent', 'notification_read', 'created_at'
    ]
    list_filter = ['notification_sent', 'notification_read', 'created_at']
    search_fields = [
        'mentioned_user__username', 'mention_text', 'message__content'
    ]
    readonly_fields = ['id', 'created_at', 'updated_at', 'position_start', 'position_end']
    
    def message_preview(self, obj):
        preview = obj.message.content[:50] + '...' if len(obj.message.content) > 50 else obj.message.content
        return preview
    message_preview.short_description = 'Message'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('mentioned_user', 'message')


@admin.register(TypingIndicator)
class TypingIndicatorAdmin(admin.ModelAdmin):
    list_display = ['user', 'conversation_title', 'is_typing', 'last_typing_at', 'is_stale_indicator']
    list_filter = ['is_typing', 'last_typing_at']
    search_fields = ['user__username', 'conversation__title']
    readonly_fields = ['id', 'created_at', 'updated_at', 'last_typing_at']
    
    def conversation_title(self, obj):
        return obj.conversation.title
    conversation_title.short_description = 'Conversation'
    
    def is_stale_indicator(self, obj):
        is_stale = obj.is_stale()
        if is_stale:
            return format_html('<span style="color: red;">Yes</span>')
        return format_html('<span style="color: green;">No</span>')
    is_stale_indicator.short_description = 'Stale'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'conversation')
