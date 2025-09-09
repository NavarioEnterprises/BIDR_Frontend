from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta
from core.models import TransactionReference
from returns.models import ReturnRequest


class Dispute(models.Model):
    """Disputes between buyers and sellers"""
    # Related objects
    transaction = models.ForeignKey(TransactionReference, on_delete=models.CASCADE)
    return_request = models.ForeignKey(ReturnRequest, on_delete=models.CASCADE, null=True, blank=True)
    
    # Parties involved
    complainant = models.ForeignKey(User, on_delete=models.CASCADE, related_name='disputes_filed')
    respondent = models.ForeignKey(User, on_delete=models.CASCADE, related_name='disputes_received')
    mediator = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='disputes_mediated')
    
    # Dispute details
    dispute_type = models.CharField(max_length=30, choices=[
        ('return_rejected', 'Return Rejected'),
        ('refund_denied', 'Refund Denied'),
        ('item_not_received', 'Item Not Received'),
        ('item_damaged', 'Item Damaged'),
        ('not_as_described', 'Not as Described'),
        ('payment_issue', 'Payment Issue'),
        ('shipping_issue', 'Shipping Issue'),
        ('communication_issue', 'Communication Issue'),
        ('other', 'Other')
    ])
    
    subject = models.CharField(max_length=200)
    description = models.TextField()
    desired_resolution = models.TextField()
    
    # Status and priority
    status = models.CharField(max_length=20, choices=[
        ('open', 'Open'),
        ('in_review', 'In Review'),
        ('awaiting_response', 'Awaiting Response'),
        ('escalated', 'Escalated to Admin'),
        ('mediation', 'In Mediation'),
        ('resolved', 'Resolved'),
        ('closed', 'Closed')
    ], default='open')
    
    priority = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent')
    ], default='medium')
    
    # Financial details
    disputed_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    resolution_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    
    # Important dates
    created_at = models.DateTimeField(auto_now_add=True)
    first_response_at = models.DateTimeField(null=True, blank=True)
    escalated_at = models.DateTimeField(null=True, blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    auto_escalate_at = models.DateTimeField(null=True, blank=True)
    
    # Resolution details
    resolution_type = models.CharField(max_length=20, choices=[
        ('full_refund', 'Full Refund'),
        ('partial_refund', 'Partial Refund'),
        ('replacement', 'Replacement'),
        ('store_credit', 'Store Credit'),
        ('no_action', 'No Action Required'),
        ('other', 'Other')
    ], blank=True)
    resolution_notes = models.TextField(blank=True)
    
    def __str__(self):
        return f"Dispute {self.id}: {self.subject}"
    
    def save(self, *args, **kwargs):
        if not self.auto_escalate_at and self.status == 'open':
            self.auto_escalate_at = timezone.now() + timedelta(hours=72)  # 72 hours
        super().save(*args, **kwargs)


class DisputeMessage(models.Model):
    """Messages in dispute conversations"""
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='messages')
    sender = models.ForeignKey(User, on_delete=models.CASCADE)
    message = models.TextField()
    is_internal = models.BooleanField(default=False)  # Internal admin notes
    is_resolution_offer = models.BooleanField(default=False)
    
    # Message metadata
    read_by_complainant = models.BooleanField(default=False)
    read_by_respondent = models.BooleanField(default=False)
    read_by_admin = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Message in dispute {self.dispute.id} by {self.sender.username}"


class DisputeEvidence(models.Model):
    """Evidence submitted for disputes"""
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='evidence')
    submitted_by = models.ForeignKey(User, on_delete=models.CASCADE)
    
    evidence_type = models.CharField(max_length=20, choices=[
        ('photo', 'Photo'),
        ('document', 'Document'),
        ('screenshot', 'Screenshot'),
        ('receipt', 'Receipt'),
        ('communication', 'Communication Log'),
        ('other', 'Other')
    ])
    
    file = models.FileField(upload_to='disputes/evidence/')
    description = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Evidence for dispute {self.dispute.id}"


class DisputeResolutionOffer(models.Model):
    """Resolution offers made during disputes"""
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='resolution_offers')
    offered_by = models.ForeignKey(User, on_delete=models.CASCADE)
    
    # Offer details
    offer_type = models.CharField(max_length=20, choices=[
        ('full_refund', 'Full Refund'),
        ('partial_refund', 'Partial Refund'),
        ('replacement', 'Replacement'),
        ('store_credit', 'Store Credit'),
        ('discount', 'Discount on Future Purchase'),
        ('other', 'Other')
    ])
    
    offer_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    description = models.TextField()
    terms_and_conditions = models.TextField(blank=True)
    
    # Status
    status = models.CharField(max_length=15, choices=[
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
        ('withdrawn', 'Withdrawn')
    ], default='pending')
    
    # Dates
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    responded_at = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"Resolution offer for dispute {self.dispute.id} - {self.offer_type}"


class DisputeStatusHistory(models.Model):
    """Track status changes for disputes"""
    dispute = models.ForeignKey(Dispute, on_delete=models.CASCADE, related_name='status_history')
    status = models.CharField(max_length=20)
    changed_by = models.ForeignKey(User, on_delete=models.CASCADE)
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name_plural = "Dispute status histories"
    
    def __str__(self):
        return f"Dispute {self.dispute.id} -> {self.status}"


class DisputeCategory(models.Model):
    """Categories for organizing disputes"""
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField()
    auto_escalate_hours = models.PositiveIntegerField(default=72)
    requires_evidence = models.BooleanField(default=True)
    default_priority = models.CharField(max_length=10, choices=[
        ('low', 'Low'),
        ('medium', 'Medium'),
        ('high', 'High'),
        ('urgent', 'Urgent')
    ], default='medium')
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return self.name


class MediationSession(models.Model):
    """Formal mediation sessions for complex disputes"""
    dispute = models.OneToOneField(Dispute, on_delete=models.CASCADE, related_name='mediation')
    mediator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='mediation_sessions')
    
    # Session details
    session_type = models.CharField(max_length=15, choices=[
        ('chat', 'Chat Session'),
        ('video', 'Video Call'),
        ('phone', 'Phone Call'),
        ('email', 'Email Exchange')
    ], default='chat')
    
    scheduled_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    
    # Participation
    complainant_attended = models.BooleanField(default=False)
    respondent_attended = models.BooleanField(default=False)
    
    # Outcome
    outcome = models.CharField(max_length=15, choices=[
        ('agreement', 'Agreement Reached'),
        ('partial', 'Partial Agreement'),
        ('no_agreement', 'No Agreement'),
        ('escalated', 'Escalated to Admin'),
        ('cancelled', 'Cancelled')
    ], blank=True)
    
    mediator_notes = models.TextField(blank=True)
    agreement_terms = models.TextField(blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Mediation for dispute {self.dispute.id}"


class DisputeStatistics(models.Model):
    """Aggregate statistics for disputes"""
    date = models.DateField(unique=True)
    
    # Daily counts
    total_disputes = models.PositiveIntegerField(default=0)
    new_disputes = models.PositiveIntegerField(default=0)
    resolved_disputes = models.PositiveIntegerField(default=0)
    escalated_disputes = models.PositiveIntegerField(default=0)
    
    # Resolution types
    full_refunds = models.PositiveIntegerField(default=0)
    partial_refunds = models.PositiveIntegerField(default=0)
    replacements = models.PositiveIntegerField(default=0)
    no_actions = models.PositiveIntegerField(default=0)
    
    # Average resolution time in hours
    avg_resolution_time = models.FloatField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Dispute Stats for {self.date}"
