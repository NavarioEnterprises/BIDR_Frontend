import 'package:badges/badges.dart' as badges;
import 'package:bidr/pages/buyer_home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:motion_toast/motion_toast.dart';

import '../../../constants/Constants.dart';
import '../../../customWdget/custom_input2.dart';
import '../../../customWdget/mobileBottomNavBar.dart';
import '../../../models/alert.dart';
import '../../../models/ticket.dart';
import '../../../services/notification_api_service.dart';
import '../../../services/ticket_api_service.dart';
import '../../notification.dart';
import '../breakpoints.dart';
import 'landingMobileController.dart';

class SupportMobile extends StatefulWidget {
  @override
  _SupportMobileState createState() => _SupportMobileState();
}

bool isFromDashboard = false;

class _SupportMobileState extends State<SupportMobile>
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
    final bool isMobile = Breakpoints.isMobile(context);

    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: isFromDashboard
              ? IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {});
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Constants.ftaColorLight,
                    elevation: 5,
                    shadowColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    CupertinoIcons.back,
                    color: Constants.ftaColorLight,
                  ),
                )
              : IconButton(
                  onPressed: () {
                    currentIndex = 0;
                    currentControllerValueNotifier.value++;
                    setState(() {});
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Constants.ftaColorLight,
                    elevation: 5,
                    shadowColor: Colors.black54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    CupertinoIcons.back,
                    color: Constants.ftaColorLight,
                  ),
                ),
          title: Text(
            'Support',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Container(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: spacing.paddingLarge,
                  right: spacing.paddingLarge,
                  top: spacing.spacingLarge,
                ),
                constraints: BoxConstraints(maxWidth: 1600),
                child: _buildMobileLayout(typography, spacing),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Column(children: [_buildCreateTicketForm(typography, spacing)]);
  }

  Widget _buildCreateTicketForm(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),

      padding: EdgeInsets.all(spacing.spacingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline, color: Constants.ftaColorLight),
              SizedBox(width: spacing.spacingSmall),
              Text(
                'Create New Ticket',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Constants.ftaColorLight,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.spacingSmall),
          Text(
            'Fill out the form below to submit a support request',
            style: GoogleFonts.manrope(
              fontSize: typography.normal,
              fontWeight: FontWeight.w300,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset((20 * (1 - value)).toDouble(), 0),
                  child: _buildAnimatedTextField(
                    label: 'Subject',
                    hintText: 'Subject',
                    controller: _subjectController,
                    focusNode: _subjectFocusNode,
                    icon: HugeIcons.strokeRoundedSubtitle,
                    required: false,
                    delay: 200,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset((20 * (1 - value)).toDouble(), 0),
                  child: _buildAnimatedMessageField(
                    label: 'Description',
                    hintText: 'Enter your description',
                    controller: _descriptionController,
                    focusNode: _descriptionFocusNode,
                    delay: 200,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (20 * (1 - value)).toDouble()),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: _isCreatingTicket ? null : _createTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                            shadowColor: Constants.ctaColorLight.withOpacity(
                              0.3,
                            ),
                          ),
                          child: _isCreatingTicket
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: spacing.spacingSmall),
                                    Text(
                                      'Creating...',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: typography.normal,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Raise a Ticket',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: typography.normal,
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
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (20 * (1 - value)).toDouble()),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewMyTicket(),
                              ),
                            );
                            setState(() {});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ftaColorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                            shadowColor: Constants.ftaColorLight.withOpacity(
                              0.3,
                            ),
                          ),
                          child: Text(
                            'View My Tickets',
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: typography.normal,
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
          SizedBox(height: spacing.spacingLarge),
        ],
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required bool required,
    required int delay,
    Function(String)? onSubmitted,
  }) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: CustomInputTransparent4(
              hintText: hintText,
              labelText: label,
              controller: controller,
              focusNode: focusNode,
              prefix: Icon(
                icon,
                color: Constants.ctaColorLight,
                size: typography.normal,
              ),
              textInputAction: TextInputAction.next,
              isPasswordField: false,
              onChanged: (value) {},
              onSubmitted: onSubmitted ?? (value) {},
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedMessageField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Container(
              height: 120, // Bigger height for message field
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null, // Allow unlimited lines
                expands: true, // Expand to fill container height
                textAlignVertical: TextAlignVertical.top, // Start text at top
                style: GoogleFonts.manrope(
                  fontSize: Breakpoints.isTablet(context)
                      ? ResponsiveTypography.getTypography(context).normal
                      : 14,
                  color: Colors.black87,
                ),

                decoration: InputDecoration(
                  hintText: hintText.replaceAll('*', ''),
                  hintStyle: GoogleFonts.manrope(
                    fontSize: Breakpoints.isTablet(context)
                        ? ResponsiveTypography.getTypography(context).normal
                        : 14,
                    color: Colors.grey[500],
                  ),
                  labelText: label.replaceAll('*', ''),
                  labelStyle: TextStyle(
                    color: Constants.ftaColorLight,
                    fontSize: Breakpoints.isTablet(context)
                        ? ResponsiveTypography.getTypography(context).normal
                        : 14,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Constants.ftaColorLight,
                    fontSize: Breakpoints.isTablet(context)
                        ? ResponsiveTypography.getTypography(context).normal
                        : 14,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Constants.ftaColorLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Color(0xFFF5A623), width: 2),
                  ),
                  contentPadding: Breakpoints.isTablet(context)
                      ? EdgeInsets.all(
                          ResponsiveSpacing.getSpacing(context).paddingMedium,
                        )
                      : EdgeInsets.all(16), // More padding for bigger field
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ViewMyTicket extends StatefulWidget {
  @override
  _ViewMyTicketState createState() => _ViewMyTicketState();
}

class _ViewMyTicketState extends State<ViewMyTicket>
    with TickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);

    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Constants.ftaColorLight,
              elevation: 5,
              shadowColor: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(CupertinoIcons.back, color: Constants.ftaColorLight),
          ),
          title: Text(
            'My Tickets',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  left: spacing.paddingLarge,
                  right: spacing.paddingLarge,
                  top: spacing.spacingLarge,
                ),
                constraints: BoxConstraints(maxWidth: 1600),
                child: _buildMobileLayout(typography, spacing),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Column(children: [_buildMyTicketsList(typography, spacing)]);
  }

  Widget _buildMyTicketsList(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return AnimatedContainer(
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
      padding: EdgeInsets.all(spacing.paddingLarge),
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: _isLoadingTickets
                ? Center(
                    child: CircularProgressIndicator(
                      color: Constants.ftaColorLight,
                    ),
                  )
                : tickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: spacing.spacingMedium),
                        Text(
                          (_authUserUid == null || _authUserUid!.isEmpty)
                              ? 'Please login to view tickets'
                              : 'No tickets yet',
                          style: GoogleFonts.manrope(
                            fontSize: typography.medium,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: spacing.spacingSmall),
                        Text(
                          (_authUserUid == null || _authUserUid!.isEmpty)
                              ? 'Login to access support'
                              : 'Create your first support ticket',
                          style: GoogleFonts.manrope(
                            fontSize: typography.normal,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
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
                              offset: Offset((-30 * (1 - value)).toDouble(), 0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatMobileScreen(ticket: ticket),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    bottom: spacing.spacingSmall,
                                  ),
                                  padding: EdgeInsets.all(
                                    spacing.paddingMedium,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade50,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Constants.ftaColorLight
                                          .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Constants.ftaColorLight
                                            .withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ticket.title,
                                              style: GoogleFonts.manrope(
                                                fontSize: typography.normal,
                                                fontWeight: FontWeight.w600,
                                                color: Constants.ftaColorLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: spacing.spacingSmall),
                                          TweenAnimationBuilder<double>(
                                            duration: Duration(
                                              milliseconds: 600,
                                            ),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, badgeValue, child) {
                                              return Transform.scale(
                                                scale: badgeValue,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        spacing.paddingSmall,
                                                    vertical:
                                                        spacing.paddingSmall /
                                                        2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        ticket.status ==
                                                            'Pending'
                                                        ? Colors.grey[400]
                                                        : Constants
                                                              .ctaColorLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    ticket.status,
                                                    style: GoogleFonts.manrope(
                                                      color: Colors.white,
                                                      fontSize:
                                                          typography.normal *
                                                          0.8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing.spacingSmall),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ticket.ticketId,
                                              style: GoogleFonts.manrope(
                                                fontSize:
                                                    typography.normal * 0.85,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w300,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            ticket.date,
                                            style: GoogleFonts.manrope(
                                              fontSize:
                                                  typography.normal * 0.85,
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
    );
  }
}

class SellerSupportMobile extends StatefulWidget {
  @override
  _SellerSupportMobileState createState() => _SellerSupportMobileState();
}

class _SellerSupportMobileState extends State<SellerSupportMobile>
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
    final bool isMobile = Breakpoints.isMobile(context);

    // This widget should ONLY be used on mobile devices
    if (!isMobile) {
      return Container(
        child: Center(
          child: Text(
            'This view is only available on mobile devices',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(height: spacing.spacingLarge),
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    left: spacing.paddingLarge,
                    right: spacing.paddingLarge,
                    top: spacing.spacingLarge,
                  ),
                  constraints: BoxConstraints(maxWidth: 1600),
                  child: _buildMobileLayoutSeller(typography, spacing),
                ),
                SizedBox(height: spacing.spacingLarge),
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 1600),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (20 * (1 - value)).toDouble()),
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

  Widget _buildMobileLayoutSeller(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Column(
      children: [
        _buildCreateTicketFormSeller(typography, spacing),
        SizedBox(height: spacing.spacingLarge),
        _buildMyTicketsListSeller(typography, spacing),
      ],
    );
  }

  Widget _buildMyTicketsListSeller(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return AnimatedContainer(
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
      padding: EdgeInsets.all(spacing.paddingLarge),
      height: 400,
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
                      size: typography.large,
                    ),
                    SizedBox(width: spacing.spacingSmall),
                    Text(
                      'My Tickets',
                      style: GoogleFonts.manrope(
                        fontSize: typography.subHeading,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: spacing.spacingMedium),
                        Text(
                          (_authUserUid == null || _authUserUid!.isEmpty)
                              ? 'Please login to view tickets'
                              : 'No tickets yet',
                          style: GoogleFonts.manrope(
                            fontSize: typography.medium,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: spacing.spacingSmall),
                        Text(
                          (_authUserUid == null || _authUserUid!.isEmpty)
                              ? 'Login to access support'
                              : 'Create your first support ticket',
                          style: GoogleFonts.manrope(
                            fontSize: typography.normal,
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
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 1000 + (index * 200)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset((-30 * (1 - value)).toDouble(), 0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatMobileScreen(ticket: ticket),
                                    ),
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    bottom: spacing.spacingSmall,
                                  ),
                                  padding: EdgeInsets.all(
                                    spacing.paddingMedium,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.grey.shade50,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Constants.ftaColorLight
                                          .withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Constants.ftaColorLight
                                            .withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ticket.title,
                                              style: GoogleFonts.manrope(
                                                fontSize: typography.normal,
                                                fontWeight: FontWeight.w600,
                                                color: Constants.ftaColorLight,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: spacing.spacingSmall),
                                          TweenAnimationBuilder<double>(
                                            duration: Duration(
                                              milliseconds: 600,
                                            ),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, badgeValue, child) {
                                              return Transform.scale(
                                                scale: badgeValue,
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        spacing.paddingSmall,
                                                    vertical:
                                                        spacing.paddingSmall /
                                                        2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        ticket.status ==
                                                            'Pending'
                                                        ? Colors.grey[400]
                                                        : Constants
                                                              .ctaColorLight,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    ticket.status,
                                                    style: GoogleFonts.manrope(
                                                      color: Colors.white,
                                                      fontSize:
                                                          typography.normal *
                                                          0.8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing.spacingSmall),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ticket.ticketId,
                                              style: GoogleFonts.manrope(
                                                fontSize:
                                                    typography.normal * 0.85,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w300,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            ticket.date,
                                            style: GoogleFonts.manrope(
                                              fontSize:
                                                  typography.normal * 0.85,
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
    );
  }

  Widget _buildCreateTicketFormSeller(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return AnimatedContainer(
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
      padding: EdgeInsets.all(spacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Constants.ctaColorLight,
                size: typography.large,
              ),
              SizedBox(width: spacing.spacingSmall),
              Text(
                'Create New Ticket',
                style: GoogleFonts.manrope(
                  fontSize: typography.subHeading,
                  fontWeight: FontWeight.bold,
                  color: Constants.ctaColorLight,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.spacingSmall),
          Text(
            'Fill out the form below to submit a support request',
            style: GoogleFonts.manrope(
              fontSize: typography.normal,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset((20 * (1 - value)).toDouble(), 0),
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
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset((20 * (1 - value)).toDouble(), 0),
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
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1400),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (20 * (1 - value)).toDouble()),
                  child: Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        child: ElevatedButton(
                          onPressed: _isCreatingTicket ? null : _createTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                            shadowColor: Constants.ctaColorLight.withOpacity(
                              0.3,
                            ),
                          ),
                          child: _isCreatingTicket
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: spacing.spacingSmall),
                                    Text(
                                      'Creating...',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: typography.normal,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Raise a Ticket',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: typography.normal,
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
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: spacing.paddingSmall),
          child: Text(
            hintText,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: typography.normal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: spacing.spacingSmall),
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
                  fontSize: typography.normal,
                  color: Colors.grey.withOpacity(0.7),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(spacing.paddingMedium),
              ),
              style: GoogleFonts.manrope(
                fontSize: typography.normal,
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

class ChatMobileScreen extends StatefulWidget {
  final Ticket ticket;

  const ChatMobileScreen({super.key, required this.ticket});

  @override
  _ChatMobileScreenState createState() => _ChatMobileScreenState();
}

class _ChatMobileScreenState extends State<ChatMobileScreen>
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
    final bool isMobile = Breakpoints.isMobile(context);
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Container(
      margin: EdgeInsets.only(
        left: message.isMe ? spacing.paddingLarge : spacing.paddingMedium,
        right: message.isMe ? spacing.paddingMedium : spacing.paddingLarge,
        bottom: spacing.spacingSmall,
      ),
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.paddingMedium,
              vertical: spacing.spacingSmall,
            ),
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
                fontSize: typography.normal,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: spacing.spacingSmall / 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMM dd, HH:mm').format(message.timestamp),
                style: GoogleFonts.manrope(
                  color: Colors.grey[600],
                  fontSize: typography.normal * 0.8,
                ),
              ),
              if (message.isMe) ...[
                SizedBox(width: spacing.spacingSmall / 2),
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
    final bool isMobile = Breakpoints.isMobile(context);

    // This widget should ONLY be used on mobile devices
    if (!isMobile) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          child: Center(
            child: Text(
              'This view is only available on mobile devices',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

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
                fontSize: typography.medium,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.ticket.ticketId,
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: typography.normal * 0.85,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: spacing.paddingMedium),
            padding: EdgeInsets.symmetric(
              horizontal: spacing.paddingSmall,
              vertical: spacing.paddingSmall / 2,
            ),
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
                fontSize: typography.normal * 0.85,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          color: Colors.grey[50],
          child: Column(
            children: [
              // Ticket Info Header
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(spacing.paddingMedium),
                padding: EdgeInsets.all(spacing.paddingLarge),
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
                            HugeIcons.strokeRoundedCustomerSupport,
                            color: Constants.ftaColorLight,
                            size: typography.medium,
                          ),
                        ),
                        SizedBox(width: spacing.spacingSmall),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned to ${widget.ticket.assignee?['name'] ?? 'Support Team'}',
                                style: GoogleFonts.manrope(
                                  fontSize: typography.normal,
                                  fontWeight: FontWeight.w600,
                                  color: Constants.ftaColorLight,
                                ),
                              ),
                              Text(
                                'Created on ${widget.ticket.date}',
                                style: GoogleFonts.manrope(
                                  fontSize: typography.normal * 0.85,
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
                  margin: EdgeInsets.symmetric(
                    horizontal: spacing.paddingMedium,
                  ),
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
                              offset: Offset(0, (20 * (1 - value)).toDouble()),
                              child: _buildMessageBubble(
                                _messages[index],
                                index,
                              ),
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
                padding: EdgeInsets.all(spacing.paddingMedium),
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
                        fontSize: typography.normal,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: spacing.spacingSmall),
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
                            fontSize: typography.normal,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(spacing.paddingMedium),
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: typography.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.spacingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: double.infinity,
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
                                SizedBox(width: spacing.spacingSmall / 2),
                                Text(
                                  'Send',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: typography.normal,
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
      ),
    );
  }
}

class BuyerDashboardHeader extends StatefulWidget {
  final String headerName;
  final int totalAlert;
  const BuyerDashboardHeader({
    super.key,
    required this.headerName,
    required this.totalAlert,
  });

  @override
  State<BuyerDashboardHeader> createState() => _BuyerDashboardHeaderState();
}

List<WebNotification> notifications = [];

class _BuyerDashboardHeaderState extends State<BuyerDashboardHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
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
    _loadNotificationsFromApi();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationsFromApi() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Use the user's UUID from Constants
      final userUuid = Constants.currentUser?.uid ?? Constants.myUid;
      if (userUuid.isNotEmpty) {
        final fetchedNotifications = await _notificationApiService
            .getUserNotifications(userUuid);
        if (mounted) {
          setState(() {
            notifications = fetchedNotifications;
            _isLoadingNotifications = false;
          });
        }
      } else {
        // If no user UUID, set empty notifications
        if (mounted) {
          setState(() {
            notifications = [];
            _isLoadingNotifications = false;
          });
        }
      }
    } catch (e) {
      print('Error loading notifications from API: $e');
      // On error, set empty notifications
      if (mounted) {
        setState(() {
          notifications = [];
          _isLoadingNotifications = false;
        });
      }
    }
  }

  void _showNotificationDialog() {
    // Only refresh notifications if we don't have any yet
    if (notifications.isEmpty && !_isLoadingNotifications) {
      _loadNotificationsFromApi();
    }
    _animationController.forward();
    showDialog(
      context: context,
      barrierDismissible: true,

      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAlertStats(),
                  const SizedBox(height: 20),
                  _buildRecentNotifications(),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Constants.buyerAppBarValue = 8;
                        //appBarValueNotifier.value++;
                        //sellerHomeValueNotifier.value++;
                      },
                      child: Text(
                        'More Notifications',
                        style: TextStyle(
                          color: Constants.ctaColorLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _animationController.reset();
    });
  }

  Widget _buildAlertStats() {
    // Calculate stats from actual notifications
    final totalNotifications = notifications.length;
    final readNotifications = notifications.where((n) => n.read).length;
    final unreadNotifications = notifications.where((n) => !n.read).length;

    return Column(
      children: [
        _buildStatItem('Total Notifications', totalNotifications.toString()),
        const SizedBox(height: 8),
        _buildStatItem('Read Notifications', readNotifications.toString()),
        const SizedBox(height: 8),
        _buildStatItem('Unread Notifications', unreadNotifications.toString()),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
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
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotifications() {
    if (_isLoadingNotifications) {
      return Container(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Constants.ctaColorLight,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading notifications...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: notification.read
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
    final bool isMobile = Breakpoints.isMobile(context);

    // This widget should ONLY be used on mobile devices
    if (!isMobile) {
      return Container(
        child: Center(
          child: Text(
            'This view is only available on mobile devices',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }

    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Container(
      height: 60,
      width: MediaQuery.of(context).size.width,
      color: Constants.ctaColorLight,
      padding: EdgeInsets.only(
        left: spacing.paddingLarge,
        right: spacing.paddingLarge,
        top: spacing.paddingSmall,
        bottom: spacing.paddingSmall,
      ),
      child: Row(
        children: [
          Text(
            widget.headerName,
            style: GoogleFonts.manrope(
              color: Constants.ftaColorLight,
              fontSize: typography.medium,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          badges.Badge(
            position: badges.BadgePosition.topEnd(top: -6, end: -6),
            showBadge: true,
            ignorePointer: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(notifications: []),
                ),
              );
            },
            badgeContent: Text(
              widget.totalAlert.toString(),
              style: GoogleFonts.manrope(
                fontSize: typography.normal * 0.7,
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
              padding: EdgeInsets.all(spacing.paddingSmall / 2),
              borderRadius: BorderRadius.circular(10),
              elevation: 3,
            ),
            child: Container(
              padding: EdgeInsets.all(spacing.paddingSmall),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Constants.ftaColorLight,
              ),
              child: Icon(
                HugeIcons.strokeRoundedNotification01,
                size: typography.medium,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
