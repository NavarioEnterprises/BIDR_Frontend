from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from mptt.admin import MPTTModelAdmin
from .models import Category, CategorySpecification, CategoryAttribute
from core.admin import CoreAdminMixin


@admin.register(Category)
class CategoryAdmin(MPTTModelAdmin, CoreAdminMixin):
    list_display = [
        'name', 'parent', 'status_display', 'is_featured', 
        'show_in_menu', 'product_count', 'commission_rate', 'created_at_display'
    ]
    list_filter = ['status', 'is_featured', 'show_in_menu', 'created_at']
    search_fields = ['name', 'slug', 'description']
    prepopulated_fields = {'slug': ('name',)}
    readonly_fields = ['created_at_display', 'updated_at_display', 'product_count']
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'slug', 'parent', 'description')
        }),
        ('Display Settings', {
            'fields': ('icon', 'image', 'color', 'sort_order', 'is_featured', 'show_in_menu')
        }),
        ('Status & Settings', {
            'fields': ('status', 'commission_rate')
        }),
        ('SEO', {
            'fields': ('meta_title', 'meta_description'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def product_count(self, obj):
        return obj.products.count()
    product_count.short_description = 'Products'
    product_count.admin_order_field = 'products__count'
    
    def get_queryset(self, request):
        return super().get_queryset(request).prefetch_related('products')


@admin.register(CategorySpecification)
class CategorySpecificationAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = ['category', 'category_type', 'is_active', 'created_at_display', 'updated_at_display']
    list_filter = ['category_type', 'is_active', 'created_at']
    search_fields = ['category__name', 'category_type']
    readonly_fields = ['created_at_display', 'updated_at_display']
    fieldsets = (
        ('Basic Information', {
            'fields': ('category', 'category_type')
        }),
        ('Schema Configuration', {
            'fields': ('specification_schema', 'form_template')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )


@admin.register(CategoryAttribute)
class CategoryAttributeAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'name', 'category', 'attribute_type', 'is_required', 
        'is_filterable', 'is_searchable', 'sort_order', 'created_at_display'
    ]
    list_filter = ['attribute_type', 'is_required', 'is_filterable', 'is_searchable']
    search_fields = ['name', 'label', 'category__name']
    readonly_fields = ['created_at_display', 'updated_at_display']
    fieldsets = (
        ('Basic Information', {
            'fields': ('category', 'name', 'attribute_type', 'label')
        }),
        ('Configuration', {
            'fields': ('is_required', 'is_filterable', 'is_searchable', 'show_in_listing')
        }),
        ('Display', {
            'fields': ('help_text', 'placeholder', 'sort_order')
        }),
        ('Validation', {
            'fields': ('min_value', 'max_value', 'min_length', 'max_length', 'regex_pattern'),
            'classes': ('collapse',)
        }),
        ('Choices & Defaults', {
            'fields': ('choices', 'default_value'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
