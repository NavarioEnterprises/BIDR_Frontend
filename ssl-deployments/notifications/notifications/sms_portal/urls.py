from django.urls import path
from . import views

app_name = 'sms_portal'

urlpatterns = [
    # Configuration management
    path('config/', views.SMSPortalConfigListView.as_view(), name='config-list'),
    path('config/<uuid:pk>/', views.SMSPortalConfigDetailView.as_view(), name='config-detail'),
    
    # SMS sending
    path('send/', views.SendSMSView.as_view(), name='send-sms'),
    path('send/otp/', views.SendOTPSMSView.as_view(), name='send-otp'),
    path('send/bulk/', views.BulkSMSView.as_view(), name='send-bulk'),
    
    # Message management
    path('messages/', views.SMSMessageListView.as_view(), name='message-list'),
    path('messages/<uuid:pk>/', views.SMSMessageDetailView.as_view(), name='message-detail'),
    path('messages/update-status/', views.UpdateMessageStatusView.as_view(), name='update-status'),
    
    # Usage statistics
    path('stats/', views.SMSUsageStatsListView.as_view(), name='usage-stats'),
    path('dashboard/', views.sms_dashboard_stats, name='dashboard-stats'),
    
    # Templates
    path('templates/', views.SMSTemplateListView.as_view(), name='template-list'),
    path('templates/<uuid:pk>/', views.SMSTemplateDetailView.as_view(), name='template-detail'),
    
    # Account info
    path('account/balance/', views.account_balance, name='account-balance'),
]