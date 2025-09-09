from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from core.models import TransactionReference


class Review(models.Model):
    """Product/Transaction reviews"""
    transaction = models.ForeignKey(TransactionReference, on_delete=models.CASCADE)
    reviewer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_given')
    reviewed_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews_received')
    
    # Review details
    rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)]
    )
    title = models.CharField(max_length=200)
    content = models.TextField()
    
    # Review categories
    communication_rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True, blank=True
    )
    product_quality_rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True, blank=True
    )
    delivery_rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        null=True, blank=True
    )
    
    # Status and metadata
    is_verified = models.BooleanField(default=False)
    is_published = models.BooleanField(default=True)
    is_flagged = models.BooleanField(default=False)
    flag_reason = models.TextField(blank=True, null=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = ['transaction', 'reviewer']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Review by {self.reviewer.username} - {self.rating} stars"


class ReviewPhoto(models.Model):
    """Photos attached to reviews"""
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='photos')
    image = models.ImageField(upload_to='reviews/photos/')
    caption = models.CharField(max_length=200, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Photo for review {self.review.id}"


class ReviewResponse(models.Model):
    """Responses to reviews (from reviewed users)"""
    review = models.OneToOneField(Review, on_delete=models.CASCADE, related_name='response')
    responder = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Response to review {self.review.id}"


class ReviewHelpfulness(models.Model):
    """Track helpful votes on reviews"""
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='helpfulness_votes')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    is_helpful = models.BooleanField()  # True for helpful, False for not helpful
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['review', 'user']
    
    def __str__(self):
        helpful_text = "helpful" if self.is_helpful else "not helpful"
        return f"{self.user.username} found review {self.review.id} {helpful_text}"


class ReviewFlag(models.Model):
    """Flags raised against reviews"""
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='flags')
    flagger = models.ForeignKey(User, on_delete=models.CASCADE)
    reason = models.CharField(max_length=50, choices=[
        ('spam', 'Spam'),
        ('fake', 'Fake Review'),
        ('inappropriate', 'Inappropriate Content'),
        ('personal_info', 'Contains Personal Information'),
        ('harassment', 'Harassment'),
        ('other', 'Other')
    ])
    details = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('reviewed', 'Reviewed'),
        ('resolved', 'Resolved'),
        ('dismissed', 'Dismissed')
    ], default='pending')
    admin_notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"Flag on review {self.review.id} - {self.reason}"


class ReviewSummary(models.Model):
    """Aggregate review statistics for users"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='review_summary')
    
    # As a buyer
    reviews_given_count = models.PositiveIntegerField(default=0)
    avg_rating_given = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    
    # As a seller
    reviews_received_count = models.PositiveIntegerField(default=0)
    avg_rating_received = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    
    # Detailed breakdown
    five_star_count = models.PositiveIntegerField(default=0)
    four_star_count = models.PositiveIntegerField(default=0)
    three_star_count = models.PositiveIntegerField(default=0)
    two_star_count = models.PositiveIntegerField(default=0)
    one_star_count = models.PositiveIntegerField(default=0)
    
    last_updated = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.user.username} - Review Summary"
