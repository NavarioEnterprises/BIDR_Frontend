from django.db import models
from django.contrib.auth.models import User
from django.core.validators import FileExtensionValidator


class FAQ(models.Model):
    """Model for Frequently Asked Questions"""
    
    CATEGORY_CHOICES = [
        ('general', 'General'),
        ('security', 'Security'),
        ('products', 'Products'),
        ('buying', 'Buying'),
        ('selling', 'Selling'),
        ('returns', 'Returns'),
        ('payments', 'Payments'),
    ]
    
    question = models.CharField(max_length=300)
    answer = models.TextField()
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES, default='general')
    order = models.IntegerField(default=0, help_text="Display order (lower numbers appear first)")
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['category', 'order', '-created_at']
        verbose_name = "FAQ"
        verbose_name_plural = "FAQs"
    
    def __str__(self):
        return f"{self.get_category_display()}: {self.question[:50]}..."


class Blog(models.Model):
    """Model for Blog posts"""
    
    SECTION_CHOICES = [
        ('auto_transport', 'Auto & Transport'),
        ('electronics', 'Electronics'),
        ('marketplace_tips', 'Marketplace Tips'),
        ('company_news', 'Company News'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField(help_text="Short description/excerpt")
    content = models.TextField(help_text="Full blog content")
    
    # Image
    image_url = models.URLField(blank=True, null=True, help_text="URL to blog image")
    image_file = models.ImageField(
        upload_to='blog_images/',
        blank=True,
        null=True,
        validators=[FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'webp'])]
    )
    
    # Metadata
    section = models.CharField(max_length=20, choices=SECTION_CHOICES, default='marketplace_tips')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blog_posts')
    tags = models.CharField(max_length=200, blank=True, help_text="Comma-separated tags")
    
    # Engagement
    likes = models.IntegerField(default=0)
    views = models.IntegerField(default=0)
    
    # Status
    is_published = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def save(self, *args, **kwargs):
        if self.is_published and not self.published_at:
            from django.utils import timezone
            self.published_at = timezone.now()
        super().save(*args, **kwargs)
    
    @property
    def image(self):
        """Return image URL or file URL"""
        if self.image_file:
            return self.image_file.url
        return self.image_url
    
    def __str__(self):
        return self.title


class BlogComment(models.Model):
    """Model for blog comments"""
    
    blog = models.ForeignKey(Blog, on_delete=models.CASCADE, related_name='comments')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    content = models.TextField()
    is_approved = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Comment by {self.user.username} on {self.blog.title}"


class Policy(models.Model):
    """Model for company policies"""
    
    POLICY_TYPES = [
        ('privacy', 'Privacy Policy'),
        ('terms', 'Terms of Service'),
        ('return', 'Return Policy'),
        ('shipping', 'Shipping Policy'),
        ('cookies', 'Cookie Policy'),
        ('disclaimer', 'Disclaimer'),
    ]
    
    title = models.CharField(max_length=200)
    policy_type = models.CharField(max_length=20, choices=POLICY_TYPES, unique=True)
    content = models.TextField(help_text="Full policy content in HTML or markdown")
    version = models.CharField(max_length=10, default="1.0")
    
    is_active = models.BooleanField(default=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    effective_date = models.DateField(help_text="When this policy becomes effective")
    
    class Meta:
        ordering = ['policy_type']
        verbose_name_plural = "Policies"
    
    def __str__(self):
        return f"{self.get_policy_type_display()} v{self.version}"


class ContactSubmission(models.Model):
    """Model for contact form submissions"""
    
    SUBJECT_CHOICES = [
        ('general', 'General Inquiry'),
        ('support', 'Technical Support'),
        ('billing', 'Billing Question'),
        ('partnership', 'Partnership Opportunity'),
        ('feedback', 'Feedback'),
        ('complaint', 'Complaint'),
        ('other', 'Other'),
    ]
    
    STATUS_CHOICES = [
        ('new', 'New'),
        ('in_progress', 'In Progress'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed'),
    ]
    
    # Contact information
    name = models.CharField(max_length=100)
    email = models.EmailField()
    phone = models.CharField(max_length=20, blank=True)
    company = models.CharField(max_length=100, blank=True)
    
    # Message details
    subject = models.CharField(max_length=20, choices=SUBJECT_CHOICES, default='general')
    message = models.TextField()
    
    # Status and assignment
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='new')
    assigned_to = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_contacts'
    )
    
    # Response
    response = models.TextField(blank=True)
    responded_at = models.DateTimeField(null=True, blank=True)
    responded_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='contact_responses'
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Contact Submission"
        verbose_name_plural = "Contact Submissions"
    
    def __str__(self):
        return f"{self.name} - {self.get_subject_display()}"


class NewsletterSubscription(models.Model):
    """Model for newsletter subscriptions"""
    
    email = models.EmailField(unique=True)
    name = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)
    
    # Preferences
    marketing_emails = models.BooleanField(default=True)
    product_updates = models.BooleanField(default=True)
    weekly_digest = models.BooleanField(default=False)
    
    # Timestamps
    subscribed_at = models.DateTimeField(auto_now_add=True)
    unsubscribed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-subscribed_at']
    
    def __str__(self):
        return f"{self.email} - {'Active' if self.is_active else 'Inactive'}"
