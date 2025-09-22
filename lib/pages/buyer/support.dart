import 'dart:io';
import 'package:badges/badges.dart' as badges;
import 'package:bidr/global_values.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:motion_toast/motion_toast.dart';

import '../../constants/Constants.dart';
import '../../customWdget/custom_input2.dart';
import '../../models/alert.dart';
import '../../models/ticket.dart';
import '../../services/ticket_api_service.dart';
import '../mobileView/breakpoints.dart';

import 'package:google_fonts/google_fonts.dart';

import '../notification.dart';
import '../../services/notification_api_service.dart';

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

  // API Service and State
  final TicketApiService _ticketApiService = TicketApiService();
  List<Ticket> tickets = [];
  bool _isLoadingTickets = true;
  bool _isCreatingTicket = false;
  String? _authUserUid = Constants.myUid.isNotEmpty ? Constants.myUid : null;

  @override
  void initState() {
    super.initState();
    // Update auth user UID from Constants
    _authUserUid = Constants.myUid.isNotEmpty ? Constants.myUid : null;

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _leftSlideAnimation = Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _rightSlideAnimation = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    // Load tickets from API
    _loadTickets();
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

  /// Load tickets from API
  Future<void> _loadTickets() async {
    // If user is not authenticated, don't try to load tickets
    if (_authUserUid == null || _authUserUid!.isEmpty) {
      setState(() {
        _isLoadingTickets = false;
        tickets = [];
      });
      return;
    }

    setState(() {
      _isLoadingTickets = true;
    });

    try {
      final fetchedTickets = await _ticketApiService.fetchUserTickets(
        _authUserUid!,
      );
      if (fetchedTickets != null && mounted) {
        setState(() {
          tickets = fetchedTickets;
          _isLoadingTickets = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      print('Error loading tickets: $e');
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

  /// Create a new ticket
  Future<void> _createTicket() async {
    // Check if user is logged in
    if (_authUserUid == null || _authUserUid!.isEmpty) {
      MotionToast.error(
        title: Text(
          "Authentication Required",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          "Please login first",
          style: TextStyle(color: Colors.white),
        ),
        toastDuration: Duration(seconds: 3),
        barrierColor: Colors.black.withOpacity(0.3),
        displayBorder: false,
      ).show(context);
      return;
    }

    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingTicket = true;
    });

    try {
      final result = await _ticketApiService.createTicket(
        authUserUid: _authUserUid!,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: 'medium',
      );

      if (mounted) {
        setState(() {
          _isCreatingTicket = false;
        });

        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ticket created successfully!'),
              backgroundColor: Constants.ctaColorLight,
            ),
          );
          _subjectController.clear();
          _descriptionController.clear();

          // Reload tickets to show the new one
          _loadTickets();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['error'] ?? 'Failed to create ticket'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating ticket: $e');
      if (mounted) {
        setState(() {
          _isCreatingTicket = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            child: BuyerDashboardHeader(headerName: 'Buyer Dashboard'),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child!,
                ),
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: Breakpoints.isTablet(context)
                        ? EdgeInsets.only(
                            left: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingLarge,
                            right: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingLarge,
                            top: ResponsiveSpacing.getSpacing(
                              context,
                            ).paddingLarge,
                          )
                        : const EdgeInsets.only(left: 68, right: 68, top: 24),
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
                                  colors: [Colors.white, Colors.grey.shade50],
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
                                              Icons
                                                  .confirmation_number_outlined,
                                              color: Constants.ftaColorLight,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'My Tickets',
                                              style: GoogleFonts.manrope(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Constants.ftaColorLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 24),
                                  Expanded(
                                    child: _isLoadingTickets
                                        ? Center(
                                            child: CircularProgressIndicator(
                                              color: Constants.ftaColorLight,
                                            ),
                                          )
                                        : tickets.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.inbox_outlined,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  (_authUserUid == null ||
                                                          _authUserUid!.isEmpty)
                                                      ? 'Please login to view tickets'
                                                      : 'No tickets yet',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 16,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  (_authUserUid == null ||
                                                          _authUserUid!.isEmpty)
                                                      ? 'Login to access support'
                                                      : 'Create your first support ticket',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 14,
                                                    color: Colors.grey[500],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: tickets.length,
                                            itemBuilder: (context, index) {
                                              final ticket = tickets[index];
                                              return TweenAnimationBuilder<
                                                double
                                              >(
                                                duration: Duration(
                                                  milliseconds:
                                                      1000 + (index * 200),
                                                ),
                                                tween: Tween(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                builder: (context, value, child) {
                                                  return Opacity(
                                                    opacity: value,
                                                    child: Transform.translate(
                                                      offset: Offset(
                                                        -30 * (1 - value),
                                                        0,
                                                      ),
                                                      child: InkWell(
                                                        onTap: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    context,
                                                                  ) => ChatScreen(
                                                                    ticket:
                                                                        ticket,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                        child: AnimatedContainer(
                                                          duration: Duration(
                                                            milliseconds: 200,
                                                          ),
                                                          margin:
                                                              EdgeInsets.only(
                                                                bottom: 12,
                                                              ),
                                                          padding:
                                                              EdgeInsets.all(
                                                                16,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                LinearGradient(
                                                                  colors: [
                                                                    Colors
                                                                        .white,
                                                                    Colors
                                                                        .grey
                                                                        .shade50,
                                                                  ],
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            border: Border.all(
                                                              color: Constants
                                                                  .ftaColorLight
                                                                  .withOpacity(
                                                                    0.3,
                                                                  ),
                                                              width: 1.5,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Constants
                                                                    .ftaColorLight
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                spreadRadius: 1,
                                                                blurRadius: 4,
                                                                offset: Offset(
                                                                  0,
                                                                  2,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    ticket
                                                                        .title,
                                                                    style: GoogleFonts.manrope(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color: Constants
                                                                          .ftaColorLight,
                                                                    ),
                                                                  ),
                                                                  TweenAnimationBuilder<
                                                                    double
                                                                  >(
                                                                    duration: Duration(
                                                                      milliseconds:
                                                                          600,
                                                                    ),
                                                                    tween: Tween(
                                                                      begin:
                                                                          0.0,
                                                                      end: 1.0,
                                                                    ),
                                                                    builder:
                                                                        (
                                                                          context,
                                                                          badgeValue,
                                                                          child,
                                                                        ) {
                                                                          return Transform.scale(
                                                                            scale:
                                                                                badgeValue,
                                                                            child: Container(
                                                                              padding: EdgeInsets.symmetric(
                                                                                horizontal: 8,
                                                                                vertical: 4,
                                                                              ),
                                                                              decoration: BoxDecoration(
                                                                                color:
                                                                                    ticket.status ==
                                                                                        'Pending'
                                                                                    ? Colors.grey[400]
                                                                                    : Constants.ctaColorLight,
                                                                                borderRadius: BorderRadius.circular(
                                                                                  12,
                                                                                ),
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
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    ticket
                                                                        .ticketId,
                                                                    style: GoogleFonts.manrope(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .black,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w300,
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    ticket.date,
                                                                    style: GoogleFonts.manrope(
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .black,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w300,
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
                                  colors: [Colors.white, Colors.grey.shade50],
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
                                          color: Constants.ctaColorLight,
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
                                      color: Colors.grey.shade600,
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
                                              width:
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.width *
                                                  0.5,
                                              height: 45,
                                              child: AnimatedContainer(
                                                duration: Duration(
                                                  milliseconds: 200,
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: _isCreatingTicket
                                                      ? null
                                                      : _createTicket,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Constants.ctaColorLight,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                    ),
                                                    elevation: 2,
                                                    shadowColor: Constants
                                                        .ctaColorLight
                                                        .withOpacity(0.3),
                                                  ),
                                                  child: _isCreatingTicket
                                                      ? Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    color: Colors
                                                                        .white,
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Creating...',
                                                              style: GoogleFonts.manrope(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : Text(
                                                          'Raise a Ticket',
                                                          style:
                                                              GoogleFonts.manrope(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w300,
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
                  SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: FooterSection(
                            logo: "lib/assets/images/bidr_logo2.png",
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
    bool isDescription = false,
  }) {
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
              textInputAction: nextFocusNode != null
                  ? TextInputAction.next
                  : TextInputAction.done,
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
            textInputAction: nextFocusNode != null
                ? TextInputAction.next
                : TextInputAction.done,
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

class SellerSupport extends StatefulWidget {
  @override
  _SellerSupportState createState() => _SellerSupportState();
}

class _SellerSupportState extends State<SellerSupport>
    with TickerProviderStateMixin {
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

  // API Service and State
  final TicketApiService _ticketApiService = TicketApiService();
  List<Ticket> tickets = [];
  bool _isLoadingTickets = true;
  bool _isCreatingTicket = false;
  String? _authUserUid = Constants.myUid.isNotEmpty ? Constants.myUid : null;

  @override
  void initState() {
    super.initState();
    // Update auth user UID from Constants
    _authUserUid = Constants.myUid.isNotEmpty ? Constants.myUid : null;

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _leftSlideAnimation = Tween<Offset>(begin: Offset(-1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _rightSlideAnimation = Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    // Load tickets from API
    _loadTickets();
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

  /// Load tickets from API
  Future<void> _loadTickets() async {
    // If user is not authenticated, don't try to load tickets
    if (_authUserUid == null || _authUserUid!.isEmpty) {
      setState(() {
        _isLoadingTickets = false;
        tickets = [];
      });
      return;
    }

    setState(() {
      _isLoadingTickets = true;
    });

    try {
      final fetchedTickets = await _ticketApiService.fetchUserTickets(
        _authUserUid!,
      );
      if (fetchedTickets != null && mounted) {
        setState(() {
          tickets = fetchedTickets;
          _isLoadingTickets = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      print('Error loading tickets: $e');
      if (mounted) {
        setState(() {
          _isLoadingTickets = false;
        });
      }
    }
  }

  /// Create a new ticket
  Future<void> _createTicket() async {
    // Check if user is logged in
    if (_authUserUid == null || _authUserUid!.isEmpty) {
      MotionToast.error(
        title: Text(
          "Authentication Required",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        description: Text(
          "Please login first",
          style: TextStyle(color: Colors.white),
        ),
        toastDuration: Duration(seconds: 3),
        barrierColor: Colors.black.withOpacity(0.3),
        displayBorder: false,
      ).show(context);
      return;
    }

    if (_subjectController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingTicket = true;
    });

    try {
      final result = await _ticketApiService.createTicket(
        authUserUid: _authUserUid!,
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: 'medium',
      );

      if (mounted) {
        setState(() {
          _isCreatingTicket = false;
        });

        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ticket created successfully!'),
              backgroundColor: Constants.ctaColorLight,
            ),
          );
          _subjectController.clear();
          _descriptionController.clear();

          // Reload tickets to show the new one
          _loadTickets();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result?['error'] ?? 'Failed to create ticket'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error creating ticket: $e');
      if (mounted) {
        setState(() {
          _isCreatingTicket = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(height: 24),
          SingleChildScrollView(
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
                                colors: [Colors.white, Colors.grey.shade50],
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
                                              color: Constants.ftaColorLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 24),
                                Expanded(
                                  child: _isLoadingTickets
                                      ? Center(
                                          child: CircularProgressIndicator(
                                            color: Constants.ftaColorLight,
                                          ),
                                        )
                                      : tickets.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.inbox_outlined,
                                                size: 48,
                                                color: Colors.grey[400],
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                (_authUserUid == null ||
                                                        _authUserUid!.isEmpty)
                                                    ? 'Please login to view tickets'
                                                    : 'No tickets yet',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                (_authUserUid == null ||
                                                        _authUserUid!.isEmpty)
                                                    ? 'Login to access support'
                                                    : 'Create your first support ticket',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: tickets.length,
                                          itemBuilder: (context, index) {
                                            final ticket = tickets[index];
                                            return TweenAnimationBuilder<
                                              double
                                            >(
                                              duration: Duration(
                                                milliseconds:
                                                    1000 + (index * 200),
                                              ),
                                              tween: Tween(
                                                begin: 0.0,
                                                end: 1.0,
                                              ),
                                              builder: (context, value, child) {
                                                return Opacity(
                                                  opacity: value,
                                                  child: Transform.translate(
                                                    offset: Offset(
                                                      -30 * (1 - value),
                                                      0,
                                                    ),
                                                    child: InkWell(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => ChatScreen(
                                                                  ticket:
                                                                      ticket,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: AnimatedContainer(
                                                        duration: Duration(
                                                          milliseconds: 200,
                                                        ),
                                                        margin: EdgeInsets.only(
                                                          bottom: 12,
                                                        ),
                                                        padding: EdgeInsets.all(
                                                          16,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                                colors: [
                                                                  Colors.white,
                                                                  Colors
                                                                      .grey
                                                                      .shade50,
                                                                ],
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color: Constants
                                                                .ftaColorLight
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            width: 1.5,
                                                          ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Constants
                                                                  .ftaColorLight
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              spreadRadius: 1,
                                                              blurRadius: 4,
                                                              offset: Offset(
                                                                0,
                                                                2,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  ticket.title,
                                                                  style: GoogleFonts.manrope(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Constants
                                                                        .ftaColorLight,
                                                                  ),
                                                                ),
                                                                TweenAnimationBuilder<
                                                                  double
                                                                >(
                                                                  duration:
                                                                      Duration(
                                                                        milliseconds:
                                                                            600,
                                                                      ),
                                                                  tween: Tween(
                                                                    begin: 0.0,
                                                                    end: 1.0,
                                                                  ),
                                                                  builder:
                                                                      (
                                                                        context,
                                                                        badgeValue,
                                                                        child,
                                                                      ) {
                                                                        return Transform.scale(
                                                                          scale:
                                                                              badgeValue,
                                                                          child: Container(
                                                                            padding: EdgeInsets.symmetric(
                                                                              horizontal: 8,
                                                                              vertical: 4,
                                                                            ),
                                                                            decoration: BoxDecoration(
                                                                              color:
                                                                                  ticket.status ==
                                                                                      'Pending'
                                                                                  ? Colors.grey[400]
                                                                                  : Constants.ctaColorLight,
                                                                              borderRadius: BorderRadius.circular(
                                                                                12,
                                                                              ),
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
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  ticket
                                                                      .ticketId,
                                                                  style: GoogleFonts.manrope(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  ticket.date,
                                                                  style: GoogleFonts.manrope(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w300,
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
                                colors: [Colors.white, Colors.grey.shade50],
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
                                        color: Constants.ctaColorLight,
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
                                    color: Colors.grey.shade600,
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
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.5,
                                            height: 45,
                                            child: AnimatedContainer(
                                              duration: Duration(
                                                milliseconds: 200,
                                              ),
                                              child: ElevatedButton(
                                                onPressed: _isCreatingTicket
                                                    ? null
                                                    : _createTicket,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Constants.ctaColorLight,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          30,
                                                        ),
                                                  ),
                                                  elevation: 2,
                                                  shadowColor: Constants
                                                      .ctaColorLight
                                                      .withOpacity(0.3),
                                                ),
                                                child: _isCreatingTicket
                                                    ? Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  color: Colors
                                                                      .white,
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Creating...',
                                                            style:
                                                                GoogleFonts.manrope(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w300,
                                                                ),
                                                          ),
                                                        ],
                                                      )
                                                    : Text(
                                                        'Raise a Ticket',
                                                        style:
                                                            GoogleFonts.manrope(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w300,
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
                SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 1600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: FooterSection(
                          logo: "lib/assets/images/bidr_logo2.png",
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
    bool isDescription = false,
  }) {
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
              textInputAction: nextFocusNode != null
                  ? TextInputAction.next
                  : TextInputAction.done,
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
            textInputAction: nextFocusNode != null
                ? TextInputAction.next
                : TextInputAction.done,
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

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

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
    _messages.add(
      Message(
        text: widget.ticket.description,
        isMe: true,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        status: MessageStatus.read,
      ),
    );

    // Add assignee's initial response
    _messages.add(
      Message(
        text:
            "Hello! I've received your ticket and I'm looking into this issue. I'll get back to you with more details soon.",
        isMe: false,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        status: MessageStatus.read,
      ),
    );
  }

  void _sendReply() {
    if (_replyController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          text: _replyController.text.trim(),
          isMe: true,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
        ),
      );
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
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isMe
                  ? Constants.ftaColorLight.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : 16),
              ),
              border: Border.all(
                color: message.isMe
                    ? Constants.ftaColorLight.withOpacity(0.3)
                    : Colors.grey[300]!,
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
              widget.ticket.ticketId,
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
                              'Assigned to ${widget.ticket.assignee?['name'] ?? 'Support Team'}',
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
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
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
                              Icon(Icons.send, size: 16, color: Colors.white),
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

  const BuyerDashboardHeader({super.key, required this.headerName});

  @override
  State<BuyerDashboardHeader> createState() => _BuyerDashboardHeaderState();
}

List<WebNotification> notifications = [];
int unreadCount = 0;
bool isHoveringText = false;
bool isHoveringIcon = false;

class _BuyerDashboardHeaderState extends State<BuyerDashboardHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isOverlayShown = false;
  bool _isLoadingNotifications = false;

  final NotificationApiService _notificationApiService =
      NotificationApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    unreadCount = 0;
    // Add a small delay to ensure widget is fully mounted and stable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeNotifications();
      }
    });
  }

  @override
  void didUpdateWidget(covariant BuyerDashboardHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reinitialize if the header name changed
    if (oldWidget.headerName != widget.headerName && !_isLoadingNotifications) {
      _initializeNotifications();
    }
  }

  Future<void> _initializeNotifications() async {
    if (!mounted) return;

    // Prevent multiple concurrent calls
    if (_isLoadingNotifications) {
      print('Already loading notifications, skipping...');
      print('Current widget instance: ${this.hashCode}');
      return;
    }

    try {
      // Simple initial load without complex refresh logic
      final userUuid = Constants.currentUser?.uid ?? Constants.myUid;
      print('Initializing notifications for user UUID: $userUuid');

      if (userUuid.isNotEmpty) {
        setState(() {
          _isLoadingNotifications = true;
        });

        // Load notifications first
        final fetchedNotifications = await _notificationApiService
            .getUserNotifications(userUuid)
            .timeout(const Duration(seconds: 20));

        print('Fetched ${fetchedNotifications.length} notifications');

        if (mounted) {
          print(
            'Before setState: _isLoadingNotifications = $_isLoadingNotifications',
          );
          print('Widget hashCode: ${this.hashCode}');
          setState(() {
            // Force update of instance variable first
            _isLoadingNotifications = false;
            // Then update global variables
            notifications = fetchedNotifications;
            // Calculate unread count from loaded notifications
            unreadCount = fetchedNotifications.where((n) => !n.read).length;
            print(
              'Inside setState: _isLoadingNotifications = $_isLoadingNotifications',
            );
            print('notifications updated: ${notifications.length} items');
          });
          print(
            'After setState: _isLoadingNotifications = $_isLoadingNotifications',
          );
        } else {
          // Reset loading state even if not mounted to prevent stuck state
          _isLoadingNotifications = false;
          print('Widget unmounted after fetch, but loading state reset');
        }
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      if (mounted) {
        setState(() {
          notifications = [];
          unreadCount = 0;
          _isLoadingNotifications = false;
          print('Loading state set to false in error handler');
        });
      } else {
        _isLoadingNotifications = false;
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationsFromApi() async {
    if (!mounted) return;

    try {
      // Use the user's UUID from Constants
      final userUuid = Constants.currentUser?.uid ?? Constants.myUid;
      print('Loading notifications for user UUID: $userUuid');

      if (userUuid.isNotEmpty) {
        final fetchedNotifications = await _notificationApiService
            .getUserNotifications(userUuid);

        if (mounted) {
          setState(() {
            notifications = fetchedNotifications;
          });
        }
      } else {
        print('No user UUID found');
        if (mounted) {
          setState(() {
            notifications = [];
          });
        }
      }
    } catch (e) {
      print('Error loading notifications from API: $e');
      // On error, just set empty notifications
      if (mounted) {
        setState(() {
          notifications = [];
        });
      }
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final success = await _notificationApiService.markAsRead(notificationId);
      if (success && mounted) {
        // Update local notification state immediately
        setState(() {
          final index = notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            notifications[index].read = true;
          }
          // Recalculate unread count from notifications
          unreadCount = notifications.where((n) => !n.read).length;
        });
        print('Notification marked as read: $notificationId');
      } else {
        print('Failed to mark notification as read: $notificationId');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _showNotificationOverlay() {
    if (_isOverlayShown) {
      _removeOverlay();
      return;
    }

    // Only refresh if we have no notifications or it's been a while
    if (notifications.isEmpty && !_isLoadingNotifications) {
      _initializeNotifications();
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to catch taps outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // The actual notification overlay
          Positioned(
            top: offset.dy + buttonSize.height + 5,
            right: 68, // Match the padding of the header
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: Container(
                  width: 310,
                  constraints: BoxConstraints(maxWidth: 310, maxHeight: 6500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ALERT',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _removeOverlay,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildAlertStats(),
                            const SizedBox(height: 20),
                            //Text(_isLoadingNotifications.toString()),
                            _buildRecentNotifications(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: unreadCount > 0
                                      ? () async {
                                          // Mark all as read
                                          final userUuid =
                                              Constants.currentUser?.uid ??
                                              Constants.myUid;
                                          if (userUuid.isNotEmpty) {
                                            final success =
                                                await _notificationApiService
                                                    .markAllAsRead(userUuid);
                                            if (success && mounted) {
                                              setState(() {
                                                // Mark all notifications as read locally
                                                for (var notification
                                                    in notifications) {
                                                  notification.read = true;
                                                }
                                                unreadCount = 0;
                                              });
                                            }
                                          }
                                        }
                                      : null,
                                  child: Text(
                                    'Mark All Read',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: unreadCount > 0
                                          ? Constants.ctaColorLight
                                          : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _showFilteredNotifications('all'),
                                  child: Text(
                                    'View all',
                                    style: TextStyle(
                                      color: Constants.ctaColorLight,
                                      fontWeight: FontWeight.w600,
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
              ),
            ),
          ),
        ],
      ),
    );

    _isOverlayShown = true;
    _animationController.forward();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isOverlayShown = false;
      });
    }
  }

  Widget _buildAlertStats() {
    // Calculate stats from actual notifications
    final totalNotifications = notifications.length;
    final readNotifications = notifications.where((n) => n.read).length;
    final unreadNotifications = notifications.where((n) => !n.read).length;

    return Column(
      children: [
        _buildStatItem(
          'Total Notifications',
          totalNotifications.toString(),
          onTap: () => _showFilteredNotifications('all'),
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          'Read Notifications',
          readNotifications.toString(),
          onTap: () => _showFilteredNotifications('read'),
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          'Unread Notifications',
          unreadNotifications.toString(),
          onTap: () => _showFilteredNotifications('unread'),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Constants.ctaColorLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilteredNotifications(String filter) {
    _removeOverlay();

    List<WebNotification> filteredNotifications;
    String title;

    switch (filter) {
      case 'all':
        filteredNotifications = notifications;
        title = 'All Notifications';
        break;
      case 'read':
        filteredNotifications = notifications.where((n) => n.read).toList();
        title = 'Read Notifications';
        break;
      case 'unread':
        filteredNotifications = notifications.where((n) => !n.read).toList();
        title = 'Unread Notifications';
        break;
      default:
        filteredNotifications = notifications;
        title = 'All Notifications';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: filteredNotifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications to show',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(
                              filteredNotifications[index],
                              isCompact: false,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSingleNotification(WebNotification notification) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: notification.read
                              ? Colors.grey.shade100
                              : Constants.ctaColorLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: notification.read
                                ? Colors.grey.shade300
                                : Constants.ctaColorLight.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          notification.read ? 'Read' : 'Unread',
                          style: TextStyle(
                            color: notification.read
                                ? Colors.grey.shade600
                                : Constants.ctaColorLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Message content
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Timestamp
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mark as read/unread button
                      if (!notification.read)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _markNotificationAsRead(notification.id);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Mark as Read',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildRecentNotifications() {
    if (notifications.isEmpty) {
      return Container(
        height: 80,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, color: Colors.grey[400], size: 24),
              const SizedBox(height: 4),
              Text(
                'No notifications yet',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final recentNotifications = notifications.take(4).toList();
    final groupedNotifications = <String, List<WebNotification>>{};

    for (var notification in recentNotifications) {
      final dayKey = _getDayKey(notification.createdAt);
      groupedNotifications[dayKey] ??= [];
      groupedNotifications[dayKey]!.add(notification);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedNotifications.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...entry.value.map(
              (notification) =>
                  _buildNotificationItem(notification, isCompact: true),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getDayKey(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == 2) return 'Monday';
    return '${difference} days ago';
  }

  Widget _buildNotificationItem(
    WebNotification notification, {
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: () {
        // Close the overlay first
        _removeOverlay();

        // Show single notification dialog
        _showSingleNotification(notification);

        // Mark as read if it's unread
        if (!notification.read) {
          _markNotificationAsRead(notification.id);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: notification.read
              ? Colors.transparent
              : Constants.ctaColorLight.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: notification.read
              ? null
              : Border.all(
                  color: Constants.ctaColorLight.withOpacity(0.2),
                  width: 1,
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Constants.ctaColorLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: Constants.ctaColorLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Constants.ctaColorLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'accept':
        return Icons.check_circle_outline;
      case 'update':
        return Icons.update;
      case 'order':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showNotificationOverlay,
      child: Container(
        height: 60,
        width: MediaQuery.of(context).size.width,
        color: Constants.ctaColorLight,
        padding: EdgeInsets.only(left: 68, right: 68, top: 8, bottom: 8),
        child: Row(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => isHoveringText = true),
              onExit: (_) => setState(() => isHoveringText = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: TextStyle(
                  color: isHoveringText
                      ? Constants.ftaColorLight.withOpacity(0.7)
                      : Constants.ftaColorLight,
                  fontSize: 16,
                  fontFamily: 'YuGothic',
                  decoration: isHoveringText
                      ? TextDecoration.underline
                      : TextDecoration.none,
                  decorationColor: Constants.ftaColorLight.withOpacity(0.7),
                  decorationThickness: 2,
                  shadows: isHoveringText
                      ? [
                          Shadow(
                            color: Constants.ftaColorLight.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(widget.headerName),
              ),
            ),
            Spacer(),
            MouseRegion(
              onEnter: (_) => setState(() => isHoveringIcon = true),
              onExit: (_) => setState(() => isHoveringIcon = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                transform: Matrix4.identity()
                  ..scale(isHoveringIcon ? 1.1 : 1.0),
                child: badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -6, end: -6),

                  showBadge: unreadCount > 0,
                  ignorePointer: true,
                  badgeContent: Text(
                    unreadCount.toString(),
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
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHoveringIcon
                          ? Constants.ftaColorLight.withOpacity(0.8)
                          : Constants.ftaColorLight,
                      boxShadow: isHoveringIcon
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedNotification01,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
