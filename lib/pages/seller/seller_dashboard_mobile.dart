import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/notification.dart';
import 'package:bidr/pages/seller/profile_management.dart';
import 'package:bidr/pages/seller/rating_and_review.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import "package:universal_html/html.dart" as html;

import '../../customWdget/appbar.dart';
import '../../customWdget/dropdownMenu.dart';
import '../../models/alert.dart';
import '../../models/request_models.dart';
import '../../services/chat_service.dart';
import '../../services/notification_api_service.dart';
import '../../services/products_management_api_service.dart';
import '../buyer/share_with_friends.dart';
import '../buyer/support.dart';
import '../buyer_home.dart';
import '../group_chat.dart';
import 'enter_pin.dart';

enum LeadStatus { open, closed, unsuccessful, pending, inProgress }

class SellerDashboardMobile extends StatefulWidget {
  @override
  _SellerDashboardMobileState createState() => _SellerDashboardMobileState();
}

List<WebNotification> notifications = [];

class _SellerDashboardMobileState extends State<SellerDashboardMobile>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  int tabActiveIndex = 0;
  int selectedSubIndex = 0; // For transaction history tabs
  bool isPinVerifiedSuccessful = false;
  bool _isLoadingNotifications = false;
  final NotificationApiService _notificationApiService =
      NotificationApiService();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  int itemsPerPage = 4; // Less items for mobile

  // Orders summary state variables
  Map<String, dynamic>? ordersSummary;
  bool isLoadingOrdersSummary = true;
  String? ordersSummaryError;
  String selectedTimeframe = 'monthly'; // daily, weekly, monthly, yearly

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

  final List<IconData> menuIcons = [
    HugeIcons.strokeRoundedChart03,
    HugeIcons.strokeRoundedClock01,
    HugeIcons.strokeRoundedAlert01,
    HugeIcons.strokeRoundedAnalyticsUp,
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
          color: Colors.orange.shade700,
          isActive: false,
        );
      case LeadStatus.pending:
        return StatusConfig(
          displayName: 'Pending',
          color: Colors.yellow.shade700,
          isActive: true,
        );
      case LeadStatus.inProgress:
        return StatusConfig(
          displayName: 'In Progress',
          color: Colors.blue.shade700,
          isActive: true,
        );
      default:
        return StatusConfig(
          displayName: 'Unknown',
          color: Colors.grey,
          isActive: false,
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    _fetchRequestsData();
    _fetchQuotesData();
    _fetchOrdersSummary();
    _loadNotifications();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
    _animationController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _animationController.dispose();
    _priceController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  // Copy all the API methods from the desktop version
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final notificationsData = await _notificationApiService
          .getUserNotifications(Constants.myUid ?? '');
      setState(() {
        notifications = notificationsData;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationApiService.markAsRead(notificationId);
      await _loadNotifications(); // Reload to update state
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationApiService.markAllAsRead(Constants.myUid ?? '');
      await _loadNotifications(); // Reload to update state
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    // Implementation from desktop version
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
          final List<dynamic> allRequests = data['results'] ?? [];

          newRequests = allRequests.where((dynamic request) {
            final List<dynamic> quotes =
                request['quotes'] as List<dynamic>? ?? [];
            return quotes.isEmpty;
          }).toList();

          processedRequests = allRequests.where((dynamic request) {
            final List<dynamic> quotes =
                request['quotes'] as List<dynamic>? ?? [];
            return quotes.isNotEmpty;
          }).toList();

          totalNewRequests = newRequests.length;
          totalProcessedRequests = processedRequests.length;
          sellerLocation = data['seller_location'];
          isLoadingRequests = false;
        });
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

  Future<void> _fetchOrdersSummary() async {
    try {
      setState(() {
        isLoadingOrdersSummary = true;
        ordersSummaryError = null;
      });

      final response = await ApiService.getSellerOrdersSummary(
        authUserUid: Constants.myUid,
        timeframe: selectedTimeframe,
      );

      if (response['success'] == true) {
        setState(() {
          ordersSummary = response['data'];
          isLoadingOrdersSummary = false;
        });
      } else {
        setState(() {
          ordersSummaryError =
              response['message'] ?? 'Failed to load orders summary';
          isLoadingOrdersSummary = false;
        });
      }
    } catch (e) {
      setState(() {
        ordersSummaryError = 'Network error: ${e.toString()}';
        isLoadingOrdersSummary = false;
      });
    }
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: NotificationDialog(
              notifications: notifications,
              isLoading: _isLoadingNotifications,
              onMarkAsRead: _markAsRead,
              onMarkAllAsRead: _markAllAsRead,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.read).length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.ftaColorLight,
        elevation: 0,
        title: Text(
          'Seller Dashboard',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  HugeIcons.strokeRoundedNotification01,
                  color: Colors.white,
                ),
                onPressed: _showNotificationDialog,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight,
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
          IconButton(
            icon: Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileManagement()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Navigation tabs
          Container(
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMobileNavItem(
                    'Dashboard',
                    0,
                    HugeIcons.strokeRoundedDashboardSquare01,
                  ),
                  _buildMobileNavItem(
                    'Products',
                    1,
                    HugeIcons.strokeRoundedShoppingBag01,
                  ),
                  _buildMobileNavItem(
                    'Chats',
                    2,
                    HugeIcons.strokeRoundedMessage01,
                  ),
                  _buildMobileNavItem(
                    'Ratings',
                    3,
                    HugeIcons.strokeRoundedStar,
                  ),
                  _buildMobileNavItem(
                    'Support',
                    4,
                    HugeIcons.strokeRoundedHeadphones,
                  ),
                  _buildMobileNavItem(
                    'Share',
                    5,
                    HugeIcons.strokeRoundedShare02,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: selectedIndex == 0 ? _buildBottomMenuBar() : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Constants.ftaColorLight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  Constants.myDisplayname ?? 'Seller Name',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Constants.myEmail ?? 'seller@email.com',
                  style: GoogleFonts.manrope(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileManagement()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              // Handle logout
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomMenuBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: menuItems.asMap().entries.map((entry) {
              int index = entry.key;
              String item = entry.value;
              IconData icon = menuIcons[index];
              bool isActive = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                    _restartAnimations();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isActive ? Constants.ctaColorLight : Colors.grey,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        item,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isActive
                              ? Constants.ctaColorLight
                              : Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavItem(String title, int index, IconData icon) {
    bool isActive = tabActiveIndex == index;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () async {
          setState(() {
            tabActiveIndex = index;
          });
          await _handleNavigation(index);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Constants.ctaColorLight : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Constants.ctaColorLight : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : Colors.grey[600],
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNavigation(int index) async {
    switch (index) {
      case 0:
        // Dashboard - already here
        break;
      case 1:
        // Products
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BuyerHomePage()),
        );
        break;
      case 2:
        // Chats
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Chat feature coming soon')));
        break;
      case 3:
        // Ratings
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RatingReviewWidget(sellerId: ''),
          ),
        );
        break;
      case 4:
        // Support
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Support()),
        );
        break;
      case 5:
        // Share
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShareWidget()),
        );
        break;
    }
  }

  void _restartAnimations() {
    _fadeController.reset();
    _slideController.reset();
    _animationController.reset();
    _fadeController.forward();
    _slideController.forward();
    _animationController.forward();
  }

  Widget _buildMainContent() {
    switch (selectedIndex) {
      case 0:
        return _buildRevenueTracker();
      case 1:
        return _buildTransactionHistory();
      case 2:
        return _buildManageDisputes();
      case 3:
        return _buildAnalytics();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alerts Section
        _buildAlertsSection(),
        SizedBox(height: 24),
        // Requests Section
        _buildRequestsSection(),
      ],
    );
  }

  Widget _buildAlertsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ALERTS',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Constants.ftaColorLight,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You have ${totalNewRequests} new requests',
                    style: GoogleFonts.manrope(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
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
                'LEADS/REQUESTS',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Constants.ftaColorLight,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  _fetchRequestsData();
                  _fetchQuotesData();
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          // Tabs
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: requestTabLabels.asMap().entries.map((entry) {
                int index = entry.key;
                String label = entry.value;
                bool isActive = selectedRequestTab == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedRequestTab = index;
                        currentPage = 1;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isActive
                                ? Constants.ftaColorLight
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16),
          // Content
          if (isLoadingRequests)
            Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (requestsError != null)
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
                ],
              ),
            )
          else if (selectedRequestTab == 0)
            _buildNewRequestsList()
          else
            _buildMyBidsList(),
        ],
      ),
    );
  }

  Widget _buildNewRequestsList() {
    if (newRequests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 60, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No new requests',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'New requests will appear here',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedRequests = newRequests.sublist(
      startIndex,
      endIndex > newRequests.length ? newRequests.length : endIndex,
    );
    final totalPages = (newRequests.length / itemsPerPage).ceil();

    return Column(
      children: [
        ...paginatedRequests.map((request) => _buildMobileRequestCard(request)),
        if (totalPages > 1) ...[
          SizedBox(height: 16),
          _buildMobilePagination(totalPages, newRequests.length),
        ],
      ],
    );
  }

  Widget _buildMyBidsList() {
    if (processedRequests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.gavel_outlined, size: 60, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No bids placed yet',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your bids will appear here',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedRequests = processedRequests.sublist(
      startIndex,
      endIndex > processedRequests.length ? processedRequests.length : endIndex,
    );
    final totalPages = (processedRequests.length / itemsPerPage).ceil();

    return Column(
      children: [
        ...paginatedRequests.map((request) => _buildMobileBidCard(request)),
        if (totalPages > 1) ...[
          SizedBox(height: 16),
          _buildMobilePagination(totalPages, processedRequests.length),
        ],
      ],
    );
  }

  Widget _buildMobileRequestCard(Map<String, dynamic> request) {
    final uuid = request['uuid'] ?? 'N/A';
    final category = request['category'] ?? 'Unknown Category';
    final partName = request['part_name'] ?? 'Unknown Part';
    final status = request['status'] ?? 'open';
    final createdAt = request['created_at'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  uuid,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              partName,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              category,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  _formatDateTime(createdAt),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showBidDialog(context, request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Place Bid',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showRequestDetails(request),
                  icon: Icon(Icons.info_outline),
                  color: Constants.ftaColorLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileBidCard(Map<String, dynamic> request) {
    final quotes = request['quotes'] as List<dynamic>? ?? [];
    final myQuote = quotes.isNotEmpty ? quotes[0] : null;

    if (myQuote == null) return Container();

    final quoteAmount = myQuote['quote_amount'] ?? 0;
    final deliveryTime = myQuote['delivery_time'] ?? 0;
    final status = myQuote['status'] ?? 'pending';
    final createdAt = myQuote['created_at'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BID #${myQuote['quote_number'] ?? 'N/A'}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bid Amount',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'R${quoteAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Delivery',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '$deliveryTime days',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              _formatDateTime(createdAt),
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePagination(int totalPages, int totalItems) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    currentPage--;
                  });
                }
              : null,
          icon: Icon(Icons.chevron_left),
        ),
        Text(
          'Page $currentPage of $totalPages',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        IconButton(
          onPressed: currentPage < totalPages
              ? () {
                  setState(() {
                    currentPage++;
                  });
                }
              : null,
          icon: Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildRevenueTracker() {
    if (isLoadingOrdersSummary) {
      return Center(child: CircularProgressIndicator());
    }

    if (ordersSummaryError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading revenue data',
              style: GoogleFonts.manrope(fontSize: 16, color: Colors.red),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchOrdersSummary,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final summary = ordersSummary?['summary'] ?? {};
    final ordersByStatus = ordersSummary?['orders_by_status'] ?? {};
    final totalRevenue = summary['total_revenue'] ?? 0;
    final totalOrders = summary['total_orders'] ?? 0;
    final avgOrderValue = summary['average_order_value'] ?? 0;

    return Column(
      children: [
        // Timeframe selector
        Container(
          height: 40,
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['daily', 'weekly', 'monthly', 'yearly'].map((timeframe) {
              bool isSelected = selectedTimeframe == timeframe;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTimeframe = timeframe;
                    });
                    _fetchOrdersSummary();
                  },
                  child: Container(
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        timeframe.toUpperCase(),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Constants.ctaColorLight
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Revenue cards
        _buildMobileRevenueCard(
          'Total Revenue',
          'R${totalRevenue.toStringAsFixed(2)}',
          Colors.green,
          Icons.account_balance_wallet,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMobileStatCard(
                'Total Orders',
                totalOrders.toString(),
                Colors.blue,
                Icons.shopping_cart,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildMobileStatCard(
                'Avg Order',
                'R${avgOrderValue.toStringAsFixed(0)}',
                Colors.orange,
                Icons.trending_up,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Order status breakdown
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders by Status',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              ...ordersByStatus.entries.map((entry) {
                final status = entry.key;
                final count = entry.value ?? 0;
                final percentage = totalOrders > 0
                    ? (count / totalOrders * 100)
                    : 0;

                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatStatusName(status),
                            style: GoogleFonts.manrope(fontSize: 14),
                          ),
                          Text(
                            '$count (${percentage.toStringAsFixed(1)}%)',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getStatusProgressColor(status),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileRevenueCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab Navigation
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: _buildSubTab('Earning History', 0)),
              Expanded(child: _buildSubTab('Withdraw History', 1)),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Transaction List
        ..._getMobileTransactions().map(
          (transaction) => _buildMobileTransactionItem(transaction),
        ),
      ],
    );
  }

  Widget _buildSubTab(String title, int index) {
    bool isActive = selectedSubIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? Constants.ctaColorLight : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTransactionItem(Map<String, dynamic> transaction) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: transaction['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transaction['icon'],
              color: transaction['color'],
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'],
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  transaction['date'],
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            transaction['amount'],
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: transaction['isPositive'] ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageDisputes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Disputes',
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        ..._getMobileDisputes().map(
          (dispute) => _buildMobileDisputeCard(dispute),
        ),
      ],
    );
  }

  Widget _buildMobileDisputeCard(Map<String, dynamic> dispute) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dispute['id'],
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: dispute['statusColor'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dispute['status'],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dispute['statusColor'],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              dispute['title'],
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  dispute['date'],
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  dispute['time'],
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Pin dialog simplified for mobile
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Dispute resolved')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[50],
                      foregroundColor: Colors.green,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Resolve',
                      style: GoogleFonts.manrope(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalytics() {
    return Column(
      children: [
        Text(
          'Upgrade Your Plan',
          style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Choose the plan that best fits your needs',
          style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 24),
        _buildMobilePricingCard(
          'Starter Plan',
          'R199',
          '/month',
          _getStarterFeatures(),
          false,
        ),
        SizedBox(height: 16),
        _buildMobilePricingCard(
          'Professional Plan',
          'R399',
          '/month',
          _getProfessionalFeatures(),
          true,
        ),
        SizedBox(height: 16),
        _buildMobilePricingCard(
          'Enterprise Plan',
          'Custom',
          'pricing',
          _getEnterpriseFeatures(),
          false,
        ),
      ],
    );
  }

  Widget _buildMobilePricingCard(
    String title,
    String price,
    String period,
    List<String> features,
    bool isPopular,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? Constants.ctaColorLight : Colors.grey[200]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular
                ? Constants.ctaColorLight.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Constants.ctaColorLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'POPULAR',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          if (isPopular) SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Constants.ctaColorLight,
                ),
              ),
              Text(
                period,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ...features
              .map(
                (feature) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? Constants.ctaColorLight
                    : Colors.white,
                foregroundColor: isPopular
                    ? Colors.white
                    : Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Constants.ctaColorLight,
                    width: isPopular ? 0 : 1,
                  ),
                ),
              ),
              child: Text(
                'Choose Plan',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'closed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(String dateTime) {
    if (dateTime.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateTime;
    }
  }

  String _formatStatusName(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  Color _getStatusProgressColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getMobileTransactions() {
    if (selectedSubIndex == 0) {
      return [
        {
          'title': 'Order #12345',
          'date': '12 Dec 2023',
          'amount': '+R1,200',
          'icon': Icons.add_circle_outline,
          'color': Colors.green,
          'isPositive': true,
        },
        {
          'title': 'Order #12344',
          'date': '11 Dec 2023',
          'amount': '+R850',
          'icon': Icons.add_circle_outline,
          'color': Colors.green,
          'isPositive': true,
        },
      ];
    } else {
      return [
        {
          'title': 'Bank Transfer',
          'date': '10 Dec 2023',
          'amount': '-R2,000',
          'icon': Icons.account_balance,
          'color': Colors.blue,
          'isPositive': false,
        },
        {
          'title': 'PayPal Withdrawal',
          'date': '05 Dec 2023',
          'amount': '-R1,500',
          'icon': Icons.payment,
          'color': Colors.blue,
          'isPositive': false,
        },
      ];
    }
  }

  List<Map<String, dynamic>> _getMobileDisputes() {
    return [
      {
        'id': 'D-001',
        'title': 'Wrong part delivered',
        'status': 'Open',
        'statusColor': Colors.orange,
        'date': '12 Dec 2023',
        'time': '14:30',
      },
      {
        'id': 'D-002',
        'title': 'Quality issue',
        'status': 'In Progress',
        'statusColor': Colors.blue,
        'date': '10 Dec 2023',
        'time': '09:15',
      },
    ];
  }

  List<String> _getStarterFeatures() {
    return [
      'Up to 50 requests per month',
      'Basic analytics',
      'Email support',
      'Single user account',
    ];
  }

  List<String> _getProfessionalFeatures() {
    return [
      'Unlimited requests',
      'Advanced analytics',
      'Priority support',
      'Team collaboration',
      'Custom branding',
    ];
  }

  List<String> _getEnterpriseFeatures() {
    return [
      'Everything in Professional',
      'Dedicated account manager',
      'API access',
      'Custom integrations',
      'SLA guarantee',
    ];
  }

  void _showBidDialog(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Place Your Bid',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Bid Amount (R)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _commentsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Comments (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle bid submission
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Bid submitted successfully'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Submit Bid',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Request Details',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              // Add request details here
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('UUID', request['uuid'] ?? 'N/A'),
                      _buildDetailRow('Category', request['category'] ?? 'N/A'),
                      _buildDetailRow(
                        'Part Name',
                        request['part_name'] ?? 'N/A',
                      ),
                      _buildDetailRow('Status', request['status'] ?? 'N/A'),
                      _buildDetailRow(
                        'Created',
                        _formatDateTime(request['created_at'] ?? ''),
                      ),
                      if (request['description'] != null) ...[
                        SizedBox(height: 16),
                        Text(
                          'Description',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          request['description'],
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
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

class NotificationDialog extends StatelessWidget {
  final List<WebNotification> notifications;
  final bool isLoading;
  final Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;

  const NotificationDialog({
    Key? key,
    required this.notifications,
    required this.isLoading,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.read).length;

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Constants.ftaColorLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications ($unreadCount unread)',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: onMarkAllAsRead,
                      child: Text(
                        'Mark all as read',
                        style: GoogleFonts.manrope(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => Divider(),
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return InkWell(
                      onTap: () {
                        if (!notification.read) {
                          onMarkAsRead(notification.id);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: notification.read
                                    ? Colors.grey[200]
                                    : Constants.ctaColorLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.notifications,
                                size: 20,
                                color: notification.read
                                    ? Colors.grey
                                    : Constants.ctaColorLight,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.title,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: notification.read
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    notification.body,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _formatNotificationTime(
                                      notification.createdAt,
                                    ),
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(dateTime);
    }
  }
}

class SellerDashboardGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Seller Dashboard',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B3B5C),
              ),
            ),
            SizedBox(height: 40),

            // Dashboard Cards Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: [
                  _buildDashboardCard(
                    title: 'My Bookkeeper',
                    icon: Icons.description,
                    onTap: () {
                      // Navigate to bookkeeper
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Support (BIDR)',
                    icon: Icons.headset_mic,
                    onTap: () {
                      // Navigate to support
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Refer a Friend/\nBusiness',
                    icon: Icons.person_add,
                    onTap: () {
                      // Navigate to referral
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Review & Rating\nManager',
                    icon: Icons.star,
                    onTap: () {
                      // Navigate to reviews
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8B366), Color(0xFFD4964A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFE8B366).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon and arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),

              Spacer(),

              // Title
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
