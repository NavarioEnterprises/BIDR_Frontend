from django.contrib import admin
from .models import AppLog, SuspiciousActivity

class AppLogAdmin(admin.ModelAdmin):
    list_display = ('employee_name', 'action', 'timestamp', 'latitude', 'longitude')
    search_fields = ('employee_name', 'action', 'app_name', 'app_version')
    list_filter = ('timestamp', 'action', 'app_name', 'app_version')
    readonly_fields = ('timestamp',)

admin.site.register(AppLog, AppLogAdmin)

class SuspiciousActivityAdmin(admin.ModelAdmin):
    list_display = ('description', 'detected_at')
    search_fields = ('description',)
    list_filter = ('detected_at',)
    readonly_fields = ('detected_at',)

admin.site.register(SuspiciousActivity, SuspiciousActivityAdmin)

