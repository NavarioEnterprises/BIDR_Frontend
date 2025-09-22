import 'dart:async';
import 'dart:convert';

import 'package:bidr/config/environment_config.dart';
import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/mobileView/SellerDashboard/RequestInfoMobile.dart';
import 'package:bidr/pages/mobileView/SellerDashboard/profileManagementMobile.dart';
import 'package:bidr/pages/mobileView/SellerDashboard/ratingReviewsMobile.dart';
import 'package:bidr/pages/mobileView/SellerDashboard/sellerDashboardGrid.dart';
import 'package:bidr/pages/mobileView/buyerDashboard/groupChatMobile.dart';
import 'package:bidr/pages/mobileView/landingPage/supportMobileView.dart';
import 'package:bidr/pages/notification.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:motion_toast/motion_toast.dart';
import "package:universal_html/html.dart" as html;

import '../../../customWdget/dropdownMenu.dart';
import '../../../global_values.dart';
import '../../../models/alert.dart';
import '../../../models/product_request_api.dart';
import '../../../models/request_models.dart';
import '../../../services/auth_api_service.dart';
import '../../../services/chat_service.dart';
import '../../../services/notification_api_service.dart';
import '../../../services/products_management_api_service.dart';
import '../../buyer_home.dart';
import '../../group_chat.dart';
import '../../seller/myBookKeeper.dart';
import '../../seller/seller_home_dashboard.dart';
import '../buyerDashboard/buyerMobileDashboard.dart'
    show
        ConsumerElectronicsDetailScreen,
        RimTyreDetailScreen,
        SparesDetailScreen;
import '../buyerDashboard/shareMobile.dart';
import 'enterPinMobile.dart';

enum LeadStatus { open, closed, unsuccessful, pending, inProgress }

class SellerMobileDashboard extends StatefulWidget {
  @override
  _SellerMobileDashboardState createState() => _SellerMobileDashboardState();
}

List<WebNotification> notifications = [];

