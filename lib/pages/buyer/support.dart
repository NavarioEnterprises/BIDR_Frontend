
import 'dart:io';
import 'package:badges/badges.dart' as badges;
import 'package:bidr/global_values.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../constants/Constants.dart';
import '../../customWdget/custom_input2.dart';
import '../../models/ticket.dart';


import 'package:google_fonts/google_fonts.dart';

class Support extends StatefulWidget {
  @override
  _SupportState createState() => _SupportState();
}

class _SupportState extends State<Support> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  // Focus Nodes
  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final FocusNode _replyFocusNode = FocusNode();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _leftSlideAnimation = Tween<Offset>(
      begin: Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _rightSlideAnimation = Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _replyController.dispose();
    _subjectFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _replyFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  final List<Ticket> tickets = [
    Ticket(
      id: '#BAF000223',
      title: 'Orders Refunds Issue',
      status: 'Pending',
      date: '12 June 2021',
      description: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled.',
      assignee: 'Mark Jones',
    ),
    Ticket(
      id: '#BAF000225',
      title: 'Login Is Not Worked',
      status: 'Resolved',
      date: '12 June 2021',
      description: 'Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry\'s standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled.',
      assignee: 'Mark Jones',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(height: 24,),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: BuyerDashboardHeader(headerName: 'Support',totalAlert: GlobalVariables.alertList.length,),
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 68, right: 68, top: 24),
                    constraints: BoxConstraints(maxWidth: 1600, maxHeight: 600),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel - My Tickets
                        Expanded(
                          flex: 1,
                          child: SlideTransition(
                            position: _leftSlideAnimation,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 800),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.confirmation_number_outlined,
                                              color: Constants.ftaColorLight,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'My Tickets',
                                              style: GoogleFonts.manrope(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Constants.ftaColorLight
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 24),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: tickets.length,
                                      itemBuilder: (context, index) {
                                        final ticket = tickets[index];
                                        return TweenAnimationBuilder<double>(
                                          duration: Duration(milliseconds: 1000 + (index * 200)),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(-30 * (1 - value), 0),
                                                child: InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ChatScreen(ticket: ticket),
                                                      ),
                                                    );
                                                  },
                                                  child: AnimatedContainer(
                                                    duration: Duration(milliseconds: 200),
                                                    margin: EdgeInsets.only(bottom: 12),
                                                    padding: EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.white,
                                                          Colors.grey.shade50,
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Constants.ftaColorLight.withOpacity(0.3),
                                                        width: 1.5,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Constants.ftaColorLight.withOpacity(0.1),
                                                          spreadRadius: 1,
                                                          blurRadius: 4,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              ticket.title,
                                                              style: GoogleFonts.manrope(
                                                                  fontSize: 14,
                                                                  fontWeight: FontWeight.w600,
                                                                  color:Constants.ftaColorLight
                                                              ),
                                                            ),
                                                            TweenAnimationBuilder<double>(
                                                              duration: Duration(milliseconds: 600),
                                                              tween: Tween(begin: 0.0, end: 1.0),
                                                              builder: (context, badgeValue, child) {
                                                                return Transform.scale(
                                                                  scale: badgeValue,
                                                                  child: Container(
                                                                    padding: EdgeInsets.symmetric(
                                                                      horizontal: 8,
                                                                      vertical: 4,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      color: ticket.status == 'Pending'
                                                                          ? Colors.grey[400]
                                                                          : Constants.ctaColorLight,
                                                                      borderRadius: BorderRadius.circular(12),
                                                                    ),
                                                                    child: Text(
                                                                      ticket.status,
                                                                      style: GoogleFonts.manrope(
                                                                        color: Colors.white,
                                                                        fontSize: 10,
                                                                        fontWeight: FontWeight.w500,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 8),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Text(
                                                              ticket.id,
                                                              style: GoogleFonts.manrope(
                                                                fontSize: 12,
                                                                color: Colors.black,
                                                                fontWeight: FontWeight.w300,
                                                              ),
                                                            ),
                                                            Text(
                                                              ticket.date,
                                                              style: GoogleFonts.manrope(
                                                                fontSize: 12,
                                                                color: Colors.black,
                                                                fontWeight: FontWeight.w300,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 24),
                        // Right Panel - Create Ticket Form
                        Expanded(
                          flex: 2,
                          child: SlideTransition(
                            position: _rightSlideAnimation,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Constants.ctaColorLight,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Create New Ticket',
                                        style: GoogleFonts.manrope(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Constants.ctaColorLight
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Fill out the form below to submit a support request',
                                    style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey.shade600
                                    ),
                                  ),
                                  SizedBox(height: 24),
                                  TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 1000),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(20 * (1 - value), 0),
                                          child: _buildCustomTextField(
                                            'Subject',
                                            _subjectController,
                                            _subjectFocusNode,
                                            _descriptionFocusNode,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 24),
                                  TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 1200),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(20 * (1 - value), 0),
                                          child: _buildCustomTextField(
                                            'Description',
                                            _descriptionController,
                                            _descriptionFocusNode,
                                            null,
                                            isDescription: true,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Spacer(),
                                  TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 1400),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - value)),
                                          child: Center(
                                            child: SizedBox(
                                              width:MediaQuery.of(context).size.width*0.5,
                                              height: 45,
                                              child: AnimatedContainer(
                                                duration: Duration(milliseconds: 200),
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    // Handle ticket creation
                                                    if (_subjectController.text.isNotEmpty &&
                                                        _descriptionController.text.isNotEmpty) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Ticket created successfully!'),
                                                          backgroundColor: Constants.ctaColorLight,
                                                        ),
                                                      );
                                                      _subjectController.clear();
                                                      _descriptionController.clear();
                                                    }
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Constants.ctaColorLight,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(30),
                                                    ),
                                                    elevation: 2,
                                                    shadowColor: Constants.ctaColorLight.withOpacity(0.3),
                                                  ),
                                                  child: Text(
                                                    'Raise a Ticket',
                                                    style: GoogleFonts.manrope(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w300,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24,),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCustomTextField(String hintText, TextEditingController controller, FocusNode focusNode, FocusNode? nextFocusNode, {Widget? suffixIcon, bool isDescription = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            hintText,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 8),
        if (isDescription)
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
              color: Colors.grey.withOpacity(0.05),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 5,
              textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Enter your detailed description here...',
                hintStyle: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.grey.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              onChanged: (value) {},
              onSubmitted: (value) {
                if (nextFocusNode != null) {
                  nextFocusNode.requestFocus();
                }
              },
            ),
          )
        else
          CustomInputTransparent4(
            hintText: hintText,
            controller: controller,
            focusNode: focusNode,
            textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
            isPasswordField: false,
            suffix: suffixIcon,
            onChanged: (value) {},
            onSubmitted: (value) {
              if (nextFocusNode != null) {
                nextFocusNode.requestFocus();
              }
            },
          ),
      ],
    );
  }
}


