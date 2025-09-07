import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../global_values.dart';
import '../models/request_models.dart';
import '../models/moderation_models.dart';
import '../services/chat_service.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupChat groupChat;

  const GroupChatScreen({Key? key, required this.groupChat}) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  Message? _replyingTo;

  // Backend integration
  ChatConversation? _backendConversation;
  List<ChatMessage> _backendMessages = [];
  bool _isLoading = false;
  bool _useBackend = true; // Toggle between backend and local messages

  // File attachment handling
  bool _isUploadingAttachment = false;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB in bytes

  // Moderation state
  UserModerationStatus? _userModerationStatus;
  List<ModerationWarning> _userWarnings = [];
  bool _isSuspended = false;
  String? _suspensionMessage;
  bool _showModerationPanel = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    if (!_useBackend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check user moderation status first
      await _loadUserModerationStatus();

      // Create or get conversation for this request
      final conversationData =
          await ChatService.createOrGetConversationForRequest(
            widget.groupChat.uuid,
          );

      if (conversationData != null) {
        _backendConversation = ChatConversation.fromJson(conversationData);

        // Load existing messages
        await _loadMessages();

        // Load user warnings
        await _loadUserWarnings();
      }
    } catch (e) {
      print('Error initializing chat: $e');
      // Fallback to local messages
      setState(() {
        _useBackend = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load user's moderation status
  Future<void> _loadUserModerationStatus() async {
    try {
      final status = await ChatService.getUserModerationStatus(
        Constants.myDisplayname,
      );
      if (status != null) {
        setState(() {
          _userModerationStatus = status;
          _isSuspended = status.isSuspended;
          _suspensionMessage = status.statusMessage;
        });
      }
    } catch (e) {
      print('Error loading user moderation status: $e');
    }
  }

  /// Load user's moderation warnings
  Future<void> _loadUserWarnings() async {
    try {
      final warnings = await ChatService.getUserWarnings(
        Constants.myDisplayname,
      );
      if (warnings != null) {
        setState(() {
          _userWarnings = warnings;
        });
      }
    } catch (e) {
      print('Error loading user warnings: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (_backendConversation == null) return;

    try {
      final messagesData = await ChatService.getMessages(
        _backendConversation!.id,
      );

      if (messagesData != null) {
        setState(() {
          _backendMessages = messagesData
              .map(
                (json) => ChatMessage.fromJson(json, Constants.myDisplayname),
              )
              .toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading messages: $e');
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Check if user is suspended before attempting to send
    if (_isSuspended) {
      _showSuspensionDialog();
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    if (_useBackend && _backendConversation != null) {
      // Send message through backend with moderation
      try {
        final messageResult = await ChatService.sendMessage(
          _backendConversation!.id,
          content,
          userId: Constants.myDisplayname,
        );

        if (messageResult['success'] == true) {
          // Message sent successfully
          await _loadMessages();
          await _loadUserModerationStatus(); // Refresh moderation status
          await _loadUserWarnings(); // Refresh warnings

          // Show notifications for filtered content or strikes
          if (messageResult['filtered'] == true) {
            _showContentFilteredNotification(messageResult['violations'] ?? []);
          }

          if (messageResult['strike_issued'] == true) {
            _showStrikeIssuedNotification();
          }
        } else if (messageResult['blocked'] == true) {
          // Message was blocked
          _messageController.text = content; // Restore message

          if (messageResult['reason'] == 'suspended') {
            setState(() {
              _isSuspended = true;
              _suspensionMessage = messageResult['status'];
            });
            _showSuspensionDialog();
          } else {
            _showMessageBlockedDialog(
              messageResult['message'] ??
                  'Message blocked due to content violations',
              List<String>.from(messageResult['violations'] ?? []),
            );
          }
        } else {
          // Failed to send - add back to text field
          _messageController.text = content;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                messageResult['message'] ??
                    'Failed to send message. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('Error sending message: $e');
        _messageController.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Fallback to local messages
      final newMessage = Message(
        sender: User(
          name: Constants.myDisplayname, // Current user name
          role: "Buyer", // Current user role
          profileImageUrl: null,
        ),
        content: content,
        timestamp: DateTime.now(),
        isReply: _replyingTo != null,
      );

      setState(() {
        if (_replyingTo != null) {
          // Add as a reply to the specific message
          _replyingTo!.replies.add(newMessage);
          _replyingTo = null;
        } else {
          // Add as a new top-level message
          widget.groupChat.messages.add(newMessage);
        }
      });

      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleReply(Message message) {
    setState(() {
      _replyingTo = message;
    });
    _messageFocusNode.requestFocus();
    _messageController.text = "@${message.sender.name} ";
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
    _messageController.clear();
  }

  // Handle file attachment
  Future<void> _handleAttachment() async {
    try {
      // Show file type selection dialog
      final String? selectedType = await _showAttachmentTypeDialog();
      if (selectedType == null) return;

      FilePickerResult? result;
      List<String> allowedExtensions = [];
      String messageType = 'file';

      switch (selectedType) {
        case 'image':
          allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
          messageType = 'image';
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            allowMultiple: false,
          );
          break;
        case 'document':
          allowedExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf'];
          messageType = 'file';
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            allowMultiple: false,
          );
          break;
        case 'audio':
          allowedExtensions = ['mp3', 'wav', 'aac', 'm4a', 'ogg'];
          messageType = 'audio';
          result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            allowMultiple: false,
          );
          break;
        default:
          return;
      }

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Check file size (10MB limit)
        if (file.size > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File size must be less than 10MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Check if file extension is allowed
        final fileExtension = file.extension?.toLowerCase();
        if (fileExtension == null ||
            !allowedExtensions.contains(fileExtension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File type not supported'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        await _uploadAttachment(file, messageType);
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload attachment to backend
  Future<void> _uploadAttachment(PlatformFile file, String messageType) async {
    setState(() {
      _isUploadingAttachment = true;
    });

    try {
      if (_useBackend && _backendConversation != null) {
        // Upload to backend
        final result = await ChatService.sendAttachment(
          _backendConversation!.id,
          file,
          messageType: messageType,
        );

        if (result['success'] == true) {
          // Reload messages to get the new attachment message
          await _loadMessages();
          _scrollToBottom();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to upload attachment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Fallback to local message (for demo purposes)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attachment uploaded (local mode)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading attachment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload attachment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingAttachment = false;
      });
    }
  }

  // Show dialog to select attachment type
  Future<String?> _showAttachmentTypeDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Attachment Type',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.image, color: Colors.blue),
                title: Text('Images'),
                subtitle: Text('JPG, PNG, GIF (Max 10MB)'),
                onTap: () => Navigator.of(context).pop('image'),
              ),
              ListTile(
                leading: Icon(Icons.description, color: Colors.red),
                title: Text('Documents'),
                subtitle: Text('PDF, DOC, TXT (Max 10MB)'),
                onTap: () => Navigator.of(context).pop('document'),
              ),
              ListTile(
                leading: Icon(Icons.audiotrack, color: Colors.green),
                title: Text('Audio'),
                subtitle: Text('MP3, WAV, M4A (Max 10MB)'),
                onTap: () => Navigator.of(context).pop('audio'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Build message content based on message type
  Widget _buildMessageContent(
    String content,
    String messageType, {
    bool isReply = false,
    List<dynamic>? attachments,
  }) {
    switch (messageType.toLowerCase()) {
      case 'image':
        return _buildImageContent(
          content,
          isReply: isReply,
          attachments: attachments,
        );
      case 'file':
        return _buildFileContent(
          content,
          isReply: isReply,
          attachments: attachments,
        );
      case 'audio':
        return _buildAudioContent(
          content,
          isReply: isReply,
          attachments: attachments,
        );
      case 'video':
        return _buildVideoContent(
          content,
          isReply: isReply,
          attachments: attachments,
        );
      default:
        return Text(
          content,
          style: GoogleFonts.manrope(
            color: Colors.black87,
            fontSize: isReply ? 12 : 14,
            fontWeight: FontWeight.w400,
          ),
        );
    }
  }

  // Build image attachment content
  Widget _buildImageContent(
    String content, {
    bool isReply = false,
    List<dynamic>? attachments,
  }) {
    if (attachments != null && attachments.isNotEmpty) {
      final attachment = attachments.first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isReply ? 200 : 300,
                maxHeight: isReply ? 150 : 200,
              ),
              child: Image.network(
                '${GlobalVariables.chatServiceUrl}${attachment['file']}',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: isReply ? 150 : 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isReply ? 100 : 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Image failed to load',
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          if (content.contains('Attachment:')) ...[
            SizedBox(height: 4),
            Text(
              content.replaceAll('Attachment: ', ''),
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: isReply ? 10 : 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }

    // Fallback for image messages without attachments
    return Row(
      children: [
        Icon(Icons.image, color: Colors.blue, size: isReply ? 16 : 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: GoogleFonts.manrope(
              color: Colors.black87,
              fontSize: isReply ? 12 : 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // Build file attachment content
  Widget _buildFileContent(
    String content, {
    bool isReply = false,
    List<dynamic>? attachments,
  }) {
    if (attachments != null && attachments.isNotEmpty) {
      final attachment = attachments.first;
      final fileType = attachment['file_type'] ?? 'document';
      final fileName = attachment['filename'] ?? 'Unknown file';
      final fileSize = attachment['file_size_display'] ?? '';

      IconData fileIcon;
      Color iconColor;

      switch (fileType) {
        case 'document':
          fileIcon = Icons.description;
          iconColor = Colors.red;
          break;
        case 'archive':
          fileIcon = Icons.archive;
          iconColor = Colors.orange;
          break;
        default:
          fileIcon = Icons.attach_file;
          iconColor = Colors.grey;
      }

      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(fileIcon, color: iconColor, size: isReply ? 20 : 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: GoogleFonts.manrope(
                      color: Colors.black87,
                      fontSize: isReply ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fileSize.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      fileSize,
                      style: GoogleFonts.manrope(
                        color: Colors.grey[600],
                        fontSize: isReply ? 10 : 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.download,
              color: Colors.grey[600],
              size: isReply ? 16 : 20,
            ),
          ],
        ),
      );
    }

    // Fallback for file messages without attachments
    return Row(
      children: [
        Icon(Icons.attach_file, color: Colors.grey, size: isReply ? 16 : 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: GoogleFonts.manrope(
              color: Colors.black87,
              fontSize: isReply ? 12 : 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // Build audio attachment content
  Widget _buildAudioContent(
    String content, {
    bool isReply = false,
    List<dynamic>? attachments,
  }) {
    if (attachments != null && attachments.isNotEmpty) {
      final attachment = attachments.first;
      final fileName = attachment['filename'] ?? 'Unknown audio';
      final fileSize = attachment['file_size_display'] ?? '';
      final duration = attachment['duration'];

      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.audiotrack,
              color: Colors.green,
              size: isReply ? 20 : 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: GoogleFonts.manrope(
                      color: Colors.black87,
                      fontSize: isReply ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      if (duration != null) ...[
                        Text(
                          '${duration}s',
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: isReply ? 10 : 12,
                          ),
                        ),
                        if (fileSize.isNotEmpty)
                          Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                      if (fileSize.isNotEmpty)
                        Text(
                          fileSize,
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: isReply ? 10 : 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: Colors.green,
              size: isReply ? 20 : 24,
            ),
          ],
        ),
      );
    }

    // Fallback for audio messages without attachments
    return Row(
      children: [
        Icon(Icons.audiotrack, color: Colors.green, size: isReply ? 16 : 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: GoogleFonts.manrope(
              color: Colors.black87,
              fontSize: isReply ? 12 : 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // Build video attachment content
  Widget _buildVideoContent(
    String content, {
    bool isReply = false,
    List<dynamic>? attachments,
  }) {
    if (attachments != null && attachments.isNotEmpty) {
      final attachment = attachments.first;
      final fileName = attachment['filename'] ?? 'Unknown video';
      final fileSize = attachment['file_size_display'] ?? '';
      final duration = attachment['duration'];

      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.videocam, color: Colors.purple, size: isReply ? 20 : 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: GoogleFonts.manrope(
                      color: Colors.black87,
                      fontSize: isReply ? 12 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      if (duration != null) ...[
                        Text(
                          '${duration}s',
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: isReply ? 10 : 12,
                          ),
                        ),
                        if (fileSize.isNotEmpty)
                          Text(
                            ' • ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                      if (fileSize.isNotEmpty)
                        Text(
                          fileSize,
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: isReply ? 10 : 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.play_arrow,
              color: Colors.purple,
              size: isReply ? 20 : 24,
            ),
          ],
        ),
      );
    }

    // Fallback for video messages without attachments
    return Row(
      children: [
        Icon(Icons.videocam, color: Colors.purple, size: isReply ? 16 : 20),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: GoogleFonts.manrope(
              color: Colors.black87,
              fontSize: isReply ? 12 : 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Color _getUserColor(String role) {
    switch (role) {
      case "Buyer":
        return Constants.ctaColorLight;
      case "Seller":
        return Constants.ftaColorLight;
      default:
        return Colors.green[800]!;
    }
  }

  Color _getUserTextColor(String role) {
    switch (role) {
      case "Buyer":
        return Constants.ctaColorLight;
      case "Seller":
        return Constants.ftaColorLight;
      default:
        return Colors.green[800]!;
    }
  }

  Widget _buildMessageItem(Message message, {bool isReply = false}) {
    final isCurrentUser = message.sender.name == Constants.myDisplayname;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: 8, left: isReply ? 48 : 0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: isReply ? BoxDecoration() : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: isReply ? 28 : 36,
              height: isReply ? 28 : 36,
              decoration: BoxDecoration(
                color: _getUserColor(message.sender.role),
                shape: BoxShape.circle,
              ),
              child: message.sender.profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        message.sender.profileImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildAvatarFallback(message.sender, isReply);
                        },
                      ),
                    )
                  : _buildAvatarFallback(message.sender, isReply),
            ),
            SizedBox(width: 12),

            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Info
                  Row(
                    children: [
                      Text(
                        message.sender.name,
                        style: GoogleFonts.manrope(
                          color: _getUserTextColor(message.sender.role),
                          fontSize: isReply ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isReply ? 6 : 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: message.sender.role.contains("Seller")
                              ? Constants.ctaColorLight
                              : Constants.ftaColorLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message.sender.role,
                          style: GoogleFonts.manrope(
                            color: _getUserTextColor(message.sender.role),
                            fontSize: isReply ? 8 : 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.manrope(
                          color: Colors.grey[500],
                          fontSize: isReply ? 9 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Message Bubble
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.all(isReply ? 8 : 12),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentUser
                            ? Colors.blue[200]!
                            : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: _buildMessageContent(
                      message.content,
                      'text', // Local messages are always text for now
                      isReply: isReply,
                      attachments:
                          null, // Local messages don't have attachments yet
                    ),
                  ),

                  // Reply Button (only for top-level messages from other users)
                  if (!isCurrentUser && !isReply) ...[
                    SizedBox(height: 6),
                    TextButton(
                      onPressed: () => _handleReply(message),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size(0, 0),
                      ),
                      child: Text(
                        "Reply",
                        style: GoogleFonts.manrope(
                          color: Colors.blue[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // Replies
                  if (message.replies.isNotEmpty) ...[
                    SizedBox(height: 8),
                    ...message.replies.map(
                      (reply) => _buildMessageItem(reply, isReply: true),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendMessageItem(ChatMessage message, {bool isReply = false}) {
    final isCurrentUser = message.senderName == Constants.myDisplayname;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: 8, left: isReply ? 48 : 0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: isReply ? BoxDecoration() : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: isReply ? 28 : 36,
              height: isReply ? 28 : 36,
              decoration: BoxDecoration(
                color: _getUserColor(message.senderRole),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : "?",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: isReply ? 12 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),

            // Message Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Info
                  Row(
                    children: [
                      Text(
                        message.senderName,
                        style: GoogleFonts.manrope(
                          color: _getUserTextColor(message.senderRole),
                          fontSize: isReply ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isReply ? 6 : 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: message.senderRole.contains("Seller")
                              ? Constants.ctaColorLight
                              : Constants.ftaColorLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message.senderRole,
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: isReply ? 8 : 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatTime(message.timestamp),
                        style: GoogleFonts.manrope(
                          color: Colors.grey[500],
                          fontSize: isReply ? 9 : 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  // Message Bubble
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.all(isReply ? 8 : 12),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue[100] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentUser
                            ? Colors.blue[200]!
                            : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: _buildMessageContent(
                      message.content,
                      message.messageType,
                      isReply: isReply,
                      attachments: message.attachments,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          SizedBox(height: 24),
          Container(
            height: 50,
            width: MediaQuery.of(context).size.width,
            color: Constants.ctaColorLight,
            padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  icon: Icon(Icons.arrow_back_ios_new, size: 20),
                ),
                SizedBox(width: 16),
                Text(
                  'Request ',
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'Information',
                  style: GoogleFonts.manrope(
                    color: Constants.ftaColorLight,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                constraints: BoxConstraints(maxWidth: 1400),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          HugeIcons.strokeRoundedInformationCircle,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Description",
                          style: GoogleFonts.manrope(
                            color: Constants.ftaColorLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "UUID: ${(widget.groupChat.uuid?.isNotEmpty == true ? widget.groupChat.uuid!.substring(0, widget.groupChat.uuid!.length < 8 ? widget.groupChat.uuid!.length : 8) : 'N/A').toUpperCase()}",
                      style: GoogleFonts.manrope(
                        color: Constants.ftaColorLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      widget.groupChat.request.description,
                      style: GoogleFonts.manrope(
                        color: Colors.blue[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Container(
                      width: double.infinity,
                      height: 500,
                      constraints: BoxConstraints(maxWidth: 1400),
                      child: _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _useBackend
                                  ? _backendMessages.length
                                  : widget.groupChat.messages.length,
                              physics: ScrollPhysics(),
                              itemBuilder: (context, index) {
                                if (_useBackend) {
                                  final backendMessage =
                                      _backendMessages[index];
                                  return _buildBackendMessageItem(
                                    backendMessage,
                                  );
                                } else {
                                  final message =
                                      widget.groupChat.messages[index];
                                  return _buildMessageItem(message);
                                }
                              },
                            ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      constraints: BoxConstraints(maxWidth: 1400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Constants.ftaColorLight,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Attachment Button
                          IconButton(
                            onPressed: _isUploadingAttachment
                                ? null
                                : _handleAttachment,
                            icon: _isUploadingAttachment
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : Icon(
                                    Icons.attach_file,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                          ),

                          // Text Input
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                controller: _messageController,
                                focusNode: _messageFocusNode,
                                decoration: InputDecoration(
                                  hintText: _replyingTo != null
                                      ? "Reply to ${_replyingTo!.sender.name}..."
                                      : "Send information",
                                  hintStyle: GoogleFonts.manrope(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),

                          SizedBox(width: 8),

                          // Send Button
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: _sendMessage,
                              icon: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                ],
              ),
            ),
          ),

          // Message Input
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(User user, [bool isReply = false]) {
    return Center(
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
        style: GoogleFonts.manrope(
          color: user.role.contains("Seller")
              ? Constants.ctaColorLight
              : Constants.ftaColorLight,
          fontSize: isReply ? 12 : 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return "${difference.inDays}d ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }

  /// Show suspension dialog
  void _showSuspensionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Account Suspended',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your account has been temporarily suspended from sending messages.',
                style: GoogleFonts.manrope(),
              ),
              SizedBox(height: 12),
              if (_suspensionMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _suspensionMessage!,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Understand'),
            ),
            if (_userModerationStatus != null &&
                _userModerationStatus!.activeStrikes > 0) ...[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showAppealDialog();
                },
                child: Text('Appeal'),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Show message blocked dialog
  void _showMessageBlockedDialog(String message, List<String> violations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Message Blocked',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: GoogleFonts.manrope()),
              if (violations.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  'Violations detected:',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                ...violations.map(
                  (violation) => Padding(
                    padding: EdgeInsets.only(left: 8, top: 2),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 6, color: Colors.red),
                        SizedBox(width: 6),
                        Text(
                          violation,
                          style: GoogleFonts.manrope(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  'Please revise your message to comply with our community guidelines and try again.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  /// Show content filtered notification
  void _showContentFilteredNotification(List<String> violations) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.filter_alt, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Message sent with content filtering applied (${violations.join(', ')})',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  /// Show strike issued notification
  void _showStrikeIssuedNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'A strike has been issued for your message. Please follow community guidelines.',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View Warnings',
          textColor: Colors.white,
          onPressed: () {
            _showModerationPanel2();
          },
        ),
      ),
    );
  }

  /// Show moderation panel with warnings and strikes
  void _showModerationPanel2() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Moderation Status',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // User status summary
              if (_userModerationStatus != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _userModerationStatus!.isSuspended
                        ? Colors.red[50]
                        : _userModerationStatus!.needsWarning
                        ? Colors.orange[50]
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _userModerationStatus!.isSuspended
                          ? Colors.red[200]!
                          : _userModerationStatus!.needsWarning
                          ? Colors.orange[200]!
                          : Colors.green[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _userModerationStatus!.isSuspended
                                ? Icons.block
                                : _userModerationStatus!.needsWarning
                                ? Icons.warning
                                : Icons.check_circle,
                            color: _userModerationStatus!.isSuspended
                                ? Colors.red
                                : _userModerationStatus!.needsWarning
                                ? Colors.orange
                                : Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Current Status',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _userModerationStatus!.statusMessage,
                        style: GoogleFonts.manrope(),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Active Strikes: ${_userModerationStatus!.activeStrikes}/3',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w500,
                          color: _userModerationStatus!.activeStrikes > 0
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Recent warnings
              Text(
                'Recent Warnings',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: _userWarnings.isEmpty
                    ? Center(
                        child: Text(
                          'No recent warnings',
                          style: GoogleFonts.manrope(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _userWarnings.length,
                        itemBuilder: (context, index) {
                          final warning = _userWarnings[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _getWarningIcon(warning.type),
                                        size: 16,
                                        color: _getWarningColor(warning.type),
                                      ),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          warning.title,
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w500,
                                            color: _getWarningColor(
                                              warning.type,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatTime(warning.createdAt),
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    warning.message,
                                    style: GoogleFonts.manrope(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show appeal dialog
  void _showAppealDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Appeal Moderation Action',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You can appeal moderation actions if you believe they were made in error. This feature will be available soon.',
            style: GoogleFonts.manrope(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Get warning icon based on type
  IconData _getWarningIcon(String type) {
    switch (type) {
      case 'content_filtered':
        return Icons.filter_alt;
      case 'first_strike':
      case 'second_strike':
      case 'final_warning':
        return Icons.warning;
      case 'suspended':
        return Icons.block;
      default:
        return Icons.info;
    }
  }

  /// Get warning color based on type
  Color _getWarningColor(String type) {
    switch (type) {
      case 'content_filtered':
        return Colors.orange;
      case 'first_strike':
        return Colors.orange[700]!;
      case 'second_strike':
        return Colors.red[600]!;
      case 'final_warning':
      case 'suspended':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
