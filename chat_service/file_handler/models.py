from django.db import models
from django.contrib.auth.models import User
from django.core.validators import FileExtensionValidator
from django.utils import timezone
from chat_core.models import BaseModel
from chat_conversations.models import Conversation
from chat_messaging.models import Message
import hashlib
import os


class FileUpload(BaseModel):
    """Central file upload tracking and management."""
    
    FILE_CATEGORIES = [
        ('image', 'Image'),
        ('video', 'Video'),
        ('audio', 'Audio'),
        ('document', 'Document'),
        ('archive', 'Archive'),
        ('code', 'Code File'),
        ('other', 'Other'),
    ]
    
    UPLOAD_STATUS = [
        ('uploading', 'Uploading'),
        ('processing', 'Processing'),
        ('scanning', 'Virus Scanning'),
        ('available', 'Available'),
        ('quarantined', 'Quarantined'),
        ('deleted', 'Deleted'),
        ('expired', 'Expired'),
    ]
    
    # File information
    original_filename = models.CharField(max_length=255)
    file_path = models.FileField(upload_to='uploads/%Y/%m/%d/')
    file_size = models.BigIntegerField(help_text='File size in bytes')
    file_hash = models.CharField(max_length=64, unique=True, help_text='SHA-256 hash')
    mime_type = models.CharField(max_length=100)
    file_category = models.CharField(max_length=20, choices=FILE_CATEGORIES)
    
    # Upload details
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='uploaded_files')
    upload_ip = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Status and processing
    status = models.CharField(max_length=20, choices=UPLOAD_STATUS, default='uploading')
    processing_started_at = models.DateTimeField(null=True, blank=True)
    processing_completed_at = models.DateTimeField(null=True, blank=True)
    
    # Security scanning
    virus_scan_result = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('clean', 'Clean'),
        ('infected', 'Infected'),
        ('suspicious', 'Suspicious'),
        ('error', 'Scan Error'),
    ], default='pending')
    scan_engine = models.CharField(max_length=50, blank=True)
    scan_details = models.JSONField(default=dict, blank=True)
    
    # Content analysis
    content_analysis = models.JSONField(default=dict, blank=True, help_text='AI/ML analysis results')
    extracted_text = models.TextField(blank=True, help_text='Text extracted from file')
    
    # File metadata
    width = models.PositiveIntegerField(null=True, blank=True, help_text='Image/video width')
    height = models.PositiveIntegerField(null=True, blank=True, help_text='Image/video height')
    duration = models.PositiveIntegerField(null=True, blank=True, help_text='Audio/video duration in seconds')
    
    # Access control
    is_public = models.BooleanField(default=False)
    access_token = models.CharField(max_length=64, blank=True, help_text='Token for accessing file')
    expires_at = models.DateTimeField(null=True, blank=True)
    max_downloads = models.PositiveIntegerField(null=True, blank=True)
    
    # Usage tracking
    download_count = models.PositiveIntegerField(default=0)
    view_count = models.PositiveIntegerField(default=0)
    last_accessed = models.DateTimeField(null=True, blank=True)
    
    # Related objects
    related_message = models.ForeignKey(Message, on_delete=models.CASCADE, null=True, blank=True, related_name='file_uploads')
    related_conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE, null=True, blank=True, related_name='file_uploads')
    
    class Meta:
        verbose_name = "File Upload"
        verbose_name_plural = "File Uploads"
        indexes = [
            models.Index(fields=['uploaded_by']),
            models.Index(fields=['status']),
            models.Index(fields=['file_category']),
            models.Index(fields=['virus_scan_result']),
            models.Index(fields=['created_at']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self):
        return f"{self.original_filename} ({self.get_file_size_display()})"
    
    def save(self, *args, **kwargs):
        if self.file_path and not self.file_hash:
            self.file_hash = self.calculate_file_hash()
        
        if not self.access_token:
            self.access_token = self.generate_access_token()
        
        super().save(*args, **kwargs)
    
    def calculate_file_hash(self):
        """Calculate SHA-256 hash of file."""
        hash_sha256 = hashlib.sha256()
        try:
            with self.file_path.open('rb') as f:
                for chunk in iter(lambda: f.read(4096), b""):
                    hash_sha256.update(chunk)
            return hash_sha256.hexdigest()
        except:
            return ''
    
    def generate_access_token(self):
        """Generate secure access token."""
        import secrets
        return secrets.token_urlsafe(32)
    
    def get_file_size_display(self):
        """Human readable file size."""
        size = self.file_size
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if size < 1024.0:
                return f"{size:.1f} {unit}"
            size /= 1024.0
        return f"{size:.1f} PB"
    
    def is_expired(self):
        """Check if file has expired."""
        if not self.expires_at:
            return False
        return timezone.now() > self.expires_at
    
    def can_download(self):
        """Check if file can be downloaded."""
        if self.status != 'available':
            return False
        
        if self.is_expired():
            return False
        
        if self.max_downloads and self.download_count >= self.max_downloads:
            return False
        
        return True
    
    def increment_download_count(self):
        """Increment download counter."""
        self.download_count += 1
        self.last_accessed = timezone.now()
        self.save(update_fields=['download_count', 'last_accessed'])


class FileVersion(BaseModel):
    """Version history for files."""
    
    original_file = models.ForeignKey(FileUpload, on_delete=models.CASCADE, related_name='versions')
    version_number = models.PositiveIntegerField()
    file_path = models.FileField(upload_to='versions/%Y/%m/%d/')
    file_size = models.BigIntegerField()
    file_hash = models.CharField(max_length=64)
    
    # Version metadata
    uploaded_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='uploaded_versions')
    change_description = models.TextField(blank=True)
    
    class Meta:
        verbose_name = "File Version"
        verbose_name_plural = "File Versions"
        unique_together = ['original_file', 'version_number']
        indexes = [
            models.Index(fields=['original_file', 'version_number']),
        ]
    
    def __str__(self):
        return f"{self.original_file.original_filename} v{self.version_number}"


