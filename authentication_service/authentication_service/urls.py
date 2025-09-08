from django.urls import path, include
from django.contrib import admin
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from django_prometheus.exports import ExportToDjangoView

from . import views

# Swagger/OpenAPI configuration
schema_view = get_schema_view(
   openapi.Info(
      title="BIDR Authentication Service API",
      default_version='v1',
      description="Comprehensive API documentation for the BIDR Authentication Service, including user management, seller operations, and admin functions.",
      terms_of_service="https://www.bidr.co.za/terms/",
      contact=openapi.Contact(email="api@bidr.co.za"),
      license=openapi.License(name="MIT License"),
   ),
   public=True,
   permission_classes=(permissions.AllowAny,),
)

urlpatterns = [
    # Admin interface
    path('admin/', admin.site.urls),
    
    # Health check endpoints
    path('health/', views.health_check, name='health'),
    path('health/ready/', views.readiness_check, name='readiness'),
    path('health/live/', views.liveness_check, name='liveness'),
    
    # Authentication endpoints with /auth/ prefix
    path("auth/role-selection/", views.RoleSelectionView.as_view(), name="role-selection"),
    path("auth/register/", views.UserRegistrationView.as_view(), name="user-register"),
    path("auth/login/", views.UserLoginView.as_view(), name="user-login"),
    path("auth/logout/", views.UserLogoutView.as_view(), name="user-logout"),

    # Keep the original paths for backward compatibility and direct access
    # Role selection endpoint
    path("role-selection/", views.RoleSelectionView.as_view(), name="role-selection-direct"),

    # Registration endpoints
    path("register/", views.UserRegistrationView.as_view(), name="user-register-direct"),
    # path("register/buyer/", views.BuyerRegistrationView.as_view(), name="buyer-register"),
    # path("register/seller/", views.SellerRegistrationView.as_view(), name="seller-register"),

    # Authentication endpoints
    path("login/", views.UserLoginView.as_view(), name="user-login-direct"),
    path("logout/", views.UserLogoutView.as_view(), name="user-logout-direct"),

    # Password reset endpoints with /auth/ prefix
    path("auth/password-reset-request/", views.PasswordResetRequestView.as_view(), name="password-reset-request"),
    path("auth/password-reset/", views.PasswordResetView.as_view(), name="password-reset"),
    
    # Password reset endpoints (backward compatibility)
    path("password-reset-request/", views.PasswordResetRequestView.as_view(), name="password-reset-request-direct"),
    path("password-reset/", views.PasswordResetView.as_view(), name="password-reset-direct"),

    # OTP endpoints
    path('api/otp/', include('otp.urls')),
    
    # Legacy OTP endpoints for backward compatibility
    path('verify-otp/', views.OTPVerificationView.as_view(), name='verify-otp-legacy'),
    path('resend-otp/', views.ResendOTPView.as_view(), name='resend-otp-legacy'),

    # Seller business registration
    # path("seller/business-registration/", views.SellerBusinessRegistrationView.as_view(),
    #      name="seller-business-registration"),
    # path("seller/document-upload/", views.SellerDocumentUploadView.as_view(), name="seller-document-upload"),

    # Admin document vetting
    # path("admin/document-vetting/", views.DocumentVettingView.as_view(), name="document-vetting-list"),
    # path("admin/document-vetting/<int:vetting_id>/", views.DocumentVettingView.as_view(),
    #      name="document-vetting-update"),

    # User profile endpoints
    path("profile/", views.UserProfileView.as_view(), name="user-profile"),
    path("profile/comprehensive/", views.ComprehensiveUserProfileView.as_view(), name="comprehensive-profile"),
    path("profile/update/", views.UserProfileUpdateView.as_view(), name="profile-update"),
    path("profile/preferences/", views.UserPreferencesView.as_view(), name="user-preferences"),
    path("profile/completion/", views.ProfileCompletionView.as_view(), name="profile-completion"),
    
    # Address management endpoints
    path("addresses/", views.AddressListCreateView.as_view(), name="address-list-create"),
    path("addresses/<uuid:address_id>/", views.AddressDetailView.as_view(), name="address-detail"),
    path("addresses/<uuid:address_id>/set-primary/", views.AddressSetPrimaryView.as_view(), name="address-set-primary"),
    path("addresses/primary/", views.UserPrimaryAddressView.as_view(), name="primary-address"),
    path("addresses/type/<str:address_type>/", views.UserAddressesByTypeView.as_view(), name="addresses-by-type"),
    
    # Permissions and roles management
    path("permissions/", include('permissions.urls')),
    
    # Session management
    path('api/sessions/', include('user_sessions.urls')),
    
    # API key management
    path('api/api-management/', include('api_management.urls')),
    
    # Analytics and reporting
    path('api/analytics/', include('analytics.urls')),
    
    # Seller endpoints
    path('api/seller/', include('seller.urls')),
    
    # API Documentation
    path('swagger<format>/', schema_view.without_ui(cache_timeout=0), name='schema-json'),
    path('swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
    
    # Metrics endpoint for Prometheus
    path('metrics', ExportToDjangoView, name='prometheus-django-metrics'),
    
    # Default root path for swagger UI (this must be last)
    path('', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui-root'),
]

