import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/seller/profile_management.dart';
import 'package:bidr/pages/seller/rating_and_review.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

import '../../customWdget/appbar.dart';
import '../../models/alert.dart';
import '../../services/products_management_api_service.dart';
import '../buyer/share_with_friends.dart';
import '../buyer/support.dart';
import '../buyer_home.dart';
import 'enter_pin.dart';

enum LeadStatus { open, closed, unsuccessful, pending, inProgress }

class SellerDashboard extends StatefulWidget {
  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

List<WebNotification> notifications = [];

class _SellerDashboardState extends State<SellerDashboard>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  int tabActiveIndex = 0;
  int selectedSubIndex = 0; // For transaction history tabs
  bool isPinVerifiedSuccessful = false;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // API data state variables
  List<dynamic> newRequests = [];
  List<dynamic> processedRequests = [];
  bool isLoadingRequests = true;
  String? requestsError;
  int totalNewRequests = 0;
  int totalProcessedRequests = 0;
  Map<String, dynamic>? sellerLocation;

  // Quotes data state variables
  List<dynamic> myQuotes = [];
  bool isLoadingQuotes = true;
  String? quotesError;
  int totalQuotes = 0;

  // Tab and pagination state
  int selectedRequestTab = 0; // 0: New Requests, 1: My Bids
  int currentPage = 1;
  int itemsPerPage = 12; // 4x4 grid

  // Tab labels
  List<String> requestTabLabels = ['New Requests', 'My Requests'];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<String> menuItems = [
    'Revenue Tracker',
    'Transaction History',
    'Manage Disputes',
    'Analytics',
  ];
  StatusConfig getStatusConfig(LeadStatus status) {
    switch (status) {
      case LeadStatus.open:
        return StatusConfig(
          displayName: 'Open',
          color: Constants.ftaColorLight,
          isActive: true,
        );
      case LeadStatus.closed:
        return StatusConfig(
          displayName: 'Closed',
          color: Colors.red.shade700,
          isActive: false,
        );
      case LeadStatus.unsuccessful:
        return StatusConfig(
          displayName: 'Unsuccessful',
          color: Color(0xFFD62828).withOpacity(0.45),
          isActive: false,
        );
      case LeadStatus.pending:
        return StatusConfig(
          displayName: 'Pending',
          color: Color(0xFFFCA32C),
          isActive: true,
        );
      case LeadStatus.inProgress:
        return StatusConfig(
          displayName: 'In Progress',
          color: Colors.green,
          isActive: true,
        );
    }
  }

