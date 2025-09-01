from django.urls import path
from . import views

urlpatterns = [
    # Rating CRUD operations
    path('', views.RatingListCreateView.as_view(), name='rating-list-create'),
    path('<int:pk>/', views.RatingDetailView.as_view(), name='rating-detail'),
    
    # Average ratings
    path('average/', views.AverageRatingListView.as_view(), name='average-rating-list'),
    
    # Seller-specific reviews and ratings (formatted for frontend)
    path('seller/<str:seller_id>/', views.seller_reviews_and_ratings, name='seller-reviews-ratings'),
    
    # Product-specific reviews and ratings
    path('product/<str:product_id>/', views.product_reviews_and_ratings, name='product-reviews-ratings'),
    
    # Actions
    path('respond/', views.respond_to_review, name='respond-to-review'),
    path('report/', views.report_review, name='report-review'),
]