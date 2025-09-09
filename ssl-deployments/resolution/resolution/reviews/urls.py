from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'reviews', views.ReviewViewSet, basename='review')
router.register(r'review-photos', views.ReviewPhotoViewSet, basename='reviewphoto')
router.register(r'review-responses', views.ReviewResponseViewSet, basename='reviewresponse')
router.register(r'review-helpfulness', views.ReviewHelpfulnessViewSet, basename='reviewhelpfulness')
router.register(r'review-flags', views.ReviewFlagViewSet, basename='reviewflag')
router.register(r'review-summaries', views.ReviewSummaryViewSet, basename='reviewsummary')

urlpatterns = [
    path('', include(router.urls)),
    path('reviews/<int:review_id>/mark-helpful/', views.mark_review_helpful, name='mark_review_helpful'),
    path('reviews/<int:review_id>/flag/', views.flag_review, name='flag_review'),
    path('user/<int:user_id>/review-summary/', views.get_user_review_summary, name='user_review_summary'),
    path('transaction/<str:transaction_id>/reviews/', views.get_transaction_reviews, name='transaction_reviews'),
]