  Future<void> showPinDialog({
    required BuildContext context,
    Function(String pin)? onPinCompleted,
    Function()? onCancel,
    int pinLength = 4,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PinEntryDialog(
          onPinCompleted: onPinCompleted,
          onCancel: onCancel,
          pinLength: pinLength,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSampleNotifications();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.3, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    // Check location permission and load requests data
    _checkLocationPermissionAndFetchData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _priceController.dispose();
    _commentsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _animateContentChange() {
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkLocationPermissionAndFetchData() async {
    // For web, directly try to get location which will prompt for permission
    await _getCurrentLocation();
    _fetchRequestsData();
    _fetchQuotesData();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location is already available
      if (Constants.myLatitude != null && Constants.myLongitude != null) {
        print(
          'Using existing location: lat=${Constants.myLatitude}, lng=${Constants.myLongitude}',
        );
        return;
      }

      // Use HTML5 geolocation for web
      final position = await _getWebLocation();
      if (position != null) {
        Constants.myLatitude = position['latitude'];
        Constants.myLongitude = position['longitude'];
        print(
          'Location updated: lat=${Constants.myLatitude}, lng=${Constants.myLongitude}',
        );
      } else {
        throw Exception('Unable to get location');
      }
    } catch (e) {
      print('Error getting location: $e');
      // Show location permission dialog for web
      if (mounted) {
        _showLocationPermissionDialog();
      }
      // Set default location (Johannesburg) if location fails
      Constants.myLatitude = -26.2041;
      Constants.myLongitude = 28.0473;
    }
  }

  Future<Map<String, double>?> _getWebLocation() async {
    try {
      final position = await html.window.navigator.geolocation
          .getCurrentPosition();
      return {
        'latitude': position.coords!.latitude!.toDouble(),
        'longitude': position.coords!.longitude!.toDouble(),
      };
    } catch (e) {
      print('Web geolocation error: $e');
      return null;
    }
  }

  Future<void> _showLocationPermissionDialog({
    bool isPermanentlyDenied = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Access'),
          content: Text(
            'This app needs location access to show you nearby requests. Please allow location access when prompted by your browser.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Skip'),
              onPressed: () {
                Navigator.of(context).pop();
                // Keep default coordinates and proceed
              },
            ),
            TextButton(
              child: Text('Try Again'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _getCurrentLocation();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchRequestsData() async {
    try {
      setState(() {
        isLoadingRequests = true;
        requestsError = null;
      });

      final response = await ApiService.getRequestsBySeller(
        authUserUid: Constants.myUid,
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          newRequests = data['new_requests'] ?? [];
          processedRequests = data['processed_requests'] ?? [];
          totalNewRequests = data['total_new_requests'] ?? 0;
          totalProcessedRequests = data['total_processed_requests'] ?? 0;
          sellerLocation = data['seller_location'];
          isLoadingRequests = false;
        });

        print('New requests: ${newRequests.length}');
        print('Processed requests: ${processedRequests.length}');
      } else {
        setState(() {
          requestsError = response['message'] ?? 'Failed to load requests';
          isLoadingRequests = false;
        });
      }
    } catch (e) {
      setState(() {
        requestsError = 'Network error: ${e.toString()}';
        isLoadingRequests = false;
      });
    }
  }

  Future<void> _fetchQuotesData() async {
    try {
      setState(() {
        isLoadingQuotes = true;
        quotesError = null;
      });

      final response = await ApiService.getQuotesBySeller();

      if (response['success'] == true) {
        setState(() {
          myQuotes = response['quotes'] ?? [];
          totalQuotes = response['total_count'] ?? 0;
          isLoadingQuotes = false;
        });

        print('My quotes: ${myQuotes.length}');
      } else {
        setState(() {
          quotesError = response['message'] ?? 'Failed to load quotes';
          isLoadingQuotes = false;
        });
      }
    } catch (e) {
      setState(() {
        quotesError = 'Network error: ${e.toString()}';
        isLoadingQuotes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.read).length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 66, vertical: 15),
              decoration: BoxDecoration(color: Constants.ftaColorLight),
              child: Row(
                children: [
                  Text(
                    'Seller Dashboard',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight,
                      shape: BoxShape.circle,
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined),
                              onPressed: _showNotificationDialog,
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 15),
                  Icon(
                    HugeIcons.strokeRoundedFilter,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
            // Orange Navigation Bar
            SizedBox(height: 24),
            // Main Content Area
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 64, right: 64),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    constraints: BoxConstraints(maxWidth: 1600),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          () {
                            print('Dashboard tab clicked');
                            setState(() {
                              tabActiveIndex = 0;
                            });
                          },
                          HugeIcons.strokeRoundedDashboardSquare01,
                          'My Dashboard',
                          tabActiveIndex == 0 ? true : false,
                        ),
                        _buildNavItem(
                          () {
                            setState(() {
                              tabActiveIndex = 1;
                            });
                          },
                          HugeIcons.strokeRoundedBook01,
                          'My Bookkeeper',
                          tabActiveIndex == 1 ? true : false,
                        ),
                        _buildNavItem(
                          () {
                            setState(() {
                              tabActiveIndex = 2;
                            });
                          },
                          HugeIcons.strokeRoundedCustomerSupport,
                          'Support (BIDR)',
                          tabActiveIndex == 2 ? true : false,
                        ),
                        _buildNavItem(
                          () {
                            setState(() {
                              tabActiveIndex = 3;
                            });
                          },
                          HugeIcons.strokeRoundedUserAdd01,
                          'Refer a Friend/Business',
                          tabActiveIndex == 3 ? true : false,
                        ),
                        _buildNavItem(
                          () {
                            setState(() {
                              tabActiveIndex = 4;
                            });
                          },
                          HugeIcons.strokeRoundedStar,
                          'Review & Rating Manager',
                          tabActiveIndex == 4 ? true : false,
                        ),
                        _buildNavItem(
                          () {
                            setState(() {
                              tabActiveIndex = 5;
                            });
                          },
                          HugeIcons.strokeRoundedProfile,
                          'Profile Management',
                          tabActiveIndex == 5 ? true : false,
                        ),
                      ],
                    ),
                  ),
                ),
                if (tabActiveIndex == 0)
                  ...[]
                else if (tabActiveIndex == 1) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 64, right: 64),
                    child: Container(
                      height: 900,
                      width: MediaQuery.of(context).size.width,
                      constraints: BoxConstraints(maxWidth: 1600),
                      padding: EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Sidebar
                          Container(
                            width: 180,
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(height: 10),
                                ...menuItems.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  String item = entry.value;
                                  return _buildMenuItem(item, index);
                                }).toList(),
                              ],
                            ),
                          ),
                          // Main Content
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(20),
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildMainContent(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (tabActiveIndex == 2) ...[
                  Support(),
                ] else if (tabActiveIndex == 3) ...[
                  ShareWidget(),
                ] else if (tabActiveIndex == 4) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 64, right: 64),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      constraints: BoxConstraints(maxWidth: 1600),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: ReviewScreen(),
                    ),
                  ),
                ] else if (tabActiveIndex == 5) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 64, right: 64),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      constraints: BoxConstraints(maxWidth: 1600),
                      //padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: ProfileManagement(),
                    ),
                  ),
                ] else ...[
                  Container(),
                ],
                SizedBox(height: 24),
                FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _loadSampleNotifications() {
    setState(() {
      notifications = [
        WebNotification(
          id: 1,
          title: 'Request Accept',
          body: 'John Doe has accepted the concern. He help...',
          description:
              'John Doe has accepted the concern. He will help you with your request.',
          type: 'accept',
          read: false,
          createdAt: DateTime.now(),
        ),
        WebNotification(
          id: 2,
          title: 'Bank Details Update Succesfully',
          body: 'Lorem ipsum is a placeholder text commonly',
          description:
              'Lorem ipsum is a placeholder text commonly used in the printing industry.',
          type: 'update',
          read: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        WebNotification(
          id: 3,
          title: 'Your Profile Is Update Succesfully',
          body: 'Lorem ipsum is a placeholder text commonly',
          description:
              'Lorem ipsum is a placeholder text commonly used in the printing industry.',
          type: 'update',
          read: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        WebNotification(
          id: 4,
          title: 'Seller Profile Update Succesfully',
          body: 'Lorem ipsum is a placeholder text commonly',
          description:
              'Lorem ipsum is a placeholder text commonly used in the printing industry.',
          type: 'update',
          read: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        WebNotification(
          id: 5,
          title: 'New Order Received',
          body: 'You have received a new order from customer',
          description:
              'You have received a new order from customer. Please check your dashboard.',
          type: 'order',
          read: false,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];
    });
  }

  void _showNotificationDialog() {
    _animationController.forward();
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
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
                        appBarValueNotifier.value++;
                        sellerHomeValueNotifier.value++;
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
    return Column(
      children: [
        _buildStatItem('Requests Received', '100'),
        const SizedBox(height: 8),
        _buildStatItem('Requests Answered', '50'),
        const SizedBox(height: 8),
        _buildStatItem('Requests Pending', '50'),
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

  LeadStatus _getLeadStatus(String? status) {
    if (status == null) return LeadStatus.pending;

    switch (status.toLowerCase()) {
      case 'open':
        return LeadStatus.open;
      case 'closed':
        return LeadStatus.closed;
      case 'unsuccessful':
        return LeadStatus.unsuccessful;
      case 'pending':
        return LeadStatus.pending;
      case 'in_progress':
      case 'inprogress':
        return LeadStatus.inProgress;
      default:
        return LeadStatus.pending;
    }
  }

  Widget buildLeadsRequestsWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'LEADS/REQUESTS',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Constants.ftaColorLight,
              ),
            ),
            Spacer(),
            if (isLoadingRequests)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Constants.ftaColorLight,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 16),

        // Error handling
        if (requestsError != null)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    requestsError!,
                    style: GoogleFonts.manrope(
                      color: Colors.red.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(onPressed: _fetchRequestsData, child: Text('Retry')),
              ],
            ),
          )
        // Loading state
        else if (isLoadingRequests)
          Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        // Main content with tabs
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left sidebar with tabs (bookkeeper style)
              Container(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 10),
                    // New Requests Tab
                    _buildRequestMenuItem(
                      'New Requests ($totalNewRequests)',
                      0,
                      totalNewRequests,
                    ),
                    // My Bids Tab
                    _buildRequestMenuItem(
                      'My Bids ($totalQuotes)',
                      1,
                      totalQuotes,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 20),
              // Main content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content based on selected tab
                    if (selectedRequestTab == 0)
                      _buildRequestContent(newRequests, 'new requests')
                    else
                      _buildQuotesContent(myQuotes, 'my bids'),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLeadCard({
    required String uuid,
    required LeadStatus status,
    required String description,
    required String additionalNotes,
  }) {
    final statusConfig = getStatusConfig(status);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: statusConfig.displayName == "Open"
            ? Colors.white
            : statusConfig.displayName == "Closed"
            ? Color(0xFFE7E7E7)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  uuid,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                    SizedBox(width: 4),
                    Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                    SizedBox(width: 4),
                    Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                    SizedBox(width: 4),
                    Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: statusConfig.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusConfig.displayName,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Description:',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Constants.ftaColorLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              description,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Additional Notes:',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Constants.ftaColorLight,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              additionalNotes,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (statusConfig.displayName == "Open") ...[
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showBidDialog(context, {}),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Bid',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showFlagDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Constants.ftaColorLight,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'Flag',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Constants.ctaColorLight,
                        padding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: Text(
                        'Request More Info',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: Constants.ftaColorLight,
                        padding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: Text(
                        'Full Description',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Tab menu item using bookkeeper style
  Widget _buildRequestMenuItem(String title, int index, int count) {
    bool isSelected = selectedRequestTab == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.23),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          print('Tab clicked: $index, title: $title');
          setState(() {
            selectedRequestTab = index;
            currentPage = 1; // Reset to first page when switching tabs
          });
          print('Selected tab is now: $selectedRequestTab');
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 4),
            color: isSelected ? Colors.transparent : Constants.ftaColorLight,
          ),
          child: Text(
            title,
            style: GoogleFonts.manrope(
              color: isSelected ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Content area for selected tab
  Widget _buildRequestContent(List<dynamic> requests, String type) {
    print('Building request content for $type with ${requests.length} items');

    if (requests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'No ${type.replaceAll('requests', 'requests')} found',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You haven\'t received any $type yet.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate pagination
    final totalPages = (requests.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedRequests = requests.sublist(
      startIndex,
      endIndex > requests.length ? requests.length : endIndex,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4x4 Grid of cards
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: paginatedRequests.length,
              itemBuilder: (context, index) {
                final request = paginatedRequests[index];
                final globalIndex =
                    startIndex + index + 1; // +1 for 1-based indexing
                return _buildOriginalLeadCard(request, globalIndex);
              },
            );
          },
        ),
        SizedBox(height: 16),
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages, requests.length),
      ],
    );
  }

  Widget _buildQuotesContent(List<dynamic> quotes, String type) {
    print('Building quotes content for $type with ${quotes.length} items');

    if (quotes.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16),
              Text(
                'No ${type.replaceAll('bids', 'bids')} found',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You haven\'t submitted any $type yet.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate pagination
    final totalPages = (quotes.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedQuotes = quotes.sublist(
      startIndex,
      endIndex > quotes.length ? quotes.length : endIndex,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 4x3 Grid of quote cards
        LayoutBuilder(
          builder: (context, constraints) {
            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: paginatedQuotes.length,
              itemBuilder: (context, index) {
                final quote = paginatedQuotes[index];
                final globalIndex = startIndex + index + 1;
                return _buildQuoteCard(quote, globalIndex);
              },
            );
          },
        ),
        SizedBox(height: 16),
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages, quotes.length),
      ],
    );
  }

  // Updated card design to match screenshot
  Widget _buildOriginalLeadCard(
    Map<String, dynamic> request,
    int requestNumber,
  ) {
    final title = request['title'] ?? "";
    final businessName = request['business_name'] ?? '';
    final createdAt = request['created_at'] ?? '';
    final purchasedPrice = request['purchased_price'] ?? '';
    final rating = request['rating'] ?? '3/5';
    final distance = request['distance'] ?? '30KM';
    final location = request['location'] ?? '';
    final comments = request['comments'] ?? '';
    final quotesCount = (request['quotes'] as List?)?.length ?? 0;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with business name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'REQUEST #$requestNumber',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),

            // Product title
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),

            // Date/time and status badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateTime(createdAt),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Ongoing',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // View Details link
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  // Handle view details
                },
                child: Text(
                  'View Details',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),

            // Purchase price
            Row(
              children: [
                Text(
                  'Purchased Price: ',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  purchasedPrice,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),

            // Rating
            Row(
              children: [
                Text(
                  'Rating: ',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  rating,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),

            // Distance
            Row(
              children: [
                Text(
                  'Radius/Distance: ',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  distance,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),

            // Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location: ',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    location,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Comments section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comments:',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  comments,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            SizedBox(height: 8),

            // Collect Goods button with car icon
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showBidDialog(context, request);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      quotesCount > 0 ? 'Update Bid' : 'Place Bid',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Format date to display as "04/03/2025 - 10:34 PM"
  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) {
      return '04/03/2025 - 10:34 PM'; // Default fallback
    }

    try {
      // Try to parse the API date string (assuming ISO format)
      DateTime dateTime;
      if (dateTimeString.contains('T')) {
        // ISO format like "2025-03-04T22:34:00Z"
        dateTime = DateTime.parse(dateTimeString);
      } else if (dateTimeString.contains('/')) {
        // Already in the desired format
        return dateTimeString;
      } else {
        // Fallback for other formats
        dateTime = DateTime.parse(dateTimeString);
      }

      // Format to "04/03/2025 - 10:34 PM"
      final dateFormatter = DateFormat('dd/MM/yyyy');
      final timeFormatter = DateFormat('h:mm a');

      return '${dateFormatter.format(dateTime)} - ${timeFormatter.format(dateTime)}';
    } catch (e) {
      // If parsing fails, return default
      return '04/03/2025 - 10:34 PM';
    }
  }

  // Convert API status to LeadStatus enum
  LeadStatus _getLeadStatusFromApi(String apiStatus, int quotesCount) {
    switch (apiStatus.toUpperCase()) {
      case 'ACTIVE':
        return quotesCount > 0 ? LeadStatus.inProgress : LeadStatus.open;
      case 'CLOSED':
        return LeadStatus.closed;
      case 'EXPIRED':
        return LeadStatus.unsuccessful;
      default:
        return LeadStatus.pending;
    }
  }

  // Pagination widget
  Widget _buildPagination(int totalPages, int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Total: $totalItems items',
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(width: 24),
        // Previous button
        if (currentPage > 1)
          IconButton(
            onPressed: () => _goToPage(currentPage - 1),
            icon: Icon(Icons.chevron_left, color: Colors.grey[600]),
          ),
        // Page numbers (show max 5)
        ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
          int pageNum;
          if (totalPages <= 5) {
            pageNum = index + 1;
          } else {
            int startPage = currentPage - 2;
            if (startPage < 1) startPage = 1;
            if (startPage + 4 > totalPages) startPage = totalPages - 4;
            pageNum = startPage + index;
          }

          return GestureDetector(
            onTap: () => _goToPage(pageNum),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pageNum == currentPage
                    ? Constants.ctaColorLight
                    : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: pageNum == currentPage
                      ? Constants.ctaColorLight
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                '$pageNum',
                style: GoogleFonts.manrope(
                  color: pageNum == currentPage ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
        // Next button
        if (currentPage < totalPages)
          IconButton(
            onPressed: () => _goToPage(currentPage + 1),
            icon: Icon(Icons.chevron_right, color: Colors.grey[600]),
          ),
      ],
    );
  }

  void _goToPage(int page) {
    setState(() {
      currentPage = page;
    });
  }

  Widget _buildQuoteCard(Map<String, dynamic> quote, int quoteNumber) {
    final totalAmount = quote['total_amount']?.toString() ?? '0';
    final currency = quote['currency'] ?? 'ZAR';
    final status = quote['status'] ?? 'PENDING';
    final createdAt = quote['created_at'] ?? '';
    final quoteId = quote['quote_id'] ?? 'N/A';
    final estimatedDeliveryDays =
        quote['estimated_delivery_days']?.toString() ?? 'N/A';
    final sellerNotes = quote['seller_notes'] ?? '';

    // Get request info if available
    final requestInfo = quote['request_id'] ?? {};
    final requestTitle = requestInfo is Map
        ? (requestInfo['title'] ?? 'Request')
        : 'Request';
    final requestId = requestInfo is Map
        ? (requestInfo['request_id'] ?? 'N/A')
        : 'N/A';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with quote number and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BID #$quoteNumber',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'ACCEPTED'
                        ? Colors.green[100]
                        : status == 'REJECTED'
                        ? Colors.red[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: status == 'ACCEPTED'
                          ? Colors.green[700]
                          : status == 'REJECTED'
                          ? Colors.red[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // Request title
            Text(
              requestTitle,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),

            // Date and quote ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDateTime(createdAt),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '#${quoteId.substring(0, 8)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Bid amount
            Row(
              children: [
                Text(
                  'Bid Amount: ',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$currency $totalAmount',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),

            // Delivery time
            Row(
              children: [
                Text(
                  'Delivery: ',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$estimatedDeliveryDays days',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            if (sellerNotes.isNotEmpty) ...[
              SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes:',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    sellerNotes,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],

            SizedBox(height: 16),

            // View Details button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle view quote details
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'View Details',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enter Bid Details',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  'Best Price Advice',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Submit precise, best offer upfront, as there is no certainty of negotiation. If your initial bid is reasonable, you have a higher chance of securing the business. Offering competitive price early increases your chances of converting the lead into a sale.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Price*',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _priceController,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Price',
                    hintStyle: GoogleFonts.manrope(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                Text(
                  'Comments',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _commentsController,
                  maxLines: 4,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter',
                    hintStyle: GoogleFonts.manrope(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(36),
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _handleSubmitBid(context, request);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Submit',
                      style: GoogleFonts.manrope(
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

  Future<void> _handleSubmitBid(
    BuildContext context,
    Map<String, dynamic> request,
  ) async {
    // Validate inputs
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalAmount = double.tryParse(priceText);
    if (totalAmount == null || totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final requestId = request['request_id']?.toString();
    if (requestId == null || requestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Submitting bid...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Submit the quote
      final result = await ApiService.submitQuote(
        requestId: requestId,
        totalAmount: totalAmount,
        estimatedDeliveryDays: 7, // Default to 7 days
        sellerNotes: _commentsController.text.trim().isNotEmpty
            ? _commentsController.text.trim()
            : null,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (result['success'] == true) {
        // Close bid dialog
        Navigator.of(context).pop();

        // Clear form
        _priceController.clear();
        _commentsController.clear();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bid submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data to show new bid in "My Bids"
        await _fetchRequestsData();
        await _fetchQuotesData();

        // Switch to "My Bids" tab
        setState(() {
          selectedRequestTab = 1;
        });
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit bid'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting bid: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _verifyPinDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confirm Pin',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    isPinVerifiedSuccessful
                        ? "lib/assets/images/confirmed.png"
                        : "lib/assets/images/rejected.png",
                    width: 120,
                    height: 120,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isPinVerifiedSuccessful
                      ? 'Your Unique Identification Number has been matched'
                      : "Your Unique Identification Number has not been matched",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Verify button
                isPinVerifiedSuccessful
                    ? SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                          ),
                          child: Text(
                            'Verify',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              isPinVerifiedSuccessful = true;
                              Navigator.pop(context);
                              showPinDialog(context: context);
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Constants.ctaColorLight,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                          ),
                          child: Text(
                            'Re-Enter the PIN',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
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

  void _incorrectPinDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Confirm Pin',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    "lib/assets/images/confirmed.png",
                    width: 120,
                    height: 120,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your Unique Identification Number has been matched',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                    ),
                    child: Text(
                      'Verify',
                      style: GoogleFonts.manrope(
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

  void _showFlagDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Flag This Request',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  'The specifications are erroneous. No such part is available from the manufacturer.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle flag request logic here
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Okay',
                      style: GoogleFonts.manrope(
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

  Widget _buildNavItem(
    VoidCallback voidCallBack,
    IconData icon,
    String title,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: voidCallBack,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            isActive ? SizedBox(width: 8) : SizedBox.shrink(),
            isActive
                ? Container(
                    height: 12,
                    width: 12,
                    decoration: BoxDecoration(
                      color: Constants.ftaColorLight,
                      shape: BoxShape.circle,
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String title, int index) {
    bool isSelected = selectedIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.23),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            selectedIndex = index;
            selectedSubIndex = 0;
          });
          _animateContentChange();
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 4),
            color: isSelected ? Colors.transparent : Constants.ftaColorLight,
          ),
          child: Text(
            title,
            style: GoogleFonts.manrope(
              color: isSelected ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (selectedIndex) {
      // This is now the first and default widget
      case 0:
        return _buildRevenueTracker();
      case 1:
        return _buildTransactionHistory();
      case 2:
        return _buildManageDisputes();
      case 3:
        return _buildAnalytics();
      default:
        return _buildRevenueTracker(); // Default to leads/requests
    }
  }

  Widget _buildRevenueTracker() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Revenue Card
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8E8E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Revenue',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 6539),
                        duration: Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            'R6,539',
                            style: GoogleFonts.manrope(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Constants.ctaColorLight,
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'This Month',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFBDC3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Day',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Container(
                  height: 280,
                  child: BarChart(
                    BarChartData(
                      barGroups: [
                        _buildBarGroup(0, 180),
                        _buildBarGroup(1, 240),
                        _buildBarGroup(2, 200),
                        _buildBarGroup(3, 280),
                        _buildBarGroup(4, 260),
                        _buildBarGroup(5, 160),
                        _buildBarGroup(6, 220),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  days[value.toInt()],
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 24),
          // Pie Chart with Legend
          Expanded(
            flex: 1,
            child: Container(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pie Chart
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Color(0xFF3498DB),
                            value: 23,
                            title: '',
                            radius: 20,
                          ),
                          PieChartSectionData(
                            color: Constants.ctaColorLight,
                            value: 85,
                            title: '',
                            radius: 20,
                          ),
                          PieChartSectionData(
                            color: Constants.ctaColorLight,
                            value: 183,
                            title: '',
                            radius: 20,
                          ),
                          PieChartSectionData(
                            color: Color(0xFFE74C3C),
                            value: 93,
                            title: '',
                            radius: 20,
                          ),
                        ],
                        centerSpaceRadius: 80,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Legend
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem(Color(0xFF3498DB), '2.3K', 'Option A'),
                        SizedBox(height: 8),
                        _buildLegendItem(
                          Constants.ctaColorLight,
                          '8.5K',
                          'Option B',
                        ),
                        SizedBox(height: 8),
                        _buildLegendItem(
                          Constants.ctaColorLight,
                          '18.3K',
                          'Option C',
                        ),
                        SizedBox(height: 8),
                        _buildLegendItem(Color(0xFFE74C3C), '9.3K', 'Option D'),
                      ],
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

  Widget _buildLegendItem(Color color, String value, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w400),
        ),
        SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: Constants.ctaColorLight,
          width: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      children: [
        // Tab Navigation
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildSubTab('Earning History', 0),
              _buildSubTab('Withdraw History', 1),
            ],
          ),
        ),
        SizedBox(height: 20),
        // Transaction List
        Row(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Constants.ftaColorLight, width: 2),
                ),
                child: Column(
                  children: List.generate(
                    5,
                    (index) => TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: _buildTransactionItem(),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubTab(String title, int index) {
    bool isSelected = selectedSubIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSubIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Constants.ctaColorLight : Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: isSelected ? Colors.white : Color(0xFF7F8C8D),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFECF0F1), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selectedSubIndex == 0
                  ? Color(0xFFD5EDDA)
                  : Color(0xFFF8D7DA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              selectedSubIndex == 0 ? Icons.add : Icons.remove,
              color: selectedSubIndex == 0
                  ? Constants.ctaColorLight
                  : Constants.ftaColorLight,
              size: 16,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle Service',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sep 5, 2023',
                  style: GoogleFonts.manrope(
                    color: Color(0xFF7F8C8D),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'R500',
            style: GoogleFonts.manrope(
              color: selectedSubIndex == 0
                  ? Constants.ctaColorLight
                  : Color(0xFFE74C3C),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageDisputes() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: 0.8,
                          child: _buildDisputeCard(
                            'DP-202402-00123',
                            'Mark Anthony',
                            '12 March 2024',
                            '12:36 PM',
                          ),
                        ),
                      );
                    },
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: 0.8,
                          child: _buildDisputeCard(
                            'DP-202402-00108',
                            'Juke Bezos',
                            '29 July 2024',
                            '1:45 PM',
                          ),
                        ),
                      );
                    },
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: 0.8,
                          child: _buildDisputeCard(
                            'DP-202508-10123',
                            'Sara Carla',
                            '12 August 2024',
                            '05:56 PM',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDisputeCard(String id, String name, String date, String time) {
    return Container(
      width: 300,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade900, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Row(
              children: [
                Text(
                  id,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade900,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(360),
                      topLeft: Radius.circular(360),
                    ),
                  ),
                  child: Text(
                    'OPEN',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Text(
              name,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedCalendar01,
                  size: 16,
                  color: Color(0xFF7F8C8D),
                ),
                SizedBox(width: 6),
                Text(
                  date,
                  style: GoogleFonts.manrope(
                    color: Constants.ftaColorLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              children: [
                Icon(
                  HugeIcons.strokeRoundedTime01,
                  size: 16,
                  color: Color(0xFF7F8C8D),
                ),
                SizedBox(width: 6),
                Text(
                  time,
                  style: GoogleFonts.manrope(
                    color: Constants.ftaColorLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Constants.ftaColorLight,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12), //showPinDialog
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => showPinDialog(
                      context: context,
                      onPinCompleted: (string) {
                        Navigator.pop(context);
                        _verifyPinDialog(context);
                        setState(() {});
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ftaColorLight,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(36),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAnalytics() {
    return Row(
      children: [
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Expanded(
                  child: _buildPricingCard(
                    'Starter Plan',
                    'R199',
                    '/month',
                    _getStarterFeatures(),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Expanded(
                  child: _buildPricingCard(
                    'Advance Plan',
                    'R299',
                    '/month',
                    _getAdvanceFeatures(),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: Duration(milliseconds: 1000),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Expanded(
                  child: _buildPricingCard(
                    'Ultra Advance Plan',
                    'R599',
                    '/month',
                    _getUltraFeatures(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    String title,
    String price,
    String period,
    List<String> features,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                period,
                style: GoogleFonts.manrope(
                  color: Color(0xFF7F8C8D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Display stats in Google organic search result and showcase reviews on your website',
            style: GoogleFonts.manrope(
              color: Color(0xFF7F8C8D),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20),
          ...features
              .map(
                (feature) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check,
                        color: Constants.ctaColorLight,
                        size: 16,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Buy Now',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getStarterFeatures() {
    return [
      'Unlimited Listings',
      'Advanced Analytics',
      '5 Accounts',
      'Customized Domain',
      'Made your Brand',
      'Awesome Support',
    ];
  }

  List<String> _getAdvanceFeatures() {
    return [
      'Unlimited Listings',
      'Advanced Analytics',
      '5 Accounts',
      'Customized Domain',
      'Made your Brand',
      'Awesome Support',
    ];
  }

  List<String> _getUltraFeatures() {
    return [
      'Unlimited Listings',
      'Advanced Analytics',
      '5 Accounts',
      'Customized Domain',
      'Made your Brand',
      'Awesome Support',
    ];
  }
}

class StatusConfig {
  final String displayName;
  final Color color;
  final bool isActive;

  StatusConfig({
    required this.displayName,
    required this.color,
    required this.isActive,
  });
}
