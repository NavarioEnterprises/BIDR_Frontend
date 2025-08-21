"""
WebSocket consumers for real-time chat functionality.

Handles:
- Real-time messaging
- Typing indicators
- User presence
- Message delivery confirmations
- Live notifications
"""

import json
import asyncio
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth.models import User
from django.utils import timezone
from django.core.serializers import serialize
from chat_conversations.models import Conversation, ConversationParticipant
from chat_messaging.models import Message, TypingIndicator, MessageReadReceipt
from chat_core.models import UserProfile, AuditLog
from services.translation_service import get_translation_service
import logging

logger = logging.getLogger(__name__)


class ChatConsumer(AsyncWebsocketConsumer):
    """Main chat consumer for real-time messaging."""
    
    async def connect(self):
        """Handle WebSocket connection."""
        self.user = self.scope["user"]
        
        if not self.user.is_authenticated:
            await self.close(code=4001)
            return
        
        # Get conversation ID from URL
        self.conversation_id = self.scope['url_route']['kwargs']['conversation_id']
        self.room_group_name = f'chat_{self.conversation_id}'
        
        # Verify user has access to conversation
        has_access = await self.check_conversation_access()
        if not has_access:
            await self.close(code=4003)
            return
        
        # Join room group
        await self.channel_layer.group_add(
            self.room_group_name,
            self.channel_name
        )
        
        # Mark user as online
        await self.update_user_status(True)
        
        # Accept connection
        await self.accept()
        
        # Send user connected event to group
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'user_status_change',
                'user_id': self.user.id,
                'username': self.user.username,
                'status': 'online',
                'timestamp': timezone.now().isoformat()
            }
        )
        
        logger.info(f"User {self.user.username} connected to conversation {self.conversation_id}")
    
    async def disconnect(self, close_code):
        """Handle WebSocket disconnection."""
        if hasattr(self, 'room_group_name'):
            # Leave room group
            await self.channel_layer.group_discard(
                self.room_group_name,
                self.channel_name
            )
            
            # Mark user as offline
            await self.update_user_status(False)
            
            # Clear typing indicator
            await self.clear_typing_indicator()
            
            # Send user disconnected event to group
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'user_status_change',
                    'user_id': self.user.id,
                    'username': self.user.username,
                    'status': 'offline',
                    'timestamp': timezone.now().isoformat()
                }
            )
        
        logger.info(f"User {self.user.username} disconnected from conversation {self.conversation_id}")
    
    async def receive(self, text_data):
        """Handle incoming WebSocket messages."""
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            # Route message to appropriate handler
            if message_type == 'chat_message':
                await self.handle_chat_message(data)
            elif message_type == 'typing_start':
                await self.handle_typing_start(data)
            elif message_type == 'typing_stop':
                await self.handle_typing_stop(data)
            elif message_type == 'message_read':
                await self.handle_message_read(data)
            elif message_type == 'message_edit':
                await self.handle_message_edit(data)
            elif message_type == 'message_delete':
                await self.handle_message_delete(data)
            elif message_type == 'translate_request':
                await self.handle_translate_request(data)
            else:
                await self.send_error('Unknown message type')
                
        except json.JSONDecodeError:
            await self.send_error('Invalid JSON format')
        except Exception as e:
            logger.error(f"Error handling message: {str(e)}")
            await self.send_error('Internal server error')
    
    async def handle_chat_message(self, data):
        """Handle new chat message."""
        content = data.get('content', '').strip()
        reply_to_id = data.get('reply_to_id')
        message_type = data.get('message_type', 'text')
        
        if not content:
            await self.send_error('Message content is required')
            return
        
        # Check if user can send messages
        can_send = await self.check_send_permission()
        if not can_send:
            await self.send_error('You do not have permission to send messages')
            return
        
        # Create message
        message = await self.create_message(
            content=content,
            message_type=message_type,
            reply_to_id=reply_to_id
        )
        
        if message:
            # Send message to group
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    'type': 'chat_message_broadcast',
                    'message_id': str(message.id),
                    'content': message.content,
                    'sender_id': message.sender.id,
                    'sender_username': message.sender.username,
                    'message_type': message.message_type,
                    'reply_to_id': str(message.reply_to.id) if message.reply_to else None,
                    'timestamp': message.created_at.isoformat(),
                    'client_message_id': data.get('client_message_id')
                }
            )
            
            # Clear typing indicator for sender
            await self.clear_typing_indicator()
    
    async def handle_typing_start(self, data):
        """Handle typing indicator start."""
        await self.set_typing_indicator(True)
        
        # Broadcast to other users in room
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_indicator_broadcast',
                'user_id': self.user.id,
                'username': self.user.username,
                'is_typing': True,
                'timestamp': timezone.now().isoformat()
            }
        )
    
    async def handle_typing_stop(self, data):
        """Handle typing indicator stop."""
        await self.set_typing_indicator(False)
        
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'typing_indicator_broadcast',
                'user_id': self.user.id,
                'username': self.user.username,
                'is_typing': False,
                'timestamp': timezone.now().isoformat()
            }
        )
    
    async def handle_message_read(self, data):
        """Handle message read receipt."""
        message_id = data.get('message_id')
        if message_id:
            await self.mark_message_as_read(message_id)
    
    async def handle_message_edit(self, data):
        """Handle message edit."""
        # Implementation for message editing
        pass
    
    async def handle_message_delete(self, data):
        """Handle message deletion."""
        # Implementation for message deletion
        pass
    
    async def handle_translate_request(self, data):
        """Handle translation request."""
        message_id = data.get('message_id')
        target_language = data.get('target_language', 'en')
        
        if not message_id:
            await self.send_error('Message ID is required for translation')
            return
        
        try:
            # Get message content
            message = await self.get_message(message_id)
            if not message:
                await self.send_error('Message not found')
                return
            
            # Translate message
            translation_service = get_translation_service()
            result = await translation_service.translate_text(
                text=message.content,
                target_language=target_language
            )
            
            # Send translation back to requesting user
            await self.send(text_data=json.dumps({
                'type': 'translation_result',
                'message_id': message_id,
                'original_text': message.content,
                'translated_text': result['translated_text'],
                'source_language': result['detected_source_language'],
                'target_language': target_language,
                'provider': result['provider'],
                'confidence': result['confidence']
            }))
            
        except Exception as e:
            logger.error(f"Translation error: {str(e)}")
            await self.send_error('Translation failed')
    
    # Broadcast handlers
    async def chat_message_broadcast(self, event):
        """Send message to WebSocket."""
        # Don't send message back to sender
        if event['sender_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'message',
                'message_id': event['message_id'],
                'content': event['content'],
                'sender_id': event['sender_id'],
                'sender_username': event['sender_username'],
                'message_type': event['message_type'],
                'reply_to_id': event['reply_to_id'],
                'timestamp': event['timestamp']
            }))
        else:
            # Send confirmation to sender
            await self.send(text_data=json.dumps({
                'type': 'message_sent',
                'message_id': event['message_id'],
                'client_message_id': event.get('client_message_id'),
                'timestamp': event['timestamp']
            }))
    
    async def typing_indicator_broadcast(self, event):
        """Send typing indicator to WebSocket."""
        # Don't send typing indicator back to sender
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'typing_indicator',
                'user_id': event['user_id'],
                'username': event['username'],
                'is_typing': event['is_typing'],
                'timestamp': event['timestamp']
            }))
    
    async def user_status_change(self, event):
        """Send user status change to WebSocket."""
        # Don't send status back to the user themselves
        if event['user_id'] != self.user.id:
            await self.send(text_data=json.dumps({
                'type': 'user_status',
                'user_id': event['user_id'],
                'username': event['username'],
                'status': event['status'],
                'timestamp': event['timestamp']
            }))
    
    # Helper methods
    async def send_error(self, message):
        """Send error message to client."""
        await self.send(text_data=json.dumps({
            'type': 'error',
            'message': message,
            'timestamp': timezone.now().isoformat()
        }))
    
    @database_sync_to_async
    def check_conversation_access(self):
        """Check if user has access to conversation."""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            return conversation.can_user_access(self.user)
        except Conversation.DoesNotExist:
            return False
    
    @database_sync_to_async
    def check_send_permission(self):
        """Check if user can send messages."""
        try:
            participant = ConversationParticipant.objects.get(
                conversation_id=self.conversation_id,
                user=self.user
            )
            return participant.can_perform_action('send_message')
        except ConversationParticipant.DoesNotExist:
            return False
    
    @database_sync_to_async
    def create_message(self, content, message_type='text', reply_to_id=None):
        """Create a new message."""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            
            reply_to = None
            if reply_to_id:
                try:
                    reply_to = Message.objects.get(id=reply_to_id, conversation=conversation)
                except Message.DoesNotExist:
                    pass
            
            message = Message.objects.create(
                conversation=conversation,
                sender=self.user,
                content=content,
                message_type=message_type,
                reply_to=reply_to
            )
            
            return message
            
        except Conversation.DoesNotExist:
            return None
    
    @database_sync_to_async
    def get_message(self, message_id):
        """Get message by ID."""
        try:
            return Message.objects.get(
                id=message_id,
                conversation_id=self.conversation_id
            )
        except Message.DoesNotExist:
            return None
    
    @database_sync_to_async
    def update_user_status(self, is_online):
        """Update user online status."""
        try:
            profile = self.user.chat_profile
            profile.last_seen = timezone.now()
            if hasattr(profile, 'last_activity'):
                profile.last_activity = timezone.now()
            profile.save()
        except UserProfile.DoesNotExist:
            pass
    
    @database_sync_to_async
    def set_typing_indicator(self, is_typing):
        """Set typing indicator for user."""
        try:
            conversation = Conversation.objects.get(id=self.conversation_id)
            
            if is_typing:
                TypingIndicator.objects.update_or_create(
                    conversation=conversation,
                    user=self.user,
                    defaults={
                        'is_typing': True,
                        'last_typing_at': timezone.now()
                    }
                )
            else:
                TypingIndicator.objects.filter(
                    conversation=conversation,
                    user=self.user
                ).update(is_typing=False)
                
        except Conversation.DoesNotExist:
            pass
    
    @database_sync_to_async
    def clear_typing_indicator(self):
        """Clear typing indicator for user."""
        try:
            TypingIndicator.objects.filter(
                conversation_id=self.conversation_id,
                user=self.user
            ).update(is_typing=False)
        except:
            pass
    
    @database_sync_to_async
    def mark_message_as_read(self, message_id):
        """Mark message as read by user."""
        try:
            message = Message.objects.get(
                id=message_id,
                conversation_id=self.conversation_id
            )
            
            # Create read receipt if it doesn't exist
            MessageReadReceipt.objects.get_or_create(
                message=message,
                user=self.user,
                defaults={'read_at': timezone.now()}
            )
            
            # Update participant's last read timestamp
            ConversationParticipant.objects.filter(
                conversation_id=self.conversation_id,
                user=self.user
            ).update(last_read_at=timezone.now())
            
        except (Message.DoesNotExist, ConversationParticipant.DoesNotExist):
            pass