class _SellerMobileDashboardState extends State<SellerMobileDashboard>
    with TickerProviderStateMixin {
  int selectedIndex = 0;
  int tabActiveIndex = 0;
  int selectedSubIndex = 0; // For transaction history tabs
  bool isPinVerifiedSuccessful = false;
  bool _isLoadingNotifications = false;
  bool _isOverlayShown = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;

  // Timer declarations for auto-refresh and countdown
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  int _unreadCount = 0;
  final NotificationApiService _notificationApiService =
      NotificationApiService();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  // Store current request for alternate bids
  Map<String, dynamic>? _currentRequestForAlternateBid;

  // Store previous bids for the current request
  List<dynamic> _previousBids = [];
  bool _isLoadingPreviousBids = false;

  // API data state variables
  List<dynamic> newRequests = [];
  List<dynamic> processedRequests = [];
  bool isLoadingRequests = true;
  bool _isInitialRequestsLoad = true;
  String? requestsError;
  int totalNewRequests = 0;
  int totalProcessedRequests = 0;
  Map<String, dynamic>? sellerLocation;

  // Navigation item hover states
  Map<String, bool> _navItemHoverStates = {};

  // Button hover states for Request More Info and Full Description
  Map<String, bool> _buttonHoverStates = {};

  // Quotes data state variables
  List<dynamic> myQuotes = [];
  bool isLoadingQuotes = true;
  bool _isInitialQuotesLoad = true;
  String? quotesError;
  int totalQuotes = 0;

  // Orders data state variables for approved bids
  List<dynamic> sellerOrders = [];
  bool isLoadingOrders = true;
  String? ordersError;

  // Disputed orders data state variables
  List<dynamic> disputedOrders = [];
  bool isLoadingDisputes = true;
  String? disputesError;

  // Resolved disputes data state variables
  List<dynamic> resolvedDisputes = [];
  bool isLoadingResolvedDisputes = true;
  String? resolvedDisputesError;

  // Paid and Completed bids data
  List<dynamic> paidBids = [];
  List<dynamic> completedBids = [];
  int totalPaidBids = 0;
  int totalCompletedBids = 0;

  // Tab and pagination state
  int selectedRequestTab = 0; // 0: New Requests, 1: My Bids
  int currentPage = 1;
  int itemsPerPage = 8; // 8 items per page (3 rows of 3, minus 1)

  // Orders summary state variables
  Map<String, dynamic>? ordersSummary;
  bool isLoadingOrdersSummary = true;
  String? ordersSummaryError;
  String selectedTimeframe = 'monthly'; // daily, weekly, monthly, yearly

  // Earning history state variables (PAID orders)
  List<dynamic> earningHistory = [];
  bool isLoadingEarnings = false;
  String? earningsError;
  int currentEarningsPage = 1;
  int totalEarningsCount = 0;
  bool hasNextEarningsPage = false;

  // Withdraw history state variables (REFUNDED orders)
  List<dynamic> withdrawHistory = [];
  bool isLoadingWithdraws = false;
  String? withdrawsError;
  int currentWithdrawsPage = 1;
  int totalWithdrawsCount = 0;
  bool hasNextWithdrawsPage = false;

  int currentWithdrawPage = 1;
  int totalWithdrawCount = 0;
  bool hasNextWithdrawPage = false;

  // Auth service instance
  final AuthApiService _authService = AuthApiService();

  // Tab labels
  List<String> requestTabLabels = ['New Requests', 'My Requests'];

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
        return PinEntryMobileDialog(
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
    _loadNotificationsFromApi();
    _loadSellerOrders();
    _loadEarningHistory();
    _fetchDisputedOrders();
    _fetchResolvedDisputes();
    _startAutoRefresh();
    _startCountdownTimer();
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
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _priceController.dispose();
    _commentsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Start countdown timer that updates every second
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild every second, updating all countdowns
        });
      }
    });
  }

  // Start auto-refresh timer for background updates every 60 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      // Only refresh if the widget is still mounted and not loading
      if (mounted) {
        // Refresh seller data
        _loadNotificationsFromApi();
        _loadSellerOrders();
        _checkLocationPermissionAndFetchData();
      }
    });
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
    _fetchOrdersSummary();
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
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxWidth: 400, // Max width for larger screens
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Location Access Required',
                        style: GoogleFonts.manrope(
                          textStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.close, color: Colors.black87),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Location icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        color: Constants.ctaColorLight,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Content
                  Center(
                    child: Column(
                      children: [
                        Text(
                          isPermanentlyDenied
                              ? 'Location Permission Denied'
                              : 'Enable Location Services',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          isPermanentlyDenied
                              ? 'Please enable location permission in your device settings to see nearby product requests.'
                              : 'This app needs location access to show you nearby product requests. Please allow location access when prompted by your browser.',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Keep default coordinates and proceed
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            'Skip for Now',
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _getCurrentLocation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            isPermanentlyDenied ? 'Open Settings' : 'Try Again',
                            style: GoogleFonts.manrope(
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
          // Get all results from the API
          final List<dynamic> allRequests = data['results'] ?? [];

          // Filter new requests (no quotes yet) and processed requests (has quotes)
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
          _isInitialRequestsLoad = false;
        });

        // Apply sorting after data is loaded and setState completes
        if (mounted) {
          _applySorting();
        }

        print('New requests: ${newRequests.length}');
        print('Processed requests: ${processedRequests.length}');
        print('Total requests from API: ${(data['results'] ?? []).length}');
      } else {
        setState(() {
          requestsError = response['message'] ?? 'Failed to load requests';
          isLoadingRequests = false;
          _isInitialRequestsLoad = false;
        });
      }
    } catch (e) {
      setState(() {
        requestsError = 'Network error: ${e.toString()}';
        isLoadingRequests = false;
        _isInitialRequestsLoad = false;
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
          _isInitialQuotesLoad = false;
        });

        // Apply sorting after quotes data is loaded and setState completes
        if (mounted) {
          _applySorting();
        }

        print('My quotes: ${myQuotes.length}');
      } else {
        setState(() {
          quotesError = response['message'] ?? 'Failed to load quotes';
          isLoadingQuotes = false;
          _isInitialQuotesLoad = false;
        });
      }
    } catch (e) {
      setState(() {
        quotesError = 'Network error: ${e.toString()}';
        isLoadingQuotes = false;
        _isInitialQuotesLoad = false;
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

        print('Orders summary: ${ordersSummary?['summary']}');
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

  Future<void> _fetchDisputedOrders() async {
    try {
      setState(() {
        isLoadingDisputes = true;
        disputesError = null;
      });

      // Fetch orders with REFUND_REQUESTED status for the current seller
      final url =
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=REFUND_REQUESTED';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] ?? [];

        print('DEBUG DISPUTED ORDERS API Response:');
        print('URL: ${url}');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('Results count: ${results.length}');

        if (results.isNotEmpty) {
          print('First disputed order sample:');
          print('${results[0]}');
        }

        setState(() {
          disputedOrders = results;
          isLoadingDisputes = false;
        });

        // Apply sorting after disputed orders data is loaded and setState completes
        if (mounted) {
          _applySorting();
        }
        print('Loaded ${disputedOrders.length} disputed orders');
      } else {
        setState(() {
          disputesError =
              'Failed to load disputed orders: ${response.statusCode}';
          isLoadingDisputes = false;
        });
      }
    } catch (e) {
      setState(() {
        disputesError = 'Network error: ${e.toString()}';
        isLoadingDisputes = false;
      });
      print('Error fetching disputed orders: $e');
    }
  }

  Future<void> _fetchResolvedDisputes() async {
    try {
      setState(() {
        isLoadingResolvedDisputes = true;
        resolvedDisputesError = null;
      });

      // Fetch orders with REFUNDED and CANCELLED status for the current seller
      final refundedUrl =
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=REFUNDED';
      final cancelledUrl =
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=CANCELLED';

      final refundedResponse = await http.get(
        Uri.parse(refundedUrl),
        headers: {'Content-Type': 'application/json'},
      );
      final cancelledResponse = await http.get(
        Uri.parse(cancelledUrl),
        headers: {'Content-Type': 'application/json'},
      );

      List<dynamic> allResolvedOrders = [];

      print('DEBUG RESOLVED DISPUTES - REFUNDED API:');
      print('URL: ${refundedUrl}');
      print('Status: ${refundedResponse.statusCode}');

      if (refundedResponse.statusCode == 200) {
        final refundedData = json.decode(refundedResponse.body);
        final refundedResults = refundedData['results'] ?? [];
        print('Refunded orders count: ${refundedResults.length}');
        if (refundedResults.isNotEmpty) {
          print('Sample refunded order: ${refundedResults[0]}');
        }
        allResolvedOrders.addAll(refundedResults);
      }

      print('DEBUG RESOLVED DISPUTES - CANCELLED API:');
      print('URL: ${cancelledUrl}');
      print('Status: ${cancelledResponse.statusCode}');

      if (cancelledResponse.statusCode == 200) {
        final cancelledData = json.decode(cancelledResponse.body);
        final cancelledResults = cancelledData['results'] ?? [];
        print('Cancelled orders count: ${cancelledResults.length}');
        if (cancelledResults.isNotEmpty) {
          print('Sample cancelled order: ${cancelledResults[0]}');
        }
        allResolvedOrders.addAll(cancelledResults);
      }

      // Sort by updated_at (most recent first)
      allResolvedOrders.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime(1970);
        final bDate =
            DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      setState(() {
        resolvedDisputes = allResolvedOrders;
        isLoadingResolvedDisputes = false;
      });
      print('Loaded ${resolvedDisputes.length} resolved disputes');
    } catch (e) {
      setState(() {
        resolvedDisputesError = 'Network error: ${e.toString()}';
        isLoadingResolvedDisputes = false;
      });
      print('Error fetching resolved disputes: $e');
    }
  }

  Future<void> _loadSellerOrders() async {
    setState(() {
      isLoadingOrders = true;
      ordersError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different possible response structures
        List<dynamic> ordersData;
        if (data is List) {
          ordersData = data;
        } else if (data is Map && data.containsKey('results')) {
          ordersData = data['results'];
        } else if (data is Map && data.containsKey('orders')) {
          ordersData = data['orders'];
        } else {
          ordersData = [];
        }

        setState(() {
          sellerOrders = ordersData;

          // Filter only orders that belong to this seller
          final myOrders = ordersData.where((order) {
            return order['seller_id'] == Constants.myUid ||
                order['seller'] == Constants.myUid;
          }).toList();

          // Separate paid and completed bids
          paidBids = myOrders.where((order) {
            final status = order['status']?.toString().toUpperCase() ?? '';
            return status == 'PAID';
          }).toList();

          completedBids = myOrders.where((order) {
            final status = order['status']?.toString().toUpperCase() ?? '';
            return status == 'COMPLETED' || status == 'DELIVERED';
          }).toList();

          // Update totals
          totalPaidBids = paidBids.length;
          totalCompletedBids = completedBids.length;

          isLoadingOrders = false;
          print('DEBUG: Loaded ${ordersData.length} seller orders');
          print('DEBUG: My orders count: ${myOrders.length}');
          print(
            'DEBUG: Paid: ${paidBids.length}, Completed: ${completedBids.length}',
          );
          print(
            'DEBUG: First order sample: ${ordersData.isNotEmpty ? ordersData[0] : 'No orders'}',
          );
        });

        // Apply sorting after data is loaded
        if (mounted) {
          _applySorting();
        }
      } else {
        setState(() {
          ordersError = 'Failed to load orders: ${response.statusCode}';
          isLoadingOrders = false;
        });
      }
    } catch (e) {
      setState(() {
        ordersError = 'Error loading orders: $e';
        isLoadingOrders = false;
      });
    }
  }

  Future<void> _loadEarningHistory({int page = 1}) async {
    if (page == 1) {
      setState(() {
        isLoadingEarnings = true;
        earningsError = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=PAID&page=$page',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newEarnings = data['results'] ?? [];

        setState(() {
          if (page == 1) {
            earningHistory = newEarnings;
          } else {
            earningHistory.addAll(newEarnings);
          }
          totalEarningsCount = data['count'] ?? newEarnings.length;
          hasNextEarningsPage = data['next'] != null;
          currentEarningsPage = page;
          isLoadingEarnings = false;
        });

        print('Loaded ${newEarnings.length} earning records (PAID orders)');
      } else {
        setState(() {
          earningsError =
              'Failed to load earning history: ${response.statusCode}';
          isLoadingEarnings = false;
        });
      }
    } catch (e) {
      setState(() {
        earningsError = 'Network error: ${e.toString()}';
        isLoadingEarnings = false;
      });
    }
  }

  Future<void> _loadWithdrawHistory({int page = 1}) async {
    if (page == 1) {
      setState(() {
        isLoadingWithdraws = true;
        withdrawsError = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=REFUNDED&page=$page',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> newWithdraws = data['results'] ?? [];

        setState(() {
          if (page == 1) {
            withdrawHistory = newWithdraws;
          } else {
            withdrawHistory.addAll(newWithdraws);
          }
          totalWithdrawsCount = data['count'] ?? newWithdraws.length;
          hasNextWithdrawsPage = data['next'] != null;
          currentWithdrawsPage = page;
          isLoadingWithdraws = false;
        });

        print(
          'Loaded ${newWithdraws.length} withdraw records (REFUNDED orders)',
        );
      } else {
        setState(() {
          withdrawsError =
              'Failed to load withdraw history: ${response.statusCode}';
          isLoadingWithdraws = false;
        });
      }
    } catch (e) {
      setState(() {
        withdrawsError = 'Network error: ${e.toString()}';
        isLoadingWithdraws = false;
      });
    }
  }

  // Order action methods
  Future<void> _updateOrderStatus(
    String orderId,
    String status,
    String notes,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/orders/$orderId/update_status/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'status': status, 'notes': notes}),
      );

      if (response.statusCode == 200) {
        print('Order status updated successfully');
        // Refresh the relevant data
        _fetchOrdersSummary();
        _loadEarningHistory();
      } else {
        print('Failed to update order status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final userUuid = Constants.myUid;
      if (userUuid != null && userUuid.isNotEmpty) {
        final fetchedNotifications = await _notificationApiService
            .getUserNotifications(userUuid);
        final unreadCount = await _notificationApiService
            .getUnreadNotificationCount(userUuid);

        setState(() {
          notifications = fetchedNotifications;
          // You can add unreadNotificationCount to your state variables
          print(
            'Loaded ${notifications.length} notifications, $unreadCount unread',
          );
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _notificationApiService.markAsRead(notificationId);
      // Update local state
      setState(() {
        notifications = notifications.map((notification) {
          if (notification.id == notificationId) {
            return notification.copyWith(read: true);
          }
          return notification;
        }).toList();
      });
      print('Marked notification as read: $notificationId');
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllNotificationsAsRead() async {
    try {
      final userUuid = Constants.myUid;
      if (userUuid != null && userUuid.isNotEmpty) {
        await _notificationApiService.markAllAsRead(userUuid);
        // Update local state
        setState(() {
          notifications = notifications
              .map((notification) => notification.copyWith(read: true))
              .toList();
        });
        print('Marked all notifications as read');
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<void> _getProductRequestDetails(String requestId) async {
    try {
      final details = await ApiService.getProductRequestDetails(requestId);
      print('Product request details for $requestId: $details');
    } catch (e) {
      print('Error getting product request details: $e');
    }
  }

  Future<void> _getQuotesForRequest(String requestId) async {
    try {
      final quotes = await ApiService.getQuotesForRequest(requestId);
      print('Quotes for request $requestId: ${quotes.length}');
    } catch (e) {
      print('Error getting quotes for request: $e');
    }
  }

  String _getRequestDescription2(dynamic request) {
    print("sakjsa $request ${request.runtimeType}");
    try {
      // Handle both order format and quote format - extract the actual request data
      dynamic actualRequest = request;

      if (request is Map) {
        if (request.containsKey('request_details')) {
          // This is a quote response format
          actualRequest = request['request_details'];
        } else if (request.containsKey('request_id') &&
            request['request_id'] is Map) {
          // This might be an order with nested request data
          actualRequest = request['request_id'];
        }
      }

      if (actualRequest == null ||
          (actualRequest is Map &&
              actualRequest['category'] == null &&
              actualRequest['request_category'] == null)) {
        return "No description available";
      }

      // Get category from various possible locations
      final category =
          (actualRequest['category'] ??
                  actualRequest['request_category'] ??
                  request['request_category'] ??
                  '')
              .toString()
              .toUpperCase();

      // Handle different request types based on category
      switch (category) {
        case "VEHICLE_SPARES":
        case "VEHICLE SPARES":
          // Use vehicle_spares_summary from API or build from data
          final vehicleSparesSummary =
              actualRequest['vehicle_spares_summary'] ??
              request['vehicle_spares_summary'] ??
              '';
          if (vehicleSparesSummary.isNotEmpty) {
            return vehicleSparesSummary;
          }

          // Try to build from vehicle_spares_data
          final vehicleData =
              actualRequest['vehicle_spares_data'] ??
              request['vehicle_spares_data'];
          if (vehicleData != null && vehicleData is Map) {
            final make = vehicleData['vehicle_make'] ?? '';
            final model = vehicleData['vehicle_model'] ?? '';
            final year = vehicleData['vehicle_year']?.toString() ?? '';
            final partName = vehicleData['part_name'] ?? '';

            if (make.isNotEmpty &&
                model.isNotEmpty &&
                year.isNotEmpty &&
                partName.isNotEmpty) {
              return "$partName, $make $model, $year";
            } else if (make.isNotEmpty &&
                model.isNotEmpty &&
                partName.isNotEmpty) {
              return "$partName, $make $model";
            } else if (partName.isNotEmpty) {
              return partName;
            }
          }

          // Fallback to title/description
          final title =
              actualRequest['title'] ?? request['request_title'] ?? '';
          final description =
              actualRequest['description'] ??
              request['request_description'] ??
              '';
          if (title.isNotEmpty) {
            return "$title${description.isNotEmpty ? ' - $description' : ''}";
          }
          return "Vehicle Spares Request";

        case "TYRES_RIMS":
        case "VEHICLE TYRES AND RIMS":
        case "TYRES/RIMS":
          // Use tyres_rims_summary from API or build from data
          final tyresRimsSummary =
              actualRequest['tyres_rims_summary'] ??
              request['tyres_rims_summary'] ??
              '';

          // Try to build from vehicle_tyres_rims_data
          final tyresData =
              actualRequest['vehicle_tyres_rims_data'] ??
              request['vehicle_tyres_rims_data'];
          if (tyresData != null && tyresData is Map) {
            final tyreType = tyresData['select_tyres_rims'] ?? 'Tyres';
            final tyreWidth = tyresData['tyre_width']?.toString() ?? '';
            final sidewall = tyresData['sidewall_profile']?.toString() ?? '';
            final rimDiameter =
                tyresData['wheel_rim_diameter']?.toString() ?? '';
            final brand = tyresData['preferred_brand'] ?? 'Various Brands';

            if (tyreWidth.isNotEmpty &&
                sidewall.isNotEmpty &&
                rimDiameter.isNotEmpty) {
              return "$tyreType, $tyreWidth/${sidewall}R$rimDiameter, $brand";
            } else if (tyresRimsSummary.isNotEmpty) {
              // Use the summary if we couldn't build a full description
              final title =
                  actualRequest['title'] ??
                  request['request_title'] ??
                  'Tyre/Rim Request';
              return "$tyresRimsSummary - $title";
            }
          } else if (tyresRimsSummary.isNotEmpty) {
            final title =
                actualRequest['title'] ??
                request['request_title'] ??
                'Tyre/Rim Request';
            return "$tyresRimsSummary - $title";
          }

          // Fallback to title/description
          final title =
              actualRequest['title'] ?? request['request_title'] ?? '';
          final description =
              actualRequest['description'] ??
              request['request_description'] ??
              '';
          if (title.isNotEmpty) {
            return "$title${description.isNotEmpty ? ' - $description' : ''}";
          }
          return "Tyre/Rim Request";

        case "ELECTRONICS":
        case "CONSUMER ELECTRONICS":
          // Use consumer_electronics_summary from API or build from data
          final electronicsSummary =
              actualRequest['consumer_electronics_summary'] ??
              request['consumer_electronics_summary'] ??
              '';
          if (electronicsSummary.isNotEmpty) {
            return electronicsSummary;
          }

          // Try to build from consumer_electronics_data
          final electronicsData =
              actualRequest['consumer_electronics_data'] ??
              request['consumer_electronics_data'];
          if (electronicsData != null && electronicsData is Map) {
            final typeOfElectronics =
                electronicsData['electronics_type'] ?? 'Electronics';
            final brandPreference =
                electronicsData['brand_preference'] ?? 'Various Brands';
            final modelSeries = electronicsData['model_series'] ?? '';

            return "$typeOfElectronics, $brandPreference${modelSeries.isNotEmpty ? ', $modelSeries' : ''}";
          }

          // Fallback to title/description
          final title =
              actualRequest['title'] ?? request['request_title'] ?? '';
          final description =
              actualRequest['description'] ??
              request['request_description'] ??
              '';
          if (title.isNotEmpty) {
            return "$title${description.isNotEmpty ? ' - $description' : ''}";
          }
          return "Electronics Request";

        default:
          // Fallback to title and description from API
          final title =
              actualRequest['title'] ?? request['request_title'] ?? '';
          final description =
              actualRequest['description'] ??
              request['request_description'] ??
              '';
          if (title.isNotEmpty) {
            return "$title${description.isNotEmpty ? ' - $description' : ''}";
          }

          // Last resort - use order/quote ID
          final orderId =
              request['order_number'] ??
              request['quote_id'] ??
              actualRequest['request_id'] ??
              'Unknown';
          final idStr = orderId.toString();
          return "Request #${idStr.length > 8 ? idStr.substring(0, 8).toUpperCase() : idStr.toUpperCase()}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable";
    }
  }

  SortOption? _currentSort;

  void _applySorting({bool shouldSetState = true}) {
    if (_currentSort == null) return;

    // Helper function to get comparable value from item
    double _getSortValue(dynamic item) {
      switch (_currentSort!) {
        case SortOption.highToLow:
        case SortOption.lowToHigh:
          // Try to get price/budget from different possible fields
          if (item['budget'] != null) {
            final value = double.tryParse(item['budget'].toString()) ?? 0.0;
            return value;
          }
          if (item['price'] != null) {
            final value = double.tryParse(item['price'].toString()) ?? 0.0;
            return value;
          }
          if (item['amount'] != null) {
            final value = double.tryParse(item['amount'].toString()) ?? 0.0;
            return value;
          }
          if (item['quote_amount'] != null) {
            final value =
                double.tryParse(item['quote_amount'].toString()) ?? 0.0;
            return value;
          }
          if (item['total_amount'] != null) {
            final value =
                double.tryParse(item['total_amount'].toString()) ?? 0.0;
            return value;
          }
          return 0.0;

        case SortOption.rating:
          // Try to get rating from different possible fields
          if (item['rating'] != null) {
            final value = double.tryParse(item['rating'].toString()) ?? 0.0;
            return value;
          }
          if (item['seller_rating'] != null) {
            final value =
                double.tryParse(item['seller_rating'].toString()) ?? 0.0;
            return value;
          }
          if (item['buyer_rating'] != null) {
            final value =
                double.tryParse(item['buyer_rating'].toString()) ?? 0.0;
            return value;
          }
          return 0.0;

        default:
          return 0.0;
      }
    }

    void _performSort() {
      print('\n=== SORTING DEBUG - BEFORE SORTING ===');
      print('Sort option: $_currentSort');

      // Debug print before sorting
      if (newRequests.isNotEmpty) {
        print('\nNEW REQUESTS (${newRequests.length} items) - Before sorting:');
        for (int i = 0; i < newRequests.length && i < 5; i++) {
          final item = newRequests[i];
          final value = _getSortValue(item);
          // Show available keys for the first item
          if (i == 0) {
            print('  Available keys: ${item.keys.toList()}');
          }
          print(
            '  [$i] Value: $value, Title: ${item['title'] ?? 'N/A'}, ID: ${item['id'] ?? 'N/A'}',
          );
          // Show which field provided the value
          String sourceField = 'none';
          if (item['budget'] != null)
            sourceField = 'budget: ${item['budget']}';
          else if (item['price'] != null)
            sourceField = 'price: ${item['price']}';
          else if (item['amount'] != null)
            sourceField = 'amount: ${item['amount']}';
          else if (item['quote_amount'] != null)
            sourceField = 'quote_amount: ${item['quote_amount']}';
          else if (item['total_amount'] != null)
            sourceField = 'total_amount: ${item['total_amount']}';
          print('    Source field: $sourceField');
        }
      }

      if (myQuotes.isNotEmpty) {
        print('\nMY QUOTES (${myQuotes.length} items) - Before sorting:');
        for (int i = 0; i < myQuotes.length && i < 5; i++) {
          final item = myQuotes[i];
          final value = _getSortValue(item);
          // Show available keys for the first item
          if (i == 0) {
            print('  Available keys: ${item.keys.toList()}');
          }
          print(
            '  [$i] Value: $value, Amount: ${item['quote_amount'] ?? item['amount'] ?? 'N/A'}, ID: ${item['id'] ?? 'N/A'}',
          );
          // Show which field provided the value
          String sourceField = 'none';
          if (item['budget'] != null)
            sourceField = 'budget: ${item['budget']}';
          else if (item['price'] != null)
            sourceField = 'price: ${item['price']}';
          else if (item['amount'] != null)
            sourceField = 'amount: ${item['amount']}';
          else if (item['quote_amount'] != null)
            sourceField = 'quote_amount: ${item['quote_amount']}';
          else if (item['total_amount'] != null)
            sourceField = 'total_amount: ${item['total_amount']}';
          print('    Source field: $sourceField');
        }
      }

      if (sellerOrders.isNotEmpty) {
        print(
          '\nSELLER ORDERS (${sellerOrders.length} items) - Before sorting:',
        );
        for (int i = 0; i < sellerOrders.length && i < 5; i++) {
          final item = sellerOrders[i];
          final value = _getSortValue(item);
          // Show available keys for the first item
          if (i == 0) {
            print('  Available keys: ${item.keys.toList()}');
          }
          print(
            '  [$i] Value: $value, Amount: ${item['total_amount'] ?? item['amount'] ?? 'N/A'}, ID: ${item['id'] ?? item['order_id'] ?? 'N/A'}',
          );
        }
      }

      // Actual sorting logic based on the selected option
      switch (_currentSort!) {
        case SortOption.highToLow:
          newRequests.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          processedRequests.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          myQuotes.sort((a, b) => _getSortValue(b).compareTo(_getSortValue(a)));
          sellerOrders.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          disputedOrders.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          print('\n=== Sorting by Price: High to Low ===');
          break;

        case SortOption.lowToHigh:
          newRequests.sort(
            (a, b) => _getSortValue(a).compareTo(_getSortValue(b)),
          );
          processedRequests.sort(
            (a, b) => _getSortValue(a).compareTo(_getSortValue(b)),
          );
          myQuotes.sort((a, b) => _getSortValue(a).compareTo(_getSortValue(b)));
          sellerOrders.sort(
            (a, b) => _getSortValue(a).compareTo(_getSortValue(b)),
          );
          disputedOrders.sort(
            (a, b) => _getSortValue(a).compareTo(_getSortValue(b)),
          );
          print('\n=== Sorting by Price: Low to High ===');
          break;

        case SortOption.rating:
          newRequests.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          processedRequests.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          myQuotes.sort((a, b) => _getSortValue(b).compareTo(_getSortValue(a)));
          sellerOrders.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          disputedOrders.sort(
            (a, b) => _getSortValue(b).compareTo(_getSortValue(a)),
          );
          print('\n=== Sorting by Rating ===');
          break;

        default:
          break;
      }

      // Debug print after sorting
      print('\n=== SORTING DEBUG - AFTER SORTING ===');
      if (newRequests.isNotEmpty) {
        print('\nNEW REQUESTS (${newRequests.length} items) - After sorting:');
        for (int i = 0; i < newRequests.length && i < 5; i++) {
          final item = newRequests[i];
          final value = _getSortValue(item);
          print(
            '  [$i] Value: $value, Title: ${item['title'] ?? 'N/A'}, ID: ${item['id'] ?? 'N/A'}',
          );
        }
      }

      if (myQuotes.isNotEmpty) {
        print('\nMY QUOTES (${myQuotes.length} items) - After sorting:');
        for (int i = 0; i < myQuotes.length && i < 5; i++) {
          final item = myQuotes[i];
          final value = _getSortValue(item);
          print(
            '  [$i] Value: $value, Amount: ${item['quote_amount'] ?? item['amount'] ?? 'N/A'}, ID: ${item['id'] ?? 'N/A'}',
          );
        }
      }

      if (sellerOrders.isNotEmpty) {
        print(
          '\nSELLER ORDERS (${sellerOrders.length} items) - After sorting:',
        );
        for (int i = 0; i < sellerOrders.length && i < 5; i++) {
          final item = sellerOrders[i];
          final value = _getSortValue(item);
          print(
            '  [$i] Value: $value, Amount: ${item['total_amount'] ?? item['amount'] ?? 'N/A'}, ID: ${item['id'] ?? item['order_id'] ?? 'N/A'}',
          );
        }
      }
    }

    // Perform the sort
    _performSort();

    // Trigger UI update if needed
    if (shouldSetState) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.read).length;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Image.asset(
            "lib/assets/images/bidr_logo1.png",
            height: 40,
            width: 55,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  HugeIcons.strokeRoundedNotification01,
                  color: Constants.ftaColorLight,
                ),
                onPressed: _showNotificationDialog,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
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
          SizedBox(width: 15),
          SellerSortDropdownMenu(
            initialValue: _currentSort,
            onSortChanged: (option) {
              setState(() {
                _currentSort = option;
              });
              print('Sort changed to: $option');
            },
          ),
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              decoration: BoxDecoration(color: Constants.ftaColorLight),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(side: BorderSide.none),
                    child: Text(
                      'Seller Dashboard',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 18,
                        decorationStyle: TextDecorationStyle.solid,
                        textStyle: TextStyle(color: Colors.white),
                        decorationColor: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Orange Navigation Bar
            SizedBox(height: 24),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: HelperWidget(
                              icon: HugeIcons.strokeRoundedBook02,
                              title: "My BookKeeper",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => MyBookkeeperScreen(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              backgroundColor: Constants.ctaColorLight,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: HelperWidget(
                              icon: HugeIcons.strokeRoundedBook02,
                              title: "Support",
                              onTap: () {
                                isFromDashboard = true;
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => SupportMobile(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                                setState(() {});
                              },
                              backgroundColor: Constants.ctaColorLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: HelperWidget(
                              icon: HugeIcons.strokeRoundedBook02,
                              title: "Refer a Friend/Business",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => ShareWidgetMobile(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              backgroundColor: Constants.ctaColorLight,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: HelperWidget(
                              icon: HugeIcons.strokeRoundedBook02,
                              title: "Reviews & Rating Manager",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => RatingReviewMobile(sellerId: ''),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              backgroundColor: Constants.ctaColorLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: HelperWidget(
                              icon: HugeIcons.strokeRoundedBook02,
                              title: "My Profile",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => ProfileManagementMobile(),
                                    transitionsBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          );
                                        },
                                  ),
                                );
                              },
                              backgroundColor: Constants.ctaColorLight,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(child: Container()),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: buildLeadsRequestsWidget(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                        tabActiveIndex = 6;
                        sellerHomeValueNotifier.value++;
                        setState(() {});
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
        SizedBox(height: 8),
        Row(
          children: [
            Text(
              'LEADS/REQUESTS',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Spacer(),
            OutlinedButton(
              onPressed: () {},
              child: Text(
                "view all",
                style: GoogleFonts.manrope(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Left sidebar with tabs (bookkeeper style)
              Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // New Requests Tab
                    Expanded(
                      child: _buildRequestMenuItem(
                        'New Requests ($totalNewRequests)',
                        0,
                        totalNewRequests,
                      ),
                    ),
                    // My Bids Tab
                    //SizedBox(width: 16,),
                    Expanded(
                      child: _buildRequestMenuItem(
                        'My Bids ($totalQuotes)',
                        1,
                        totalQuotes,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildRequestMenuItem(
                        'Paid Bids ($totalPaidBids)',
                        2,
                        totalPaidBids,
                      ),
                    ),
                    Expanded(
                      child: _buildRequestMenuItem(
                        'Completed Bids ($totalCompletedBids)',
                        3,
                        totalCompletedBids,
                      ),
                    ),

                    // Completed Bids Tab
                  ],
                ),
              ),
              // Main content area
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content based on selected tab
                        if (selectedRequestTab == 0)
                          Expanded(
                            child: _buildRequestContent(
                              newRequests,
                              'new requests',
                            ),
                          ),
                        if (selectedRequestTab == 1)
                          Expanded(
                            child: _buildQuotesContent(myQuotes, 'my bids'),
                          ),
                        if (selectedRequestTab == 2)
                          Expanded(child: _buildPaidBidsContent()),
                        if (selectedRequestTab == 3)
                          Expanded(child: _buildCompletedBidsContent()),
                      ],
                    ),
                  ),
                ],
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
                      onPressed: () {
                        // Flag functionality not available in this context
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Flag functionality not available here',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
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
                      onPressed: () async {
                        // Show loading indicator while creating/getting conversation
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Constants.ctaColorLight,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading conversation...',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        try {
                          // Create or get conversation for this request
                          final conversationData =
                              await ChatService.createOrGetConversationForRequest(
                                uuid,
                              );

                          // Close loading dialog
                          Navigator.of(context).pop();

                          if (conversationData != null) {
                            // Navigate to GroupChat with backend integration
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupChatMobile(
                                  groupChat: GroupChat(
                                    uuid: uuid,
                                    request: ProductRequest(
                                      description: description,
                                    ),
                                    messages:
                                        [], // Empty - will be loaded from backend
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Show error if backend returns null
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Unable to create conversation. Please try again.',
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          // Close loading dialog and show error
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to load conversation. Please try again.',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
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

          // Reload data when switching tabs
          _fetchRequestsData();
          _fetchQuotesData();
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
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // Content area for selected tab
  Widget _buildRequestContent(List<dynamic> requests, String type) {
    print('Building request content for $type with ${requests.length} items');

    // Show loading indicator only during initial load
    if (isLoadingRequests && _isInitialRequestsLoad) {
      return Container(
        padding: EdgeInsets.all(64),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Constants.ftaColorLight,
          ),
        ),
      );
    }

    // Show error if any
    if (requestsError != null) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              SizedBox(height: 16),
              Text(
                'Error loading requests',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                requestsError!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchRequestsData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ftaColorLight,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
        // Vertical list layout
        Column(
          children: paginatedRequests.asMap().entries.map((entry) {
            final index = entry.key;
            final request = entry.value;
            final globalIndex = startIndex + index + 1;

            // Use a unique key based on request ID for proper widget tracking
            final uniqueKey =
                request['id']?.toString() ??
                request['request_id']?.toString() ??
                '${request['budget']}_${request['created_at']}_$globalIndex';

            return Container(
              key: ValueKey(uniqueKey),
              margin: EdgeInsets.only(bottom: 16),
              child: _buildOriginalLeadCard(request, globalIndex),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages, requests.length),
      ],
    );
  }

  Widget _buildQuotesContent(List<dynamic> quotes, String type) {
    print('Building quotes content for $type with ${quotes.length} items');

    // Show loading indicator only during initial load
    if (isLoadingQuotes && _isInitialQuotesLoad) {
      return Container(
        padding: EdgeInsets.all(64),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Constants.ftaColorLight,
          ),
        ),
      );
    }

    // Show error if any
    if (quotesError != null) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              SizedBox(height: 16),
              Text(
                'Error loading bids',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                quotesError!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchQuotesData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ftaColorLight,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
        // Vertical list layout
        Column(
          children: paginatedQuotes.asMap().entries.map((entry) {
            final index = entry.key;
            final quote = entry.value;
            final globalIndex = startIndex + index + 1;

            // Use a unique key based on quote ID or fallback for proper widget tracking
            final uniqueKey =
                quote['id']?.toString() ??
                quote['quote_id']?.toString() ??
                '${quote['quote_amount']}_${quote['created_at']}_$globalIndex';

            return Container(
              key: ValueKey(uniqueKey),
              margin: EdgeInsets.only(bottom: 16),
              child: _buildOriginalLeadCard(
                quote,
                globalIndex,
                buttonText: 'Update Bid',
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages, quotes.length),
      ],
    );
  }

  void _navigateToDetailScreen(dynamic request, int index) {
    String category = "";
    var requestDetails = request['request_details'];
    if (requestDetails != null) {
      category = requestDetails?['category'];
    } else {
      category = request?['category'];
      requestDetails = request;
    }
    print("sdhdkj ${category} ");

    try {
      if (category == null) {
        _showErrorSnackBar("Cannot open request details: Invalid request data");
        return;
      }

      switch (category) {
        case "VEHICLE_SPARES":
        case "Vehicle Spares":
          _navigateToAutoSparesDetail(request, requestDetails, index);
          break;

        case "TYRES_RIMS":
        case "Vehicle Tyres and Rims":
          _navigateToRimTyreDetail(request, requestDetails, index);
          break;

        case "ELECTRONICS":
        case "Consumer Electronics":
          _navigateToElectronicsDetail(request, requestDetails, index);

          break;

        default:
          _showErrorSnackBar("Unknown request category: $category");
      }
    } catch (e) {
      print('Navigation error: $e');
      _showErrorSnackBar("Error opening request details: ${e.toString()}");
    }
  }

  void _navigateToAutoSparesDetail(
    dynamic request,
    Map<String, dynamic> requestDetails,
    int index,
  ) {
    try {
      // Create AutoSparesRequest from the response data

      // Extract product specifications
      final productSpecs = requestDetails['product_specifications'] ?? {};

      // Create AutoSpares object
      final autoSpares = AutoSpares(
        vehicleDetails: VehicleDetails(
          vin: productSpecs['vin_number'] ?? '',
          manufacturer: productSpecs['vehicle_make'] ?? '',
          makeModel:
              '${productSpecs['vehicle_make'] ?? ''} ${productSpecs['vehicle_model'] ?? ''}'
                  .trim(),
          year: productSpecs['vehicle_year']?.toString() ?? '',
          type: productSpecs['vehicle_type'] ?? '',
          condition: productSpecs['condition_preference'] ?? 'NEW',
        ),
        partDetails: PartDetails(
          partName: productSpecs['part_name'] ?? requestDetails['title'] ?? '',
          quantity: productSpecs['quantity'] ?? 1,
          location: requestDetails['buyer_location']?['address'] ?? '',
          maxDistanceKm: 50, // Default value
          urgency:
              productSpecs['urgency'] ??
              requestDetails['urgency_timeline'] ??
              '1_WEEK',
          productDescription:
              productSpecs['description'] ??
              requestDetails['description'] ??
              '',
          imageUrls: [],
        ),
        moreFields: MoreFields.fromJson({
          'part_number': productSpecs['part_number'],
          'transmission_type': productSpecs['transmission_type'],
          'fuel_type': productSpecs['fuel_type'],
          'body_type': productSpecs['body_type'],
          'mileage': productSpecs['mileage'],
          'engine_size': productSpecs['engine_size'],
          'vehicle_type': productSpecs['vehicle_type'],
        }),
      );
      final productRequestItem = ProductRequestItem(
        requestId: request['request_id'] ?? '',
        buyerId: requestDetails['buyer_id'] ?? '',
        category: requestDetails['category'] ?? 'VEHICLE_SPARES',
        title: requestDetails['title'] ?? '',
        description: requestDetails['description'] ?? '',
        quantity: productSpecs['quantity'] ?? 1,
        conditionPreference: productSpecs['condition_preference'] ?? 'NEW',
        currency: 'ZAR',
        urgencyTimeline:
            productSpecs['urgency'] ??
            requestDetails['urgency_timeline'] ??
            '1_WEEK',
        status: requestDetails['status'] ?? 'ACTIVE',
        viewCount: requestDetails['view_count'] ?? 0,
        quotes: [], // Empty quotes for seller view
        productImages: List<String>.from(
          requestDetails['product_images'] ?? [],
        ),
        images: List<String>.from(requestDetails['product_images'] ?? []),
        vinPhotoUrl: requestDetails['vin_photo_url'],
        productSpecifications: productSpecs,
        createdAt:
            DateTime.tryParse(requestDetails['created_at'] ?? '') ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(requestDetails['updated_at'] ?? '') ??
            DateTime.now(),
      );

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SparesDetailScreen(
                index: index,
                request: productRequestItem,
                autoSpare: autoSpares,
                bids:
                    [], // You can extract quotes/offers from the response if available
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      print('Error creating AutoSpares detail: $e');
      _showErrorSnackBar("Error opening vehicle spares details");
    }
  }

  void _navigateToRimTyreDetail(
    dynamic request,
    Map<String, dynamic> requestDetails,
    int index,
  ) {
    try {
      // Create RimTyreRequest from the response data

      final productSpecs = requestDetails['product_specifications'] ?? {};

      // Create RimTyre object - you'll need to adapt this based on your RimTyre model
      final rimTyre = RimTyre(
        productDetails: RimTyreProductDetails(
          tyreWidthMm: (productSpecs['tyre_width_mm'] ?? 0),
          sidewallProfile: productSpecs['sidewall_profile'].toString(),
          wheelRimDiameterInches:
              productSpecs['wheel_rim_diameter_inches'] ?? '',
          tyreType: productSpecs['tyre_type'] ?? '',
          quantity: productSpecs['quantity'] ?? 1,
          //maxDistanceKm: productSpecs['max_distance_km'] ?? requestDetails['max_distance_km'] ?? '',
          urgency:
              productSpecs['urgency'] ??
              requestDetails['urgency_timeline'] ??
              '1_WEEK',
        ),
        moreFields: RimTyreMoreFields(
          vehicleType: productSpecs['vehicle_type'] ?? '',
          preferredBrand: productSpecs['preferred_brand'] ?? '',
          pitchCircleDiameter: productSpecs['pitch_circle_diameter'] ?? '',
          tyreConstructionType: productSpecs['tyre_construction_type'] ?? '',
          description:
              productSpecs['description'] ??
              requestDetails['description'] ??
              '',
          fitmentRequired: productSpecs['fitment_required'] ?? "",
          balancingRequired: productSpecs['balancing_required'] ?? "",
          tyreRotationRequired: productSpecs['tyre_rotation_required'] ?? "",
          imageUrls: List<String>.from(requestDetails['product_images'] ?? []),
        ),
      );
      final rimTyreRequest = RimTyreRequest(
        id: request['request_id'] ?? '',
        category: requestDetails['category'] ?? 'TYRES_RIMS',
        createdAt:
            DateTime.tryParse(requestDetails['created_at'] ?? '') ??
            DateTime.now(),
        status: '',
        rimTyre: rimTyre,
        sellerOffers: [],
        // Add other required fields
      );
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              RimTyreDetailScreen(
                index: index,
                request: rimTyreRequest,
                rimTyre: rimTyre,
                bids: [],
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      print('Error creating RimTyre detail: $e');
      _showErrorSnackBar("Error opening rim/tyre details");
    }
  }

  void _navigateToElectronicsDetail(
    dynamic request,
    Map<String, dynamic> requestDetails,
    int index,
  ) {
    try {
      // Create ConsumerElectronicsRequest from the response data

      final productSpecs = requestDetails['product_specifications'] ?? {};

      // Create ConsumerElectronics object - adapt based on your model
      final consumerElectronics = ConsumerElectronics(
        productDetails: ProductDetails(
          typeOfElectronics: productSpecs['type_of_electronics'] ?? '',
          brandPreference: productSpecs['brand_preference'] ?? '',
          modelSeries: productSpecs['model_series'],
          quantityNeeded: productSpecs['quantity'] ?? 1,
          // maxDistanceKm: productSpecs['max_distance_km'] ?? requestDetails['max_distance_km'] ?? '',
        ),
        featuresAndSpecs: FeaturesAndSpecs(
          purpose: productSpecs['purpose'] ?? '',
          conditionPreference: productSpecs['condition_preference'] ?? 'NEW',
          requiredFeatures: productSpecs['required_features'],
          additionalComments: productSpecs['additional_comments'],
          documentsOrImages: List<String>.from(
            requestDetails['product_images'] ?? [],
          ),
        ),
        budgetTimeline: BudgetTimeline(
          minPrice: double.parse(productSpecs['min_price']!.toString()),
          maxPrice: double.parse(productSpecs['max_price']!.toString()),
          urgency:
              productSpecs['urgency'] ??
              requestDetails['urgency_timeline'] ??
              '1_WEEK',
          needsInstallation: productSpecs['needs_installation'] ?? false,
        ),
      );
      final electronicsRequest = ConsumerElectronicsRequest(
        id: request['request_id'] ?? '',
        category: requestDetails['category'] ?? 'ELECTRONICS',
        createdAt:
            DateTime.tryParse(requestDetails['created_at'] ?? '') ??
            DateTime.now(),
        status: '',
        consumerElectronics: consumerElectronics,
        sellerOffers: [],
        // Add other required fields
      );
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ConsumerElectronicsDetailScreen(
                index: index,
                request: electronicsRequest,
                consumerElectronics: consumerElectronics,
                bids: [],
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } catch (e) {
      print('Error creating Electronics detail: $e');
      _showErrorSnackBar("Error opening electronics details");
    }
  }

  // Helper method for error display
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Build paid bids content
  Widget _buildPaidBidsContent() {
    print('Building paid bids content');

    // Show loading state
    if (isLoadingOrders) {
      return Container(
        padding: EdgeInsets.all(64),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.ftaColorLight),
          ),
        ),
      );
    }

    // Show error if any
    if (ordersError != null) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Error loading paid bids',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              ordersError!,
              style: GoogleFonts.manrope(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadSellerOrders, child: Text('Retry')),
          ],
        ),
      );
    }

    // Show empty state if no paid bids
    if (paidBids.isEmpty) {
      return _buildEmptyPaidBids();
    }

    // Calculate pagination
    final totalPages = (paidBids.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedBids = paidBids.sublist(
      startIndex,
      endIndex > paidBids.length ? paidBids.length : endIndex,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical list layout
        Column(
          children: paginatedBids.asMap().entries.map((entry) {
            final index = entry.key;
            final bid = entry.value;
            final globalIndex = startIndex + index + 1;
            // Use a unique key based on bid ID for proper widget tracking
            final uniqueKey =
                bid['id']?.toString() ??
                bid['order_id']?.toString() ??
                '${bid['amount']}_${bid['created_at']}_$globalIndex';

            return Container(
              key: ValueKey(uniqueKey),
              margin: EdgeInsets.only(bottom: 16),
              child: _buildPaidBidCard(bid),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages, paidBids.length),
      ],
    );
  }

  // Build empty state for paid bids
  Widget _buildEmptyPaidBids() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payment_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No Paid Bids',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Orders that have been paid by buyers will appear here',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build completed bids content
  Widget _buildCompletedBidsContent() {
    print('Building completed bids content');

    // Show loading state
    if (isLoadingOrders) {
      return Container(
        padding: EdgeInsets.all(64),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Constants.ftaColorLight,
          ),
        ),
      );
    }

    // Show error if any
    if (ordersError != null) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              'Error loading completed bids',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              ordersError!,
              style: GoogleFonts.manrope(
                color: Colors.red.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadSellerOrders, child: Text('Retry')),
          ],
        ),
      );
    }

    // Show empty state if no completed bids
    if (completedBids.isEmpty) {
      return _buildEmptyCompletedBids();
    }

    // Calculate pagination
    final totalPages = (completedBids.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedBids = completedBids.sublist(
      startIndex,
      endIndex > completedBids.length ? completedBids.length : endIndex,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vertical list layout
        Column(
          children: paginatedBids.asMap().entries.map((entry) {
            final index = entry.key;
            final bid = entry.value;
            final globalIndex = startIndex + index + 1;
            // Use a unique key based on bid ID for proper widget tracking
            final uniqueKey =
                bid['id']?.toString() ??
                bid['order_id']?.toString() ??
                '${bid['amount']}_${bid['created_at']}_$globalIndex';

            return Container(
              key: ValueKey(uniqueKey),
              margin: EdgeInsets.only(bottom: 16),
              child: _buildCompletedBidCard(bid),
            );
          }).toList(),
        ),
        SizedBox(height: 16),
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages, completedBids.length),
      ],
    );
  }

  // Build empty state for completed bids
  Widget _buildEmptyCompletedBids() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No Completed Bids',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Orders that have been completed and delivered will appear here',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build individual paid bid card
  Widget _buildPaidBidCard(Map<String, dynamic> order) {
    final requestId = order['order_id']?.toString() ?? '';
    // Use request description method to get proper product name
    final title = _getRequestDescription2(order);
    final createdAt =
        order['created_at'] ??
        order['orderDate'] ??
        DateTime.now().toIso8601String();
    final totalAmount =
        order['total_amount']?.toString() ?? order['amount']?.toString() ?? '0';
    final currency = order['currency'] ?? 'ZAR';
    print("dfggh $order");
    // Use buyer_id to generate a buyer name since we don't have buyer details
    final buyerId = order['buyer_id']?.toString() ?? '';
    final buyerName = buyerId.isNotEmpty
        ? 'Buyer ${buyerId.substring(0, 8)}...'
        : 'Unknown Buyer';
    final orderStatus = order['status']?.toString().toUpperCase() ?? 'PAID';

    // Calculate time since order creation
    final DateTime createdDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    final Duration timeSinceCreated = DateTime.now().difference(createdDate);

    String timeElapsedText = '';
    int progressValue = 0;

    if (timeSinceCreated.inDays > 0) {
      timeElapsedText = '${timeSinceCreated.inDays}d';
      progressValue = (timeSinceCreated.inDays * 10).clamp(0, 100);
    } else if (timeSinceCreated.inHours > 0) {
      timeElapsedText = '${timeSinceCreated.inHours}h';
      progressValue = (timeSinceCreated.inHours * 4).clamp(0, 100);
    } else {
      timeElapsedText = '${timeSinceCreated.inMinutes}m';
      progressValue = (timeSinceCreated.inMinutes * 2).clamp(0, 100);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UUID and Timer Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // UUID Display
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    requestId.length >= 6
                        ? requestId.substring(0, 6).toUpperCase()
                        : requestId.toUpperCase(),
                    style: GoogleFonts.manrope(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Timer
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: progressValue / 100,
                      strokeWidth: 2,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeElapsedText,
                    style: GoogleFonts.manrope(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Paid',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            'Order - $title',
            style: GoogleFonts.manrope(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Additional Notes
          Text(
            'Buyer: $buyerName • Amount: $currency $totalAmount',
            style: GoogleFonts.manrope(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPinConfirmationDialog({
                    'orderNumber':
                        order['order_number'] ??
                        order['orderNumber'] ??
                        'Unknown',
                    'productName': title,
                    'amount': double.tryParse(totalAmount) ?? 0.0,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Confirm Delivery',
                    style: GoogleFonts.manrope(
                      color: Colors.green[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPaidBidDetails(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.manrope(
                      color: Colors.red[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build individual completed bid card
  Widget _buildCompletedBidCard(Map<String, dynamic> order) {
    final requestId = order['order_id']?.toString() ?? '';
    // Use request description method to get proper product name
    final title = _getRequestDescription2(order);
    final createdAt =
        order['created_at'] ??
        order['orderDate'] ??
        DateTime.now().toIso8601String();
    final totalAmount =
        order['total_amount']?.toString() ?? order['amount']?.toString() ?? '0';
    final currency = order['currency'] ?? 'ZAR';
    // Use buyer_id to generate a buyer name since we don't have buyer details
    final buyerId = order['buyer_id']?.toString() ?? '';
    final buyerName = buyerId.isNotEmpty
        ? 'Buyer ${buyerId.substring(0, 8)}...'
        : 'Unknown Buyer';
    print("dfggh $order");
    final orderStatus =
        order['status']?.toString().toUpperCase() ?? 'COMPLETED';

    // Calculate time since order creation
    final DateTime createdDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    final Duration timeSinceCreated = DateTime.now().difference(createdDate);

    String timeElapsedText = '';

    if (timeSinceCreated.inDays > 0) {
      timeElapsedText = '${timeSinceCreated.inDays}d ago';
    } else if (timeSinceCreated.inHours > 0) {
      timeElapsedText = '${timeSinceCreated.inHours}h ago';
    } else {
      timeElapsedText = '${timeSinceCreated.inMinutes}m ago';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // UUID and Status Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // UUID Display
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    requestId.length >= 6
                        ? requestId.substring(0, 6).toUpperCase()
                        : requestId.toUpperCase(),
                    style: GoogleFonts.manrope(
                      color: Colors.grey[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Completed icon
              Icon(Icons.check_circle, color: Colors.green, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Constants.ftaColorLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Completed',
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            'Order - $title',
            style: GoogleFonts.manrope(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Additional Notes
          Text(
            'Buyer: $buyerName • Amount: $currency $totalAmount',
            style: GoogleFonts.manrope(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Completion time
          Text(
            'Completed $timeElapsedText',
            style: GoogleFonts.manrope(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCompletedBidDetails(order),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE3F2FD),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'View Details',
                style: GoogleFonts.manrope(
                  color: Colors.green[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build individual approved bid card - same design as My Bids

  // Show approved bid details dialog
  Future<void> _showApprovedBidDetails(Map<String, dynamic> bid) async {
    await _navigateToSellerBidDetailScreen(bid, 'approved');
  }

  void _showPinConfirmationDialog(Map<String, dynamic> order) {
    final List<TextEditingController> pinControllers = List.generate(
      4,
      (index) => TextEditingController(),
    );
    final List<FocusNode> focusNodes = List.generate(4, (index) => FocusNode());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning Icon
                  Icon(
                    CupertinoIcons.lock_fill,
                    color:
                        Constants.ctaColorLight ??
                        Colors.orange, // Null safety fix
                    size: 50,
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    'Confirm Delivery !',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2B3A5C),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'By confirming this delivery, you acknowledge that the goods have been successfully handed over to the buyer.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.grey[600] ?? Colors.grey,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Unique Identifier Text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Enter the ',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey[600] ?? Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: '4-digit PIN',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: const Color(0xFF2B3A5C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' provided by the buyer to confirm delivery',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey[600] ?? Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4-Digit PIN Input Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        width: 50,
                        height: 50,
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        child: TextField(
                          controller: pinControllers[index],
                          focusNode: focusNodes[index],
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2B3A5C),
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Constants.ctaColorLight,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.35),
                            contentPadding: EdgeInsets.all(0),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              // Move to next field
                              focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              // Move to previous field
                              focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Confirm Delivery Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        String pin = pinControllers
                            .map((controller) => controller.text)
                            .join();
                        if (pin.length == 4) {
                          _confirmDeliveryWithPin(order, pin, context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm Delivery',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Cancel Button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[600] ?? Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Confirm delivery with PIN
  Future<void> _confirmDeliveryWithPin(
    Map<String, dynamic> order,
    String pin,
    BuildContext context,
  ) async {
    if (pin.length != 4) {
      _showErrorMessage('Please enter a 4-digit PIN');
      return;
    }

    try {
      // Call backend API to confirm delivery
      final response = await http.post(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/collection-codes/confirm/',
        ),
        headers: {
          'Content-Type': 'application/json',
          // Note: Add proper authentication headers when available
        },
        body: json.encode({
          'order_number': order['orderNumber'],
          'pin_code': pin,
          'seller_id': Constants.myUid,
        }),
      );
      if (kDebugMode) {
        print(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/collection-codes/confirm/',
        );
        print(response.body);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if response contains an error (API returns 200 even for errors)
        if (data.containsKey('error')) {
          // API returned an error message
          _showErrorMessage(data['error']);
          return;
        }

        // Check for success field or assume success if no error
        if (data['success'] == true || !data.containsKey('error')) {
          // Success - delivery confirmed
          if (mounted) {
            Navigator.of(context).pop(); // Close dialog

            // Set PIN verification as successful and navigate to completed bids
            setState(() {
              isPinVerifiedSuccessful = true;
              selectedRequestTab = 3; // Navigate to Completed Bids tab
              currentPage = 1; // Reset to first page
            });

            // Refresh the seller orders to show updated data
            _loadSellerOrders();

            // Show success message
            MotionToast.success(
              title: Text(
                'Pin verified successfully',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              description: Text(''),
              animationType: AnimationType.slideInFromBottom,
              width: 300,
              height: 45,
              borderRadius: 12,
              toastDuration: const Duration(seconds: 3),
            ).show(context);
          }
        } else {
          // API returned success=false
          _showErrorMessage(
            data['message'] ?? 'Invalid PIN or PIN has expired',
          );
        }
      } else {
        // Non-200 status code
        _showErrorMessage('Failed to confirm delivery. Please try again.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error confirming delivery: $e');
      }
      _showErrorMessage('Failed to confirm delivery. Please try again.');
    }
  }

  // Show error message
  void _showErrorMessage(String message) {
    MotionToast.error(
      title: Text(
        'Error',
        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      description: Text(
        message,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
      ),

      animationType: AnimationType.slideInFromBottom,
      width: 300,
      height: 80,
      borderRadius: 12,
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }

  // Show paid bid details dialog
  Future<void> _showPaidBidDetails(Map<String, dynamic> order) async {
    await _navigateToSellerBidDetailScreen(order, 'paid');
  }

  // Show completed bid details dialog
  Future<void> _showCompletedBidDetails(Map<String, dynamic> order) async {
    await _navigateToSellerBidDetailScreen(order, 'completed');
  }

  // Navigate to detailed bid screen with backend data
  Future<void> _navigateToSellerBidDetailScreen(
    Map<String, dynamic> bidData,
    String type,
  ) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Constants.ftaColorLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading details...',
                    style: GoogleFonts.manrope(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Fetch detailed data from backend
      final detailResponse = await _fetchDetailedBidData(bidData, type);
      Navigator.pop(context); // Close loading dialog

      if (detailResponse != null && detailResponse['success'] == true) {
        final requestData = detailResponse['data'];
        final category =
            requestData['category'] ??
            requestData['product_category'] ??
            'VEHICLE_SPARES';

        // Navigate based on category similar to buyer dashboard
        switch (category.toString().toUpperCase()) {
          case "VEHICLE_SPARES":
          case "Vehicle Spares":
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SellerSparesDetailScreen(
                      request: requestData,
                      bidData: bidData,
                      type: type,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
              ),
            );
            break;

          case "TYRES_RIMS":
          case "Vehicle Tyres and Rims":
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SellerRimTyreDetailScreen(
                      request: requestData,
                      bidData: bidData,
                      type: type,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
              ),
            );
            break;

          case "ELECTRONICS":
          case "Consumer Electronics":
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SellerConsumerElectronicsDetailScreen(
                      request: requestData,
                      bidData: bidData,
                      type: type,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
              ),
            );
            break;

          default:
            // Fallback to generic detail screen
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SellerSparesDetailScreen(
                      request: requestData,
                      bidData: bidData,
                      type: type,
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      );
                    },
              ),
            );
        }
      } else {
        print('Failed to load bid details');
        // Show error dialog or snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bid details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      print('Error loading bid details: $e');
      // Show error dialog or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading bid details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fetch detailed bid/order data from backend
  Future<Map<String, dynamic>?> _fetchDetailedBidData(
    Map<String, dynamic> bidData,
    String type,
  ) async {
    try {
      final requestId =
          bidData['request_id'] ??
          bidData['product_request_id'] ??
          bidData['order_id'];
      final orderId = bidData['order_id'] ?? bidData['id'];

      if (requestId == null) {
        throw Exception('Request ID not found');
      }

      // Call API to get detailed request data
      return await ApiService.getProductRequestDetails(requestId.toString());
    } catch (e) {
      print('Error fetching detailed bid data: $e');
      return null;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _processDisputeResolution(
    dynamic order,
    String action,
    String notes,
    BuildContext context,
  ) async {
    try {
      final String orderId = order['order_id'].toString();
      final String newStatus = action == 'approve'
          ? 'REFUNDED'
          : 'PROCESSING'; // Keep as REFUND_REQUESTED or move back to PROCESSING

      // Call backend API to update order status
      final response = await http.post(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/$orderId/update_status/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': newStatus,
          'user_id': Constants.myUid,
          'resolution_notes': notes,
          'resolved_by': 'seller',
          'resolution_action': action,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - refresh disputed orders list
        setState(() {
          // Remove the resolved dispute from the list
          disputedOrders.removeWhere(
            (dispute) => dispute['order_id'].toString() == orderId,
          );
        });

        // Show success message
        MotionToast.success(
          title: Text(
            action == 'approve' ? 'Dispute Approved' : 'Dispute Declined',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          description: Text(
            action == 'approve'
                ? 'The dispute has been approved and refund will be processed.'
                : 'The dispute has been declined with your reasoning.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          width: 350,
          height: 80,
          toastDuration: const Duration(seconds: 3),
        ).show(context);
      } else {
        throw Exception(
          'Failed to process dispute resolution: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error processing dispute resolution: $e');

      // Show error message
      MotionToast.error(
        title: Text(
          'Error',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        description: Text(
          'Failed to process dispute resolution. Please try again.',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        width: 350,
        height: 80,
        toastDuration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  /*  void _showApproveDisputeDialog(dynamic order, BuildContext context) {
    bool _acceptedTerms = false;
    final TextEditingController _notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 500,
                constraints: BoxConstraints(maxHeight: 700),
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Approve Dispute',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Order details
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['order_number'] ?? 'N/A'}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Constants.ftaColorLight,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Buyer: ${_extractBuyerName(order)}',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Terms and conditions for approval
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispute Approval Terms',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Full refund will be processed to the buyer\n'
                                '• Order status will be updated to "REFUNDED"\n'
                                '• You acknowledge the dispute is valid\n'
                                '• This action cannot be undone\n'
                                '• Both parties will be notified',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.green[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Additional notes
                    Text(
                      'Resolution Notes (Optional)',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add any notes about the resolution...',
                        hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Constants.ctaColorLight,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Acceptance checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                          activeColor: Constants.ctaColorLight,
                        ),
                        Expanded(
                          child: Text(
                            'I understand and accept the terms for approving this dispute',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _acceptedTerms
                                ? () {
                              _processDisputeResolution(
                                order,
                                'approve',
                                _notesController.text.trim(),
                                context,
                              );
                              Navigator.of(context).pop();
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _acceptedTerms
                                  ? Colors.green[600]
                                  : Colors.grey[400],
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Approve Dispute',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
      },
    );
  }*/

  /* void _showDeclineDisputeDialog(dynamic order, BuildContext context) {
    bool _acceptedTerms = false;
    final TextEditingController _reasonController = TextEditingController();
    String _selectedDeclineReason = '';

    final List<String> _declineReasons = [
      'Product was delivered as described',
      'Issue can be resolved without refund',
      'Buyer error or misunderstanding',
      'Product damage due to misuse',
      'Return period has expired',
      'Insufficient evidence provided',
      'Other',
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 500,
                constraints: BoxConstraints(maxHeight: 800),
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Decline Dispute',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close,
                            size: 24,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Order details
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['order_number'] ?? 'N/A'}',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Constants.ftaColorLight,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Buyer: ${_extractBuyerName(order)}',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Reason dropdown
                    Text(
                      'Reason for Declining *',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDeclineReason.isEmpty
                              ? null
                              : _selectedDeclineReason,
                          hint: Text(
                            'Select a reason',
                            style: GoogleFonts.manrope(color: Colors.grey[500]),
                          ),
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          items: _declineReasons.map((reason) {
                            return DropdownMenuItem(
                              value: reason,
                              child: Text(
                                reason,
                                style: GoogleFonts.manrope(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedDeclineReason = value ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Additional details
                    Text(
                      'Additional Details *',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                        'Please provide detailed explanation for declining this dispute...',
                        hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Constants.ctaColorLight,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Terms and conditions
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispute Decline Terms',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• No refund will be processed\n'
                                '• Order status will remain as "REFUND_REQUESTED"\n'
                                '• Buyer may escalate to customer support\n'
                                '• Detailed reasoning is required\n'
                                '• Both parties will be notified',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.red[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Acceptance checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                          activeColor: Constants.ctaColorLight,
                        ),
                        Expanded(
                          child: Text(
                            'I understand the consequences of declining this dispute',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                            (_selectedDeclineReason.isNotEmpty &&
                                _reasonController.text.trim().isNotEmpty &&
                                _acceptedTerms)
                                ? () {
                              _processDisputeResolution(
                                order,
                                'decline',
                                '$_selectedDeclineReason: ${_reasonController.text.trim()}',
                                context,
                              );
                              Navigator.of(context).pop();
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              (_selectedDeclineReason.isNotEmpty &&
                                  _reasonController.text
                                      .trim()
                                      .isNotEmpty &&
                                  _acceptedTerms)
                                  ? Colors.red[600]
                                  : Colors.grey[400],
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Decline Dispute',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
      },
    );
  }*/

  // Updated card design to match screenshot
  Widget _buildOriginalLeadCard(
    dynamic request,
    int requestNumber, {
    String? buttonText,
  }) {
    final requestId = request['request_id'] ?? '';
    final description = request['seller_notes'] ?? request['description'] ?? '';
    final createdAt = request['created_at'] ?? '';
    final status = request['status'] ?? 'ACTIVE';
    final urgencyTimeline = request['urgency_timeline'] ?? '';
    final category = request['category'] ?? '';
    print("fgfgjhh0 $request");

    // Use the comprehensive _getRequestDescription method
    String productSummary = _getRequestDescription2(request);

    // Get category display name
    String categoryDisplay = '';
    if (category.toUpperCase().contains('VEHICLE_SPARES') ||
        category.contains('Vehicle Spares')) {
      categoryDisplay = 'Vehicle Spares';
    } else if (category.toUpperCase().contains('TYRES') ||
        category.toUpperCase().contains('RIMS')) {
      categoryDisplay = 'Tyres/Rims';
    } else if (category.toUpperCase().contains('ELECTRONICS')) {
      categoryDisplay = 'Consumer Electronics';
    }

    // Calculate time remaining for urgency
    final DateTime createdDate = DateTime.tryParse(createdAt) ?? DateTime.now();
    final Duration timeSinceCreated = DateTime.now().difference(createdDate);

    return IntrinsicHeight(
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with UUID and countdown timer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'UUID: ${requestId.substring(0, 6).toUpperCase()}',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  // Countdown timer
                  _buildCountdownTimer(urgencyTimeline, createdDate),
                ],
              ),
              SizedBox(height: 12),

              // Date and Status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status badge on the left
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E3A5F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFF1E3A5F).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Open',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                  ),
                  // Spacer and created date on the right
                  Text(
                    createdAt.isNotEmpty
                        ? DateFormat('dd MMM yyyy, h:mm a').format(
                            DateTime.tryParse(createdAt) ?? DateTime.now(),
                          )
                        : '',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Category tag
              if (categoryDisplay.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    categoryDisplay,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              // Description
              Text(
                productSummary,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),

              // Additional notes
              if (description.isNotEmpty)
                Text(
                  'Notes: $description',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: 16), // Reduced space
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ElevatedButton(
                          onPressed: () => _showBidDialog(context, request),
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFE8F5E9),
                                foregroundColor: Colors.green[700],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ).copyWith(
                                overlayColor:
                                    MaterialStateProperty.resolveWith<Color?>((
                                      Set<MaterialState> states,
                                    ) {
                                      if (states.contains(
                                        MaterialState.hovered,
                                      )) {
                                        return Colors.green.withOpacity(0.1);
                                      }
                                      return null;
                                    }),
                              ),
                          child: Text(
                            buttonText ?? 'Bid',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: ElevatedButton(
                          onPressed: _hasUserFlaggedRequest(request)
                              ? () => _viewFlagDialog(context, request)
                              : () {
                                  // Handle flag action
                                  _showFlagDialog(context, request);
                                },
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: _hasUserFlaggedRequest(request)
                                    ? Color(0xFFFFEBEE)
                                    : Color(0xFFFFEBEE),
                                foregroundColor: Colors.red[700],
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ).copyWith(
                                overlayColor:
                                    MaterialStateProperty.resolveWith<Color?>((
                                      Set<MaterialState> states,
                                    ) {
                                      if (states.contains(
                                        MaterialState.hovered,
                                      )) {
                                        return Colors.red.withOpacity(0.1);
                                      }
                                      return null;
                                    }),
                              ),
                          child: Text(
                            _hasUserFlaggedRequest(request)
                                ? 'View Flag'
                                : 'Flag',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // Bottom links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(
                      () => _buttonHoverStates['request_more_info_$requestId'] =
                          true,
                    ),
                    onExit: (_) => setState(
                      () => _buttonHoverStates['request_more_info_$requestId'] =
                          false,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: Colors.orange.withOpacity(0.1),
                      splashColor: Colors.orange.withOpacity(0.2),
                      onTap: () async {
                        // Show loading indicator while creating/getting conversation
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: Container(
                              padding: EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Constants.ftaColorLight,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading conversation...',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        try {
                          // Create or get conversation for this request
                          final conversationData =
                              await ChatService.createOrGetConversationForRequest(
                                requestId,
                              );

                          // Close loading dialog
                          Navigator.of(context).pop();

                          if (conversationData != null) {
                            // Navigate to GroupChat with backend integration
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupChatScreen(
                                  groupChat: GroupChat(
                                    uuid: requestId,
                                    request: ProductRequest(
                                      description: description,
                                    ),
                                    messages:
                                        [], // Empty - will be loaded from backend
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Show error if backend returns null
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Unable to create conversation. Please try again.',
                                ),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        } catch (e) {
                          // Close loading dialog and show error
                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to load conversation. Please try again.',
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      child: AnimatedDefaultTextStyle(
                        duration: Duration(milliseconds: 200),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight:
                              _buttonHoverStates['request_more_info_$requestId'] ??
                                  false
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color:
                              _buttonHoverStates['request_more_info_$requestId'] ??
                                  false
                              ? Colors.deepOrange
                              : Colors.orange,
                          decoration:
                              _buttonHoverStates['request_more_info_$requestId'] ??
                                  false
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: Colors.deepOrange,
                          decorationThickness: 2,
                        ),
                        child: Text('Request More Info'),
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(
                      () => _buttonHoverStates['full_description_$requestId'] =
                          true,
                    ),
                    onExit: (_) => setState(
                      () => _buttonHoverStates['full_description_$requestId'] =
                          false,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: Constants.ftaColorLight.withOpacity(0.1),
                      splashColor: Constants.ftaColorLight.withOpacity(0.2),
                      onTap: () {
                        _navigateToDetailScreen(request, 1);
                      },
                      child: AnimatedDefaultTextStyle(
                        duration: Duration(milliseconds: 200),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight:
                              _buttonHoverStates['full_description_$requestId'] ??
                                  false
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color:
                              _buttonHoverStates['full_description_$requestId'] ??
                                  false
                              ? Constants.ftaColorLight
                              : Colors.orange,
                          decoration:
                              _buttonHoverStates['full_description_$requestId'] ??
                                  false
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: Constants.ftaColorLight,
                          decorationThickness: 2,
                        ),
                        child: Text('Full Description'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build countdown timer widget - shows remaining time until deadline
  Widget _buildCountdownTimer(String urgencyTimeline, DateTime createdDate) {
    final timeBreakdown = _getRemainingTimeBreakdown(
      createdDate,
      urgencyTimeline,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timeBreakdown['months']! > 0) ...[
          _buildTimerCircle(timeBreakdown['months'].toString(), "MO"),
          SizedBox(width: 8),
        ],
        if (timeBreakdown['weeks']! > 0) ...[
          _buildTimerCircle(timeBreakdown['weeks'].toString(), "W"),
          SizedBox(width: 8),
        ],
        _buildTimerCircle(timeBreakdown['days'].toString(), "D"),
        SizedBox(width: 8),
        _buildTimerCircle(timeBreakdown['hours'].toString(), "H"),
        SizedBox(width: 8),
        _buildTimerCircle(timeBreakdown['minutes'].toString(), "M"),
        SizedBox(width: 8),
        _buildTimerCircle(timeBreakdown['seconds'].toString(), "S"),
      ],
    );
  }

  Widget _buildTimerCircle(String value, String label) {
    // Parse the value to get current progress
    int currentValue = int.tryParse(value) ?? 0;

    // Determine max value based on label
    int maxValue;
    switch (label.toLowerCase()) {
      case 'mo':
        maxValue = 12;
        break;
      case 'w':
        maxValue = 4;
        break;
      case 'd':
        maxValue = 7; // Days in a week for remaining days
        break;
      case 'h':
        maxValue = 24;
        break;
      case 'm':
        maxValue = 60;
        break;
      case 's':
        maxValue = 60;
        break;
      default:
        maxValue = 100;
    }

    // Calculate progress percentage
    double progress = currentValue / maxValue;

    // Determine opacity based on value
    double opacity = currentValue == 0 ? 0.55 : 1.0;

    return Column(
      children: [
        Container(
          width: 25,
          height: 25,
          child: Stack(
            children: [
              // Circular progress indicator
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                backgroundColor: label == "D"
                    ? Colors.grey.shade600
                    : Colors.orange.shade50,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.orange.shade600.withOpacity(opacity),
                ),
              ),
              // Center text
              Center(
                child: Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: currentValue == 0
                        ? Colors.grey.withOpacity(0.55)
                        : Colors.orange.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getElapsedTime(DateTime? createdAt, String unit) {
    if (createdAt == null) return "0";

    final difference = DateTime.now().difference(createdAt);

    switch (unit) {
      case 'days':
        return difference.inDays.toString();
      case 'hours':
        return difference.inHours.toString();
      case 'minutes':
        return difference.inMinutes.toString();
      case 'seconds':
        return difference.inSeconds.toString();
      default:
        return "0";
    }
  }

  // Get time breakdown in months, weeks, days, hours, minutes, seconds
  // Get remaining time breakdown for countdown
  Map<String, int> _getRemainingTimeBreakdown(
    DateTime? createdAt,
    String urgencyTimeline,
  ) {
    if (createdAt == null) {
      return {
        'months': 0,
        'weeks': 0,
        'days': 0,
        'hours': 0,
        'minutes': 0,
        'seconds': 0,
      };
    }

    // Calculate the deadline based on urgency timeline
    DateTime deadline;
    switch (urgencyTimeline) {
      case 'ASAP':
        deadline = createdAt.add(Duration(hours: 12));
        break;
      case '12_HOURS':
        deadline = createdAt.add(Duration(hours: 12));
        break;
      case '24_HOURS':
        deadline = createdAt.add(Duration(hours: 24));
        break;
      case '2-3_DAYS':
        deadline = createdAt.add(Duration(days: 3));
        break;
      case '1_WEEK':
        deadline = createdAt.add(Duration(days: 7));
        break;
      case '2_WEEKS':
        deadline = createdAt.add(Duration(days: 14));
        break;
      case '1_MONTH':
        deadline = createdAt.add(Duration(days: 30));
        break;
      default:
        deadline = createdAt.add(Duration(days: 7));
    }

    // Calculate remaining time
    final remaining = deadline.difference(DateTime.now());

    // If time has expired, return all zeros
    if (remaining.isNegative) {
      return {
        'months': 0,
        'weeks': 0,
        'days': 0,
        'hours': 0,
        'minutes': 0,
        'seconds': 0,
      };
    }

    // Calculate total seconds remaining
    int totalSeconds = remaining.inSeconds;

    // Calculate months (approximating 30 days per month)
    int months = totalSeconds ~/ (30 * 24 * 60 * 60);
    totalSeconds %= (30 * 24 * 60 * 60);

    // Calculate weeks
    int weeks = totalSeconds ~/ (7 * 24 * 60 * 60);
    totalSeconds %= (7 * 24 * 60 * 60);

    // Calculate days
    int days = totalSeconds ~/ (24 * 60 * 60);
    totalSeconds %= (24 * 60 * 60);

    // Calculate hours
    int hours = totalSeconds ~/ (60 * 60);
    totalSeconds %= (60 * 60);

    // Calculate minutes
    int minutes = totalSeconds ~/ 60;
    totalSeconds %= 60;

    // Remaining seconds
    int seconds = totalSeconds;

    return {
      'months': months,
      'weeks': weeks,
      'days': days,
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  Map<String, int> _getTimeBreakdown(DateTime? createdAt) {
    if (createdAt == null) {
      return {
        'months': 0,
        'weeks': 0,
        'days': 0,
        'hours': 0,
        'minutes': 0,
        'seconds': 0,
      };
    }

    final difference = DateTime.now().difference(createdAt);

    // Calculate total seconds
    int totalSeconds = difference.inSeconds;

    // Calculate months (approximating 30 days per month)
    int months = totalSeconds ~/ (30 * 24 * 60 * 60);
    totalSeconds %= (30 * 24 * 60 * 60);

    // Calculate weeks
    int weeks = totalSeconds ~/ (7 * 24 * 60 * 60);
    totalSeconds %= (7 * 24 * 60 * 60);

    // Calculate days
    int days = totalSeconds ~/ (24 * 60 * 60);
    totalSeconds %= (24 * 60 * 60);

    // Calculate hours
    int hours = totalSeconds ~/ (60 * 60);
    totalSeconds %= (60 * 60);

    // Calculate minutes
    int minutes = totalSeconds ~/ 60;
    totalSeconds %= 60;

    // Remaining seconds
    int seconds = totalSeconds;

    return {
      'months': months,
      'weeks': weeks,
      'days': days,
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
    };
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

  void _showBidDialog(
    BuildContext context,
    Map<String, dynamic> request, {
    bool isAlternateBid = false,
  }) {
    // Fetch previous bids if this is an alternate bid
    if (isAlternateBid) {
      final requestId = request['request_id']?.toString();
    }

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
                      isAlternateBid
                          ? 'Enter Alternate Bid Details'
                          : 'Enter Bid Details',
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

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button (X) at top right
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Star eyes emoji
                Container(
                  width: 80,
                  height: 80,
                  child: Text(
                    '🤩',
                    style: TextStyle(fontSize: 60),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),

                // Thank You title
                Text(
                  'Thank You',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),

                // Subtitle
                Text(
                  'your bid has been submitted',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 32),

                // Submit an Alternate Bid button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Show the bid dialog for alternate bid
                      if (_currentRequestForAlternateBid != null) {
                        _showBidDialog(
                          context,
                          _currentRequestForAlternateBid!,
                          isAlternateBid: true,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight, // Orange color
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Submit an Alternate Bid',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Done button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight, // Orange color
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.manrope(
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
                CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Constants.ftaColorLight,
                ),
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
        // Store current request for potential alternate bids
        _currentRequestForAlternateBid = Map<String, dynamic>.from(request);

        // Close bid dialog
        Navigator.of(context).pop();

        // Clear form
        _priceController.clear();
        _commentsController.clear();

        // Show success dialog with alternate bid option
        _showSuccessDialog(context, 'Bid submitted successfully!');

        // Add the new bid to myQuotes list directly from the API response
        if (result['data'] != null) {
          setState(() {
            myQuotes.insert(
              0,
              result['data'],
            ); // Insert at beginning to show latest first
            totalQuotes = myQuotes.length;
          });
        }

        // Switch to "My Bids" tab without additional API calls
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

  /// Check if the current user has already flagged this request
  bool _hasUserFlaggedRequest(Map<String, dynamic> request) {
    final flags = request['flags'] as List<dynamic>? ?? [];
    final userUid = Constants.myUid;

    return flags.any((flag) => flag['uid'] == userUid);
  }

  /// Get the current user's flag reason for this request
  String _getUserFlagReason(Map<String, dynamic> request) {
    final flags = request['flags'] as List<dynamic>? ?? [];
    final userUid = Constants.myUid;

    try {
      final userFlag = flags.firstWhere((flag) => flag['uid'] == userUid);
      return userFlag['reason'] ?? 'No reason provided';
    } catch (e) {
      return 'No flag found for this user';
    }
  }

  void _showFlagDialog(BuildContext context, Map<String, dynamic> request) {
    final TextEditingController flagReasonController = TextEditingController();

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
                  'Please provide a reason for flagging this request:',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: flagReasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter your reason for flagging this request...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.orange, width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Handle flag request logic here
                          String reason = flagReasonController.text.trim();
                          if (reason.isNotEmpty) {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.orange,
                                    ),
                                  ),
                                );
                              },
                            );

                            try {
                              // Get request ID from the current request being flagged
                              final requestId = request['request_id'] ?? '';

                              // Submit the flag with the reason
                              final result = await ApiService.flagRequest(
                                requestId: requestId,
                                reason: reason,
                                authUserUid: Constants.myUid,
                              );

                              // Close loading dialog
                              Navigator.of(context).pop();
                              // Close flag dialog
                              Navigator.of(context).pop();

                              if (result['success']) {
                                // Refresh data to update UI
                                await _fetchRequestsData();

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Request flagged successfully',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message'] ??
                                          'Failed to flag request',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              // Close loading dialog
                              Navigator.of(context).pop();
                              // Close flag dialog
                              Navigator.of(context).pop();

                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error flagging request: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewFlagDialog(BuildContext context, Map<String, dynamic> request) {
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
                      ' This Request is Flagged',
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
                  _getUserFlagReason(request),
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

  String _getTimeframeLabel(String timeframe) {
    switch (timeframe) {
      case 'daily':
        return 'Today';
      case 'weekly':
        return 'This Week';
      case 'monthly':
        return 'This Month';
      case 'yearly':
        return 'This Year';
      default:
        return 'This Month';
    }
  }

  void _showTimeframeSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(
            'Select Timeframe',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            _buildTimeframeOption('daily', 'Daily'),
            _buildTimeframeOption('weekly', 'Weekly'),
            _buildTimeframeOption('monthly', 'Monthly'),
            _buildTimeframeOption('yearly', 'Yearly'),
          ],
        );
      },
    );
  }

  Widget _buildTimeframeOption(String value, String label) {
    return SimpleDialogOption(
      onPressed: () {
        setState(() {
          selectedTimeframe = value;
        });
        Navigator.of(context).pop();
        _fetchOrdersSummary();
      },
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: selectedTimeframe == value
              ? FontWeight.w600
              : FontWeight.w400,
          color: selectedTimeframe == value
              ? Constants.ctaColorLight
              : Colors.black87,
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(List ordersByStatus) {
    if (ordersByStatus.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey[300]!,
          value: 100,
          title: '',
          radius: 20,
        ),
      ];
    }

    // Define colors for different statuses
    final statusColors = {
      'PENDING': Color(0xFF3498DB),
      'PAID': Color(0xFF2ECC71),
      'COMPLETED': Constants.ctaColorLight,
      'CANCELLED': Color(0xFFE74C3C),
      'DELIVERED': Color(0xFF9B59B6),
      'SHIPPED': Color(0xFFF39C12),
    };

    return ordersByStatus.map<PieChartSectionData>((status) {
      final statusName = status['status'] ?? 'UNKNOWN';
      final count = (status['count'] ?? 0) as int;
      final color = statusColors[statusName] ?? Colors.grey;

      return PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '',
        radius: 20,
      );
    }).toList();
  }

  // Build dispute card from real order data
  Widget _buildDisputeCardFromOrder(Map<String, dynamic> order) {
    final orderNumber = order['order_number'] ?? order['orderNumber'] ?? 'N/A';
    final buyerName =
        order['buyer_name'] ?? order['buyerName'] ?? 'Unknown Buyer';
    final productName = order['product_name'] ?? order['productName'] ?? 'N/A';
    final status = order['status'] ?? 'N/A';
    final createdAt =
        order['created_at'] ??
        order['createdAt'] ??
        DateTime.now().toIso8601String();
    final amount = order['total_amount'] ?? order['amount'] ?? 0.0;

    // Format date
    DateTime dateTime;
    String formattedDate = 'N/A';
    String formattedTime = 'N/A';

    try {
      if (createdAt is String) {
        dateTime = DateTime.parse(createdAt);
        formattedDate = DateFormat('dd MMMM yyyy').format(dateTime);
        formattedTime = DateFormat('HH:mm').format(dateTime);
      }
    } catch (e) {
      // Use default values if parsing fails
    }

    return Container(
      width: 300,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #$orderNumber',
                      style: GoogleFonts.manrope(
                        color: Constants.ftaColorLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(status)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.manrope(
                          color: _getStatusColor(status),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  productName,
                  style: GoogleFonts.manrope(
                    color: Constants.ftaColorLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'Amount: R${amount.toString()}',
                  style: GoogleFonts.manrope(
                    color: Constants.ctaColorLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      buyerName,
                      style: GoogleFonts.manrope(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      '$formattedDate - $formattedTime',
                      style: GoogleFonts.manrope(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle dispute resolution
                      _showDisputeDetailsDialog(order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'View Details',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
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
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REFUNDED':
        return Colors.green;
      case 'RETURNED':
        return Colors.orange;
      case 'REFUND_REQUESTED':
      case 'REFUND REQUESTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Show dispute details dialog
  void _showDisputeDetailsDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Dispute Details',
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${order['order_number'] ?? 'N/A'}'),
              Text('Product: ${order['product_name'] ?? 'N/A'}'),
              Text('Buyer: ${order['buyer_name'] ?? 'N/A'}'),
              Text('Status: ${order['status'] ?? 'N/A'}'),
              Text(
                'Amount: R${order['total_amount'] ?? order['amount'] ?? 0.0}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
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

  void _showRequestInfoDialog(
    BuildContext context,
    Map<String, dynamic> request,
  ) {
    final requestId = request['request_id']?.toString() ?? '';
    final title = request['title']?.toString() ?? '';
    final description = request['description']?.toString() ?? '';
    final createdAt = request['created_at']?.toString() ?? '';
    final category = request['category']?.toString() ?? '';
    final vehicleSparesSummary =
        request['vehicle_spares_summary']?.toString() ?? '';
    final tyresRimsSummary = request['tyres_rims_summary']?.toString() ?? '';
    final electronicssSummary =
        request['consumer_electronics_summary']?.toString() ?? '';
    final budget = request['budget']?.toString() ?? '';
    final maxBudget = request['max_budget']?.toString() ?? '';
    final urgencyTimeline = request['urgency_timeline']?.toString() ?? '';
    final images = request['images'] ?? [];
    final quantity = request['quantity']?.toString() ?? '';
    final conditionPreference =
        request['condition_preference']?.toString() ?? '';
    final productSpecifications = request['product_specifications'] ?? {};
    final vehicleSparesData = request['vehicle_spares_data'] ?? {};
    final electronicsData = request['consumer_electronics_data'] ?? {};
    final tyresRimsData = request['vehicle_tyres_rims_data'] ?? {};

    // Format the request number for display
    final requestNumber = requestId.substring(0, 6).toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        if (category == 'VEHICLE_SPARES') {
          // Use the exact design from _SparesDetailScreenState
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Request #$requestNumber Information',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Constants.ctaColorLight,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle Details Card
                          Expanded(
                            child: _buildVehicleDetailCard(
                              "Vehicle Details",
                              Constants.ctaColorLight,
                              vehicleSparesData.isNotEmpty
                                  ? vehicleSparesData
                                  : {
                                      'VIN Number': 'Not specified',
                                      'Manufacturer': 'Not specified',
                                      'Make & Model': title.isNotEmpty
                                          ? title
                                          : 'Not specified',
                                      'Year': '',
                                      'Type': 'Not specified',
                                      'Condition':
                                          conditionPreference.isNotEmpty
                                          ? conditionPreference
                                                .replaceAll('_', ' ')
                                                .toLowerCase()
                                                .split(' ')
                                                .map(
                                                  (word) => word.isNotEmpty
                                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                      : word,
                                                )
                                                .join(' ')
                                          : 'Not specified',
                                    },
                            ),
                          ),
                          SizedBox(width: 16),

                          // Part Details Card
                          Expanded(
                            child: _buildVehicleDetailCard(
                              "Part Details",
                              Colors.orange,
                              {
                                'Part Name/Description':
                                    vehicleSparesSummary.isNotEmpty
                                    ? vehicleSparesSummary
                                    : (title.isNotEmpty
                                          ? title
                                          : 'Not specified'),
                                'Quantity': quantity.isNotEmpty
                                    ? quantity
                                    : 'Not specified',
                                'Budget': budget.isNotEmpty
                                    ? 'R$budget'
                                    : 'Not specified',
                                'Urgency': urgencyTimeline.isNotEmpty
                                    ? urgencyTimeline
                                          .replaceAll('_', ' ')
                                          .toLowerCase()
                                          .split(' ')
                                          .map(
                                            (word) => word.isNotEmpty
                                                ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                : word,
                                          )
                                          .join(' ')
                                    : 'Not specified',
                                'Description': description.isNotEmpty
                                    ? description
                                    : 'No description provided',
                                'Product Images': images.isNotEmpty
                                    ? '${images.length} image(s) available'
                                    : 'No images',
                              },
                            ),
                          ),
                          SizedBox(width: 16),

                          // More Details Card
                          Expanded(
                            child: _buildVehicleDetailCard(
                              "More Details",
                              Colors.orange,
                              {
                                ...productSpecifications,
                                'Request ID': requestNumber,
                                'Created': createdAt.isNotEmpty
                                    ? DateTime.tryParse(
                                            createdAt,
                                          )?.toString().split(' ')[0] ??
                                          createdAt
                                    : 'Not specified',
                                'Category': category
                                    .replaceAll('_', ' ')
                                    .toLowerCase()
                                    .split(' ')
                                    .map(
                                      (word) => word.isNotEmpty
                                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                                          : word,
                                    )
                                    .join(' '),
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // For other categories, use simplified design
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Request Information',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Request summary card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REQUEST #$requestNumber',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  title.isNotEmpty
                                      ? title
                                      : (description.isNotEmpty
                                            ? description
                                            : 'No title provided'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    category
                                        .replaceAll('_', ' ')
                                        .toLowerCase()
                                        .split(' ')
                                        .map(
                                          (word) => word.isNotEmpty
                                              ? '${word[0].toUpperCase()}${word.substring(1)}'
                                              : word,
                                        )
                                        .join(' '),
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Three sections in a row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Product Details',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    _buildDetailItem(
                                      'Category',
                                      category.isNotEmpty
                                          ? category
                                                .replaceAll('_', ' ')
                                                .toLowerCase()
                                                .split(' ')
                                                .map(
                                                  (word) => word.isNotEmpty
                                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                      : word,
                                                )
                                                .join(' ')
                                          : 'Not specified',
                                    ),
                                    if (electronicsData['brand'] != null)
                                      _buildDetailItem(
                                        'Brand',
                                        electronicsData['brand']?.toString() ??
                                            'Not specified',
                                      ),
                                    if (electronicsData['model'] != null)
                                      _buildDetailItem(
                                        'Model',
                                        electronicsData['model']?.toString() ??
                                            'Not specified',
                                      ),
                                    if (tyresRimsData['tyre_brand'] != null)
                                      _buildDetailItem(
                                        'Tyre Brand',
                                        tyresRimsData['tyre_brand']
                                                ?.toString() ??
                                            'Not specified',
                                      ),
                                    _buildDetailItem(
                                      'Quantity',
                                      quantity.isNotEmpty
                                          ? quantity
                                          : 'Not specified',
                                    ),
                                    if (conditionPreference.isNotEmpty)
                                      _buildDetailItem(
                                        'Condition',
                                        conditionPreference
                                            .replaceAll('_', ' ')
                                            .toLowerCase()
                                            .split(' ')
                                            .map(
                                              (word) => word.isNotEmpty
                                                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                  : word,
                                            )
                                            .join(' '),
                                      ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 24),

                              // Budget and Timeline
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Budget and Timeline',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    _buildDetailItem(
                                      'Budget',
                                      budget.isNotEmpty
                                          ? 'R$budget'
                                          : 'Not specified',
                                    ),
                                    if (maxBudget.isNotEmpty)
                                      _buildDetailItem(
                                        'Max Budget',
                                        'R$maxBudget',
                                      ),
                                    _buildDetailItem(
                                      'Urgency Required',
                                      urgencyTimeline.isNotEmpty
                                          ? urgencyTimeline
                                                .replaceAll('_', ' ')
                                                .toLowerCase()
                                                .split(' ')
                                                .map(
                                                  (word) => word.isNotEmpty
                                                      ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                      : word,
                                                )
                                                .join(' ')
                                          : 'Not specified',
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(width: 24),

                              // Features and Specifications
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Features and Specifications',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    if (productSpecifications.isNotEmpty)
                                      ...productSpecifications.entries
                                          .map(
                                            (entry) => _buildDetailItem(
                                              entry.key
                                                  .toString()
                                                  .replaceAll('_', ' ')
                                                  .split(' ')
                                                  .map(
                                                    (word) => word.isNotEmpty
                                                        ? '${word[0].toUpperCase()}${word.substring(1)}'
                                                        : word,
                                                  )
                                                  .join(' '),
                                              entry.value.toString(),
                                            ),
                                          )
                                          .toList(),
                                    if (description.isNotEmpty)
                                      _buildDetailItem(
                                        'Description',
                                        description,
                                      ),
                                    if (images.isNotEmpty)
                                      _buildDetailItem(
                                        'Images',
                                        '${images.length} image(s) available',
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (description.isNotEmpty) ...[
                            SizedBox(height: 24),
                            Text(
                              'Additional Notes',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              description,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetailCard(
    String title,
    Color titleColor,
    Map<String, dynamic> data,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: titleColor.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),

          // Card content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 12),
                      Text(
                        entry.key
                            .toString()
                            .replaceAll('_', ' ')
                            .split(' ')
                            .map(
                              (word) => word.isNotEmpty
                                  ? '${word[0].toUpperCase()}${word.substring(1)}'
                                  : word,
                            )
                            .join(' '),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        entry.value?.toString() ?? 'Not specified',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
