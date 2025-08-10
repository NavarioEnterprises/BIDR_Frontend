from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from django.urls import reverse
from .models import (
    ConsumerElectronics, VehicleSpares, VehicleTyresRims, ProductRequest, RequestImage, RequestSpecification, 
    RequestMessage, RequestWatchlist, RequestTemplate
)
from core.admin import CoreAdminMixin


class RequestImageInline(admin.TabularInline):
    model = RequestImage
    extra = 1
    fields = ['image', 'caption', 'sort_order']
    readonly_fields = []


class RequestSpecificationInline(admin.TabularInline):
    model = RequestSpecification
    extra = 0
    fields = ['name', 'value', 'is_required', 'sort_order']
    readonly_fields = []


class RequestMessageInline(admin.TabularInline):
    model = RequestMessage
    extra = 0
    fields = ['sender', 'message_type', 'subject', 'message', 'is_internal']
    readonly_fields = ['created_at']
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('sender')


@admin.register(ConsumerElectronics)
class ConsumerElectronicsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'full_product_description', 'electronics_type', 'brand_preference', 'quantity_needed',
        'condition_preference', 'urgency', 'is_urgent', 'budget_range_display',
        'requires_professional_service', 'created_at_display'
    ]
    list_filter = [
        'electronics_type', 'condition_preference', 'urgency', 'purpose_of_purchase',
        'installation_required', 'warranty_required', 'energy_efficiency_required', 'created_at'
    ]
    search_fields = [
        'electronics_type', 'brand_preference', 'model_series', 'required_features',
        'additional_comments'
    ]
    readonly_fields = [
        'id', 'created_at_display', 'updated_at_display', 
        'full_product_description', 'is_urgent', 'budget_range_display', 'is_energy_conscious'
    ]
    
    fieldsets = (
        ('Product Information', {
            'fields': ('electronics_type', 'brand_preference', 'model_series', 'full_product_description')
        }),
        ('Quantity & Timeline', {
            'fields': ('quantity_needed', 'urgency', 'is_urgent')
        }),
        ('Budget Information', {
            'fields': ('min_price', 'max_price', 'currency', 'budget_range_display')
        }),
        ('Product Requirements', {
            'fields': ('condition_preference', 'required_features', 'purpose_of_purchase')
        }),
        ('Services & Support', {
            'fields': ('installation_required', 'warranty_required', 'warranty_duration'),
            'classes': ('collapse',)
        }),
        ('Energy Efficiency', {
            'fields': ('energy_efficiency_required', 'is_energy_conscious'),
            'classes': ('collapse',)
        }),
        ('Additional Information', {
            'fields': ('additional_comments', 'delivery_location'),
            'classes': ('collapse',)
        }),
        ('Images', {
            'fields': ('product_images',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def full_product_description(self, obj):
        return obj.full_product_description
    full_product_description.short_description = 'Product Description'
    full_product_description.admin_order_field = 'electronics_type'
    
    def is_urgent(self, obj):
        if obj.is_urgent:
            return format_html('<span style="color: red; font-weight: bold;">🔥 URGENT</span>')
        return '⏰ Normal'
    is_urgent.short_description = 'Priority'
    is_urgent.admin_order_field = 'urgency'
    
    def budget_range_display(self, obj):
        return obj.budget_range_display
    budget_range_display.short_description = 'Budget Range'
    
    def requires_professional_service(self, obj):
        if obj.requires_professional_service():
            services = []
            if obj.installation_required == 'YES':
                services.append('Installation')
            if obj.warranty_required == 'YES':
                services.append('Warranty')
            return format_html('<span style="color: blue;">✅ {}</span>', ', '.join(services))
        return '❌ No Services'
    requires_professional_service.short_description = 'Services'
    
    def is_energy_conscious(self, obj):
        if obj.is_energy_conscious:
            return format_html('<span style="color: green;">🌱 Energy Efficient</span>')
        return '⚡ Standard'
    is_energy_conscious.short_description = 'Energy Priority'


@admin.register(VehicleSpares)
class VehicleSparesAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'vehicle_display', 'part_name', 'part_category', 'quantity', 
        'condition_preference', 'urgency', 'is_urgent', 'requires_professional_service', 
        'created_at_display'
    ]
    list_filter = [
        'vehicle_type', 'part_category', 'condition_preference', 'urgency',
        'installation_required', 'warranty_required', 'created_at'
    ]
    search_fields = [
        'vehicle_make', 'vehicle_model', 'part_name', 'part_number', 
        'preferred_brand', 'vin_number'
    ]
    readonly_fields = [
        'id', 'created_at_display', 'updated_at_display', 
        'vehicle_display', 'is_urgent', 'full_part_description'
    ]
    
    fieldsets = (
        ('Vehicle Information', {
            'fields': ('vehicle_make', 'vehicle_model', 'vehicle_year', 'vehicle_type', 
                      'vehicle_display', 'engine_size', 'vin_number')
        }),
        ('Part Specifications', {
            'fields': ('part_name', 'part_category', 'part_number', 'full_part_description')
        }),
        ('Request Details', {
            'fields': ('quantity', 'condition_preference', 'urgency', 'description')
        }),
        ('Compatibility & Brands', {
            'fields': ('compatible_models', 'preferred_brand', 'avoid_brands'),
            'classes': ('collapse',)
        }),
        ('Services Required', {
            'fields': ('installation_required', 'warranty_required'),
            'classes': ('collapse',)
        }),
        ('Budget & Location', {
            'fields': ('max_budget', 'currency', 'location_info'),
            'classes': ('collapse',)
        }),
        ('Media', {
            'fields': ('product_images', 'vin_photo'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def vehicle_display(self, obj):
        return obj.vehicle_display
    vehicle_display.short_description = 'Vehicle'
    vehicle_display.admin_order_field = 'vehicle_make'
    
    def is_urgent(self, obj):
        if obj.is_urgent:
            return format_html('<span style="color: red; font-weight: bold;">🔥 URGENT</span>')
        return '⏰ Normal'
    is_urgent.short_description = 'Priority'
    is_urgent.admin_order_field = 'urgency'
    
    def requires_professional_service(self, obj):
        if obj.requires_professional_service():
            services = []
            if obj.installation_required == 'YES':
                services.append('Installation')
            if obj.warranty_required == 'YES':
                services.append('Warranty')
            return format_html('<span style="color: blue;">✅ {}</span>', ', '.join(services))
        return '❌ No Services'
    requires_professional_service.short_description = 'Services'
    
    def full_part_description(self, obj):
        return obj.full_part_description
    full_part_description.short_description = 'Part Description'


@admin.register(VehicleTyresRims)
class VehicleTyresRimsAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'tyre_size_display', 'select_tyres_rims', 'vehicle_type', 
        'quantity', 'urgency', 'is_urgent', 'requires_professional_service', 
        'created_at_display'
    ]
    list_filter = [
        'select_tyres_rims', 'vehicle_type', 'urgency', 'tyre_construction_type',
        'balancing_required', 'fitment_required', 'created_at'
    ]
    search_fields = [
        'preferred_brand', 'description', 'pitch_circle_diameter'
    ]
    readonly_fields = [
        'id', 'created_at_display', 'updated_at_display', 
        'tyre_size_display', 'is_urgent'
    ]
    
    fieldsets = (
        ('Tyre/Rim Specifications', {
            'fields': ('tyre_width', 'sidewall_profile', 'wheel_rim_diameter', 
                      'tyre_size_display', 'select_tyres_rims')
        }),
        ('Request Details', {
            'fields': ('quantity', 'urgency', 'description')
        }),
        ('Vehicle Information', {
            'fields': ('vehicle_type', 'pitch_circle_diameter')
        }),
        ('Preferences', {
            'fields': ('preferred_brand', 'tyre_construction_type'),
            'classes': ('collapse',)
        }),
        ('Services Required', {
            'fields': ('balancing_required', 'tyre_rotation_required', 'fitment_required'),
            'classes': ('collapse',)
        }),
        ('Images', {
            'fields': ('product_images',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def tyre_size_display(self, obj):
        return obj.tyre_size_display
    tyre_size_display.short_description = 'Tyre Size'
    
    def is_urgent(self, obj):
        if obj.is_urgent:
            return format_html('<span style="color: red; font-weight: bold;">🔥 URGENT</span>')
        return '⏰ Normal'
    is_urgent.short_description = 'Priority'
    is_urgent.admin_order_field = 'urgency'
    
    def requires_professional_service(self, obj):
        if obj.requires_professional_service():
            services = []
            if obj.balancing_required == 'YES':
                services.append('Balancing')
            if obj.tyre_rotation_required == 'YES':
                services.append('Rotation')
            if obj.fitment_required == 'YES':
                services.append('Fitment')
            return format_html('<span style="color: blue;">✅ {}</span>', ', '.join(services))
        return '❌ No Services'
    requires_professional_service.short_description = 'Services'


@admin.register(ProductRequest)
class ProductRequestAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'request_id_short', 'title', 'category', 'buyer_id', 'quantity', 
        'tyres_rims_summary', 'vehicle_spares_summary', 'consumer_electronics_summary', 'urgency_timeline', 'status_display', 'view_count', 'created_at_display'
    ]
    list_filter = [
        'status', 'category', 'urgency_timeline', 'condition_preference',
        'terms_accepted', 'contact_consent', 'created_at'
    ]
    search_fields = [
        'request_id', 'title', 'description', 'buyer_id__username', 
        'buyer_id__email'
    ]
    readonly_fields = [
        'request_id', 'created_at_display', 'updated_at_display', 
        'expiry_date', 'view_count', 'is_expired_display', 'is_urgent_display',
        'tyres_rims_summary', 'vehicle_spares_summary', 'consumer_electronics_summary'
    ]
    inlines = [RequestImageInline, RequestSpecificationInline, RequestMessageInline]
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('request_id', 'buyer_id', 'category', 'title', 'description')
        }),
        ('Product Specifications', {
            'fields': ('product_specifications', 'vehicle_tyres_rims', 'vehicle_spares', 'consumer_electronics',
                      'tyres_rims_summary', 'vehicle_spares_summary', 'consumer_electronics_summary')
        }),
        ('Requirements', {
            'fields': ('quantity', 'condition_preference', 'max_budget', 'currency')
        }),
        ('Location & Travel', {
            'fields': ('buyer_location', 'max_travel_distance'),
            'classes': ('collapse',)
        }),
        ('Timeline & Urgency', {
            'fields': ('urgency_timeline', 'expiry_date', 'is_expired_display', 'is_urgent_display')
        }),
        ('Media', {
            'fields': ('product_images', 'vin_photo_url'),
            'classes': ('collapse',)
        }),
        ('Terms & Consent', {
            'fields': ('terms_accepted', 'contact_consent')
        }),
        ('Status & Analytics', {
            'fields': ('status', 'view_count')
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def request_id_short(self, obj):
        return str(obj.request_id)[:8]
    request_id_short.short_description = 'Request ID'
    request_id_short.admin_order_field = 'request_id'
    
    def is_expired_display(self, obj):
        if obj.is_expired:
            return format_html('<span style="color: red; font-weight: bold;">Yes</span>')
        return format_html('<span style="color: green;">No</span>')
    is_expired_display.short_description = 'Expired'
    
    def is_urgent_display(self, obj):
        if obj.is_urgent:
            return format_html('<span style="color: red; font-weight: bold;">Yes</span>')
        return format_html('<span style="color: green;">No</span>')
    is_urgent_display.short_description = 'Urgent'
    
    def tyres_rims_summary(self, obj):
        summary = obj.tyres_rims_summary
        if summary:
            return format_html('<span style="color: blue; font-weight: bold;">{}</span>', summary)
        return '-'
    tyres_rims_summary.short_description = 'Tyre Size'
    
    def vehicle_spares_summary(self, obj):
        summary = obj.vehicle_spares_summary
        if summary:
            return format_html('<span style="color: green; font-weight: bold;">{}</span>', summary)
        return '-'
    vehicle_spares_summary.short_description = 'Vehicle Spare'
    
    def consumer_electronics_summary(self, obj):
        summary = obj.consumer_electronics_summary
        if summary:
            return format_html('<span style="color: purple; font-weight: bold;">{}</span>', summary)
        return '-'
    consumer_electronics_summary.short_description = 'Electronics'
    
    def status_display(self, obj):
        """Display status with color coding."""
        status_colors = {
            'ACTIVE': 'green',
            'CLOSED': 'orange', 
            'EXPIRED': 'red'
        }
        color = status_colors.get(obj.status, 'black')
        return format_html(
            '<span style="color: {}; font-weight: bold;">{}</span>',
            color, obj.get_status_display()
        )
    status_display.short_description = 'Status'
    status_display.admin_order_field = 'status'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('buyer_id', 'vehicle_tyres_rims', 'vehicle_spares', 'consumer_electronics')


@admin.register(RequestImage)
class RequestImageAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = ['request_short', 'image_thumbnail', 'caption', 'sort_order']
    list_filter = ['request__category', 'request__status']
    search_fields = ['request__title', 'caption']
    readonly_fields = ['image_thumbnail']
    
    def request_short(self, obj):
        return f"{str(obj.request.request_id)[:8]} - {obj.request.title[:30]}"
    request_short.short_description = 'Request'
    
    def image_thumbnail(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" width="50" height="50" style="object-fit: cover;" />',
                obj.image.url
            )
        return "No Image"
    image_thumbnail.short_description = 'Thumbnail'


@admin.register(RequestSpecification)
class RequestSpecificationAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = ['request_short', 'name', 'value_truncated', 'is_required', 'sort_order']
    list_filter = ['is_required', 'request__category']
    search_fields = ['request__title', 'name', 'value']
    
    def request_short(self, obj):
        return f"{str(obj.request.request_id)[:8]} - {obj.request.title[:30]}"
    request_short.short_description = 'Request'
    
    def value_truncated(self, obj):
        return obj.value[:50] + '...' if len(obj.value) > 50 else obj.value
    value_truncated.short_description = 'Value'


@admin.register(RequestMessage)
class RequestMessageAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'request_short', 'sender', 'message_type', 'subject', 
        'is_internal', 'is_read_display', 'created_at_display'
    ]
    list_filter = [
        'message_type', 'is_internal', 'read_at', 'created_at', 'request__category'
    ]
    search_fields = [
        'request__title', 'sender__username', 'subject', 'message'
    ]
    readonly_fields = ['created_at_display', 'read_at', 'is_read_display']
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Message Information', {
            'fields': ('request', 'sender', 'message_type', 'subject', 'message')
        }),
        ('Settings', {
            'fields': ('is_internal',)
        }),
        ('Read Status', {
            'fields': ('read_at', 'is_read_display'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at_display',),
            'classes': ('collapse',)
        })
    )
    
    def request_short(self, obj):
        return f"{str(obj.request.request_id)[:8]} - {obj.request.title[:30]}"
    request_short.short_description = 'Request'
    
    def is_read_display(self, obj):
        if obj.is_read:
            return format_html('<span style="color: green;">✓ Read</span>')
        return format_html('<span style="color: orange;">✗ Unread</span>')
    is_read_display.short_description = 'Read Status'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('request', 'sender')


@admin.register(RequestWatchlist)
class RequestWatchlistAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'user', 'request_short', 'notify_on_quotes', 
        'notify_on_updates', 'notify_on_messages', 'created_at_display'
    ]
    list_filter = [
        'notify_on_quotes', 'notify_on_updates', 'notify_on_messages',
        'created_at', 'request__category'
    ]
    search_fields = ['user__username', 'request__title']
    readonly_fields = ['created_at_display']
    
    fieldsets = (
        ('Watchlist Information', {
            'fields': ('request', 'user')
        }),
        ('Notification Preferences', {
            'fields': ('notify_on_quotes', 'notify_on_updates', 'notify_on_messages')
        }),
        ('Timestamps', {
            'fields': ('created_at_display',),
            'classes': ('collapse',)
        })
    )
    
    def request_short(self, obj):
        return f"{str(obj.request.request_id)[:8]} - {obj.request.title[:30]}"
    request_short.short_description = 'Request'
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'request')


@admin.register(RequestTemplate)
class RequestTemplateAdmin(admin.ModelAdmin, CoreAdminMixin):
    list_display = [
        'name', 'category', 'request_type', 'usage_count', 
        'is_active', 'created_at_display', 'updated_at_display'
    ]
    list_filter = ['request_type', 'is_active', 'category', 'created_at']
    search_fields = ['name', 'description', 'category__name']
    readonly_fields = ['created_at_display', 'updated_at_display', 'usage_count']
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'category', 'request_type')
        }),
        ('Template Data', {
            'fields': ('template_data',)
        }),
        ('Status & Usage', {
            'fields': ('is_active', 'usage_count')
        }),
        ('Timestamps', {
            'fields': ('created_at_display', 'updated_at_display'),
            'classes': ('collapse',)
        })
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('category')
