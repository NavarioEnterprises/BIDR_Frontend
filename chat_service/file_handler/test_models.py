"""
Test suite for file_handler app

Tests cover:
- File upload and management
- File scanning and virus detection
- File compression and processing
- File sharing and permissions
- File cleanup and retention
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
    FileProcessingJob, FileThumbnail, FileScan,
    FileCleanupTask, FileCompressionJob, FileAccessLog
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
            file=uploaded_file,
            original_filename='test_document.pdf',
            file_size=len(file_content),
            mime_type='application/pdf',
            file_hash='abc123def456',
            related_object_type='message',
            related_object_id=self.message.id
        )
        
        self.assertEqual(file_upload.uploaded_by, self.user)
        self.assertEqual(file_upload.original_filename, 'test_document.pdf')
        self.assertEqual(file_upload.file_size, len(file_content))
        self.assertEqual(file_upload.mime_type, 'application/pdf')
        self.assertEqual(file_upload.upload_status, 'completed')
        self.assertFalse(file_upload.is_processed)
    
    def test_file_size_display(self):
        """Test human-readable file size display."""
        file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('test.txt', b'content'),
            original_filename='test.txt',
            file_size=2048,
            mime_type='text/plain'
        )
        
        size_display = file_upload.get_file_size_display()
        self.assertEqual(size_display, '2.0 KB')
    
    def test_file_type_detection(self):
        """Test file type detection from mime type."""
        # Test image file
        image_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('test.jpg', b'fake_image_data'),
            original_filename='test.jpg',
            file_size=1000,
            mime_type='image/jpeg'
        )
        
        self.assertEqual(image_upload.get_file_type(), 'image')
        
        # Test document file
        doc_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('test.pdf', b'fake_pdf_data'),
            original_filename='test.pdf',
            file_size=5000,
            mime_type='application/pdf'
        )
        
        self.assertEqual(doc_upload.get_file_type(), 'document')
    
    def test_generate_download_url(self):
        """Test generating secure download URL."""
        file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('test.txt', b'content'),
            original_filename='test.txt',
            file_size=100,
            mime_type='text/plain'
        )
        
        download_url = file_upload.generate_download_url()
        
        self.assertIsNotNone(download_url)
        self.assertIn('download', download_url)
    
    def test_mark_file_as_processed(self):
        """Test marking file as processed."""
        file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('test.txt', b'content'),
            original_filename='test.txt',
            file_size=100,
            mime_type='text/plain',
            is_processed=False
        )
        
        file_upload.mark_as_processed()
        
        file_upload.refresh_from_db()
        self.assertTrue(file_upload.is_processed)
        self.assertIsNotNone(file_upload.processed_at)


class FileScanTest(TestCase):
    """Test FileScan model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('test.exe', b'suspicious_content'),
            original_filename='test.exe',
            file_size=1024,
            mime_type='application/x-executable'
        )
    
    def test_create_file_scan(self):
        """Test creating a file scan record."""
        scan = FileScan.objects.create(
            file_upload=self.file_upload,
            scan_engine='clamav',
            scan_status='completed',
            is_safe=True,
            scan_details={
                'signatures_checked': 5000,
                'scan_time_ms': 150
            }
        )
        
        self.assertEqual(scan.file_upload, self.file_upload)
        self.assertEqual(scan.scan_engine, 'clamav')
        self.assertEqual(scan.scan_status, 'completed')
        self.assertTrue(scan.is_safe)
        self.assertIsNone(scan.threat_detected)
    
    def test_detect_malware(self):
        """Test malware detection scenario."""
        scan = FileScan.objects.create(
            file_upload=self.file_upload,
            scan_engine='virustotal',
            scan_status='completed',
            is_safe=False,
            threat_detected='Trojan.Generic',
            threat_level='high',
            scan_details={
                'detection_engines': 15,
                'threat_classification': 'trojan'
            }
        )
        
        self.assertFalse(scan.is_safe)
        self.assertEqual(scan.threat_detected, 'Trojan.Generic')
        self.assertEqual(scan.threat_level, 'high')
        
        # File should be quarantined
        self.file_upload.refresh_from_db()
        # Note: This would typically trigger quarantine logic
    
    def test_scan_timeout(self):
        """Test scan timeout scenario."""
        scan = FileScan.objects.create(
            file_upload=self.file_upload,
            scan_engine='custom_scanner',
            scan_status='timeout',
            scan_details={
                'timeout_seconds': 300,
                'partial_scan': True
            }
        )
        
        self.assertEqual(scan.scan_status, 'timeout')
        self.assertIsNone(scan.is_safe)  # Unknown safety status
    
    def test_get_scan_summary(self):
        """Test getting scan summary information."""
        scan = FileScan.objects.create(
            file_upload=self.file_upload,
            scan_engine='comprehensive',
            scan_status='completed',
            is_safe=True,
            scan_details={
                'engines_used': ['clamav', 'virustotal'],
                'total_signatures': 10000,
                'scan_duration': '2.5s'
            }
        )
        
        summary = scan.get_scan_summary()
        
        self.assertIn('status', summary)
        self.assertIn('safe', summary)
        self.assertIn('engine', summary)


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
            file=SimpleUploadedFile('shared_file.pdf', b'shared content'),
            original_filename='shared_file.pdf',
            file_size=2048,
            mime_type='application/pdf'
        )
    
    def test_create_file_share(self):
        """Test creating a file share."""
        share = FileShare.objects.create(
            file_upload=self.file_upload,
            shared_by=self.owner,
            shared_with=self.recipient,
            permission_level='view',
            expires_at=timezone.now() + timezone.timedelta(days=7),
            is_password_protected=False
        )
        
        self.assertEqual(share.file_upload, self.file_upload)
        self.assertEqual(share.shared_by, self.owner)
        self.assertEqual(share.shared_with, self.recipient)
        self.assertEqual(share.permission_level, 'view')
        self.assertFalse(share.is_expired())
    
    def test_password_protected_share(self):
        """Test password-protected file share."""
        share = FileShare.objects.create(
            file_upload=self.file_upload,
            shared_by=self.owner,
            permission_level='download',
            is_password_protected=True,
            share_password='secure123',
            expires_at=timezone.now() + timezone.timedelta(days=1)
        )
        
        self.assertTrue(share.is_password_protected)
        
        # Test password verification
        self.assertTrue(share.verify_password('secure123'))
        self.assertFalse(share.verify_password('wrong_password'))
    
    def test_generate_share_token(self):
        """Test generating secure share token."""
        share = FileShare.objects.create(
            file_upload=self.file_upload,
            shared_by=self.owner,
            permission_level='view',
            expires_at=timezone.now() + timezone.timedelta(hours=24)
        )
        
        token = share.generate_share_token()
        
        self.assertIsNotNone(token)
        self.assertTrue(len(token) > 20)  # Should be a secure token
        
        # Token should be saved
        share.refresh_from_db()
        self.assertEqual(share.share_token, token)
    
    def test_share_expiry(self):
        """Test file share expiration."""
        # Create expired share
        expired_share = FileShare.objects.create(
            file_upload=self.file_upload,
            shared_by=self.owner,
            shared_with=self.recipient,
            permission_level='view',
            expires_at=timezone.now() - timezone.timedelta(hours=1)
        )
        
        self.assertTrue(expired_share.is_expired())
        
        # Create non-expired share
        active_share = FileShare.objects.create(
            file_upload=self.file_upload,
            shared_by=self.owner,
            shared_with=self.recipient,
            permission_level='view',
            expires_at=timezone.now() + timezone.timedelta(hours=1)
        )
        
        self.assertFalse(active_share.is_expired())
    
    def test_revoke_share(self):
        """Test revoking file share."""
        share = FileShare.objects.create(
            file_upload=self.file_upload,
            shared_by=self.owner,
            shared_with=self.recipient,
            permission_level='download'
        )
        
        # Revoke share
        share.revoke()
        
        share.refresh_from_db()
        self.assertTrue(share.is_revoked)
        self.assertIsNotNone(share.revoked_at)


