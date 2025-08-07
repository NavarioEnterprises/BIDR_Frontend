"""
Admin interface for Categories app.
"""

from django.contrib import admin
from mptt.admin import MPTTModelAdmin
from .models import Category, CategoryAttribute


class CategoryAttributeInline(admin.TabularInline):
    model = CategoryAttribute
    extra = 0
    fields = (
        'name', 'attribute_type', 'is_required', 'is_filterable', 
        'is_searchable', 'show_in_listing', 'sort_order'
    )
    ordering = ['sort_order', 'name']


@admin.register(Category)
class CategoryAdmin(MPTTModelAdmin):
    list_display = (
        'name', 'parent', 'status', 'is_featured', 'show_in_menu', 
        'commission_rate', 'sort_order', 'created_at'
    )
    list_filter = ('status', 'is_featured', 'show_in_menu', 'parent')
    search_fields = ('name', 'description', 'slug')
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ('id', 'created_at', 'updated_at')
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'description', 'parent')
        }),
        ('Display Settings', {
            'fields': ('icon', 'image', 'color', 'sort_order')
        }),
        ('Status & Visibility', {
            'fields': ('status', 'is_featured', 'show_in_menu')
        }),
        ('SEO', {
            'fields': ('meta_title', 'meta_description')
        }),
        ('Business Settings', {
            'fields': ('commission_rate',)
        }),
        ('Metadata', {
            'fields': ('tags', 'notes', 'metadata'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    inlines = [CategoryAttributeInline]
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('parent')


@admin.register(CategoryAttribute)
class CategoryAttributeAdmin(admin.ModelAdmin):
    list_display = (
        'category', 'name', 'attribute_type', 'is_required', 
        'is_filterable', 'is_searchable', 'sort_order'
    )
    list_filter = (
        'attribute_type', 'is_required', 'is_filterable', 
        'is_searchable', 'show_in_listing', 'category__status'
    )
    search_fields = ('name', 'label', 'category__name')
    readonly_fields = ('id', 'created_at', 'updated_at')
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('category', 'name', 'attribute_type')
        }),
        ('Configuration', {
            'fields': (
                'is_required', 'is_filterable', 'is_searchable', 
                'show_in_listing'
            )
        }),
        ('Display', {
            'fields': ('label', 'help_text', 'placeholder', 'sort_order')
        }),
        ('Validation', {
            'fields': (
                'min_value', 'max_value', 'min_length', 'max_length', 
                'regex_pattern'
            ),
            'classes': ('collapse',)
        }),
        ('Choices & Defaults', {
            'fields': ('choices', 'default_value'),
            'classes': ('collapse',)
        }),
        ('System Information', {
            'fields': ('id', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('category')
