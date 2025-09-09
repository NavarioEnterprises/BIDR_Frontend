"""
URLs for the analytics app.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'analytics'

router = DefaultRouter()
router.register(r'product-request-analytics', views.ProductRequestAnalyticsViewSet)
router.register(r'category-analytics', views.CategoryAnalyticsViewSet)
router.register(r'user-behavior-analytics', views.UserBehaviorAnalyticsViewSet)
router.register(r'search-analytics', views.SearchAnalyticsViewSet)
router.register(r'sales-analytics', views.SalesAnalyticsViewSet)
router.register(r'inventory-analytics', views.InventoryAnalyticsViewSet)
router.register(r'reports', views.AnalyticsReportViewSet)
router.register(r'dashboard', views.AnalyticsDashboardViewSet, basename='analytics-dashboard')

urlpatterns = [
    path('', include(router.urls)),
]
