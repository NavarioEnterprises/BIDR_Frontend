from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth.models import User
from django.db.models import Q
from .models import Conversation, ConversationParticipant
from .serializers import ConversationSerializer, ConversationCreateSerializer
from chat_messaging.models import Message, MessageAttachment
from chat_messaging.serializers import MessageSerializer, MessageCreateSerializer


class ConversationViewSet(viewsets.ModelViewSet):
    """ViewSet for managing conversations."""
    
    serializer_class = ConversationSerializer
    permission_classes = [permissions.AllowAny]
    
    def get_queryset(self):
        """Return conversations for the current user or all conversations if unauthenticated."""
        if self.request.user.is_authenticated:
            user = self.request.user
            return Conversation.objects.filter(
                Q(buyer=user) | Q(participants=user)
            ).distinct().select_related('buyer').prefetch_related('participants')
        else:
            # For unauthenticated users, return all conversations
            return Conversation.objects.all().select_related('buyer').prefetch_related('participants')
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ConversationCreateSerializer
        return ConversationSerializer
    
    def perform_create(self, serializer):
        """Create a new conversation with current user as buyer or anonymous user."""
        if self.request.user.is_authenticated:
            conversation = serializer.save(buyer=self.request.user)
            # Add buyer as participant
            conversation.add_participant(self.request.user, role='owner')
        else:
            # For unauthenticated users, create conversation without buyer
            conversation = serializer.save()
        return conversation
    
    @action(detail=True, methods=['get'])
    def messages(self, request, pk=None):
        """Get all messages for a conversation."""
        conversation = self.get_object()
        
        # For authenticated users, check access; for unauthenticated users, allow all
        if request.user.is_authenticated and not conversation.can_user_access(request.user):
            return Response(
                {'error': 'You do not have access to this conversation'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        messages = Message.objects.filter(
            conversation=conversation,
            is_active=True
        ).order_by('created_at')
        
        serializer = MessageSerializer(messages, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def send_message(self, request, pk=None):
        """Send a message to a conversation."""
        conversation = self.get_object()
        
        # For authenticated users, check access and permissions
        if request.user.is_authenticated:
            # Check if user has access to this conversation
            if not conversation.can_user_access(request.user):
                return Response(
                    {'error': 'You do not have access to this conversation'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if user can send messages
            try:
                participant = ConversationParticipant.objects.get(
                    conversation=conversation,
                    user=request.user
                )
                if not participant.can_perform_action('send_message'):
                    return Response(
                        {'error': 'You do not have permission to send messages'},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except ConversationParticipant.DoesNotExist:
                return Response(
                    {'error': 'You are not a participant in this conversation'},
                    status=status.HTTP_403_FORBIDDEN
                )
        # For unauthenticated users, allow sending messages without permission checks
        
        # Create message
        message_data = {
            'conversation': conversation.id,
            'content': request.data.get('content', ''),
            'message_type': request.data.get('message_type', 'text'),
            'sender_name': request.data.get('sender_name', ''),
            'sender_role': request.data.get('sender_role', 'user'),
        }
        
        message_serializer = MessageCreateSerializer(data=message_data, context={'request': request})
        if message_serializer.is_valid():
            message = message_serializer.save()
            
            # Update conversation metadata
            conversation.total_messages += 1
            conversation.last_message_at = message.created_at
            conversation.save(update_fields=['total_messages', 'last_message_at'])
            
            return Response(message_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(message_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def send_attachment(self, request, pk=None):
        """Send a file attachment to a conversation."""
        conversation = self.get_object()
        
        # For authenticated users, check access and permissions
        if request.user.is_authenticated:
            # Check if user has access to this conversation
            if not conversation.can_user_access(request.user):
                return Response(
                    {'error': 'You do not have access to this conversation'},
                    status=status.HTTP_403_FORBIDDEN
                )
            
            # Check if user can send messages
            try:
                participant = ConversationParticipant.objects.get(
                    conversation=conversation,
                    user=request.user
                )
                if not participant.can_perform_action('send_message'):
                    return Response(
                        {'error': 'You do not have permission to send attachments'},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except ConversationParticipant.DoesNotExist:
                return Response(
                    {'error': 'You are not a participant in this conversation'},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Get uploaded file
        if 'attachment' not in request.FILES:
            return Response(
                {'error': 'No file uploaded'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        uploaded_file = request.FILES['attachment']
        
        # Validate file size (10MB limit)
        max_size = 10 * 1024 * 1024  # 10MB
        if uploaded_file.size > max_size:
            return Response(
                {'error': 'File size exceeds 10MB limit'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Create message with attachment
        message_data = {
            'conversation': conversation.id,
            'content': f'Attachment: {uploaded_file.name}',
            'message_type': request.data.get('message_type', 'file'),
            'sender_name': request.data.get('sender_name', ''),
            'sender_role': request.data.get('sender_role', 'user'),
        }
        
        message_serializer = MessageCreateSerializer(data=message_data, context={'request': request})
        if message_serializer.is_valid():
            message = message_serializer.save()
            
            # Create attachment
            import mimetypes
            mime_type, _ = mimetypes.guess_type(uploaded_file.name)
            
            # Determine file type based on mime type
            file_type = 'other'
            if mime_type:
                if mime_type.startswith('image/'):
                    file_type = 'image'
                elif mime_type.startswith('video/'):
                    file_type = 'video'
                elif mime_type.startswith('audio/'):
                    file_type = 'audio'
                elif mime_type in ['application/pdf', 'application/msword', 
                                 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                                 'text/plain']:
                    file_type = 'document'
                elif mime_type in ['application/zip', 'application/x-rar-compressed']:
                    file_type = 'archive'
            
            attachment = MessageAttachment.objects.create(
                message=message,
                file=uploaded_file,
                filename=uploaded_file.name,
                file_size=uploaded_file.size,
                file_type=file_type,
                mime_type=mime_type or 'application/octet-stream',
            )
            
            # Update conversation metadata
            conversation.total_messages += 1
            conversation.last_message_at = message.created_at
            conversation.save(update_fields=['total_messages', 'last_message_at'])
            
            # Return message with attachment data
            message_data = MessageSerializer(message, context={'request': request}).data
            return Response(message_data, status=status.HTTP_201_CREATED)
        
        return Response(message_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def by_request(self, request):
        """Get conversation by request_id."""
        request_id = request.query_params.get('request_id')
        if not request_id:
            return Response(
                {'error': 'request_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            if request.user.is_authenticated:
                # For authenticated users, filter by participation
                conversation = Conversation.objects.get(
                    request_id=request_id,
                    participants=request.user
                )
            else:
                # For unauthenticated users, get any conversation with this request_id
                conversation = Conversation.objects.filter(
                    request_id=request_id
                ).first()
                if not conversation:
                    raise Conversation.DoesNotExist
            
            serializer = self.get_serializer(conversation)
            return Response(serializer.data)
        except Conversation.DoesNotExist:
            return Response(
                {'error': 'Conversation not found for this request'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=False, methods=['post'])
    def create_for_request(self, request):
        """Create a conversation for a specific request_id."""
        request_id = request.data.get('request_id')

        if not request_id:
            return Response(
                {'error': 'request_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check if conversation already exists for this request
        existing_conversation = Conversation.objects.filter(request_id=request_id).first()
        if existing_conversation:
            serializer = self.get_serializer(existing_conversation)
            return Response(serializer.data)
        
        # Create new conversation
        conversation_data = {
            'request_id': request_id,
            'title': request.data.get('title', f'Conversation for Request #{request_id}'),
            'conversation_type': request.data.get('conversation_type', 'product_inquiry'),
        }
        
        serializer = ConversationCreateSerializer(data=conversation_data)
        if serializer.is_valid():
            # Create conversation
            if request.user.is_authenticated:
                conversation = serializer.save(buyer=request.user)
                # Add buyer as participant
                conversation.add_participant(request.user, role='owner')
            else:
                # For unauthenticated users, create conversation without buyer
                conversation = serializer.save()
            
            response_serializer = self.get_serializer(conversation)
            return Response(response_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
