import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../models/moderation_models.dart';
import '../../../models/request_models.dart';
import '../../../services/chat_service.dart';
import '../breakpoints.dart';

class GroupChatMobile extends StatefulWidget {
  final GroupChat groupChat;

  const GroupChatMobile({Key? key, required this.groupChat}) : super(key: key);

  @override
  State<GroupChatMobile> createState() => _GroupChatMobileState();
}

class _GroupChatMobileState extends State<GroupChatMobile> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  Message? _replyingTo;

  // Backend integration
  ChatConversation? _backendConversation;
  List<ChatMessage> _backendMessages = [];
  bool _isLoading = false;
  bool _useBackend = true;

  // Moderation state
  UserModerationStatus? _userModerationStatus;
  List<ModerationWarning> _userWarnings = [];
  bool _isSuspended = false;
  String? _suspensionMessage;

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
      await _loadUserModerationStatus();

      final conversationData = await ChatService.createOrGetConversationForRequest(
        widget.groupChat.uuid,
      );

      if (conversationData != null) {
        _backendConversation = ChatConversation.fromJson(conversationData);
        await _loadMessages();
        await _loadUserWarnings();
      }
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _useBackend = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
              .map((json) => ChatMessage.fromJson(json, Constants.myDisplayname))
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

    if (_isSuspended) {
      _showSuspensionDialog();
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();

    if (_useBackend && _backendConversation != null) {
      try {
        final messageResult = await ChatService.sendMessage(
          _backendConversation!.id,
          content,
          userId: Constants.myDisplayname,
        );

        if (messageResult['success'] == true) {
          await _loadMessages();
          await _loadUserModerationStatus();
          await _loadUserWarnings();

          if (messageResult['filtered'] == true) {
            _showContentFilteredNotification(messageResult['violations'] ?? []);
          }

          if (messageResult['strike_issued'] == true) {
            _showStrikeIssuedNotification();
          }
        } else if (messageResult['blocked'] == true) {
          _messageController.text = content;

          if (messageResult['reason'] == 'suspended') {
            setState(() {
              _isSuspended = true;
              _suspensionMessage = messageResult['status'];
            });
            _showSuspensionDialog();
          } else {
            _showMessageBlockedDialog(
              messageResult['message'] ?? 'Message blocked due to content violations',
              List<String>.from(messageResult['violations'] ?? []),
            );
          }
        } else {
          _messageController.text = content;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                messageResult['message'] ?? 'Failed to send message. Please try again.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (e) {
        print('Error sending message: $e');
        _messageController.text = content;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred. Please try again.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } else {
      final newMessage = Message(
        sender: User(
          name: Constants.myDisplayname,
          role: "Buyer",
          profileImageUrl: null,
        ),
        content: content,
        timestamp: DateTime.now(),
        isReply: _replyingTo != null,
      );

      setState(() {
        if (_replyingTo != null) {
          _replyingTo!.replies.add(newMessage);
          _replyingTo = null;
        } else {
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
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Chat',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'UUID: ${widget.groupChat.uuid}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          if (_userModerationStatus != null && _userModerationStatus!.activeStrikes > 0)
            IconButton(
              icon: Stack(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: _showModerationPanel,
            ),
        ],
      ),
      body: Column(
        children: [
          // Request Description Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Constants.ctaColorLight,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Request Description',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.groupChat.request.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Constants.ctaColorLight,
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _useBackend
                  ? _backendMessages.length
                  : widget.groupChat.messages.length,
              itemBuilder: (context, index) {
                if (_useBackend) {
                  return _buildBackendMessageItem(_backendMessages[index]);
                } else {
                  return _buildMessageItem(widget.groupChat.messages[index]);
                }
              },
            ),
          ),

          // Reply indicator
          if (_replyingTo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!.sender.name}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Attachment Button
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Handle attachment
                      },
                      icon: Icon(
                        Icons.attach_file,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text Input
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        decoration: InputDecoration(
                          hintText: _replyingTo != null
                              ? 'Reply to ${_replyingTo!.sender.name}...'
                              : 'Type a message...',
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF9CA3AF),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1A1A1A),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Send Button
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, {bool isReply = false}) {
    final isCurrentUser = message.sender.name == Constants.myDisplayname;
    final alignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Container(
      margin: EdgeInsets.only(
        bottom: isReply ? 4 : 8,
        left: isReply ? 48 : (isCurrentUser ? 60 : 0),
        right: isReply ? 0 : (isCurrentUser ? 0 : 60),
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          // Message bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Constants.ctaColorLight
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isCurrentUser ? 16 : 4),
                topRight: Radius.circular(isCurrentUser ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.sender.name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser ? Colors.white70 : Constants.ctaColorLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.2)
                              : Constants.ctaColorLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.sender.role,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isCurrentUser ? Colors.white : Constants.ctaColorLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isCurrentUser ? Colors.white : const Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isCurrentUser ? Colors.white70 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Reply button
          if (!isCurrentUser && !isReply) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _handleReply(message),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Reply',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Constants.ctaColorLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // Replies
          if (message.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...message.replies.map((reply) => _buildMessageItem(reply, isReply: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildBackendMessageItem(ChatMessage message) {
    final isCurrentUser = message.senderName == Constants.myDisplayname;
    final alignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isCurrentUser ? 60 : 0,
        right: isCurrentUser ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Constants.ctaColorLight
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isCurrentUser ? 16 : 4),
                topRight: Radius.circular(isCurrentUser ? 4 : 16),
                bottomLeft: const Radius.circular(16),
                bottomRight: const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.senderName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCurrentUser ? Colors.white70 : Constants.ctaColorLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.white.withOpacity(0.2)
                              : Constants.ctaColorLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.senderRole,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isCurrentUser ? Colors.white : Constants.ctaColorLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message.content,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: isCurrentUser ? Colors.white : const Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isCurrentUser ? Colors.white70 : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  // Moderation dialogs and notifications
  void _showSuspensionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.block,
                    color: const Color(0xFFEF4444),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Account Suspended',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account has been temporarily suspended from sending messages.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_suspensionMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Text(
                      _suspensionMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Understood',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    if (_userModerationStatus != null &&
                        _userModerationStatus!.activeStrikes > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showAppealDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Appeal',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMessageBlockedDialog(String message, List<String> violations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9E7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning,
                    color: const Color(0xFFF59E0B),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Message Blocked',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (violations.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9E7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Violations detected:',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...violations.map((violation) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Color(0xFF92400E))),
                              Expanded(
                                child: Text(
                                  violation,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Understood',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContentFilteredNotification(List<String> violations) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.filter_alt, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Message sent with content filtering',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showStrikeIssuedNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Strike issued. Please follow community guidelines.',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: _showModerationPanel,
        ),
      ),
    );
  }

  void _showModerationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Moderation Status',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_userModerationStatus != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _userModerationStatus!.isSuspended
                                ? const Color(0xFFFEF2F2)
                                : _userModerationStatus!.needsWarning
                                ? const Color(0xFFFEF9E7)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _userModerationStatus!.isSuspended
                                  ? const Color(0xFFFECACA)
                                  : _userModerationStatus!.needsWarning
                                  ? const Color(0xFFFCD34D)
                                  : const Color(0xFFBBF7D0),
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
                                        ? const Color(0xFFEF4444)
                                        : _userModerationStatus!.needsWarning
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Status',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userModerationStatus!.statusMessage,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _userModerationStatus!.activeStrikes > 0
                                          ? const Color(0xFFFEF2F2)
                                          : const Color(0xFFF0FDF4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      'Active Strikes: ${_userModerationStatus!.activeStrikes}/3',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _userModerationStatus!.activeStrikes > 0
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF059669),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Recent Warnings',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_userWarnings.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 48,
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No recent warnings',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...List.generate(_userWarnings.length, (index) {
                          final warning = _userWarnings[index];
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _getWarningIcon(warning.type),
                                      size: 20,
                                      color: _getWarningColor(warning.type),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        warning.title,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(warning.createdAt),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  warning.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF6B7280),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAppealDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.gavel,
                  size: 48,
                  color: Constants.ctaColorLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'Appeal Moderation Action',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can appeal moderation actions if you believe they were made in error. This feature will be available soon.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

  Color _getWarningColor(String type) {
    switch (type) {
      case 'content_filtered':
        return const Color(0xFFF59E0B);
      case 'first_strike':
        return const Color(0xFFF97316);
      case 'second_strike':
        return const Color(0xFFEF4444);
      case 'final_warning':
      case 'suspended':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
