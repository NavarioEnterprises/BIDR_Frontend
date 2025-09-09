from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'disputes', views.DisputeViewSet, basename='dispute')
router.register(r'dispute-messages', views.DisputeMessageViewSet, basename='disputemessage')
router.register(r'dispute-evidence', views.DisputeEvidenceViewSet, basename='disputeevidence')
router.register(r'resolution-offers', views.DisputeResolutionOfferViewSet, basename='resolutionoffer')
router.register(r'dispute-categories', views.DisputeCategoryViewSet, basename='disputecategory')
router.register(r'mediation-sessions', views.MediationSessionViewSet, basename='mediationsession')

urlpatterns = [
    path('', include(router.urls)),
    path('disputes/<int:dispute_id>/escalate/', views.escalate_dispute, name='escalate_dispute'),
    path('disputes/<int:dispute_id>/resolve/', views.resolve_dispute, name='resolve_dispute'),
    path('disputes/<int:dispute_id>/close/', views.close_dispute, name='close_dispute'),
    path('disputes/<int:dispute_id>/messages/', views.get_dispute_messages, name='dispute_messages'),
    path('resolution-offers/<int:offer_id>/accept/', views.accept_resolution_offer, name='accept_resolution_offer'),
    path('resolution-offers/<int:offer_id>/reject/', views.reject_resolution_offer, name='reject_resolution_offer'),
    path('transaction/<str:transaction_id>/disputes/', views.get_transaction_disputes, name='transaction_disputes'),
    path('user/<int:user_id>/disputes/', views.get_user_disputes, name='user_disputes'),
    path('stats/', views.dispute_statistics, name='dispute_statistics'),
]