class FileThumbnail(BaseModel):
    """Generated thumbnails for files."""
    
    THUMBNAIL_SIZES = [
        ('small', '150x150'),
        ('medium', '300x300'),
        ('large', '600x600'),
        ('preview', '1200x800'),
    ]
    
    original_file = models.ForeignKey(FileUpload, on_delete=models.CASCADE, related_name='thumbnails')
    size_type = models.CharField(max_length=20, choices=THUMBNAIL_SIZES)
    thumbnail_path = models.ImageField(upload_to='thumbnails/%Y/%m/%d/')
    width = models.PositiveIntegerField()
    height = models.PositiveIntegerField()
    
    # Generation details
    generated_at = models.DateTimeField(default=timezone.now)
    generation_method = models.CharField(max_length=50, blank=True, help_text='Tool/library used')
    
    class Meta:
        verbose_name = "File Thumbnail"
        verbose_name_plural = "File Thumbnails"
        unique_together = ['original_file', 'size_type']
        indexes = [
            models.Index(fields=['original_file']),
        ]
    
    def __str__(self):
        return f"{self.original_file.original_filename} - {self.get_size_type_display()}"


class FileShare(BaseModel):
    """File sharing permissions and tracking."""
    
    PERMISSION_LEVELS = [
        ('view', 'View Only'),
        ('download', 'Download'),
        ('edit', 'Edit'),
        ('admin', 'Admin'),
    ]
    
    file = models.ForeignKey(FileUpload, on_delete=models.CASCADE, related_name='shares')
    shared_by = models.ForeignKey(User, on_delete=models.CASCADE, related_name='shared_files')
    shared_with = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True, related_name='received_files')
    
    # Share details
    permission_level = models.CharField(max_length=20, choices=PERMISSION_LEVELS, default='view')
    share_token = models.CharField(max_length=64, unique=True)
    public_share = models.BooleanField(default=False)
    
    # Access control
    password_protected = models.BooleanField(default=False)
    password_hash = models.CharField(max_length=128, blank=True)
    requires_login = models.BooleanField(default=True)
    
    # Expiration
    expires_at = models.DateTimeField(null=True, blank=True)
    max_uses = models.PositiveIntegerField(null=True, blank=True)
    use_count = models.PositiveIntegerField(default=0)
    
    # Tracking
    last_accessed = models.DateTimeField(null=True, blank=True)
    access_log = models.JSONField(default=list, blank=True)
    
    class Meta:
        verbose_name = "File Share"
        verbose_name_plural = "File Shares"
        indexes = [
            models.Index(fields=['file']),
            models.Index(fields=['shared_by']),
            models.Index(fields=['shared_with']),
            models.Index(fields=['share_token']),
        ]
    
    def __str__(self):
        target = self.shared_with.username if self.shared_with else 'Public'
        return f"{self.file.original_filename} shared with {target}"
    
    def save(self, *args, **kwargs):
        if not self.share_token:
            import secrets
            self.share_token = secrets.token_urlsafe(32)
        super().save(*args, **kwargs)
    
    def is_valid(self):
        """Check if share is still valid."""
        if self.expires_at and timezone.now() > self.expires_at:
            return False
        
        if self.max_uses and self.use_count >= self.max_uses:
            return False
        
        return True
    
    def log_access(self, user=None, ip_address=None):
        """Log file access."""
        access_entry = {
            'timestamp': timezone.now().isoformat(),
            'user': user.username if user else 'Anonymous',
            'ip_address': ip_address,
        }
        
        if not self.access_log:
            self.access_log = []
        
        self.access_log.append(access_entry)
        self.use_count += 1
        self.last_accessed = timezone.now()
        self.save(update_fields=['access_log', 'use_count', 'last_accessed'])


