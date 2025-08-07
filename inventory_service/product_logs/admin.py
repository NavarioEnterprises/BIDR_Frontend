from django.contrib import admin
from .models import ProductChangeLog, ProductAccessLog, BulkOperationLog


@admin.register(ProductChangeLog)
class ProductChangeLogAdmin(admin.ModelAdmin):
    list_display = ['content_type', 'object_id', 'change_type', 'field_name', 'changed_by', 'created_at']
    list_filter = ['change_type', 'content_type', 'created_at']
    search_fields = ['object_id', 'field_name', 'change_reason']
    ordering = ['-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser


@admin.register(ProductAccessLog)
class ProductAccessLogAdmin(admin.ModelAdmin):
    list_display = ['content_type', 'object_id', 'access_type', 'user', 'created_at']
    list_filter = ['access_type', 'content_type', 'created_at']
    search_fields = ['object_id']
    ordering = ['-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser


@admin.register(BulkOperationLog)
class BulkOperationLogAdmin(admin.ModelAdmin):
    list_display = ['operation_type', 'status', 'created_at']
    list_filter = ['operation_type', 'status', 'created_at']
    search_fields = ['operation_type']
    ordering = ['-created_at']
    readonly_fields = ['id', 'created_at', 'updated_at']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False
    
    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser
