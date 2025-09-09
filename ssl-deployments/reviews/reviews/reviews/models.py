from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator


class Review(models.Model):
    """Model for product/service reviews"""
    
    # User who wrote the review
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reviews')
    
    # Product/Service identifiers (assuming external references)
    product_id = models.CharField(max_length=100, help_text="External product ID")
    seller_id = models.CharField(max_length=100, blank=True, null=True, help_text="External seller ID")
    
    # Review content
    title = models.CharField(max_length=200)
    content = models.TextField()
    
    # Rating (1-5 stars)
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="Rating from 1 to 5 stars"
    )
    
    # Status
    is_approved = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        unique_together = ['user', 'product_id']  # One review per user per product
    
    def __str__(self):
        return f"Review by {self.user.username} - {self.title} ({self.rating}★)"


class ReviewResponse(models.Model):
    """Model for seller responses to reviews"""
    
    review = models.OneToOneField(Review, on_delete=models.CASCADE, related_name='seller_response')
    responder = models.ForeignKey(User, on_delete=models.CASCADE, related_name='review_responses')
    response_text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Response to {self.review.title} by {self.responder.username}"


class ReviewHelpful(models.Model):
    """Model to track helpful votes on reviews"""
    
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='helpful_votes')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    is_helpful = models.BooleanField()  # True = helpful, False = not helpful
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['review', 'user']  # One vote per user per review
    
    def __str__(self):
        return f"{self.user.username} - {'Helpful' if self.is_helpful else 'Not Helpful'} on {self.review.title}"


class Ticket(models.Model):
    """Model for support tickets"""
    
    STATUS_CHOICES = [
        ('open', 'Open'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]
    
    PRIORITY_CHOICES = [
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent'),
    ]
    
    # User and authentication
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='tickets')
    auth_user_uid = models.CharField(max_length=100, help_text="Firebase/External User ID")
    
    # Ticket details
    ticket_id = models.CharField(max_length=20, unique=True, editable=False)
    subject = models.CharField(max_length=200)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    priority = models.CharField(max_length=10, choices=PRIORITY_CHOICES, default='medium')
    
    # Assignment
    assignee = models.ForeignKey(
        User, 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='assigned_tickets',
        help_text="Support agent assigned to this ticket"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        if not self.ticket_id:
            # Generate ticket ID like #BAF000223
            import random
            import string
            ticket_num = ''.join(random.choices(string.digits, k=6))
            self.ticket_id = f"#BAF{ticket_num}"
        super().save(*args, **kwargs)
    
    def __str__(self):
        return f"{self.ticket_id} - {self.subject}"


class TicketMessage(models.Model):
    """Model for ticket conversation messages"""
    
    ticket = models.ForeignKey(Ticket, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    is_from_staff = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message on {self.ticket.ticket_id} by {self.sender.username}"
