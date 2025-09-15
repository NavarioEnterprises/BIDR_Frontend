import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bidr/constants/Constants.dart';
import 'package:bidr/config/environment_config.dart';
import 'package:bidr/global_values.dart';
import 'package:bidr/pages/notification.dart';
import 'package:bidr/pages/seller/profile_management.dart';
import 'package:bidr/pages/seller/rating_and_review.dart';
import 'package:bidr/pages/seller/seller_dashboard_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import "package:universal_html/html.dart" as html;
import 'package:motion_toast/motion_toast.dart';
import 'package:badges/badges.dart' as badges;
import '../../customWdget/appbar.dart';
import '../../customWdget/dropdownMenu.dart';
import '../../models/alert.dart';
import '../../models/request_models.dart';
import '../../services/auth_api_service.dart';
import '../../services/chat_service.dart';
import '../../services/notification_api_service.dart';
import '../../services/products_management_api_service.dart';
import '../../services/shared_preferences.dart';
import '../buyer/share_with_friends.dart';
import '../buyer/support.dart';
import '../buyer_dashboard.dart';
import '../buyer_home.dart';
import '../group_chat.dart';
import '../mobileView/SellerDashboard/sellerMobileDashboard.dart';
import 'enter_pin.dart';
import 'seller_dashboard_mobile.dart';

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
  bool _isLoadingNotifications = false;
  bool _isOverlayShown = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;

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
  String? requestsError;
  int totalNewRequests = 0;
  int totalProcessedRequests = 0;
  Map<String, dynamic>? sellerLocation;

  // Quotes data state variables
  List<dynamic> myQuotes = [];
  bool isLoadingQuotes = true;
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
  int selectedRequestTab =
      0; // 0: New Requests, 1: My Bids, 2: Paid Bids, 3: Completed Bids
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
    'Plans & Billing',
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
    _loadNotificationsFromApi();
    _loadSellerOrders();
    _loadEarningHistory();
    _fetchDisputedOrders();
    _fetchResolvedDisputes();
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

        // Apply sorting after quotes data is loaded and setState completes
        if (mounted) {
          _applySorting();
        }

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

  Future<void> _testFetchAllRefundRequests() async {
    try {
      print(
        'DEBUG TEST: Fetching ALL REFUND_REQUESTED orders (no seller filter)',
      );

      // First, test without any seller filter to see if there are any REFUND_REQUESTED orders at all
      final allRefundsUrl =
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?status=REFUND_REQUESTED';
      print('DEBUG TEST: URL: $allRefundsUrl');

      final response = await http.get(
        Uri.parse(allRefundsUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print('DEBUG TEST: Response status: ${response.statusCode}');
      print('DEBUG TEST: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allRefunds = data['results'] ?? [];
        print(
          'DEBUG TEST: Found ${allRefunds.length} total REFUND_REQUESTED orders',
        );

        // Now let's see which sellers these orders belong to
        for (int i = 0; i < allRefunds.length; i++) {
          final order = allRefunds[i];
          print(
            'DEBUG TEST: Order $i: seller_id=${order['seller_id']}, buyer_id=${order['buyer_id']}, status=${order['status']}',
          );
          print('DEBUG TEST: My seller ID: ${Constants.myUid}');
          print('DEBUG TEST: Match: ${order['seller_id'] == Constants.myUid}');
        }

        // Show a dialog with the results
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Debug Results'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total REFUND_REQUESTED orders: ${allRefunds.length}'),
                  Text('Your seller ID: ${Constants.myUid}'),
                  SizedBox(height: 10),
                  ...allRefunds
                      .map(
                        (order) => Text(
                          'Order: ${order['order_number']} - Seller: ${order['seller_id']}',
                          style: TextStyle(fontSize: 12),
                        ),
                      )
                      .toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG TEST: Error: $e');
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
            '  [$i] Value: $value, Total: ${item['total_amount'] ?? 'N/A'}, Order: ${item['order_number'] ?? 'N/A'}',
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

      // Sort each list based on the selected option
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
          break;

        default:
          break;
      }

      print('\n=== SORTING DEBUG - AFTER SORTING ===');

      // Debug print after sorting
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
            '  [$i] Value: $value, Total: ${item['total_amount'] ?? 'N/A'}, Order: ${item['order_number'] ?? 'N/A'}',
          );
        }
      }

      print('=== END SORTING DEBUG ===\n');
    }

    if (shouldSetState && mounted) {
      setState(() {
        _performSort();
      });
      print('🔄 setState called - UI should rebuild now');
    } else {
      _performSort();
      print('🔄 Sort performed without setState');
    }

    print('Applied sorting: $_currentSort');
    print('New requests count after sorting: ${newRequests.length}');
    print('My quotes count after sorting: ${myQuotes.length}');
  }

  @override
  Widget build(BuildContext context) {
    // Show mobile version for screens smaller than 800px
    if (MediaQuery.of(context).size.width < 800) {
      return SellerMobileDashboard();
    }

    final unreadCount = notifications.where((n) => !n.read).length;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SellerDashboardHeader(
            headerName: 'Seller Dashboard',
            initialSort: _currentSort,
            tabActiveIndex: tabActiveIndex,
            onSortChanged: (option) {
              print('\n🔄 SORT CALLBACK TRIGGERED');
              print('Previous sort: $_currentSort');
              print('New sort: $option');
              _currentSort = option;
              _applySorting();
              print('Sort change completed ✅\n');
            },
          ),
          // Orange Navigation Bar
          SizedBox(height: 24),
          // Main Content Area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 64, right: 64),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
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
                  if (tabActiveIndex == 0) ...[
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
                        child: buildLeadsRequestsWidget(),
                      ),
                    ),
                  ] else if (tabActiveIndex == 1) ...[
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
                    Container(
                      //height: 400,
                      width: MediaQuery.of(context).size.width,
                      child: SellerSupport(),
                    ),
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
                  ] else if (tabActiveIndex == 6) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 64, right: 64),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        constraints: BoxConstraints(maxWidth: 1600),
                        //padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: NotificationPage(notifications: notifications),
                      ),
                    ),
                  ] else ...[
                    const SizedBox.shrink(),
                  ],
                  SizedBox(height: 24),
                  FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                ],
              ),
            ),
          ),
        ],
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

  // Load earning history from backend API (PAID orders only)
  Future<void> _loadEarningHistory({int page = 1}) async {
    if (page == 1) {
      setState(() {
        isLoadingEarnings = true;
        earningsError = null;
      });
    }

    try {
      // Fetch orders with PAID status for the current seller
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

          currentEarningsPage = page;
          totalEarningsCount = data['count'] ?? 0;
          hasNextEarningsPage = data['next'] != null;
          isLoadingEarnings = false;
          earningsError = null;
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
      print('Error loading earning history: $e');
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
      // Fetch orders with REFUNDED status for the current seller
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

          currentWithdrawsPage = page;
          totalWithdrawsCount = data['count'] ?? 0;
          hasNextWithdrawsPage = data['next'] != null;
          isLoadingWithdraws = false;
          withdrawsError = null;
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
      print('Error loading withdraw history: $e');
    }
  }

  // API service method to fetch seller orders for approved bids
  Future<void> _loadSellerOrders() async {
    setState(() {
      isLoadingOrders = true;
      ordersError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/',
        ).replace(queryParameters: {'seller_id': Constants.myUid}),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Handle different possible response structures
        List<dynamic> ordersData;
        if (jsonData is List) {
          ordersData = jsonData;
        } else if (jsonData is Map && jsonData.containsKey('results')) {
          ordersData = jsonData['results'];
        } else if (jsonData is Map && jsonData.containsKey('orders')) {
          ordersData = jsonData['orders'];
        } else {
          ordersData = [];
        }

        setState(() {
          sellerOrders = ordersData;

          // Filter orders for this seller
          final myOrders = ordersData
              .where((order) => order['seller_id'] == Constants.myUid)
              .toList();

          // Separate paid and completed bids
          paidBids = myOrders.where((order) {
            final status = order['status']?.toString().toUpperCase() ?? '';
            return status == 'PAID' || status == 'PAYMENT CONFIRMED';
          }).toList();

          completedBids = myOrders.where((order) {
            final status = order['status']?.toString().toUpperCase() ?? '';
            return status == 'PURCHASED' ||
                status == 'COMPLETED' ||
                status == 'DELIVERED';
          }).toList();

          totalPaidBids = paidBids.length;
          totalCompletedBids = completedBids.length;

          isLoadingOrders = false;
          print('DEBUG: Loaded ${ordersData.length} seller orders');
          print(
            'DEBUG: Paid bids: ${totalPaidBids}, Completed bids: ${totalCompletedBids}',
          );
          if (ordersData.isNotEmpty) {
            print('DEBUG: First order: ${ordersData.first}');
            print('DEBUG: Order keys: ${ordersData.first.keys.toList()}');
          }
        });

        // Apply sorting after orders data is loaded and setState completes
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

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;

    try {
      final userUuid = Constants.currentUser?.uid ?? Constants.myUid;
      print('Loading unread count for user UUID: $userUuid');

      if (userUuid.isNotEmpty) {
        final unreadCount = await _notificationApiService
            .getUnreadNotificationCount(userUuid);

        if (mounted) {
          setState(() {
            _unreadCount = unreadCount;
          });
        }
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
    }
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Add timeout to prevent infinite loading
      await Future.wait([
        _loadNotificationsFromApi(),
        _loadUnreadCount(),
      ]).timeout(const Duration(seconds: 15));
    } catch (e) {
      print('Error refreshing notifications: $e');
      // Set empty state on error
      if (mounted) {
        setState(() {
          notifications = [];
          _unreadCount = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
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
          _unreadCount = notifications.where((n) => !n.read).length;
        });
        print('Notification marked as read: $notificationId');
      } else {
        print('Failed to mark notification as read: $notificationId');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    if (!mounted) return;

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
            .timeout(const Duration(seconds: 10));

        if (mounted) {
          setState(() {
            notifications = fetchedNotifications;
            // Calculate unread count from loaded notifications
            _unreadCount = fetchedNotifications.where((n) => !n.read).length;
            _isLoadingNotifications = false;
          });
        }
      }
    } catch (e) {
      print('Error initializing notifications: $e');
      if (mounted) {
        setState(() {
          notifications = [];
          _unreadCount = 0;
          _isLoadingNotifications = false;
        });
      }
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
                            _buildRecentNotifications(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: _unreadCount > 0
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
                                                _unreadCount = 0;
                                              });
                                            }
                                          }
                                        }
                                      : null,
                                  child: Text(
                                    'Mark All Read',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _unreadCount > 0
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
                  strokeWidth: 1.5,
                  color: Constants.ftaColorLight,
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24),
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
                  TextButton(
                    onPressed: _fetchRequestsData,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          // Loading state
          else if (isLoadingRequests)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Constants.ftaColorLight,
                ),
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
                      // Paid Bids Tab
                      _buildRequestMenuItem(
                        'Paid Bids ($totalPaidBids)',
                        2,
                        totalPaidBids,
                      ),
                      // Completed Bids Tab
                      _buildRequestMenuItem(
                        'Completed Bids ($totalCompletedBids)',
                        3,
                        totalCompletedBids,
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
                      else if (selectedRequestTab == 1)
                        _buildQuotesContent(myQuotes, 'my bids')
                      else if (selectedRequestTab == 2)
                        _buildPaidBidsContent()
                      else if (selectedRequestTab == 3)
                        _buildCompletedBidsContent(),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
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
              'Additional Notes2:',
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
                                uuid,
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

    // Show loading indicator
    if (isLoadingRequests) {
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
        // 3 items per row with intrinsic height
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - 32) /
                3; // 3 items per row with 16px spacing

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paginatedRequests.asMap().entries.map((entry) {
                final index = entry.key;
                final request = entry.value;
                final globalIndex = startIndex + index + 1;

                // Use a unique key based on request ID for proper widget tracking
                final uniqueKey =
                    request['id']?.toString() ??
                    request['request_id']?.toString() ??
                    '${request['budget']}_${request['created_at']}_$globalIndex';

                return IntrinsicHeight(
                  key: ValueKey(uniqueKey),
                  child: SizedBox(
                    width: itemWidth,
                    child: _buildOriginalLeadCard(request, globalIndex),
                  ),
                );
              }).toList(),
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

    // Show loading indicator
    if (isLoadingQuotes) {
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
        // 3 items per row with intrinsic height
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - 32) /
                3; // 3 items per row with 16px spacing

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paginatedQuotes.asMap().entries.map((entry) {
                final index = entry.key;
                final quote = entry.value;
                final globalIndex = startIndex + index + 1;

                // Use a unique key based on quote ID or fallback for proper widget tracking
                final uniqueKey =
                    quote['id']?.toString() ??
                    quote['quote_id']?.toString() ??
                    '${quote['quote_amount']}_${quote['created_at']}_$globalIndex';

                return IntrinsicHeight(
                  key: ValueKey(uniqueKey),
                  child: SizedBox(
                    width: itemWidth,
                    child: _buildOriginalLeadCard(
                      quote,
                      globalIndex,
                      buttonText: 'Update Bid',
                    ),
                  ),
                );
              }).toList(),
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

              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Open',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
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
                      child: ElevatedButton(
                        onPressed: () => _showBidDialog(context, request),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE8F5E9),
                          foregroundColor: Colors.green[700],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _hasUserFlaggedRequest(request)
                            ? () => _viewFlagDialog(context, request)
                            : () {
                                // Handle flag action
                                _showFlagDialog(context, request);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasUserFlaggedRequest(request)
                              ? Color(0xFFFFEBEE)
                              : Color(0xFFFFEBEE),
                          foregroundColor: Colors.red[700],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                ],
              ),
              SizedBox(height: 12),
              // Bottom links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
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
                    child: Text(
                      'Request More Info',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _showRequestInfoDialog(context, request);
                    },
                    child: Text(
                      'Full Description',

                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
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

  // Build countdown timer widget - shows elapsed time since created
  Widget _buildCountdownTimer(String urgencyTimeline, DateTime createdDate) {
    final timeBreakdown = _getTimeBreakdown(createdDate);

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
                strokeWidth: 1.5,
                color: Constants.ftaColorLight,
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
      if (requestId != null) {
        _fetchPreviousBids(requestId);
      }
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

                // Alternate bid indicator
                if (isAlternateBid)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.blue[700],
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Submitting Alternate Bid',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Request: ${request['product_type'] ?? request['category'] ?? 'Product Request'}',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        if (request['description'] != null)
                          Text(
                            'Description: ${request['description'].toString().length > 50 ? request['description'].toString().substring(0, 50) + '...' : request['description']}',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),

                // Previous bids section for alternate bids
                if (isAlternateBid)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 16),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Your Previous Bids',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            if (_isLoadingPreviousBids)
                              Container(
                                height: 40,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Constants.ftaColorLight,
                                  ),
                                ),
                              )
                            else if (_previousBids.isEmpty)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'No previous bids found',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            else
                              Container(
                                constraints: BoxConstraints(maxHeight: 120),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _previousBids.length,
                                  itemBuilder: (context, index) {
                                    final bid = _previousBids[index];
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 8),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'R${bid['total_amount'] ?? 'N/A'}',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (bid['seller_notes'] != null)
                                                Text(
                                                  '${bid['seller_notes']}',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: bid['status'] == 'PENDING'
                                                  ? Colors.orange[100]
                                                  : bid['status'] == 'ACCEPTED'
                                                  ? Colors.green[100]
                                                  : Colors.red[100],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${bid['status'] ?? 'PENDING'}',
                                              style: GoogleFonts.manrope(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    bid['status'] == 'PENDING'
                                                    ? Colors.orange[700]
                                                    : bid['status'] ==
                                                          'ACCEPTED'
                                                    ? Colors.green[700]
                                                    : Colors.red[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

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

  /// Fetch previous bids for a specific request
  Future<void> _fetchPreviousBids(String requestId) async {
    setState(() {
      _isLoadingPreviousBids = true;
    });

    try {
      final result = await ApiService.getQuotesForRequest(requestId);
      print("dsjdhjhggh ${result}");

      setState(() {
        _isLoadingPreviousBids = false;
        if (result['success'] == true) {
          _previousBids = result['data'] ?? [];
        } else {
          _previousBids = [];
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingPreviousBids = false;
        _previousBids = [];
      });
      print('Error fetching previous bids: $e');
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
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to Completed Bids tab and reload data
                            setState(() {
                              selectedRequestTab = 3; // Completed Bids tab
                              currentPage = 1; // Reset to first page
                            });
                            _loadSellerOrders(); // Reload orders to show updated data
                          },
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
                                    strokeWidth: 1.5,
                                    color: Constants.ftaColorLight,
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
    if (isLoadingOrdersSummary) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Constants.ftaColorLight,
          ),
        ),
      );
    }

    if (ordersSummaryError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load revenue data',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              ordersSummaryError!,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrdersSummary,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final summary = ordersSummary?['summary'] ?? {};
    final totalRevenue = (summary['total_revenue'] ?? 0.0) as double;
    final totalOrders = (summary['total_orders'] ?? 0) as int;
    final avgOrderValue = (summary['average_order_value'] ?? 0.0) as double;
    final ordersByStatus = (summary['orders_by_status'] ?? []) as List;
    final chartData = (summary['chart_data'] ?? []) as List;

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
                        tween: Tween<double>(begin: 0, end: totalRevenue),
                        duration: Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Text(
                            'R${value.toStringAsFixed(0)}',
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
                            _getTimeframeLabel(selectedTimeframe),
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () => _showTimeframeSelector(),
                            child: Container(
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
                                    selectedTimeframe.toUpperCase(),
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
                      barGroups: chartData.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map item = entry.value;
                        double revenue = (item['revenue'] ?? 0.0) as double;
                        return _buildBarGroup(index, revenue);
                      }).toList(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < chartData.length) {
                                final periodLabel =
                                    chartData[value.toInt()]['period'] ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    periodLabel,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return SizedBox.shrink();
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
                        sections: _buildPieChartSections(ordersByStatus),
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
                      children: _buildLegendItems(ordersByStatus),
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

  List<Widget> _buildLegendItems(List ordersByStatus) {
    if (ordersByStatus.isEmpty) {
      return [_buildLegendItem(Colors.grey[300]!, '0', 'No Orders')];
    }

    final statusColors = {
      'PENDING': Color(0xFF3498DB),
      'PAID': Color(0xFF2ECC71),
      'COMPLETED': Constants.ctaColorLight,
      'CANCELLED': Color(0xFFE74C3C),
      'DELIVERED': Color(0xFF9B59B6),
      'SHIPPED': Color(0xFFF39C12),
    };

    final statusLabels = {
      'PENDING': 'Pending',
      'PAID': 'Paid',
      'COMPLETED': 'Completed',
      'CANCELLED': 'Cancelled',
      'DELIVERED': 'Delivered',
      'SHIPPED': 'Shipped',
    };

    List<Widget> items = [];
    for (int i = 0; i < ordersByStatus.length; i++) {
      final status = ordersByStatus[i];
      final statusName = status['status'] ?? 'UNKNOWN';
      final count = (status['count'] ?? 0) as int;
      final color = statusColors[statusName] ?? Colors.grey;
      final label = statusLabels[statusName] ?? statusName;

      items.add(_buildLegendItem(color, count.toString(), label));
      if (i < ordersByStatus.length - 1) {
        items.add(SizedBox(height: 8));
      }
    }

    return items;
  }

  Widget _buildTransactionHistory() {
    return Column(
      children: [
        // Tab Navigation
        Row(
          children: [
            _buildSubTab('Earning History', 0),
            _buildSubTab('Withdraw History', 1),
          ],
        ),
        SizedBox(height: 20),
        // Content based on selected tab
        selectedSubIndex == 0
            ? _buildEarningHistoryContent()
            : _buildWithdrawHistoryContent(),
      ],
    );
  }

  Widget _buildEarningHistoryContent() {
    if (isLoadingEarnings) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Constants.ftaColorLight,
          ),
        ),
      );
    }

    if (earningsError != null) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                earningsError!,
                style: GoogleFonts.manrope(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadEarningHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (earningHistory.isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Colors.grey[400],
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No Earning History',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You haven\'t received any payments yet.\nStart accepting orders to see your earnings!',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Column(
        children: [
          // Earning transactions
          ...earningHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final earning = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildEarningTransactionItem(earning),
                  ),
                );
              },
            );
          }).toList(),

          // Load more button if there are more pages
          if (hasNextEarningsPage)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: () =>
                    _loadEarningHistory(page: currentEarningsPage + 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Load More',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWithdrawHistoryContent() {
    if (isLoadingWithdraws) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Constants.ctaColorLight,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading withdraw history...',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (withdrawsError != null) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 64),
              SizedBox(height: 16),
              Text(
                'Failed to load withdraw history',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                withdrawsError!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadWithdrawHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (withdrawHistory.isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.grey[400],
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No Withdrawal History',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No refunded orders found.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build withdraw history list
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Order',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Date',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Status',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // Withdraw history items
        Expanded(
          child: ListView.builder(
            itemCount: withdrawHistory.length,
            itemBuilder: (context, index) {
              final order = withdrawHistory[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['request_title'] ??
                                'Order #${order['order_number'] ?? 'N/A'}',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order['request_category'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              order['request_category'],
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${order['currency'] ?? 'ZAR'} ${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatDate(order['updated_at'] ?? order['created_at']),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'REFUNDED',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Load more button
        if (hasNextWithdrawsPage)
          Container(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLoadingWithdraws
                  ? null
                  : () => _loadWithdrawHistory(page: currentWithdrawsPage + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Load More',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubTab(String title, int index) {
    bool isSelected = selectedSubIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubIndex = index;
        });

        // Load earning history when switching to earning history tab
        if (index == 0 && earningHistory.isEmpty && !isLoadingEarnings) {
          _loadEarningHistory();
        }
        // Load withdraw history when switching to withdraw history tab
        if (index == 1 && withdrawHistory.isEmpty && !isLoadingWithdraws) {
          _loadWithdrawHistory();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Constants.ctaColorLight
                    : Colors.transparent,
                width: 2.2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: isSelected ? Constants.ctaColorLight : Color(0xFF7F8C8D),
              fontWeight: FontWeight.w700,
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
      padding: EdgeInsets.only(bottom: 6, top: 6, right: 16, left: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(360),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,

              border: Border.all(color: Color(0xFF04AD01)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: Color(0xFF04AD01),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #BF123456',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Vehicle Spares',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ZAR 1,500.00',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF04AD01),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '12 Sep 2024',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageDisputes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Dispute Management',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ),

        Expanded(
          child: Row(
            children: [
              // Active Disputes Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.report_problem,
                            color: Colors.red[600],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Active Disputes (${disputedOrders.length})',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Disputes Content
                    Expanded(child: _buildActiveDisputesContent()),
                  ],
                ),
              ),

              SizedBox(width: 20),

              // Resolved Disputes Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[600],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Resolved Disputes (${resolvedDisputes.length})',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Resolved Disputes Content
                    Expanded(child: _buildResolvedDisputesContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOldManageDisputes() {
    if (isLoadingDisputes) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
          ),
        ),
      );
    }

    if (disputesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Failed to load disputes',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              disputesError!,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchDisputedOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _testFetchAllRefundRequests,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Test All REFUND_REQUESTED',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (disputedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Disputes Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All orders are proceeding smoothly!',
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFetchAllRefundRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Debug: Check All REFUND_REQUESTED Orders',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                children: disputedOrders.map<Widget>((order) {
                  final index = disputedOrders.indexOf(order);
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            width: 350,
                            margin: EdgeInsets.only(bottom: 16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  spreadRadius: 1,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.red.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.report_problem,
                                        color: Colors.red[600],
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dispute #${order['order_number'] ?? 'N/A'}',
                                            style: GoogleFonts.manrope(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                          Text(
                                            order['request_title'] ??
                                                'Order Request',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Order details
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Amount:',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            '${order['currency'] ?? 'ZAR'} ${(order['total_amount'] ?? 0).toString()}',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Date:',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            _formatDate(order['created_at']),
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Buyer:',
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            _extractBuyerName(order),
                                            style: GoogleFonts.manrope(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            _showDeclineDisputeDialog(
                                              order,
                                              context,
                                            ),
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          side: BorderSide(
                                            color: Colors.red[400]!,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Decline',
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            _showApproveDisputeDialog(
                                              order,
                                              context,
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green[600],
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Approve',
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
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateFromString(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    if (amount is String) {
      try {
        final double parsedAmount = double.parse(amount);
        return parsedAmount.toStringAsFixed(2);
      } catch (e) {
        return amount; // Return as-is if can't parse
      }
    } else if (amount is num) {
      return amount.toStringAsFixed(2);
    }
    return '0.00';
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

  String _getRequestId(dynamic request) {
    try {
      if (request is Map) {
        // Try various possible locations for the request ID
        return request['request_id']?.toString() ??
            request['id']?.toString() ??
            request['order_id']?.toString() ??
            request['quote_id']?.toString() ??
            'Unknown';
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildActiveDisputesContent() {
    if (isLoadingDisputes) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
          ),
        ),
      );
    }

    if (disputesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Failed to load disputes',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              disputesError!,
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDisputedOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (disputedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Active Disputes',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All orders are proceeding smoothly!',
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: disputedOrders.length,
      itemBuilder: (context, index) {
        final order = disputedOrders[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.red[600], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order #${order['order_number'] ?? 'N/A'}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Order details
              Text(
                _getRequestDescription2(order),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                'Amount: R${_formatAmount(order['total_amount'])}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Date: ${_formatDateFromString(order['created_at'] ?? '')}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),

              // Return reason if available
              if (order['return_reason'] != null &&
                  order['return_reason'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return Reason:',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      Text(
                        order['return_reason']?.toString() ??
                            'No reason provided',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: Colors.orange[700],
                        ),
                      ),
                      if (order['return_description'] != null &&
                          order['return_description']
                              .toString()
                              .isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          'Details: ${order['return_description']}',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _showApproveDisputeDialog(context, order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        padding: EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _showDeclineDisputeDialog(context, order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        padding: EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
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
        );
      },
    );
  }

  Widget _buildResolvedDisputesContent() {
    if (isLoadingResolvedDisputes) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Constants.ftaColorLight,
          ),
        ),
      );
    }

    if (resolvedDisputesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Failed to load resolved disputes',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              resolvedDisputesError!,
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchResolvedDisputes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (resolvedDisputes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Resolved Disputes',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Resolved disputes will appear here.',
              style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: resolvedDisputes.length,
      itemBuilder: (context, index) {
        final order = resolvedDisputes[index];
        final status = order['status']?.toString().toUpperCase() ?? '';
        final isApproved = status == 'REFUNDED';
        final isDeclined = status == 'CANCELLED';

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isApproved
                  ? Colors.green.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with resolution status
              Row(
                children: [
                  Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: isApproved ? Colors.green[600] : Colors.grey[600],
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Order #${order['order_number'] ?? 'N/A'}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isApproved
                            ? Colors.green[700]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isApproved ? 'APPROVED' : 'DECLINED',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isApproved
                            ? Colors.green[800]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Order details
              Text(
                _getRequestDescription2(order),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                'Amount: R${_formatAmount(order['total_amount'])}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Resolved: ${_formatDateFromString(order['updated_at'] ?? '')}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),

              // Return reason if available
              if (order['return_reason'] != null &&
                  order['return_reason'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Return Reason:',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                      Text(
                        order['return_reason']?.toString() ??
                            'No reason provided',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: Colors.blue[700],
                        ),
                      ),
                      if (order['return_description'] != null &&
                          order['return_description']
                              .toString()
                              .isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          'Details: ${order['return_description']}',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Resolution notes if available
              if (order['notes'] != null &&
                  order['notes'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isApproved
                          ? Colors.green[200]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resolution Notes:',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isApproved
                              ? Colors.green[800]
                              : Colors.grey[800],
                        ),
                      ),
                      Text(
                        order['notes']?.toString() ?? 'No notes provided',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: isApproved
                              ? Colors.green[700]
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningHistoryContent2() {
    if (isLoadingEarnings) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: CircularProgressIndicator(
            color: Constants.ctaColorLight,
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (earningsError != null) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 64),
              SizedBox(height: 16),
              Text(
                'Failed to load earning history',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                earningsError!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadEarningHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (earningHistory.isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: Colors.grey[400],
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No Earning History',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No paid orders found.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build earning history list
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Order',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Date',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Status',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // Earning history items
        Expanded(
          child: ListView.builder(
            itemCount: earningHistory.length,
            itemBuilder: (context, index) {
              final order = earningHistory[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['request_title'] ??
                                'Order #${order['order_number'] ?? 'N/A'}',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order['request_category'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              order['request_category'],
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${order['currency'] ?? 'ZAR'} ${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.green[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatDate(
                          order['payment_date'] ?? order['created_at'],
                        ),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PAID',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Load more button
        if (hasNextEarningsPage)
          Container(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLoadingEarnings
                  ? null
                  : () => _loadEarningHistory(page: currentEarningsPage + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Load More',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWithdrawHistoryContent2() {
    if (isLoadingWithdraws) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Constants.ctaColorLight,
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading withdraw history...',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (withdrawsError != null) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 64),
              SizedBox(height: 16),
              Text(
                'Failed to load withdraw history',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                withdrawsError!,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadWithdrawHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (withdrawHistory.isEmpty) {
      return Container(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.grey[400],
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No Withdrawal History',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'No refunded orders found.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build withdraw history list
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Order',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Date',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'Status',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        // Withdraw history items
        Expanded(
          child: ListView.builder(
            itemCount: withdrawHistory.length,
            itemBuilder: (context, index) {
              final order = withdrawHistory[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['request_title'] ??
                                'Order #${order['order_number'] ?? 'N/A'}',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order['request_category'] != null) ...[
                            SizedBox(height: 4),
                            Text(
                              order['request_category'],
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${order['currency'] ?? 'ZAR'} ${(order['total_amount'] ?? 0).toStringAsFixed(2)}',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _formatDate(order['updated_at'] ?? order['created_at']),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'REFUNDED',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Load more button
        if (hasNextWithdrawsPage)
          Container(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLoadingWithdraws
                  ? null
                  : () => _loadWithdrawHistory(page: currentWithdrawsPage + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Load More',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubTab2(String title, int index) {
    bool isSelected = selectedSubIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSubIndex = index;
        });

        // Load earning history when switching to earning history tab
        if (index == 0 && earningHistory.isEmpty && !isLoadingEarnings) {
          _loadEarningHistory();
        }
        // Load withdraw history when switching to withdraw history tab
        if (index == 1 && withdrawHistory.isEmpty && !isLoadingWithdraws) {
          _loadWithdrawHistory();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Constants.ctaColorLight
                    : Colors.transparent,
                width: 2.2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: isSelected ? Constants.ctaColorLight : Color(0xFF7F8C8D),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem2() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(bottom: 6, top: 6, right: 16, left: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(360),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.transparent,

              border: Border.all(color: Color(0xFF04AD01)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              selectedSubIndex == 0 ? Icons.add : Icons.remove,
              color: selectedSubIndex == 0
                  ? Color(0xFF04AD01)
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
                    fontWeight: FontWeight.w700,
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

  Widget _buildEarningTransactionItem(Map<String, dynamic> earning) {
    final amount = earning['total_amount']?.toString() ?? '0.00';
    final currency = earning['currency'] ?? 'ZAR';
    final paymentDate = earning['payment_date'] ?? earning['created_at'] ?? '';
    // Use buyer_id to generate a buyer name since we don't have buyer details
    final buyerId = earning['buyer_id']?.toString() ?? '';
    final buyerName = buyerId.isNotEmpty
        ? 'Buyer ${buyerId.substring(0, 8)}...'
        : 'Unknown Buyer';
    final buyerEmail = earning['buyer_email'] ?? '';
    final orderId = earning['order_id']?.toString() ?? '';
    final orderNumber = earning['order_number']?.toString() ?? '';
    final earningsStatus = earning['status'] ?? 'PAID';
    final productInfo = earning['request_title'] ?? 'Product/Service';

    // Format the date
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(paymentDate);
      formattedDate = DateFormat('dd MMM yyyy, h:mm a').format(dateTime);
    } catch (e) {
      formattedDate = paymentDate;
    }

    // Status color
    Color statusColor = Constants.ctaColorLight;
    IconData statusIcon = Icons.check_circle;

    switch (earningsStatus.toLowerCase()) {
      case 'completed':
      case 'captured':
      case 'released':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Constants.ctaColorLight;
        statusIcon = Icons.payments;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment from $buyerName',
                        style: GoogleFonts.manrope(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '$currency $amount',
                      style: GoogleFonts.manrope(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  productInfo.length > 30
                      ? '${productInfo.substring(0, 30)}...'
                      : productInfo,
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    if (orderId.isNotEmpty) ...[
                      SizedBox(width: 12),
                      Text(
                        'Order: ${orderId.substring(0, 8)}...',
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageDisputes2() {
    if (isLoadingDisputes) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
          ),
        ),
      );
    }

    if (disputesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            SizedBox(height: 16),
            Text(
              'Failed to load disputes',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              disputesError!,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _fetchDisputedOrders,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _testFetchAllRefundRequests,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Test All REFUND_REQUESTED',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (disputedOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Disputes Found',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All orders are proceeding smoothly!',
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testFetchAllRefundRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
                children: disputedOrders.map<Widget>((order) {
                  final index = disputedOrders.indexOf(order);
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: 0.8,
                          child: _buildDisputeCard(order),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month] ?? '';
  }

  Widget _buildDisputeCard(dynamic order) {
    // Extract data from order object
    final String orderId = order['order_number'] ?? 'N/A';
    final String orderIdFormatted =
        'DP-${orderId.replaceAll('-', '').toUpperCase()}';
    final String buyerName = _extractBuyerName(order);
    final DateTime createdAt =
        DateTime.tryParse(order['created_at'] ?? '') ?? DateTime.now();
    final String date =
        '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';
    final String time =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} ${createdAt.hour >= 12 ? 'PM' : 'AM'}';
    return Container(
      width: 300,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 1.4),
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
            padding: const EdgeInsets.only(left: 16, top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderIdFormatted,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Constants.ctaColorLight,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF04AD01),
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
          //SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Text(
              buyerName,
              style: GoogleFonts.manrope(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w700,
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
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
                    onPressed: () => _showDeclineDisputeDialog(order, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[600],
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Decline',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showApproveDisputeDialog(order, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE2F8E3),
                      foregroundColor: Color(0xFF04AD01),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  void _navigateToDetailScreen(dynamic request, int index) {
    try {
      if (request?.category == null) {
        _showErrorSnackBar("Cannot open request details: Invalid request data");
        return;
      }

      switch (request.category) {
        case "VEHICLE_SPARES":
        case "Vehicle Spares":
          // Convert ProductRequestItem to AutoSparesRequest if needed
          dynamic autoSpareData;
          if (request.runtimeType.toString().contains('ProductRequestItem')) {
            autoSpareData = request.toAutoSparesRequest().autoSpares;
          } else {
            autoSpareData = request.autoSpares ?? request.autoSpare;
          }

          SparesDetailScreen.showAsDialog(
            context,
            index: index,
            request: request,
            autoSpare: autoSpareData,
            bids: request.sellerOffers ?? request.quotes ?? [],
          );
          break;

        case "TYRES_RIMS":
        case "Vehicle Tyres and Rims":
          RimTyreDetailScreen.showAsDialog(
            context,
            index: index,
            request: request,
            rimTyre: request.rimTyre,
            bids: request.sellerOffers ?? [],
          );
          break;

        case "ELECTRONICS":
        case "Consumer Electronics":
          ConsumerElectronicsDetailScreen.showAsDialog(
            context,
            index: index,
            request: request,
            consumerElectronics: request.consumerElectronics,
            bids: request.sellerOffers ?? [],
          );
          break;

        default:
          _showErrorSnackBar("Unknown request category: ${request.category}");
      }
    } catch (e) {
      print('Navigation error: $e');
      _showErrorSnackBar("Error opening request details");
    }
  }

  void _showRequestInfoDialog(
    BuildContext context,
    Map<String, dynamic> request,
  ) {
    print("request data2: $request");
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
    final productImages = request['product_images'] ?? [];
    final vinPhotoUrl = request['vin_photo_url']?.toString() ?? '';
    final quantity = request['quantity']?.toString() ?? '';
    final conditionPreference =
        request['condition_preference']?.toString() ?? '';
    final productSpecifications = request['product_specifications'] ?? {};
    final vehicleSparesData = request['vehicle_spares_data'] ?? {};
    final electronicsData = request['consumer_electronics_data'] ?? {};
    final tyresRimsData = request['vehicle_tyres_rims_data'] ?? {};

    // Combine all image sources
    final allImages = <String>[];
    if (productImages is List) {
      allImages.addAll(
        productImages
            .map((img) => img.toString())
            .where((img) => img.isNotEmpty),
      );
    }
    if (images is List) {
      allImages.addAll(
        images.map((img) => img.toString()).where((img) => img.isNotEmpty),
      );
    }
    if (vinPhotoUrl.isNotEmpty) {
      allImages.add(vinPhotoUrl);
    }

    // Format the request number for display
    final requestNumber = requestId.substring(0, 6).toUpperCase();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
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
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Request #$requestNumber - Images',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey[600]),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // Images content
                Expanded(
                  child: allImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No images available',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: EdgeInsets.all(20),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1,
                                ),
                            itemCount: allImages.length,
                            itemBuilder: (context, index) {
                              final imageUrl = allImages[index];
                              final fullImageUrl = _getFullImageUrl(imageUrl);

                              return InkWell(
                                onTap: () {
                                  // Show full-screen image viewer
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.black,
                                      insetPadding: EdgeInsets.zero,
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: InteractiveViewer(
                                              child: Image.network(
                                                fullImageUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        color: Colors.grey[900],
                                                        child: Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors
                                                                .grey[600],
                                                            size: 48,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 40,
                                            right: 20,
                                            child: IconButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              icon: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                              ),
                                              iconSize: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    color: Colors.grey[100],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.network(
                                      fullImageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                                color: Constants.ftaColorLight,
                                              ),
                                            );
                                          },
                                      errorBuilder: (context, error, stackTrace) {
                                        print(
                                          'Image error for URL: $fullImageUrl',
                                        );
                                        print('Error: $error');
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.grey[400],
                                              size: 32,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
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

  // Helper method to safely parse values to double
  double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Build approved bids content - shows paid orders belonging to this seller
  Widget _buildApprovedBidsContent() {
    print('Building approved bids content');

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
              'Error loading approved bids',
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

    // Filter paid orders for this seller and transform to match lead card format
    final List<Map<String, dynamic>> approvedBids = sellerOrders
        .where((order) {
          return (order['status'] == 'PAID' ||
                  order['status'] == 'Payment Confirmed') &&
              order['seller_id'] == Constants.myUid;
        })
        .map(
          (order) => {
            'request_id': order['order_id']?.toString() ?? 'N/A',
            'title': order['product_name'] ?? order['productName'] ?? 'Order',
            'description':
                order['seller_notes'] ?? 'No additional notes provided',
            'created_at':
                order['created_at'] ??
                order['orderDate'] ??
                DateTime.now().toIso8601String(),
            'status': 'APPROVED', // Show as approved status
            'urgency_timeline': 'Delivery Required',
            'category': 'ORDER',
            'vehicle_spares_summary': '',
            'tyres_rims_summary': '',
            'consumer_electronics_summary': '',
            'total_amount':
                order['total_amount']?.toString() ??
                order['amount']?.toString() ??
                '0',
            'currency': order['currency'] ?? 'ZAR',
            'delivery_address': order['delivery_address'] ?? 'Not provided',
            'orderNumber':
                order['order_number'] ?? order['orderNumber'] ?? 'N/A',
            'buyerName':
                order['buyer_name'] ?? order['buyerName'] ?? 'Unknown Buyer',
            'order': order, // Keep full order data for API calls
          },
        )
        .toList();

    print('Filtered approved bids: ${approvedBids.length}');

    // Show empty state if no approved bids
    if (approvedBids.isEmpty) {
      return _buildEmptyApprovedBids();
    }

    // Calculate pagination (same as My Bids)
    final totalPages = (approvedBids.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;
    final paginatedBids = approvedBids.sublist(
      startIndex,
      endIndex > approvedBids.length ? approvedBids.length : endIndex,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 items per row with intrinsic height (same layout as My Bids)
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - 32) /
                3; // 3 items per row with 16px spacing
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paginatedBids.asMap().entries.map((entry) {
                final index = entry.key;
                final bid = entry.value;
                final globalIndex = startIndex + index + 1;
                // Use a unique key based on bid ID for proper widget tracking
                final uniqueKey =
                    bid['id']?.toString() ??
                    bid['order_id']?.toString() ??
                    '${bid['amount']}_${bid['created_at']}_$globalIndex';

                return IntrinsicHeight(
                  key: ValueKey(uniqueKey),
                  child: SizedBox(
                    width: itemWidth,
                    child: _buildApprovedBidCard(bid),
                  ),
                );
              }).toList(),
            );
          },
        ),
        SizedBox(height: 16),
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages, approvedBids.length),
      ],
    );
  }

  // Build empty state for approved bids
  Widget _buildEmptyApprovedBids() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
          SizedBox(height: 20),
          Text(
            'No Approved Bids',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Paid orders waiting for confirmation will appear here',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
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
        // 3 items per row with intrinsic height
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - 32) /
                3; // 3 items per row with 16px spacing
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paginatedBids.asMap().entries.map((entry) {
                final index = entry.key;
                final bid = entry.value;
                final globalIndex = startIndex + index + 1;
                // Use a unique key based on bid ID for proper widget tracking
                final uniqueKey =
                    bid['id']?.toString() ??
                    bid['order_id']?.toString() ??
                    '${bid['amount']}_${bid['created_at']}_$globalIndex';

                return IntrinsicHeight(
                  key: ValueKey(uniqueKey),
                  child: SizedBox(
                    width: itemWidth,
                    child: _buildPaidBidCard(bid),
                  ),
                );
              }).toList(),
            );
          },
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
        // 3 items per row with intrinsic height
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth =
                (constraints.maxWidth - 32) /
                3; // 3 items per row with 16px spacing
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: paginatedBids.asMap().entries.map((entry) {
                final index = entry.key;
                final bid = entry.value;
                final globalIndex = startIndex + index + 1;
                // Use a unique key based on bid ID for proper widget tracking
                final uniqueKey =
                    bid['id']?.toString() ??
                    bid['order_id']?.toString() ??
                    '${bid['amount']}_${bid['created_at']}_$globalIndex';

                return IntrinsicHeight(
                  key: ValueKey(uniqueKey),
                  child: SizedBox(
                    width: itemWidth,
                    child: _buildCompletedBidCard(bid),
                  ),
                );
              }).toList(),
            );
          },
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
  Widget _buildApprovedBidCard(Map<String, dynamic> bid) {
    final requestId = bid['request_id'] ?? '';
    // Use request description method to get proper product name from request details
    final title = bid['request_details'] != null
        ? _getRequestDescription2(bid)
        : (bid['title'] ?? 'Product Request');
    final createdAt = bid['created_at'] ?? '';
    final totalAmount = bid['total_amount'] ?? '0';
    final currency = bid['currency'] ?? 'ZAR';
    // For bids/quotes, we don't have direct buyer info, so use a generic name for now
    final buyerName = 'Buyer';
    final orderStatus =
        bid['order']?['status']?.toString().toUpperCase() ?? 'APPROVED';

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
                      color: const Color(0xFFF5A623),
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
                      strokeWidth: 1.5,
                      color: Constants.ftaColorLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF5A623),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeElapsedText,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFFF5A623),
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
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Approved',
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
                  onPressed: orderStatus == 'PURCHASED'
                      ? null
                      : () => _showPinConfirmationDialog({
                          'orderNumber': bid['orderNumber'] ?? 'Unknown',
                          'productName': bid['title'] ?? 'Unknown Product',
                          'amount': (bid['total_amount'] ?? 0.0) is String
                              ? double.tryParse(
                                      bid['total_amount'].toString(),
                                    ) ??
                                    0.0
                              : (bid['total_amount'] ?? 0.0).toDouble(),
                        }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orderStatus == 'PURCHASED'
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE8F5E9),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (orderStatus == 'PURCHASED')
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                      if (orderStatus == 'PURCHASED') const SizedBox(width: 6),
                      Text(
                        orderStatus == 'PURCHASED'
                            ? 'Completed'
                            : 'Confirm Delivery',
                        style: GoogleFonts.manrope(
                          color: orderStatus == 'PURCHASED'
                              ? Colors.white
                              : Colors.green[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showApprovedBidDetails(bid),
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
          const SizedBox(height: 16),
          // Bottom Links
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => _showApprovedBidDetails(bid),
                child: Text(
                  'Full Details',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFFF5A623),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Icon(
                  CupertinoIcons.lock_fill,
                  color:
                      Constants.ctaColorLight ??
                      Colors.orange, // Null safety fix
                  size: 60,
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Confirm Delivery !',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2B3A5C),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  'By confirming this delivery, you acknowledge that the goods have been successfully handed over to the buyer.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600] ?? Colors.grey,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Unique Identifier Text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Enter the ',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey[600] ?? Colors.grey,
                        ),
                      ),
                      TextSpan(
                        text: '4-digit PIN',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF2B3A5C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' provided by the buyer to confirm delivery',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
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
                      width: 60,
                      height: 60,
                      margin: EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: pinControllers[index],
                        focusNode: focusNodes[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2B3A5C),
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(360),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Delivery',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

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
        builder: (context) => Center(
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
            SellerSparesDetailScreen.showAsDialog(
              context,
              request: requestData,
              bidData: bidData,
              type: type,
            );
            break;
          case "TYRES_RIMS":
          case "Vehicle Tyres and Rims":
            SellerRimTyreDetailScreen.showAsDialog(
              context,
              request: requestData,
              bidData: bidData,
              type: type,
            );
            break;
          case "ELECTRONICS":
          case "Consumer Electronics":
            SellerConsumerElectronicsDetailScreen.showAsDialog(
              context,
              request: requestData,
              bidData: bidData,
              type: type,
            );
            break;
          default:
            // Fallback to generic detail screen
            SellerSparesDetailScreen.showAsDialog(
              context,
              request: requestData,
              bidData: bidData,
              type: type,
            );
        }
      } else {
        print('Failed to load bid details');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      print('Error loading bid details: $e');
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

  void _showApproveDisputeDialog(dynamic order, BuildContext context) {
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
  }

  void _showDeclineDisputeDialog(dynamic order, BuildContext context) {
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
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope()),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
      ),
    );
  }
}

// Seller Spares Detail Screen
class SellerSparesDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final Map<String, dynamic> bidData;
  final String type;

  const SellerSparesDetailScreen({
    Key? key,
    required this.request,
    required this.bidData,
    required this.type,
  }) : super(key: key);

  @override
  State<SellerSparesDetailScreen> createState() =>
      _SellerSparesDetailScreenState();

  static void showAsDialog(
    BuildContext context, {
    required Map<String, dynamic> request,
    required Map<String, dynamic> bidData,
    required String type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.9,
            child: SellerSparesDetailScreen(
              request: request,
              bidData: bidData,
              type: type,
            ),
          ),
        );
      },
    );
  }
}

class _SellerSparesDetailScreenState extends State<SellerSparesDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final autoSpare =
        widget.request['auto_spares'] ?? widget.request['autoSpares'];
    final vehicle = autoSpare?['vehicle'] ?? {};

    return Container(
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
              color: Constants.ctaColorLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_getTypeTitle()} Details',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Details Section
                  _buildSection('Vehicle Details', [
                    _buildDetailRow('Make', vehicle['make'] ?? 'N/A'),
                    _buildDetailRow('Model', vehicle['model'] ?? 'N/A'),
                    _buildDetailRow(
                      'Year',
                      vehicle['year']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Engine Size',
                      '${vehicle['engine_size'] ?? 'N/A'}L',
                    ),
                    _buildDetailRow('Fuel Type', vehicle['fuel_type'] ?? 'N/A'),
                  ]),

                  SizedBox(height: 20),

                  // Part Details Section
                  _buildSection('Part Details', [
                    _buildDetailRow(
                      'Part Name',
                      autoSpare?['part_name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Part Number',
                      autoSpare?['part_number'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Condition',
                      autoSpare?['condition'] ?? 'N/A',
                    ),
                    _buildDetailRow('Brand', autoSpare?['brand'] ?? 'N/A'),
                  ]),

                  SizedBox(height: 20),

                  // Bid Information Section
                  _buildSection('Bid Information', [
                    _buildDetailRow(
                      'Your Bid Amount',
                      '${widget.bidData['currency'] ?? 'ZAR'} ${widget.bidData['total_amount'] ?? widget.bidData['amount'] ?? '0'}',
                    ),
                    _buildDetailRow('Status', _getStatusText()),
                    _buildDetailRow(
                      'Buyer',
                      widget.bidData['buyer_name'] ??
                          widget.bidData['buyerName'] ??
                          'Unknown',
                    ),
                    _buildDetailRow(
                      'Order Date',
                      _formatDate(
                        widget.bidData['created_at'] ?? widget.bidData['date'],
                      ),
                    ),
                  ]),

                  // Images Section
                  if (_getImages().isNotEmpty) ...[
                    SizedBox(height: 20),
                    _buildSection('Images', [
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _getImages().length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _getFullImageUrl(_getImages()[index]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeTitle() {
    switch (widget.type) {
      case 'paid':
        return 'Paid Bid';
      case 'completed':
        return 'Completed Bid';
      case 'approved':
        return 'Approved Bid';
      default:
        return 'Bid';
    }
  }

  String _getStatusText() {
    switch (widget.type) {
      case 'paid':
        return 'Paid - Awaiting Delivery Confirmation';
      case 'completed':
        return 'Completed and Delivered';
      case 'approved':
        return 'Approved';
      default:
        return widget.bidData['status'] ?? 'N/A';
    }
  }

  List<String> _getImages() {
    final List<String> allImages = [];

    // Get images from auto_spares/autoSpares
    final autoSpare =
        widget.request['auto_spares'] ?? widget.request['autoSpares'];
    if (autoSpare?['images'] != null) {
      allImages.addAll(List<String>.from(autoSpare['images']));
    }

    // Get product images
    if (widget.request['product_images'] != null) {
      allImages.addAll(List<String>.from(widget.request['product_images']));
    }

    // Get other images
    if (widget.request['images'] != null) {
      allImages.addAll(List<String>.from(widget.request['images']));
    }

    // Get VIN images
    if (widget.request['vin_images'] != null) {
      allImages.addAll(List<String>.from(widget.request['vin_images']));
    }

    return allImages;
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Constants.ctaColorLight,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Seller Rim Tyre Detail Screen
class SellerRimTyreDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final Map<String, dynamic> bidData;
  final String type;

  const SellerRimTyreDetailScreen({
    Key? key,
    required this.request,
    required this.bidData,
    required this.type,
  }) : super(key: key);

  @override
  State<SellerRimTyreDetailScreen> createState() =>
      _SellerRimTyreDetailScreenState();

  static void showAsDialog(
    BuildContext context, {
    required Map<String, dynamic> request,
    required Map<String, dynamic> bidData,
    required String type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.9,
            child: SellerRimTyreDetailScreen(
              request: request,
              bidData: bidData,
              type: type,
            ),
          ),
        );
      },
    );
  }
}

class _SellerRimTyreDetailScreenState extends State<SellerRimTyreDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final rimTyre = widget.request['rim_tyre'] ?? widget.request['rimTyre'];
    final vehicle = rimTyre?['vehicle'] ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header - similar to SellerSparesDetailScreen
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_getTypeTitle()} Details',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content with rim/tyre specific fields
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Details Section
                  _buildSection('Vehicle Details', [
                    _buildDetailRow('Make', vehicle['make'] ?? 'N/A'),
                    _buildDetailRow('Model', vehicle['model'] ?? 'N/A'),
                    _buildDetailRow(
                      'Year',
                      vehicle['year']?.toString() ?? 'N/A',
                    ),
                  ]),

                  SizedBox(height: 20),

                  // Rim/Tyre Details Section
                  _buildSection('Rim/Tyre Details', [
                    _buildDetailRow('Type', rimTyre?['type'] ?? 'N/A'),
                    _buildDetailRow('Size', rimTyre?['size'] ?? 'N/A'),
                    _buildDetailRow('Brand', rimTyre?['brand'] ?? 'N/A'),
                    _buildDetailRow(
                      'Condition',
                      rimTyre?['condition'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Width',
                      rimTyre?['width']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Profile',
                      rimTyre?['profile']?.toString() ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Diameter',
                      rimTyre?['diameter']?.toString() ?? 'N/A',
                    ),
                  ]),

                  SizedBox(height: 20),

                  // Bid Information Section
                  _buildSection('Bid Information', [
                    _buildDetailRow(
                      'Your Bid Amount',
                      '${widget.bidData['currency'] ?? 'ZAR'} ${widget.bidData['total_amount'] ?? widget.bidData['amount'] ?? '0'}',
                    ),
                    _buildDetailRow('Status', _getStatusText()),
                    _buildDetailRow(
                      'Buyer',
                      widget.bidData['buyer_name'] ??
                          widget.bidData['buyerName'] ??
                          'Unknown',
                    ),
                    _buildDetailRow(
                      'Order Date',
                      _formatDate(
                        widget.bidData['created_at'] ?? widget.bidData['date'],
                      ),
                    ),
                  ]),

                  // Images Section
                  if (_getImages().isNotEmpty) ...[
                    SizedBox(height: 20),
                    _buildSection('Images', [
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _getImages().length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _getFullImageUrl(_getImages()[index]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getImages() {
    final List<String> allImages = [];

    // Get images from rim_tyre/rimTyre
    final rimTyre = widget.request['rim_tyre'] ?? widget.request['rimTyre'];
    if (rimTyre?['images'] != null) {
      allImages.addAll(List<String>.from(rimTyre['images']));
    }

    // Get product images
    if (widget.request['product_images'] != null) {
      allImages.addAll(List<String>.from(widget.request['product_images']));
    }

    // Get other images
    if (widget.request['images'] != null) {
      allImages.addAll(List<String>.from(widget.request['images']));
    }

    // Get VIN images
    if (widget.request['vin_images'] != null) {
      allImages.addAll(List<String>.from(widget.request['vin_images']));
    }

    return allImages;
  }

  String _getFullImageUrl(String imagePath) {
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    // Remove leading slash if present
    final cleanPath = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;
    // Build full URL using the products service URL
    String baseUrl = GlobalVariables.productsServiceUrl;
    return '$baseUrl$cleanPath';
  }

  // Same helper methods as SellerSparesDetailScreen
  String _getTypeTitle() {
    switch (widget.type) {
      case 'paid':
        return 'Paid Bid';
      case 'completed':
        return 'Completed Bid';
      case 'approved':
        return 'Approved Bid';
      default:
        return 'Bid';
    }
  }

  String _getStatusText() {
    switch (widget.type) {
      case 'paid':
        return 'Paid - Awaiting Delivery Confirmation';
      case 'completed':
        return 'Completed and Delivered';
      case 'approved':
        return 'Approved';
      default:
        return widget.bidData['status'] ?? 'N/A';
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Constants.ctaColorLight,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Seller Consumer Electronics Detail Screen
class SellerConsumerElectronicsDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final Map<String, dynamic> bidData;
  final String type;

  const SellerConsumerElectronicsDetailScreen({
    Key? key,
    required this.request,
    required this.bidData,
    required this.type,
  }) : super(key: key);

  @override
  State<SellerConsumerElectronicsDetailScreen> createState() =>
      _SellerConsumerElectronicsDetailScreenState();

  static void showAsDialog(
    BuildContext context, {
    required Map<String, dynamic> request,
    required Map<String, dynamic> bidData,
    required String type,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.9,
            child: SellerConsumerElectronicsDetailScreen(
              request: request,
              bidData: bidData,
              type: type,
            ),
          ),
        );
      },
    );
  }
}

class _SellerConsumerElectronicsDetailScreenState
    extends State<SellerConsumerElectronicsDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final electronics =
        widget.request['consumer_electronics'] ??
        widget.request['consumerElectronics'];

    return Container(
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
              color: Constants.ctaColorLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_getTypeTitle()} Details',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Content with electronics specific fields
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Electronics Details Section
                  _buildSection('Electronics Details', [
                    _buildDetailRow(
                      'Product Name',
                      electronics?['product_name'] ?? 'N/A',
                    ),
                    _buildDetailRow('Brand', electronics?['brand'] ?? 'N/A'),
                    _buildDetailRow('Model', electronics?['model'] ?? 'N/A'),
                    _buildDetailRow(
                      'Category',
                      electronics?['category'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'Condition',
                      electronics?['condition'] ?? 'N/A',
                    ),
                    _buildDetailRow('Color', electronics?['color'] ?? 'N/A'),
                    _buildDetailRow(
                      'Storage',
                      electronics?['storage'] ?? 'N/A',
                    ),
                  ]),

                  SizedBox(height: 20),

                  // Bid Information Section
                  _buildSection('Bid Information', [
                    _buildDetailRow(
                      'Your Bid Amount',
                      '${widget.bidData['currency'] ?? 'ZAR'} ${widget.bidData['total_amount'] ?? widget.bidData['amount'] ?? '0'}',
                    ),
                    _buildDetailRow('Status', _getStatusText()),
                    _buildDetailRow(
                      'Buyer',
                      widget.bidData['buyer_name'] ??
                          widget.bidData['buyerName'] ??
                          'Unknown',
                    ),
                    _buildDetailRow(
                      'Order Date',
                      _formatDate(
                        widget.bidData['created_at'] ?? widget.bidData['date'],
                      ),
                    ),
                  ]),

                  // Images Section
                  if (_getImages().isNotEmpty) ...[
                    SizedBox(height: 20),
                    _buildSection('Images', [
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _getImages().length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _getFullImageUrl(_getImages()[index]),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 120,
                                      height: 120,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getImages() {
    final List<String> allImages = [];

    // Get images from consumer_electronics/consumerElectronics
    final electronics =
        widget.request['consumer_electronics'] ??
        widget.request['consumerElectronics'];
    if (electronics?['images'] != null) {
      allImages.addAll(List<String>.from(electronics['images']));
    }

    // Get product images
    if (widget.request['product_images'] != null) {
      allImages.addAll(List<String>.from(widget.request['product_images']));
    }

    // Get other images
    if (widget.request['images'] != null) {
      allImages.addAll(List<String>.from(widget.request['images']));
    }

    // Get VIN images (if any)
    if (widget.request['vin_images'] != null) {
      allImages.addAll(List<String>.from(widget.request['vin_images']));
    }

    return allImages;
  }

  String _getFullImageUrl(String imagePath) {
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    // Remove leading slash if present
    final cleanPath = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;
    // Build full URL using the products service URL
    String baseUrl = GlobalVariables.productsServiceUrl;
    return '$baseUrl$cleanPath';
  }

  // Same helper methods as other detail screens
  String _getTypeTitle() {
    switch (widget.type) {
      case 'paid':
        return 'Paid Bid';
      case 'completed':
        return 'Completed Bid';
      case 'approved':
        return 'Approved Bid';
      default:
        return 'Bid';
    }
  }

  String _getStatusText() {
    switch (widget.type) {
      case 'paid':
        return 'Paid - Awaiting Delivery Confirmation';
      case 'completed':
        return 'Completed and Delivered';
      case 'approved':
        return 'Approved';
      default:
        return widget.bidData['status'] ?? 'N/A';
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Constants.ctaColorLight,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
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

String _extractBuyerName(dynamic order) {
  // Try to get buyer name from the request data
  if (order['request_info'] != null &&
      order['request_info']['buyer_info'] != null) {
    final buyerInfo = order['request_info']['buyer_info'];
    final firstName = buyerInfo['first_name'] ?? '';
    final lastName = buyerInfo['last_name'] ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
  }
  return 'Buyer #${order['buyer_id']?.toString().substring(0, 8) ?? 'Unknown'}';
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

String _getFullImageUrl(String imagePath) {
  // If it's already a full URL, return as is
  if (imagePath.startsWith('http')) {
    return imagePath;
  }
  // Remove leading slash if present
  final cleanPath = imagePath.startsWith('/')
      ? imagePath.substring(1)
      : imagePath;
  // Build full URL using the products service URL
  String baseUrl = GlobalVariables.productsServiceUrl;
  return '$baseUrl$cleanPath';
}
