"""
Test suite for chat_messaging app

Tests cover:
- Message creation and management
- Message attachments
- Message reactions
- Read receipts
- Translation functionality
- Typing indicators
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
from django.utils import timezone
from django.core.files.uploadedfile import SimpleUploadedFile
from chat_conversations.models import Conversation, ConversationParticipant
from .models import (
    Message, MessageAttachment, MessageReaction, MessageReadReceipt,
    MessageTranslation, MessageMention, TypingIndicator, MessageDeletion
)


class MessageModelTest(TestCase):
    """Test Message model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@example.com',
            password='testpass123'
        )
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@example.com',
            password='testpass123'
        )
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            conversation_type='direct',
            buyer=self.user1
        )
        
        # Add participants
        ConversationParticipant.objects.create(
            conversation=self.conversation,
            user=self.user1,
            role='owner'
        )
        ConversationParticipant.objects.create(
            conversation=self.conversation,
            user=self.user2,
            role='participant'
        )
    
    def test_create_message(self):
        """Test creating a basic message."""
        message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Hello, this is a test message!',
            message_type='text'
        )
        
        self.assertEqual(message.conversation, self.conversation)
        self.assertEqual(message.sender, self.user1)
        self.assertEqual(message.content, 'Hello, this is a test message!')
        self.assertEqual(message.delivery_status, 'sent')
        self.assertIsNotNone(message.message_hash)
        
        # Check conversation update
        self.conversation.refresh_from_db()
        self.assertEqual(self.conversation.total_messages, 1)
        self.assertEqual(self.conversation.last_message_at, message.created_at)
    
    def test_message_with_reply(self):
        """Test creating a reply message."""
        # Create original message
        original_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Original message',
        )
        
        # Create reply
        reply_message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user2,
            content='This is a reply',
            reply_to=original_message
        )
        
        self.assertEqual(reply_message.reply_to, original_message)
        self.assertEqual(reply_message.thread_id, original_message.id)
        
        # Test reply chain
        nested_reply = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Nested reply',
            reply_to=reply_message
        )
        
        self.assertEqual(nested_reply.thread_id, original_message.id)
    
    def test_message_hash_generation(self):
        """Test message hash generation for deduplication."""
        message1 = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Test message'
        )
        
        message2 = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Test message'
        )
        
        # Hash should be different even for same content (different timestamps)
        self.assertNotEqual(message1.message_hash, message2.message_hash)
    
    def test_mark_message_as_read(self):
        """Test marking message as read."""
        message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Test message'
        )
        
        # Mark as read by user2
        receipt = message.mark_as_read(self.user2)
        
        self.assertIsNotNone(receipt)
        self.assertEqual(receipt.user, self.user2)
        self.assertEqual(receipt.message, message)
        
        # Check read by users
        read_users = message.get_read_by_users()
        self.assertIn(self.user2, read_users)
    
    def test_soft_delete_message(self):
        """Test soft deleting a message."""
        message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Message to be deleted'
        )
        
        # Soft delete
        message.soft_delete(deleted_by=self.user1)
        
        message.refresh_from_db()
        self.assertFalse(message.is_active)
        
        # Check deletion record
        deletion_record = MessageDeletion.objects.get(message=message)
        self.assertEqual(deletion_record.deleted_by, self.user1)
        self.assertEqual(deletion_record.deletion_reason, 'user_requested')


class MessageAttachmentTest(TestCase):
    """Test MessageAttachment model functionality."""
    
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
            content='Message with attachment',
            message_type='file'
        )
    
    def test_create_message_attachment(self):
        """Test creating message attachment."""
        # Create a simple uploaded file
        file_content = b'This is a test file content'
        uploaded_file = SimpleUploadedFile(
            'test.txt',
            file_content,
            content_type='text/plain'
        )
        
        attachment = MessageAttachment.objects.create(
            message=self.message,
            file=uploaded_file,
            filename='test.txt',
            file_size=len(file_content),
            file_type='document',
            mime_type='text/plain'
        )
        
        self.assertEqual(attachment.filename, 'test.txt')
        self.assertEqual(attachment.file_size, len(file_content))
        self.assertEqual(attachment.file_type, 'document')
        self.assertFalse(attachment.is_scanned)
    
    def test_file_size_display(self):
        """Test human readable file size display."""
        attachment = MessageAttachment.objects.create(
            message=self.message,
            file=SimpleUploadedFile('test.txt', b'content'),
            filename='test.txt',
            file_size=1024,
            file_type='document',
            mime_type='text/plain'
        )
        
        size_display = attachment.get_file_size_display()
        self.assertEqual(size_display, '1.0 KB')