class FileCleanupTaskTest(TestCase):
    """Test FileCleanupTask model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.admin_user = User.objects.create_user(
            username='admin',
            email='admin@example.com',
            password='adminpass',
            is_staff=True
        )
    
    def test_create_cleanup_task(self):
        """Test creating file cleanup task."""
        task = FileCleanupTask.objects.create(
            task_name='Clean Old Files',
            cleanup_type='age_based',
            criteria={
                'older_than_days': 30,
                'file_types': ['image', 'document'],
                'min_file_size': 0
            },
            scheduled_for=timezone.now() + timezone.timedelta(hours=2),
            created_by=self.admin_user
        )
        
        self.assertEqual(task.task_name, 'Clean Old Files')
        self.assertEqual(task.cleanup_type, 'age_based')
        self.assertEqual(task.status, 'pending')
        self.assertEqual(task.files_processed, 0)
    
    def test_start_cleanup_task(self):
        """Test starting cleanup task execution."""
        task = FileCleanupTask.objects.create(
            task_name='Cleanup Task',
            cleanup_type='size_based',
            criteria={'max_total_size_gb': 100},
            status='pending',
            created_by=self.admin_user
        )
        
        # Start task
        task.start_execution()
        
        task.refresh_from_db()
        self.assertEqual(task.status, 'running')
        self.assertIsNotNone(task.started_at)
    
    def test_complete_cleanup_task(self):
        """Test completing cleanup task."""
        task = FileCleanupTask.objects.create(
            task_name='Cleanup Task',
            cleanup_type='manual',
            criteria={'target_files': []},
            status='running',
            created_by=self.admin_user
        )
        
        # Complete task
        task.complete_execution(
            files_deleted=25,
            space_freed_bytes=1024000,
            execution_summary='Successfully cleaned up old files'
        )
        
        task.refresh_from_db()
        self.assertEqual(task.status, 'completed')
        self.assertEqual(task.files_deleted, 25)
        self.assertEqual(task.space_freed_bytes, 1024000)
        self.assertIsNotNone(task.completed_at)


class FileCompressionJobTest(TestCase):
    """Test FileCompressionJob model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('large_file.pdf', b'x' * 10000),
            original_filename='large_file.pdf',
            file_size=10000,
            mime_type='application/pdf'
        )
    
    def test_create_compression_job(self):
        """Test creating file compression job."""
        job = FileCompressionJob.objects.create(
            file_upload=self.file_upload,
            compression_type='zip',
            compression_level=6,
            original_size=10000,
            status='pending'
        )
        
        self.assertEqual(job.file_upload, self.file_upload)
        self.assertEqual(job.compression_type, 'zip')
        self.assertEqual(job.status, 'pending')
        self.assertIsNone(job.compressed_size)
    
    def test_complete_compression(self):
        """Test completing compression job."""
        job = FileCompressionJob.objects.create(
            file_upload=self.file_upload,
            compression_type='gzip',
            original_size=10000,
            status='processing'
        )
        
        # Complete compression
        job.complete_compression(
            compressed_size=7500,
            compressed_file_path='/path/to/compressed/file.gz'
        )
        
        job.refresh_from_db()
        self.assertEqual(job.status, 'completed')
        self.assertEqual(job.compressed_size, 7500)
        self.assertEqual(job.compression_ratio, 0.75)  # 7500/10000
        self.assertIsNotNone(job.completed_at)
    
    def test_compression_failure(self):
        """Test compression job failure."""
        job = FileCompressionJob.objects.create(
            file_upload=self.file_upload,
            compression_type='custom',
            original_size=10000,
            status='processing'
        )
        
        # Mark as failed
        job.mark_as_failed('Compression algorithm not supported')
        
        job.refresh_from_db()
        self.assertEqual(job.status, 'failed')
        self.assertEqual(job.error_message, 'Compression algorithm not supported')
        self.assertIsNotNone(job.failed_at)