class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageType type;
  final String? filePath;
  final String? fileName;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.status,
    this.type = MessageType.text,
    this.filePath,
    this.fileName,
  });
}

enum MessageStatus { sending, sent, delivered, read }
enum MessageType { text, image, document, voice }

class ChatScreen extends StatefulWidget {
  final Ticket ticket;

  const ChatScreen({super.key, required this.ticket});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isTyping = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _addInitialMessages();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _addInitialMessages() {
    // Add initial ticket description as first message
    _messages.add(Message(
      text: widget.ticket.description,
      isMe: true,
      timestamp: DateTime.now().subtract(Duration(days: 1)),
      status: MessageStatus.read,
    ));

    // Add assignee's initial response
    _messages.add(Message(
      text: "Hello! I've received your ticket and I'm looking into this issue. I'll get back to you with more details soon.",
      isMe: false,
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
      status: MessageStatus.read,
    ));
  }

  void _sendReply() {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: _replyController.text.trim(),
        isMe: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      ));
    });

    _replyController.clear();
    _scrollToBottom();

    // Simulate message status updates
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.last = Message(
            text: _messages.last.text,
            isMe: _messages.last.isMe,
            timestamp: _messages.last.timestamp,
            status: MessageStatus.delivered,
          );
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 14, color: Colors.grey[500]);
      case MessageStatus.sent:
        return Icon(Icons.done, size: 14, color: Colors.grey[600]);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 14, color: Colors.grey[600]);
      case MessageStatus.read:
        return Icon(Icons.done_all, size: 14, color: Constants.ctaColorLight);
    }
  }

  Widget _buildMessageBubble(Message message, int index) {
    return Container(
      margin: EdgeInsets.only(
        left: message.isMe ? 60 : 16,
        right: message.isMe ? 16 : 60,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isMe ? Constants.ftaColorLight.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : 16),
              ),
              border: Border.all(
                color: message.isMe ? Constants.ftaColorLight.withOpacity(0.3) : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Text(
              message.text,
              style: GoogleFonts.manrope(
                color: Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMM dd, HH:mm').format(message.timestamp),
                style: GoogleFonts.manrope(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              if (message.isMe) ...[
                SizedBox(width: 4),
                _buildMessageStatusIcon(message.status),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.ftaColorLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.ticket.title,
              style: GoogleFonts.manrope(
                color: Constants.ftaColorLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.ticket.id,
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.ticket.status == 'Pending'
                  ? Colors.orange[100]
                  : Constants.ctaColorLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.ticket.status == 'Pending'
                    ? Colors.orange[300]!
                    : Constants.ctaColorLight.withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.ticket.status,
              style: GoogleFonts.manrope(
                color: widget.ticket.status == 'Pending'
                    ? Colors.orange[700]
                    : Constants.ctaColorLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Ticket Info Header
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Constants.ftaColorLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.support_agent,
                          color: Constants.ftaColorLight,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned to ${widget.ticket.assignee}',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                            Text(
                              'Created on ${widget.ticket.date}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 600 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: _buildMessageBubble(_messages[index], index),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // Reply Input
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reply To Ticket',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _replyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Type your reply here...',
                        hintStyle: GoogleFonts.manrope(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _sendReply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Send',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class BuyerDashboardHeader extends StatefulWidget {
  final String headerName;
  final int totalAlert;
  const BuyerDashboardHeader({super.key, required this.headerName, required this.totalAlert});

  @override
  State<BuyerDashboardHeader> createState() => _BuyerDashboardHeaderState();
}

class _BuyerDashboardHeaderState extends State<BuyerDashboardHeader> {
  @override
  Widget build(BuildContext context) {
    return  Container(
      height: 60,
      width: MediaQuery.of(context).size.width,
      color: Constants.ctaColorLight,
      padding: EdgeInsets.only(left: 68, right: 68, top: 8, bottom: 8),
      child: Row(
        children: [
          Text(
            'Buyer',
            style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'YuGothic'),
          ),
          Text(
            ' Dashboard',
            style: TextStyle(color: Constants.ftaColorLight, fontSize: 16, fontFamily: 'YuGothic'),
          ),
          Spacer(),
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: -6, end: -6),

            showBadge: true,
            ignorePointer: false,
            onTap: () {
              /*Navigator.push(context,
                        MaterialPageRoute(builder: (context) => NotificationsScreen()));*/
            },
            badgeContent: Text(
              widget.totalAlert.toString(),
              style: TextStyle(
                fontSize: 10,
                color: Constants.ftaColorLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            badgeAnimation: badges.BadgeAnimation.rotation(
              animationDuration: const Duration(seconds: 1),
              colorChangeAnimationDuration: const Duration(seconds: 1),
              loopAnimation: false,
              curve: Curves.fastOutSlowIn,
              colorChangeAnimationCurve: Curves.easeInCubic,
            ),
            badgeStyle: badges.BadgeStyle(
              shape: badges.BadgeShape.circle,
              badgeColor: Colors.white,
              padding: const EdgeInsets.all(5),
              borderRadius: BorderRadius.circular(10),
              elevation: 3,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Constants.ftaColorLight
                /*border: Border.all(
                        color: Constants.primaryColor.withOpacity(0.5),
                        width: 1,
                      ),*/
              ),
              child: Icon(
                HugeIcons.strokeRoundedNotification01,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
