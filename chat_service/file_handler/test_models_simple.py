"""
Simple test suite for file_handler app models
"""

# Set up Django environment if not already configured
import os
import django
from django.conf import settings

if not settings.configured:
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'chat_service.settings')
    django.setup()

from django.test import TestCase
from django.contrib.auth.models import User
from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils import timezone
from chat_messaging.models import Message
from chat_conversations.models import Conversation
from .models import (
    FileUpload, FileShare, FileVersion, FileBackup,
    FileProcessingJob, FileThumbnail
)


class FileUploadTest(TestCase):
    """Test FileUpload model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            buyer=self.user
        )
        
        self.message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user,
            content='Message with file attachment'
        )
    
    def test_create_file_upload(self):
        """Test creating a file upload record."""
        file_content = b'This is test file content for testing purposes'
        uploaded_file = SimpleUploadedFile(
            'test_document.pdf',
            file_content,
            content_type='application/pdf'
        )
        
        file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file_path=uploaded_file,
            original_filename='test_document.pdf',
            file_size=len(file_content),
            mime_type='application/pdf',
            file_category='document',
            related_message=self.message
        )
        
        self.assertEqual(file_upload.uploaded_by, self.user)
        self.assertEqual(file_upload.original_filename, 'test_document.pdf')
        self.assertEqual(file_upload.file_size, len(file_content))
        self.assertEqual(file_upload.mime_type, 'application/pdf')
        self.assertEqual(file_upload.file_category, 'document')
        self.assertEqual(file_upload.status, 'uploading')
    
    def test_file_size_display(self):
        """Test human-readable file size display."""
        file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file_path=SimpleUploadedFile('test.txt', b'content'),
            original_filename='test.txt',
            file_size=2048,
            mime_type='text/plain',
            file_category='other'
        )
        
        size_display = file_upload.get_file_size_display()
        self.assertEqual(size_display, '2.0 KB')


class FileShareTest(TestCase):
    """Test FileShare model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.owner = User.objects.create_user(
            username='owner',
            email='owner@example.com',
            password='ownerpass'
        )
        self.recipient = User.objects.create_user(
            username='recipient',
            email='recipient@example.com',
            password='recipientpass'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.owner,
            file_path=SimpleUploadedFile('shared_file.pdf', b'shared content'),
            original_filename='shared_file.pdf',
            file_size=2048,
            mime_type='application/pdf',
            file_category='document'
        )
    
    def test_create_file_share(self):
        """Test creating a file share."""
        share = FileShare.objects.create(
            file=self.file_upload,
            shared_by=self.owner,
            shared_with=self.recipient,
            permission_level='view',
            expires_at=timezone.now() + timezone.timedelta(days=7)
        )
        
        self.assertEqual(share.file, self.file_upload)
        self.assertEqual(share.shared_by, self.owner)
        self.assertEqual(share.shared_with, self.recipient)
        self.assertEqual(share.permission_level, 'view')
        self.assertFalse(share.is_valid() == False)  # Should be valid (not expired)


class FileVersionTest(TestCase):
    """Test FileVersion model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file_path=SimpleUploadedFile('versioned_file.txt', b'original content'),
            original_filename='versioned_file.txt',
            file_size=100,
            mime_type='text/plain',
            file_category='other'
        )
    
    def test_create_file_version(self):
        """Test creating a file version."""
        version = FileVersion.objects.create(
            original_file=self.file_upload,
            version_number=2,
            file_path=SimpleUploadedFile('versioned_file_v2.txt', b'updated content'),
            file_size=150,
            file_hash='new_hash_value',
            uploaded_by=self.user,
            change_description='Updated content with new information'
        )
        
        self.assertEqual(version.original_file, self.file_upload)
        self.assertEqual(version.version_number, 2)
        self.assertEqual(version.uploaded_by, self.user)
        self.assertEqual(version.change_description, 'Updated content with new information')


class FileThumbnailTest(TestCase):
    """Test FileThumbnail model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file_path=SimpleUploadedFile('image.jpg', b'fake_image_data'),
            original_filename='image.jpg',
            file_size=5000,
            mime_type='image/jpeg',
            file_category='image'
        )
    
    def test_create_file_thumbnail(self):
        """Test creating a file thumbnail."""
        thumbnail = FileThumbnail.objects.create(
            original_file=self.file_upload,
            size_type='small',
            thumbnail_path=SimpleUploadedFile('thumb_small.jpg', b'thumbnail_data'),
            width=150,
            height=150,
            generation_method='PIL'
        )
        
        self.assertEqual(thumbnail.original_file, self.file_upload)
        self.assertEqual(thumbnail.size_type, 'small')
        self.assertEqual(thumbnail.width, 150)
        self.assertEqual(thumbnail.height, 150)


class FileBackupTest(TestCase):
    """Test FileBackup model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file_path=SimpleUploadedFile('important_file.pdf', b'important content'),
            original_filename='important_file.pdf',
            file_size=2000,
            mime_type='application/pdf',
            file_category='document'
        )
    
    def test_create_file_backup(self):
        """Test creating a file backup."""
        backup = FileBackup.objects.create(
            original_file=self.file_upload,
            backup_type='automatic',
            backup_path='/backups/2023/12/important_file.pdf',
            backup_size=2000,
            backup_location='s3',
            backup_hash='backup_hash_123',
            is_verified=True
        )
        
        self.assertEqual(backup.original_file, self.file_upload)
        self.assertEqual(backup.backup_type, 'automatic')
        self.assertEqual(backup.backup_location, 's3')
        self.assertTrue(backup.is_verified)


class FileProcessingJobTest(TestCase):
    """Test FileProcessingJob model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file_path=SimpleUploadedFile('processing_file.mp4', b'video content'),
            original_filename='processing_file.mp4',
            file_size=10000,
            mime_type='video/mp4',
            file_category='video'
        )
    
    def test_create_processing_job(self):
        """Test creating a file processing job."""
        job = FileProcessingJob.objects.create(
            file=self.file_upload,
            job_type='virus_scan',
            status='pending',
            parameters={'scan_depth': 'full'},
            estimated_duration=300
        )
        
        self.assertEqual(job.file, self.file_upload)
        self.assertEqual(job.job_type, 'virus_scan')
        self.assertEqual(job.status, 'pending')
        self.assertEqual(job.parameters['scan_depth'], 'full')
        self.assertEqual(job.progress_percentage, 0)