class MessageReactionTest(TestCase):
    """Test MessageReaction model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@example.com'
        )
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@example.com'
        )
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            buyer=self.user1
        )
        
        self.message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='React to this message!'
        )
    
    def test_create_message_reaction(self):
        """Test creating message reaction."""
        reaction = MessageReaction.objects.create(
            message=self.message,
            user=self.user2,
            reaction_type='like'
        )
        
        self.assertEqual(reaction.message, self.message)
        self.assertEqual(reaction.user, self.user2)
        self.assertEqual(reaction.reaction_type, 'like')
    
    def test_unique_user_reaction_per_type(self):
        """Test unique constraint on user reaction per type."""
        # Create first reaction
        MessageReaction.objects.create(
            message=self.message,
            user=self.user2,
            reaction_type='like'
        )
        
        # Same user can't react with same type again
        with self.assertRaises(Exception):
            MessageReaction.objects.create(
                message=self.message,
                user=self.user2,
                reaction_type='like'
            )
        
        # But can react with different type
        reaction2 = MessageReaction.objects.create(
            message=self.message,
            user=self.user2,
            reaction_type='love'
        )
        
        self.assertEqual(reaction2.reaction_type, 'love')


class MessageTranslationTest(TestCase):
    """Test MessageTranslation model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com'
        )
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            buyer=self.user
        )
        
        self.message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user,
            content='Hello world!'
        )
    
    def test_create_message_translation(self):
        """Test creating message translation."""
        translation = MessageTranslation.objects.create(
            message=self.message,
            target_language='es',
            translated_content='¡Hola mundo!',
            source_language='en',
            translation_service='google',
            confidence_score=0.95
        )
        
        self.assertEqual(translation.message, self.message)
        self.assertEqual(translation.target_language, 'es')
        self.assertEqual(translation.translated_content, '¡Hola mundo!')
        self.assertTrue(translation.is_auto_translation)
        self.assertFalse(translation.human_reviewed)


class TypingIndicatorTest(TestCase):
    """Test TypingIndicator model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user = User.objects.create_user(
            username='testuser',
            email='test@example.com'
        )
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            buyer=self.user
        )
    
    def test_create_typing_indicator(self):
        """Test creating typing indicator."""
        indicator = TypingIndicator.objects.create(
            conversation=self.conversation,
            user=self.user,
            is_typing=True
        )
        
        self.assertEqual(indicator.conversation, self.conversation)
        self.assertEqual(indicator.user, self.user)
        self.assertTrue(indicator.is_typing)
        self.assertIsNotNone(indicator.last_typing_at)
    
    def test_typing_indicator_staleness(self):
        """Test typing indicator staleness check."""
        # Create indicator with old timestamp
        old_time = timezone.now() - timezone.timedelta(seconds=30)
        indicator = TypingIndicator.objects.create(
            conversation=self.conversation,
            user=self.user,
            is_typing=True,
            last_typing_at=old_time
        )
        
        # Should be stale after 10 seconds
        self.assertTrue(indicator.is_stale(seconds=10))
        
        # Should not be stale within 60 seconds
        self.assertFalse(indicator.is_stale(seconds=60))


class MessageMentionTest(TestCase):
    """Test MessageMention model functionality."""
    
    def setUp(self):
        """Set up test data."""
        self.user1 = User.objects.create_user(
            username='user1',
            email='user1@example.com'
        )
        self.user2 = User.objects.create_user(
            username='user2',
            email='user2@example.com'
        )
        
        self.conversation = Conversation.objects.create(
            title='Test Conversation',
            buyer=self.user1
        )
        
        self.message = Message.objects.create(
            conversation=self.conversation,
            sender=self.user1,
            content='Hey @user2, check this out!'
        )
    
    def test_create_message_mention(self):
        """Test creating message mention."""
        mention = MessageMention.objects.create(
            message=self.message,
            mentioned_user=self.user2,
            mention_text='@user2',
            position_start=4,
            position_end=10
        )
        
        self.assertEqual(mention.message, self.message)
        self.assertEqual(mention.mentioned_user, self.user2)
        self.assertEqual(mention.mention_text, '@user2')
        self.assertFalse(mention.notification_sent)
        self.assertFalse(mention.notification_read)
