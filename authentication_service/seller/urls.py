from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Create router for viewsets
router = DefaultRouter()
router.register(r'profiles', views.SellerProfileViewSet, basename='seller-profile')

urlpatterns = [
    # ViewSet routes
    path('', include(router.urls)),
    
    # Registration endpoints
    path('register/', views.SellerRegistrationView.as_view(), name='seller-register'),
    path('business-registration/', views.SellerBusinessRegistrationView.as_view(), name='seller-business-registration'),
    
    # Document upload
    path('document-upload/', views.SellerDocumentUploadView.as_view(), name='seller-document-upload'),
    
    # Admin vetting endpoints
    path('admin/document-vetting/', views.DocumentVettingView.as_view(), name='document-vetting-list'),
    path('admin/document-vetting/<int:vetting_id>/', views.DocumentVettingView.as_view(), name='document-vetting-update'),
]