class FileBackup(BaseModel):
    """Backup copies of important files."""
    
    BACKUP_TYPES = [
        ('automatic', 'Automatic Backup'),
        ('manual', 'Manual Backup'),
        ('archive', 'Archive Backup'),
    ]
    
    original_file = models.ForeignKey(FileUpload, on_delete=models.CASCADE, related_name='backups')
    backup_type = models.CharField(max_length=20, choices=BACKUP_TYPES)
    backup_path = models.CharField(max_length=500, help_text='Path to backup location')
    backup_size = models.BigIntegerField()
    
    # Backup details
    backup_location = models.CharField(max_length=100, help_text='Storage location (local, s3, etc.)')
    backup_hash = models.CharField(max_length=64)
    compression_ratio = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    
    # Status
    is_verified = models.BooleanField(default=False)
    verification_date = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        verbose_name = "File Backup"
        verbose_name_plural = "File Backups"
        indexes = [
            models.Index(fields=['original_file']),
            models.Index(fields=['backup_type']),
        ]
    
    def __str__(self):
        return f"Backup of {self.original_file.original_filename} ({self.backup_type})"


class FileProcessingJob(BaseModel):
    """Background jobs for file processing."""
    
    JOB_TYPES = [
        ('virus_scan', 'Virus Scanning'),
        ('thumbnail_generation', 'Thumbnail Generation'),
        ('content_analysis', 'Content Analysis'),
        ('text_extraction', 'Text Extraction'),
        ('format_conversion', 'Format Conversion'),
        ('backup', 'Backup Creation'),
    ]
    
    JOB_STATUS = [
        ('pending', 'Pending'),
        ('running', 'Running'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('cancelled', 'Cancelled'),
    ]
    
    file = models.ForeignKey(FileUpload, on_delete=models.CASCADE, related_name='processing_jobs')
    job_type = models.CharField(max_length=30, choices=JOB_TYPES)
    status = models.CharField(max_length=20, choices=JOB_STATUS, default='pending')
    
    # Job details
    parameters = models.JSONField(default=dict, blank=True)
    result = models.JSONField(default=dict, blank=True)
    error_message = models.TextField(blank=True)
    
    # Timing
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    estimated_duration = models.PositiveIntegerField(null=True, blank=True, help_text='Estimated duration in seconds')
    
    # Progress
    progress_percentage = models.PositiveIntegerField(default=0)
    current_step = models.CharField(max_length=100, blank=True)
    
    class Meta:
        verbose_name = "File Processing Job"
        verbose_name_plural = "File Processing Jobs"
        indexes = [
            models.Index(fields=['file']),
            models.Index(fields=['job_type']),
            models.Index(fields=['status']),
        ]
    
    def __str__(self):
        return f"{self.get_job_type_display()} for {self.file.original_filename}"
