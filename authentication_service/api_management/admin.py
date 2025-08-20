from django.contrib import admin

from .models import APIScope, APIKey, APIRequest, RateLimitBucket, APIKeyUsageQuota


@admin.register(APIScope)
class APIScopeAdmin(admin.ModelAdmin):
    list_display = ('name', 'description', 'is_default')
    search_fields = ('name', 'description')
    list_filter = ('is_default',)


@admin.register(APIKey)
class APIKeyAdmin(admin.ModelAdmin):
    list_display = ('name', 'user', 'key_id', 'status', 'created_at', 'expires_at')
    list_filter = ('status', 'created_at', 'expires_at')
    search_fields = ('name', 'key_id', 'user__email')
    readonly_fields = ('key_id', 'key_hash', 'created_at', 'last_used_at')
    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'description', 'user', 'status')
        }),
        ('Key Details', {
            'fields': ('key_id', 'key_hash', 'created_at', 'expires_at')
        }),
        ('Usage Information', {
            'fields': ('last_used_at', 'last_used_ip', 'total_requests')
        }),
        ('Restrictions', {
            'fields': ('allowed_ips', 'allowed_origins')
        }),
    )


@admin.register(APIRequest)
class APIRequestAdmin(admin.ModelAdmin):
    list_display = ('uuid', 'api_key', 'endpoint', 'method', 'status_code', 'timestamp')
    list_filter = ('method', 'status_code', 'timestamp')
    search_fields = ('uuid', 'endpoint', 'api_key__key_id')
    readonly_fields = ('uuid', 'timestamp')


@admin.register(RateLimitBucket)
class RateLimitBucketAdmin(admin.ModelAdmin):
    list_display = ('api_key', 'period', 'request_count', 'last_request_at', 'first_request_at')
    list_filter = ('period', 'first_request_at')
    search_fields = ('api_key__key_id',)


@admin.register(APIKeyUsageQuota)
class APIKeyUsageQuotaAdmin(admin.ModelAdmin):
    list_display = ('api_key', 'quota_type', 'quota_limit', 'request_count', 'period_end')
    list_filter = ('quota_type', 'period_end')
    search_fields = ('api_key__key_id',)
    readonly_fields = ('request_count',)