class FileAccessLogTest(TestCase):
    """Test FileAccessLog model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        self.file_upload = FileUpload.objects.create(
            uploaded_by=self.user,
            file=SimpleUploadedFile('access_test.pdf', b'test content'),
            original_filename='access_test.pdf',
            file_size=1000,
            mime_type='application/pdf'
        )
    
    def test_create_file_access_log(self):
        """Test creating file access log entry."""
        log_entry = FileAccessLog.objects.create(
            file_upload=self.file_upload,
            accessed_by=self.user,
            access_type='download',
            ip_address='192.168.1.100',
            user_agent='Mozilla/5.0 (Test Browser)',
            success=True
        )
        
        self.assertEqual(log_entry.file_upload, self.file_upload)
        self.assertEqual(log_entry.accessed_by, self.user)
        self.assertEqual(log_entry.access_type, 'download')
        self.assertTrue(log_entry.success)
        self.assertIsNone(log_entry.error_message)
    
    def test_log_failed_access(self):
        """Test logging failed file access."""
        log_entry = FileAccessLog.objects.create(
            file_upload=self.file_upload,
            accessed_by=self.user,
            access_type='view',
            ip_address='192.168.1.100',
            success=False,
            error_message='File not found or access denied'
        )
        
        self.assertFalse(log_entry.success)
        self.assertEqual(log_entry.error_message, 'File not found or access denied')
    
    def test_anonymous_access_log(self):
        """Test logging anonymous file access."""
        log_entry = FileAccessLog.objects.create(
            file_upload=self.file_upload,
            access_type='view',
            ip_address='203.0.113.1',
            user_agent='Anonymous Browser',
            success=True,
            additional_data={
                'share_token': 'abc123xyz789',
                'referrer': 'https://example.com'
            }
        )
        
        self.assertIsNone(log_entry.accessed_by)  # Anonymous access
        self.assertIn('share_token', log_entry.additional_data)
    
    def test_get_access_statistics(self):
        """Test getting file access statistics."""
        # Create multiple access logs
        for i in range(5):
            FileAccessLog.objects.create(
                file_upload=self.file_upload,
                accessed_by=self.user if i % 2 == 0 else None,
                access_type='download' if i % 3 == 0 else 'view',
                ip_address=f'192.168.1.{100 + i}',
                success=True
            )
        
        # Test getting stats (this would be a method on the model or manager)
        total_accesses = FileAccessLog.objects.filter(
            file_upload=self.file_upload
        ).count()
        
        successful_accesses = FileAccessLog.objects.filter(
            file_upload=self.file_upload,
            success=True
        ).count()
        
        self.assertEqual(total_accesses, 5)
        self.assertEqual(successful_accesses, 5)
