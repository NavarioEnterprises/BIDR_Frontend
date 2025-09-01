from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Rating, AverageRating


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'email']


class RatingSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = Rating
        fields = [
            'id', 'user', 'product_id', 'seller_id', 'overall_rating',
            'quality_rating', 'service_rating', 'delivery_rating', 
            'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'created_at', 'updated_at']


class AverageRatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = AverageRating
        fields = [
            'product_id', 'seller_id', 'overall_avg', 'quality_avg',
            'service_avg', 'delivery_avg', 'total_ratings', 'total_reviews',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']


class RatingCreateSerializer(serializers.ModelSerializer):
    auth_user_uid = serializers.CharField(write_only=True)
    
    class Meta:
        model = Rating
        fields = [
            'auth_user_uid', 'product_id', 'seller_id', 'overall_rating',
            'quality_rating', 'service_rating', 'delivery_rating'
        ]
        
    def create(self, validated_data):
        # Get or create user based on auth_user_uid
        auth_user_uid = validated_data.pop('auth_user_uid')
        user, created = User.objects.get_or_create(
            username=auth_user_uid,
            defaults={'email': f'{auth_user_uid}@bidr.com'}
        )
        validated_data['user'] = user
        return super().create(validated_data)