class NotificationConsumer(AsyncWebsocketConsumer):
    """Consumer for real-time notifications."""
    
    async def connect(self):
        """Handle WebSocket connection for notifications."""
        self.user = self.scope["user"]
        
        if not self.user.is_authenticated:
            await self.close(code=4001)
            return
        
        # User-specific notification channel
        self.notification_group_name = f'notifications_{self.user.id}'
        
        # Join notification group
        await self.channel_layer.group_add(
            self.notification_group_name,
            self.channel_name
        )
        
        await self.accept()
        logger.info(f"User {self.user.username} connected to notifications")
    
    async def disconnect(self, close_code):
        """Handle notification WebSocket disconnection."""
        if hasattr(self, 'notification_group_name'):
            await self.channel_layer.group_discard(
                self.notification_group_name,
                self.channel_name
            )
        logger.info(f"User {self.user.username} disconnected from notifications")
    
    async def receive(self, text_data):
        """Handle incoming notification commands."""
        try:
            data = json.loads(text_data)
            command = data.get('command')
            
            if command == 'mark_read':
                notification_id = data.get('notification_id')
                await self.mark_notification_read(notification_id)
            elif command == 'get_unread_count':
                count = await self.get_unread_count()
                await self.send(text_data=json.dumps({
                    'type': 'unread_count',
                    'count': count
                }))
                
        except json.JSONDecodeError:
            await self.send_error('Invalid JSON format')
    
    # Notification broadcast handlers
    async def send_notification(self, event):
        """Send notification to user."""
        await self.send(text_data=json.dumps({
            'type': 'notification',
            'id': event['id'],
            'title': event['title'],
            'body': event['body'],
            'category': event.get('category', 'general'),
            'timestamp': event['timestamp'],
            'read': False
        }))
    
    @database_sync_to_async
    def mark_notification_read(self, notification_id):
        """Mark notification as read."""
        from chat_notifications.models import Notification
        try:
            notification = Notification.objects.get(
                id=notification_id,
                recipient=self.user
            )
            notification.mark_as_read()
        except Notification.DoesNotExist:
            pass
    
    @database_sync_to_async
    def get_unread_count(self):
        """Get unread notification count."""
        from chat_notifications.models import Notification
        return Notification.objects.filter(
            recipient=self.user,
            status='delivered'
        ).count()
    
    async def send_error(self, message):
        """Send error message."""
        await self.send(text_data=json.dumps({
            'type': 'error',
            'message': message,
            'timestamp': timezone.now().isoformat()
        }))
