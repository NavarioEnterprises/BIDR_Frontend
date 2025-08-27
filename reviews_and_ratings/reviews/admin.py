from django.contrib import admin
from .models import Review, ReviewHelpful, Ticket, TicketMessage


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'product_id', 'rating', 'is_approved', 'is_featured', 'created_at']
    list_filter = ['rating', 'is_approved', 'is_featured', 'created_at', 'seller_id']
    search_fields = ['title', 'content', 'user__username', 'product_id', 'seller_id']
    readonly_fields = ['created_at', 'updated_at']
    list_editable = ['is_approved', 'is_featured']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Review Information', {
            'fields': ('user', 'product_id', 'seller_id', 'title', 'content', 'rating')
        }),
        ('Status', {
            'fields': ('is_approved', 'is_featured')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(ReviewHelpful)
class ReviewHelpfulAdmin(admin.ModelAdmin):
    list_display = ['review', 'user', 'is_helpful', 'created_at']
    list_filter = ['is_helpful', 'created_at']
    search_fields = ['review__title', 'user__username']
    readonly_fields = ['created_at']
    ordering = ['-created_at']


class TicketMessageInline(admin.TabularInline):
    model = TicketMessage
    extra = 0
    readonly_fields = ['created_at']
    fields = ['sender', 'message', 'is_from_staff', 'created_at']


@admin.register(Ticket)
class TicketAdmin(admin.ModelAdmin):
    list_display = ['ticket_id', 'subject', 'user', 'auth_user_uid', 'status', 'priority', 'assignee', 'created_at']
    list_filter = ['status', 'priority', 'created_at', 'assignee']
    search_fields = ['ticket_id', 'subject', 'description', 'user__username', 'auth_user_uid']
    readonly_fields = ['ticket_id', 'created_at', 'updated_at']
    list_editable = ['status', 'priority', 'assignee']
    ordering = ['-created_at']
    inlines = [TicketMessageInline]
    
    fieldsets = (
        ('Ticket Information', {
            'fields': ('ticket_id', 'user', 'auth_user_uid', 'subject', 'description')
        }),
        ('Status & Assignment', {
            'fields': ('status', 'priority', 'assignee')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'resolved_at'),
            'classes': ('collapse',)
        }),
    )


@admin.register(TicketMessage)
class TicketMessageAdmin(admin.ModelAdmin):
    list_display = ['ticket', 'sender', 'is_from_staff', 'created_at']
    list_filter = ['is_from_staff', 'created_at']
    search_fields = ['ticket__ticket_id', 'sender__username', 'message']
    readonly_fields = ['created_at']
    ordering = ['-created_at']
