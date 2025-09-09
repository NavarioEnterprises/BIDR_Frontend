from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'return-requests', views.ReturnRequestViewSet, basename='returnrequest')
router.register(r'return-photos', views.ReturnPhotoViewSet, basename='returnphoto')
router.register(r'return-shipping', views.ReturnShippingViewSet, basename='returnshipping')
router.register(r'return-evaluations', views.ReturnEvaluationViewSet, basename='returnevaluation')
router.register(r'return-policies', views.ReturnPolicyViewSet, basename='returnpolicy')

urlpatterns = [
    path('', include(router.urls)),
    path('return-requests/<int:return_id>/approve/', views.approve_return, name='approve_return'),
    path('return-requests/<int:return_id>/reject/', views.reject_return, name='reject_return'),
    path('return-requests/<int:return_id>/ship/', views.ship_return, name='ship_return'),
    path('return-requests/<int:return_id>/receive/', views.receive_return, name='receive_return'),
    path('return-requests/<int:return_id>/evaluate/', views.evaluate_return, name='evaluate_return'),
    path('return-requests/<int:return_id>/complete/', views.complete_return, name='complete_return'),
    path('transaction/<str:transaction_id>/returns/', views.get_transaction_returns, name='transaction_returns'),
    path('user/<int:user_id>/returns/', views.get_user_returns, name='user_returns'),
]
