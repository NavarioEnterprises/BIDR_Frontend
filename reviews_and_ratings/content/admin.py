from django.contrib import admin
from .models import FAQ, Blog, BlogComment, Policy, ContactSubmission, NewsletterSubscription


@admin.register(FAQ)
class FAQAdmin(admin.ModelAdmin):
    list_display = ['question', 'category', 'order', 'is_active', 'created_at']
    list_filter = ['category', 'is_active', 'created_at']
    search_fields = ['question', 'answer']
    list_editable = ['category', 'order', 'is_active']
    ordering = ['category', 'order']
    
    fieldsets = (
        ('FAQ Content', {
            'fields': ('question', 'answer')
        }),
        ('Organization', {
            'fields': ('category', 'order', 'is_active')
        }),
    )


class BlogCommentInline(admin.TabularInline):
    model = BlogComment
    extra = 0
    readonly_fields = ['created_at']
    fields = ['user', 'content', 'is_approved', 'created_at']


@admin.register(Blog)
class BlogAdmin(admin.ModelAdmin):
    list_display = ['title', 'author', 'section', 'is_published', 'is_featured', 'likes', 'views', 'created_at']
    list_filter = ['section', 'is_published', 'is_featured', 'created_at', 'author']
    search_fields = ['title', 'description', 'content', 'tags']
    readonly_fields = ['created_at', 'updated_at', 'views']
    list_editable = ['is_published', 'is_featured']
    ordering = ['-created_at']
    inlines = [BlogCommentInline]
    
    fieldsets = (
        ('Blog Content', {
            'fields': ('title', 'description', 'content')
        }),
        ('Media', {
            'fields': ('image_url', 'image_file')
        }),
        ('Metadata', {
            'fields': ('section', 'author', 'tags')
        }),
        ('Status & Engagement', {
            'fields': ('is_published', 'is_featured', 'likes', 'views')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'published_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_form(self, request, obj=None, **kwargs):
        form = super().get_form(request, obj, **kwargs)
        if not obj:  # Creating new blog
            form.base_fields['author'].initial = request.user
        return form


@admin.register(BlogComment)
class BlogCommentAdmin(admin.ModelAdmin):
    list_display = ['blog', 'user', 'is_approved', 'created_at']
    list_filter = ['is_approved', 'created_at']
    search_fields = ['blog__title', 'user__username', 'content']
    list_editable = ['is_approved']
    ordering = ['-created_at']


@admin.register(Policy)
class PolicyAdmin(admin.ModelAdmin):
    list_display = ['title', 'policy_type', 'version', 'is_active', 'effective_date', 'updated_at']
    list_filter = ['policy_type', 'is_active', 'effective_date', 'created_at']
    search_fields = ['title', 'content']
    list_editable = ['is_active']
    ordering = ['policy_type']
    
    fieldsets = (
        ('Policy Information', {
            'fields': ('title', 'policy_type', 'version', 'effective_date')
        }),
        ('Content', {
            'fields': ('content',)
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
    )


@admin.register(ContactSubmission)
class ContactSubmissionAdmin(admin.ModelAdmin):
    list_display = ['name', 'email', 'subject', 'status', 'assigned_to', 'created_at']
    list_filter = ['subject', 'status', 'created_at', 'assigned_to']
    search_fields = ['name', 'email', 'company', 'message']
    list_editable = ['status', 'assigned_to']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Contact Information', {
            'fields': ('name', 'email', 'phone', 'company')
        }),
        ('Message', {
            'fields': ('subject', 'message')
        }),
        ('Status & Assignment', {
            'fields': ('status', 'assigned_to')
        }),
        ('Response', {
            'fields': ('response', 'responded_by', 'responded_at'),
            'classes': ('collapse',)
        }),
    )
    
    readonly_fields = ['created_at', 'updated_at']


@admin.register(NewsletterSubscription)
class NewsletterSubscriptionAdmin(admin.ModelAdmin):
    list_display = ['email', 'name', 'is_active', 'marketing_emails', 'product_updates', 'subscribed_at']
    list_filter = ['is_active', 'marketing_emails', 'product_updates', 'weekly_digest', 'subscribed_at']
    search_fields = ['email', 'name']
    list_editable = ['is_active']
    ordering = ['-subscribed_at']
    
    fieldsets = (
        ('Subscriber Information', {
            'fields': ('email', 'name', 'is_active')
        }),
        ('Email Preferences', {
            'fields': ('marketing_emails', 'product_updates', 'weekly_digest')
        }),
        ('Timestamps', {
            'fields': ('subscribed_at', 'unsubscribed_at'),
            'classes': ('collapse',)
        }),
    )
