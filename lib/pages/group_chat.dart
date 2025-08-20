import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/request_models.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupChat groupChat;

  const GroupChatScreen({
    Key? key,
    required this.groupChat,
  }) : super(key: key);

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  Message? _replyingTo;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      sender: User(
        name: Constants.myDisplayname, // Current user name
        role: "Buyer", // Current user role
        profileImageUrl: null,
      ),
      content: _messageController.text.trim(),
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

    _messageController.clear();
    _scrollToBottom();
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
      margin: EdgeInsets.only(
        bottom: 8,
        left: isReply ? 48 : 0,
      ),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: isReply ? BoxDecoration(
        ) : null,
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
                            vertical: 2
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
                        color: isCurrentUser ? Colors.blue[200]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: GoogleFonts.manrope(
                        color: Colors.black87,
                        fontSize: isReply ? 12 : 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  // Reply Button (only for top-level messages from other users)
                  if (!isCurrentUser && !isReply) ...[
                    SizedBox(height: 6),
                    TextButton(
                      onPressed: () => _handleReply(message),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    ...message.replies.map((reply) => _buildMessageItem(reply, isReply: true)),
                  ],
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
                    onPressed: (){
                      Navigator.pop(context);
                      setState(() {

                      });
                    }, icon: Icon(Icons.arrow_back_ios_new, size: 20,)
                ),
                SizedBox(width: 16,),
                Text(
                  'Request ',
                  style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                ),
                Text(
                  'Information',
                  style: GoogleFonts.manrope(color: Constants.ftaColorLight, fontSize: 16),
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
                      "UUID: ${widget.groupChat.uuid}",
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
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.groupChat.messages.length,
                        physics: ScrollPhysics(),
                        itemBuilder: (context, index) {
                          final message = widget.groupChat.messages[index];
                          return _buildMessageItem(message);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24,),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      constraints: BoxConstraints(maxWidth: 1400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Constants.ftaColorLight, width: 2),
                      ),
                      child: Row(
                        children: [
                          // Attachment Button
                          IconButton(
                            onPressed: () {
                              // Handle attachment
                            },
                            icon: Icon(
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
                                border: Border.all(color: Colors.grey[300]!, width: 1),
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
                  SizedBox(height: 24,),
                  FooterSection(logo: "lib/assets/images/bidr_logo2.png")
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
          color: user.role.contains("Seller")?Constants.ctaColorLight:Constants.ftaColorLight,
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
}



