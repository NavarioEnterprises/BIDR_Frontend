#!/usr/bin/env python
"""
Script to create sample data for reviews and ratings
"""

import os
import sys
import django
from datetime import datetime, timedelta
import random

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'reviews_and_ratings.settings')
django.setup()

from django.contrib.auth.models import User
from reviews.models import Review, ReviewHelpful
from ratings.models import Rating, AverageRating
from django.utils import timezone


def create_sample_users():
    """Create sample users"""
    users_data = [
        {'username': '000100', 'first_name': 'Joseph', 'last_name': 'Anthony', 'email': 'joseph.anthony@example.com'},
        {'username': '000180', 'first_name': 'Benjamin', 'last_name': 'Thompson', 'email': 'benjamin.thompson@example.com'},
        {'username': '003100', 'first_name': 'Jane', 'last_name': 'Smith', 'email': 'jane.smith@example.com'},
        {'username': '000200', 'first_name': 'Sarah', 'last_name': 'Johnson', 'email': 'sarah.johnson@example.com'},
        {'username': '000300', 'first_name': 'Michael', 'last_name': 'Brown', 'email': 'michael.brown@example.com'},
    ]
    
    users = []
    for user_data in users_data:
        user, created = User.objects.get_or_create(
            username=user_data['username'],
            defaults=user_data
        )
        users.append(user)
        if created:
            print(f"Created user: {user.username}")
    
    return users


def create_sample_reviews():
    """Create sample reviews"""
    users = User.objects.all()
    
    reviews_data = [
        {
            'user': users[0],  # Joseph Anthony
            'product_id': 'PROD001',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'title': 'Excellent Fuel Filter',
            'content': 'Great quality fuel filter for my Toyota Corolla 2016. Perfect fit and excellent service from the seller.',
            'rating': 5,
        },
        {
            'user': users[1],  # Benjamin Thompson
            'product_id': 'PROD002',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'title': 'Perfect Tail Light',
            'content': 'Exactly what I needed for my BMW M3 2024. Fast shipping and great quality.',
            'rating': 5,
        },
        {
            'user': users[2],  # Jane Smith
            'product_id': 'PROD001',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'title': 'Good Service',
            'content': 'Fuel filter arrived on time and works perfectly. Would recommend this seller.',
            'rating': 5,
        },
        {
            'user': users[3],  # Sarah Johnson
            'product_id': 'PROD003',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'title': 'Quality Brake Pads',
            'content': 'These brake pads are excellent quality. Installation was straightforward and they work great.',
            'rating': 4,
        },
        {
            'user': users[4],  # Michael Brown
            'product_id': 'PROD004',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'title': 'Reliable Oil Filter',
            'content': 'Good oil filter, fits my Honda Civic perfectly. Seller communication was excellent.',
            'rating': 4,
        },
    ]
    
    reviews = []
    for review_data in reviews_data:
        review, created = Review.objects.get_or_create(
            user=review_data['user'],
            product_id=review_data['product_id'],
            defaults=review_data
        )
        reviews.append(review)
        if created:
            print(f"Created review: {review.title}")
    
    return reviews


def create_sample_ratings():
    """Create sample ratings"""
    users = User.objects.all()
    
    ratings_data = [
        {
            'user': users[0],  # Joseph Anthony
            'product_id': 'PROD001',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'overall_rating': 5,
            'quality_rating': 5,
            'service_rating': 5,
            'delivery_rating': 4,
        },
        {
            'user': users[1],  # Benjamin Thompson
            'product_id': 'PROD002',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'overall_rating': 5,
            'quality_rating': 5,
            'service_rating': 5,
            'delivery_rating': 5,
        },
        {
            'user': users[2],  # Jane Smith
            'product_id': 'PROD001',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'overall_rating': 5,
            'quality_rating': 4,
            'service_rating': 5,
            'delivery_rating': 5,
        },
        {
            'user': users[3],  # Sarah Johnson
            'product_id': 'PROD003',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'overall_rating': 4,
            'quality_rating': 4,
            'service_rating': 4,
            'delivery_rating': 4,
        },
        {
            'user': users[4],  # Michael Brown
            'product_id': 'PROD004',
            'seller_id': 'c97f2da1-810c-4f86-98b4-18b722d5eecb',
            'overall_rating': 4,
            'quality_rating': 4,
            'service_rating': 5,
            'delivery_rating': 3,
        },
    ]
    
    ratings = []
    for rating_data in ratings_data:
        rating, created = Rating.objects.get_or_create(
            user=rating_data['user'],
            product_id=rating_data['product_id'],
            defaults=rating_data
        )
        ratings.append(rating)
        if created:
            print(f"Created rating for product {rating.product_id} by {rating.user.username}")
    
    return ratings


def calculate_average_ratings():
    """Calculate and create average ratings"""
    from django.db.models import Avg, Count
    
    # Get all unique product_id and seller_id combinations
    products = Rating.objects.values('product_id', 'seller_id').distinct()
    
    for product in products:
        product_id = product['product_id']
        seller_id = product['seller_id']
        
        # Calculate averages for ratings
        rating_stats = Rating.objects.filter(
            product_id=product_id,
            seller_id=seller_id
        ).aggregate(
            overall_avg=Avg('overall_rating'),
            quality_avg=Avg('quality_rating'),
            service_avg=Avg('service_rating'),
            delivery_avg=Avg('delivery_rating'),
            total_ratings=Count('id')
        )
        
        # Count reviews
        review_count = Review.objects.filter(
            product_id=product_id,
            seller_id=seller_id
        ).count()
        
        # Create or update average rating
        avg_rating, created = AverageRating.objects.get_or_create(
            product_id=product_id,
            defaults={
                'seller_id': seller_id,
                'overall_avg': rating_stats['overall_avg'] or 0,
                'quality_avg': rating_stats['quality_avg'] or 0,
                'service_avg': rating_stats['service_avg'] or 0,
                'delivery_avg': rating_stats['delivery_avg'] or 0,
                'total_ratings': rating_stats['total_ratings'],
                'total_reviews': review_count,
            }
        )
        
        if not created:
            # Update existing record
            avg_rating.seller_id = seller_id
            avg_rating.overall_avg = rating_stats['overall_avg'] or 0
            avg_rating.quality_avg = rating_stats['quality_avg'] or 0
            avg_rating.service_avg = rating_stats['service_avg'] or 0
            avg_rating.delivery_avg = rating_stats['delivery_avg'] or 0
            avg_rating.total_ratings = rating_stats['total_ratings']
            avg_rating.total_reviews = review_count
            avg_rating.save()
        
        action = "Created" if created else "Updated"
        print(f"{action} average rating for product {product_id}: {avg_rating.overall_avg}★")


def main():
    """Main function to create all sample data"""
    print("Creating sample data for reviews and ratings...")
    
    # Create sample users
    print("\n1. Creating sample users...")
    users = create_sample_users()
    
    # Create sample reviews
    print("\n2. Creating sample reviews...")
    reviews = create_sample_reviews()
    
    # Create sample ratings
    print("\n3. Creating sample ratings...")
    ratings = create_sample_ratings()
    
    # Calculate average ratings
    print("\n4. Calculating average ratings...")
    calculate_average_ratings()
    
    print(f"\nSample data creation completed!")
    print(f"- Users: {len(users)}")
    print(f"- Reviews: {len(reviews)}")
    print(f"- Ratings: {len(ratings)}")
    print(f"- Average Ratings: {AverageRating.objects.count()}")


if __name__ == "__main__":
    main()