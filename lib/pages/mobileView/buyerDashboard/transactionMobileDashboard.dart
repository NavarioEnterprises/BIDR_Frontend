import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gradient_glow_border/gradient_glow_border.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/environment_config.dart';
import '../../../customWdget/custom_input2.dart';
import '../../../models/order.dart';
import '../../../models/product_request_api.dart';
import '../../../models/request_models.dart';
import '../../../models/review_item.dart';
import '../../../services/chat_service.dart';
import '../../../services/products_management_api_service.dart';
import '../../../services/rewards_service.dart';
import '../breakpoints.dart';
import '../../buyer_dashboard.dart';
import '../../group_chat.dart';

class TransactionMobileDashboard extends StatefulWidget {
  const TransactionMobileDashboard({Key? key}) : super(key: key);

  @override
  _TransactionMobileDashboardState createState() =>
      _TransactionMobileDashboardState();
}

class _TransactionMobileDashboardState extends State<TransactionMobileDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedTab = 0;
  int _selectedTopTab = 1; // 0 for Request, 1 for Order

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
      // Reload orders whenever tab changes within the Order section
      if (_selectedTopTab == 1) {
        _loadOrdersFromAPI();
      }
    });

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0.1, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadReviewsConditionally();

    // Load orders when Order tab is initialized
    if (_selectedTopTab == 1) {
      _loadOrdersFromAPI();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _returnReasonController.dispose();
    _returnDescriptionController.dispose();
    super.dispose();
  }

  // Order data - loaded from API
  List<Order> onGoingOrders = [];
  List<Order> purchasedOrders = [];
  List<Order> returnsRefundsOrders = [];
  List<Order> cancelledOrders = [];

  bool _isLoadingOrders = false;
  String? _orderLoadingError;
  FocusNode _commentFocusNode = FocusNode();

  // API service method to fetch orders
  Future<void> _loadOrdersFromAPI() async {
    setState(() {
      _isLoadingOrders = true;
      _orderLoadingError = null;
    });

    try {
      // Use the correct API endpoint for orders from product-requests
      final response = await http.get(
        Uri.parse(
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/orders/',
        ).replace(queryParameters: {'buyer_id': Constants.currentUser!.uid}),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('API Response: ${response.body}'); // Debug log
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

        print('Orders data count: ${ordersData.length}'); // Debug log

        // Parse orders and categorize by status
        List<Order> allOrders = [];
        for (var orderJson in ordersData) {
          try {
            print('Processing order: $orderJson'); // Debug log
            allOrders.add(Order.fromJson(orderJson));
          } catch (e, stackTrace) {
            // More detailed error logging with both error and stack trace
            print(
              'Error parsing order: $e\nStack: $stackTrace\nData: $orderJson',
            );
            // Continue processing other orders
          }
        }

        // Extract reviews from orders if they contain review data
        List<ReviewItem> apiReviews = [];
        for (var order in allOrders) {
          // Check if order has review data (assuming orders might have review information)
          if (order.comments.isNotEmpty) {
            for (var comment in order.comments) {
              // Convert order comments to reviews if they have rating-like structure
              apiReviews.add(
                ReviewItem(
                  uuid:
                      Constants.currentUser != null &&
                          Constants.currentUser!.uid.isNotEmpty
                      ? Constants.currentUser!.uid
                      : DateTime.now().millisecondsSinceEpoch.toString(),
                  customerName: Constants.myDisplayname,
                  description: comment.description,
                  rating: order.rating.toInt(), // Use order rating
                  comment: comment.description,
                  createdAt: _formatDate(order.dateTime),
                  type: 'review',
                ),
              );
            }
          }
        }

        // Categorize orders by status
        setState(() {
          onGoingOrders = allOrders
              .where(
                (order) =>
                    order.status.toLowerCase().contains('ongoing') ||
                    order.status.toLowerCase().contains('pending') ||
                    order.status.toLowerCase().contains('paid') ||
                    order.status.toLowerCase().contains('payment confirmed') ||
                    order.status.toLowerCase().contains('processing') ||
                    order.status.toLowerCase().contains('shipped') ||
                    order.status.toLowerCase().contains('completed'),
              )
              .toList();
          purchasedOrders = allOrders
              .where(
                (order) =>
                    order.status.toLowerCase().contains('purchased') ||
                    order.status.toLowerCase().contains('delivered'),
              )
              .toList();
          returnsRefundsOrders = allOrders
              .where((order) => order.status.toLowerCase().contains('refund'))
              .toList();
          cancelledOrders = allOrders
              .where((order) => order.status.toLowerCase().contains('cancel'))
              .toList();

          // Update reviews from API data if available
          if (apiReviews.isNotEmpty) {
            reviews = apiReviews;
            totalReviews = reviews.length;
          }

          _isLoadingOrders = false;
        });

        print(
          'Categorized orders - Ongoing: ${onGoingOrders.length}, Purchased: ${purchasedOrders.length}, Refunds: ${returnsRefundsOrders.length}, Cancelled: ${cancelledOrders.length}',
        );
      } else {
        throw Exception(
          'Failed to load orders: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingOrders = false;
        _orderLoadingError = 'Error loading orders: ${e.toString()}';
      });
      print('Error fetching orders: $e');
    }
  }

  // Public method that can be called from parent widget
  void loadOrdersFromAPI() {
    _loadOrdersFromAPI();
  }

  TextEditingController _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _currentRating = 0.0;
  List<ReviewItem> reviews = [];
  int totalReviews = 0;

  // Save reviews to local storage
  Future<void> _saveReviewsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJson = reviews.map((review) => review.toJson()).toList();
      await prefs.setString('reviews_list', json.encode(reviewsJson));
      await prefs.setInt('total_reviews', totalReviews);
    } catch (e) {
      print('Error saving reviews locally: $e');
    }
  }

  // Load reviews from local storage
  Future<void> _loadReviewsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reviewsJsonString = prefs.getString('reviews_list');
      totalReviews = prefs.getInt('total_reviews') ?? 0;

      if (reviewsJsonString != null) {
        final reviewsJsonList = json.decode(reviewsJsonString) as List;
        reviews = reviewsJsonList
            .map((json) => ReviewItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading reviews locally: $e');
    }
  }

  // Add a new review to the list
  Future<void> _addReviewLocally(ReviewItem review) async {
    reviews.add(review);
    totalReviews = reviews.length;
    await _saveReviewsLocally();
  }

  // Calculate average rating from all reviews
  double _getAverageRating() {
    if (reviews.isEmpty) return 0.0;
    double sum = reviews.fold(0.0, (sum, review) => sum + review.rating);
    return sum / reviews.length;
  }

  // Load reviews conditionally - only from local storage if reviews list is empty
  Future<void> _loadReviewsConditionally() async {
    if (reviews.isEmpty) {
      await _loadReviewsLocally();
    }
    // If reviews is not empty, keep existing reviews (could be from API or other sources)
  }

  // Order Details Dialog
  void _showOrderDetailsDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Constants.ctaColorLight,
                        size: 18,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            "Order #${order.orderNumber}",
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 22,
                      ),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and Date Row
                        Container(
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: order.status == "Refunded"
                                          ? Colors.blue.shade600
                                          : order.status == "Cancelled"
                                          ? Colors.red.shade600
                                          : order.status == "Pending Payment"
                                          ? Colors.orange.shade600
                                          : order.status == "Delivered"
                                          ? Colors.green.shade600
                                          : Constants.ctaColorLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      order.status.toUpperCase(),
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      DateFormat(
                                        'dd/MM/yyyy - HH:mm',
                                      ).format(order.dateTime),
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        // Vendor Information Section
                        _buildDetailSection("Vendor Information", [
                          _buildDetailItem("Vendor Name", order.vendorName),
                          _buildDetailItem("Rating", "${order.rating}/5"),
                          _buildDetailItem("Location", order.location),
                          _buildDetailItem(
                            "Distance",
                            "${order.distanceInKm.toInt()} KM",
                          ),
                        ]),

                        SizedBox(height: 16),

                        // Product Information Section
                        _buildDetailSection("Product Information", [
                          _buildDetailItem("Product", order.product),
                          _buildDetailItem("Vehicle", order.vehicle),
                        ]),

                        SizedBox(height: 16),

                        // Pricing Information Section
                        _buildDetailSection("Pricing Information", [
                          _buildDetailItem(
                            "Total Amount",
                            "R${order.price.toStringAsFixed(2)}",
                            isHighlighted: true,
                          ),
                        ]),

                        SizedBox(height: 16),

                        // Comments Section - show order comments or local reviews
                        if (order.comments.isNotEmpty) ...[
                          _buildDetailSection(
                            "Comments",
                            order.comments
                                .map(
                                  (comment) =>
                                      _buildCommentItem(comment.description),
                                )
                                .toList(),
                          ),
                        ] else if (reviews.isNotEmpty) ...[
                          _buildDetailSection(
                            "Reviews",
                            reviews
                                .map(
                                  (review) => _buildCommentItem(
                                    "${review.comment} (Rating: ${review.rating}/5)",
                                  ),
                                )
                                .toList(),
                          ),
                        ],

                        SizedBox(height: 24),

                        // Action Buttons
                        if (order.status.toLowerCase() ==
                            "Pending Payment".toLowerCase()) ...[
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showCollectGoodsDialog(order),
                                  icon: Icon(
                                    CupertinoIcons.cube_box,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "Collect Goods",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Constants.ctaColorLight,
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Handle chat action
                                  },
                                  icon: Icon(
                                    CupertinoIcons.chat_bubble_2,
                                    size: 16,
                                    color: Constants.ctaColorLight,
                                  ),
                                  label: Text(
                                    "Chat",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.ctaColorLight,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(
                                      color: Constants.ctaColorLight,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (order.status.toLowerCase() ==
                            "Delivered".toLowerCase()) ...[
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _showAddReviewDialog(order);
                                  },
                                  icon: Icon(
                                    Icons.star_outline,
                                    size: 16,
                                    color: Constants.ctaColorLight,
                                  ),
                                  label: Text(
                                    "Write Review",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Constants.ctaColorLight,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    side: BorderSide(
                                      color: Constants.ctaColorLight,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showReturnAndRefundDialog(order);
                                  },
                                  icon: Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    "Return & Refund",
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    padding: EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                "Close",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
      },
    );
  }

  void _showAllReviewsDialog(Order order) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Reviews',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Order info
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag,
                        color: Constants.ctaColorLight,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${order.product} - Order #${order.orderNumber}',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Rating summary
                Row(
                  children: [
                    Icon(Icons.star, color: Constants.ctaColorLight, size: 24),
                    SizedBox(width: 4),
                    Text(
                      _getAverageRating().toStringAsFixed(1),
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '($totalReviews reviews)',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // Reviews list
                Expanded(
                  child: reviews.isEmpty
                      ? Center(
                          child: Text(
                            'No reviews yet',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: reviews.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 24),
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            return Container(
                              padding: EdgeInsets.all(16),
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
                                      CircleAvatar(
                                        backgroundColor:
                                            Constants.ctaColorLight,
                                        radius: 16,
                                        child: Text(
                                          review.customerName.isNotEmpty
                                              ? review.customerName[0]
                                                    .toUpperCase()
                                              : 'A',
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.customerName.isNotEmpty
                                                  ? review.customerName
                                                  : 'Anonymous',
                                              style: GoogleFonts.manrope(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                ...List.generate(
                                                  5,
                                                  (starIndex) => Icon(
                                                    Icons.star,
                                                    size: 14,
                                                    color:
                                                        starIndex <
                                                            review.rating
                                                        ? Constants
                                                              .ctaColorLight
                                                        : Colors.grey[300],
                                                  ),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  '${review.rating}/5',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _formatDate(
                                          DateTime.tryParse(review.createdAt) ??
                                              DateTime.now(),
                                        ),
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    review.comment,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 16),
                // Add review button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddReviewDialog(order);
                    },
                    icon: Icon(Icons.add_comment, size: 18),
                    label: Text('Add Your Review'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Constants.ctaColorLight),
                      foregroundColor: Constants.ctaColorLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

  void _submitReturnRequest(dynamic order) async {
    try {
      // First, find the order by order_number to get its ID
      final findOrderResponse = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?order_number=${order.orderNumber}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (findOrderResponse.statusCode != 200) {
        throw Exception(
          'Failed to find order: ${findOrderResponse.statusCode} - ${findOrderResponse.body}',
        );
      }

      final findOrderData = json.decode(findOrderResponse.body);
      if (findOrderData['results'] == null ||
          findOrderData['results'].isEmpty) {
        throw Exception('Order not found in results');
      }

      final String orderId = findOrderData['results'][0]['order_id'].toString();

      // Now make API call to update order status using the correct endpoint
      final response = await http.post(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/$orderId/update_status/',
        ),
        headers: {
          'Content-Type': 'application/json',
          // Add authentication headers if needed
        },
        body: json.encode({
          'status': 'REFUND_REQUESTED',
          'user_id': Constants.currentUser!.uid,
          'return_reason': _selectedReturnReason,
          'return_description': _returnDescriptionController.text,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - update local order list
        setState(() {
          // Find and update the order in the appropriate list
          for (var list in [onGoingOrders, purchasedOrders]) {
            final index = list.indexWhere(
              (o) => o.orderNumber == order.orderNumber,
            );
            if (index != -1) {
              list.removeAt(index);
              // Create updated order with new status
              final updatedOrder = Order(
                vendorName: order.vendorName,
                product: order.product,
                productId: order.productId,
                sellerId: order.sellerId,
                requestId: order.requestId,
                vehicle: order.vehicle,
                orderNumber: order.orderNumber,
                status: 'REFUND_REQUESTED',
                dateTime: order.dateTime,
                price: order.price,
                rating: order.rating,
                distanceInKm: order.distanceInKm,
                location: order.location,
                comments: order.comments,
              );
              returnsRefundsOrders.add(updatedOrder);
              break;
            }
          }
        });

        // Show success message with MotionToast
        MotionToast.success(
          title: Text(
            'Success!',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          description: Text(
            'Return request submitted successfully. We will contact you within 24 hours.',
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
        // Show error message
        MotionToast.error(
          title: Text(
            'Error',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          description: Text(
            'Failed to submit return request. Please try again.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          width: 350,
          height: 80,
          toastDuration: const Duration(seconds: 3),
        ).show(context);
      }
    } catch (e) {
      print('Error submitting return request: $e');
      // Show error message
      MotionToast.error(
        title: Text(
          'Error',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        description: Text(
          'Failed to submit return request. Please try again.',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        width: 350,
        height: 80,
        toastDuration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  void _showCancelOrderDialog(dynamic order) {
    bool _acceptedTerms = false;
    final TextEditingController _cancelReasonController =
        TextEditingController();
    String _selectedCancelReason = '';

    final List<String> _cancelReasons = [
      'Changed my mind',
      'Found a better deal elsewhere',
      'No longer need the item',
      'Order was placed by mistake',
      'Seller not responsive',
      'Delivery taking too long',
      'Personal financial reasons',
      'Other',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                padding: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cancel Order',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Constants.ftaColorLight,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              size: 22,
                              color: Colors.grey[600],
                            ),
                            constraints: BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),

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
                              'Order #${order.orderNumber}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${order.product} - ${order.vehicle}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18),

                      // Cancellation reason dropdown
                      Text(
                        'Reason for Cancellation *',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Constants.ftaColorLight,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCancelReason.isEmpty
                                ? null
                                : _selectedCancelReason,
                            hint: Text(
                              'Select a reason',
                              style: GoogleFonts.manrope(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                            isExpanded: true,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            items: _cancelReasons.map((reason) {
                              return DropdownMenuItem(
                                value: reason,
                                child: Text(
                                  reason,
                                  style: GoogleFonts.manrope(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCancelReason = value ?? '';
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 14),

                      // Additional details
                      Text(
                        'Additional Details (Optional)',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Constants.ftaColorLight,
                        ),
                      ),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: _cancelReasonController,
                        maxLines: 3,
                        style: GoogleFonts.manrope(fontSize: 13),
                        decoration: InputDecoration(
                          hintText:
                              'Please provide additional details about your cancellation...',
                          hintStyle: GoogleFonts.manrope(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
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
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      SizedBox(height: 18),

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
                              'Cancellation Terms & Conditions',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              '• A cancellation fee of 10% of the order value may apply\n'
                              '• Refund will be processed within 3-5 business days\n'
                              '• Seller will be notified of the cancellation\n'
                              '• This action cannot be undone once confirmed',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: Colors.red[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),

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
                              'I understand and accept the cancellation terms and conditions',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),

                      // Action buttons - Mobile friendly layout
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (_selectedCancelReason.isNotEmpty &&
                                      _acceptedTerms)
                                  ? () {
                                      _submitCancelRequest(
                                        order,
                                        _selectedCancelReason,
                                        _cancelReasonController.text.trim(),
                                      );
                                      Navigator.of(context).pop();
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (_selectedCancelReason.isNotEmpty &&
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
                                'Cancel Order',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
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
                                'Keep Order',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
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
      },
    );
  }

  void _submitCancelRequest(
    dynamic order,
    String reason,
    String description,
  ) async {
    try {
      // First, find the order by order_number to get its ID
      final findOrderResponse = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?order_number=${order.orderNumber}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (findOrderResponse.statusCode != 200) {
        throw Exception(
          'Failed to find order: ${findOrderResponse.statusCode}',
        );
      }

      final findOrderData = json.decode(findOrderResponse.body);
      if (findOrderData['results'] == null ||
          findOrderData['results'].isEmpty) {
        throw Exception('Order not found');
      }

      final String orderId = findOrderData['results'][0]['order_id'].toString();

      // Now make API call to update order status to CANCELLED
      final response = await http.post(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/$orderId/update_status/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'status': 'CANCELLED',
          'user_id': Constants.currentUser!.uid,
          'reason': reason,
          'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - update local order list
        setState(() {
          // Find and remove the order from ongoing orders
          final index = onGoingOrders.indexWhere(
            (o) => o.orderNumber == order.orderNumber,
          );
          if (index != -1) {
            onGoingOrders.removeAt(index);
            // Create updated order with CANCELLED status
            final cancelledOrder = Order(
              vendorName: order.vendorName,
              product: order.product,
              productId: order.productId,
              sellerId: order.sellerId,
              requestId: order.requestId,
              vehicle: order.vehicle,
              orderNumber: order.orderNumber,
              status: 'CANCELLED',
              dateTime: order.dateTime,
              price: order.price,
              rating: order.rating,
              distanceInKm: order.distanceInKm,
              location: order.location,
              comments: order.comments,
            );
            cancelledOrders.add(cancelledOrder);
          }
        });

        // Show success message
        MotionToast.success(
          title: Text(
            'Order Cancelled',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          description: Text(
            'Your order has been successfully cancelled. Refund will be processed within 3-5 business days.',
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
        // Show error message
        MotionToast.error(
          title: Text(
            'Error',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          description: Text(
            'Failed to cancel order. Please try again.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          width: 350,
          height: 80,
          toastDuration: const Duration(seconds: 3),
        ).show(context);
      }
    } catch (e) {
      print('Error cancelling order: $e');
      // Show error message
      MotionToast.error(
        title: Text(
          'Error',
          style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        description: Text(
          'Failed to cancel order. Please try again.',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        width: 350,
        height: 80,
        toastDuration: const Duration(seconds: 3),
      ).show(context);
    }
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Constants.ftaColorLight,
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isHighlighted ? Constants.ctaColorLight : Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String comment) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              comment,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
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
  ) {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      maxLines: 5,
      textInputAction: TextInputAction.next,
      isPasswordField: false,
      onChanged: (value) {},
      onSubmitted: (value) {},
    );
  }

  void _showAddReviewDialog(Order order) {
    bool _isSubmitting = false;
    final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();
    final TextEditingController _dialogCommentController =
        TextEditingController();
    double _dialogRating = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isSubmitting
                    ? Container(
                        height: 200,
                        child: Center(
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
                                'Submitting Review...',
                                style: GoogleFonts.manrope(
                                  textStyle: TextStyle(
                                    fontSize: 14,
                                    color: Constants.ftaColorLight.withOpacity(
                                      0.55,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          constraints: BoxConstraints(
                            maxWidth: 500, // Max width for larger screens
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rating & Review',
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
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.black87,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),

                              // Rating Section
                              Center(
                                child: Column(
                                  children: [
                                    RatingBar.builder(
                                      initialRating: _dialogRating,
                                      minRating: 1,
                                      direction: Axis.horizontal,
                                      allowHalfRating: false,
                                      itemCount: 5,
                                      itemSize: 40,
                                      itemPadding: EdgeInsets.symmetric(
                                        horizontal: 4.0,
                                      ),
                                      itemBuilder: (context, _) =>
                                          Icon(Icons.star, color: Colors.amber),
                                      onRatingUpdate: (rating) {
                                        setState(() {
                                          _dialogRating = rating;
                                        });
                                      },
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      _getRatingText(_dialogRating),
                                      style: GoogleFonts.manrope(
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          color: _getRatingColor(_dialogRating),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),

                              // Review Form
                              Form(
                                key: _dialogFormKey,
                                child: TextFormField(
                                  controller: _dialogCommentController,
                                  maxLines: 5,
                                  maxLength: 500,
                                  decoration: InputDecoration(
                                    labelText: 'Your Review',
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    floatingLabelStyle: TextStyle(
                                      color: Constants.ftaColorLight,
                                      fontSize: 14,
                                    ),
                                    hintText:
                                        'Share your experience with this product...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    fillColor: Colors.grey[50],
                                    contentPadding: EdgeInsets.all(16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Constants.ftaColorLight,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.red[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (_dialogRating == 0) {
                                      return 'Please select a rating';
                                    }
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your review';
                                    } else if (value.trim().length < 10) {
                                      return 'Review must be at least 10 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              // Character count
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ValueListenableBuilder(
                                  valueListenable: _dialogCommentController,
                                  builder: (context, value, child) {
                                    return Text(
                                      '${value.text.length}/500 characters',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 24),

                              // Action buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'CANCEL',
                                      style: GoogleFonts.manrope(
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_dialogFormKey.currentState!
                                              .validate() &&
                                          _dialogRating > 0) {
                                        setState(() {
                                          _isSubmitting = true;
                                        });

                                        try {
                                          // Submit to API
                                          print("gfghhhg ${order.toJson()}");

                                          final result =
                                              await RewardsService.submitReview(
                                                authUserUid:
                                                    Constants.currentUser !=
                                                            null &&
                                                        Constants
                                                            .currentUser!
                                                            .uid
                                                            .isNotEmpty
                                                    ? Constants.currentUser!.uid
                                                    : 'anonymous_${DateTime.now().millisecondsSinceEpoch}',
                                                productId:
                                                    order.productId ?? "",
                                                requestId: order.requestId!,

                                                sellerId: order
                                                    .sellerId!, // Optional seller ID
                                                rating: _dialogRating.toInt(),
                                                content:
                                                    _dialogCommentController
                                                        .text
                                                        .trim(),
                                                customerName:
                                                    Constants
                                                        .myDisplayname
                                                        .isNotEmpty
                                                    ? Constants.myDisplayname
                                                    : 'Anonymous User',
                                              );

                                          if (result['success']) {
                                            // Refresh the reviews list
                                            _loadOrdersFromAPI(); // You'll need to implement this

                                            Navigator.of(context).pop();

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Review submitted successfully!',
                                                ),
                                                backgroundColor:
                                                    Colors.green[700],
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          } else {
                                            throw Exception(result['error']);
                                          }
                                        } catch (e) {
                                          setState(() {
                                            _isSubmitting = false;
                                          });

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to submit review: ${e.toString()}',
                                              ),
                                              backgroundColor: Colors.red[700],
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
                                      } else if (_dialogRating == 0) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Please select a rating',
                                            ),
                                            backgroundColor: Colors.orange[700],
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Constants.ctaColorLight,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'SUBMIT REVIEW',
                                      style: GoogleFonts.manrope(
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
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
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods
  String _getRatingText(double rating) {
    if (rating == 0) return 'Tap to rate';
    if (rating == 1) return 'Poor';
    if (rating == 2) return 'Fair';
    if (rating == 3) return 'Good';
    if (rating == 4) return 'Very Good';
    if (rating == 5) return 'Excellent';
    return '';
  }

  Color _getRatingColor(double rating) {
    if (rating == 0) return Colors.grey;
    if (rating <= 2) return Colors.red;
    if (rating == 3) return Colors.orange;
    if (rating >= 4) return Colors.green;
    return Colors.grey;
  }

  // Method to load reviews from API

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
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
            "Transaction",
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {},
              icon: Icon(HugeIcons.strokeRoundedFilter),
            ),
          ],
        ),
        body: ResponsiveBuilder(
          builder: (context, typography, spacing) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tab Bar (Request/Order)
                ResponsiveContainer(
                  paddingType: SpacingType.small,
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTopTab = 0;
                              _animationController.reset();
                              _animationController.forward();
                            });
                            // Reload orders to ensure fresh data when switching back to Order tab later
                            _loadOrdersFromAPI();
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedTopTab == 0
                                  ? Constants.ctaColorLight.withOpacity(0.05)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTopTab == 0
                                      ? Constants.ctaColorLight
                                      : Colors.transparent,
                                  width: _selectedTopTab == 0 ? 2 : 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: ResponsiveText(
                                text: "Request",
                                type: TextType.medium,
                                fontWeight: _selectedTopTab == 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _selectedTopTab == 0
                                    ? Constants.ctaColorLight
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTopTab = 1;
                              _animationController.reset();
                              _animationController.forward();
                            });
                            // Load orders when Order tab is selected
                            _loadOrdersFromAPI();
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _selectedTopTab == 1
                                  ? Constants.ctaColorLight.withOpacity(0.05)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTopTab == 1
                                      ? Constants.ctaColorLight
                                      : Colors.grey[300]!,
                                  width: _selectedTopTab == 1 ? 2 : 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: ResponsiveText(
                                text: "Order",
                                type: TextType.medium,
                                fontWeight: _selectedTopTab == 1
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: _selectedTopTab == 1
                                    ? Constants.ctaColorLight
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ResponsiveContainer(
                        paddingType: SpacingType.medium,
                        child: _selectedTopTab == 0
                            ? _buildRequestContent(typography, spacing)
                            : SingleChildScrollView(
                                child: Center(
                                  child: _buildContent(typography, spacing),
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return ResponsiveBuilder(
      builder: (context, typography, spacing) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTab = index;
            });
            _loadOrdersFromAPI();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: isSelected
                ? EdgeInsets.only(left: 4, top: 4, right: 4)
                : EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: spacing.paddingSmall,
                  ),
            margin: EdgeInsets.only(left: 8, top: 8, right: 8),
            decoration: BoxDecoration(
              color: Constants.ftaColorLight,

              //borderRadius: BorderRadius.circular(360),
              border: Border(
                bottom: BorderSide(
                  color: isSelected
                      ? Constants.ctaColorLight
                      : Colors.transparent,
                  width: 4,
                ),
              ),
              /*  boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Constants.ctaColorLight.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,*/
            ),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : Constants.ctaColorLight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestContent(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    List<Widget> cards = _buildAllRequestCards();

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey<int>(_selectedTopTab),
        child: Wrap(runSpacing: 24, spacing: 24, children: cards),
      ),
    );
  }

  List<Widget> _buildAllRequestCards() {
    List<Widget> cards = [];

    try {
      // Auto Spares Requests
      if (GlobalVariables.combinedRequest.autoSparesRequest.isNotEmpty) {
        final autoSpareCards = GlobalVariables.combinedRequest.autoSparesRequest
            .map((spare) {
              if (spare.status == "Waiting") {
                return _buildWaitingRequestCard(spare);
              } else {
                return _buildActiveRequestCard(spare);
              }
            })
            .toList();

        cards.addAll(autoSpareCards);
        if (autoSpareCards.isNotEmpty) cards.add(SizedBox(width: 22));
      }

      // Rim Tyre Requests
      if (GlobalVariables.combinedRequest.rimTyreRequest.isNotEmpty) {
        final rimTyreCards = GlobalVariables.combinedRequest.rimTyreRequest.map(
          (tyre) {
            if (tyre == "Waiting") {
              return _buildWaitingRequestCard(tyre);
            } else {
              return _buildActiveRequestCard(tyre);
            }
          },
        ).toList();

        cards.addAll(rimTyreCards);
        if (rimTyreCards.isNotEmpty) cards.add(SizedBox(width: 22));
      }

      // Consumer Electronics Requests
      if (GlobalVariables
          .combinedRequest
          .consumerElectronicsRequest
          .isNotEmpty) {
        final electronicsCards = GlobalVariables
            .combinedRequest
            .consumerElectronicsRequest
            .map((electronics) {
              if (electronics.status == "Waiting") {
                return _buildWaitingRequestCard(electronics);
              } else {
                return _buildActiveRequestCard(electronics);
              }
            })
            .toList();

        cards.addAll(electronicsCards);
        if (electronicsCards.isNotEmpty) cards.add(SizedBox(width: 22));
      }
    } catch (e) {
      print('Error building request cards: $e');
      cards.add(_buildErrorCard("Error loading requests"));
    }

    // Show empty state if no cards
    if (cards.isEmpty) {
      cards.add(_buildEmptyStateCard());
    }

    return cards;
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      width: 350,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.manrope(
                color: Colors.red[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      padding: EdgeInsets.all(16),
      width: 350,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 48),
            SizedBox(height: 16),
            Text(
              "No requests available",
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    VoidCallback voidCallBack,
    IconData icon,
    String title,
    bool isActive,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: voidCallBack,
          icon: Icon(icon, color: Colors.white, size: 22),
          label: Text(
            title,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (isActive) ...[
          SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }

  String _getRequestDescription(dynamic request) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (request?.partDetails?.partName != null &&
              request?.vehicleDetails?.makeModel != null &&
              request?.vehicleDetails?.year != null) {
            return "${request.partDetails.partName}, ${request.vehicleDetails.makeModel}, ${request.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (request?.productDetails != null) {
            final typeOfElectronics =
                request.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference =
                request.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = request.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (request?.productDetails != null) {
            final tyreType = request.productDetails.tyreType ?? "Tyres";
            final tyreWidth = request.productDetails.tyreWidthMm ?? 0;
            final sidewall = request.productDetails.sidewallProfile ?? "";
            final rimDiameter =
                request.productDetails.wheelRimDiameterInches ?? "";
            final brand =
                request.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${request.id ?? 'Unknown'}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable";
    }
  }

  void _navigateToDetailScreen(dynamic request) {
    try {
      if (request?.category == null) {
        _showErrorSnackBar("Cannot open request details: Invalid request data");
        return;
      }

      switch (request.category) {
        case "Vehicle Spares":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SparesDetailScreen(
                request: request,
                autoSpare: request.autoSpare,
                bids: request.sellerOffers ?? [],
                index: 1,
              ),
            ),
          );
          break;

        case "Vehicle Tyres and Rims":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RimTyreDetailScreen(
                request: request,
                rimTyre: request.rimTyre,
                bids: request.sellerOffers ?? [],
                index: 1,
              ),
            ),
          );
          break;

        case "Consumer Electronics":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsumerElectronicsDetailScreen(
                request: request,
                consumerElectronics: request.consumerElectronics,
                bids: request.sellerOffers ?? [],
                index: 1,
              ),
            ),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.manrope()),
        backgroundColor: Colors.red[600],
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildWaitingRequestCard(dynamic request) {
    return GestureDetector(
      onTap: () => _navigateToDetailScreen(request),
      child: Container(
        padding: EdgeInsets.all(16),
        width: 350,
        height: 410,
        constraints: BoxConstraints(minWidth: 300),
        decoration: BoxDecoration(
          color: Constants.dtaColorLight.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Constants.ctaColorLight, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatDate(request.createdAt),
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(360),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.manrope(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: Icon(
                        HugeIcons.strokeRoundedFilter,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Request title
            Text(
              "REQUEST1 #${request?.id ?? 'Unknown'}",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Constants.ftaColorLight,
              ),
            ),
            SizedBox(height: 8),
            // Description label
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.orange, width: 3),
                ),
              ),
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Description -",
                    style: GoogleFonts.manrope(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getRequestDescription(request),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    request?.category ?? "Unknown Category",
                    style: GoogleFonts.manrope(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Status dots
            Row(
              children: [
                Expanded(child: Container()),
                Center(
                  child: Row(
                    children: [
                      _buildStatusDot(
                        "D",
                        (request?.createdAt?.day ?? 0).toString(),
                      ),
                      SizedBox(width: 8),
                      _buildStatusDot(
                        "H",
                        (request?.createdAt?.hour ?? 0).toString(),
                      ),
                      SizedBox(width: 8),
                      _buildStatusDot(
                        "M",
                        (request?.createdAt?.minute ?? 0).toString(),
                      ),
                      SizedBox(width: 8),
                      _buildStatusDot(
                        "S",
                        (request?.createdAt?.second ?? 0).toString(),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
            SizedBox(height: 24),
            // Waiting message
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Waiting For",
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    Text(
                      "Seller Response",
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: Text(
                          "Refresh",
                          style: GoogleFonts.manrope(
                            color: Constants.ctaColorLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // View Details button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _navigateToDetailScreen(request),
                child: Text(
                  "View Details",
                  style: GoogleFonts.manrope(
                    color: Color(0xFF2B3A5C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveRequestCard(dynamic request) {
    return GestureDetector(
      onTap: () => _navigateToDetailScreen(request),
      child: Container(
        padding: EdgeInsets.all(16),
        width: 350,
        //height: 410,
        constraints: BoxConstraints(minWidth: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formatDate(request.createdAt),
                  style: GoogleFonts.manrope(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red[300]!),
                        borderRadius: BorderRadius.circular(360),
                      ),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.manrope(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {});
                      },
                      icon: Icon(
                        HugeIcons.strokeRoundedFilter,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Request title
            Text(
              "REQUEST #${request?.id ?? 'Unknown'}",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Constants.ftaColorLight,
              ),
            ),
            SizedBox(height: 8),
            // Description label
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.orange, width: 3),
                ),
              ),
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Description -",
                        style: GoogleFonts.manrope(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _navigateToDetailScreen(request),
                        child: Text(
                          "View Details",
                          style: GoogleFonts.manrope(
                            color: Color(0xFF2B3A5C),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getRequestDescription(request),
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    request.category ?? "Unknown Category",
                    style: GoogleFonts.manrope(
                      color: Colors.orange[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Status dots - showing elapsed time
            Row(
              children: [
                Spacer(),
                _buildStatusDot(
                  "D",
                  _getElapsedTime(request.createdAt, 'days'),
                ),
                SizedBox(width: 8),
                _buildStatusDot(
                  "H",
                  _getElapsedTime(request.createdAt, 'hours'),
                ),
                SizedBox(width: 8),
                _buildStatusDot(
                  "M",
                  _getElapsedTime(request.createdAt, 'minutes'),
                ),
                SizedBox(width: 8),
                _buildStatusDot(
                  "S",
                  _getElapsedTime(request.createdAt, 'seconds'),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 20),
            // Seller bids
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (request?.sellerOffers != null &&
                        request.sellerOffers.isNotEmpty) ...[
                      ...request.sellerOffers
                          .take(2)
                          .where((bid) => bid is Seller)
                          .cast<Seller>()
                          .map((bid) => _buildSellerBid(bid, request)),
                      SizedBox(height: 16),
                      // View All Bids button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "View All Bids",
                            style: GoogleFonts.manrope(
                              color: Constants.ftaColorLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Constants.ftaColorLight,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${request.sellerOffers.length}",
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Center(
                        child: Text(
                          "No bids yet",
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // View Details button
          ],
        ),
      ),
    );
  }

  String _getRequestId(dynamic request) {
    // Handle ProductRequestItem from API
    if (request is ProductRequestItem) {
      return request.requestId.isNotEmpty ? request.requestId : 'Unknown';
    }

    // Handle different request types (AutoSparesRequest, etc.)
    try {
      // Try to access id property first (most common case)
      if (request?.id != null) {
        return request.id.toString();
      }

      // Try to access requestId property as fallback
      try {
        if (request?.requestId != null) {
          return request.requestId.toString();
        }
      } catch (e) {
        // requestId property doesn't exist on this type, which is fine
      }

      return 'Unknown';
    } catch (e) {
      // If all approaches fail, return Unknown
      return 'Unknown';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
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

  Widget _buildSellerBid(Seller? seller, dynamic request) {
    if (seller == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Constants.ftaColorLight),
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    seller.name ?? "Unknown Seller",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B3A5C),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showConfirmationDialog(context, seller);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shadowColor: Colors.grey.shade400,
                    backgroundColor: Colors.green,
                    foregroundColor: Constants.ftaColorLight,
                    elevation: 3,
                  ),
                  child: Text(
                    "Accept",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Text(
              _formatBidDateTime(seller.bidTime),
              style: GoogleFonts.manrope(color: Colors.grey[600], fontSize: 11),
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: RichText(
              text: TextSpan(
                text: 'Bid: ',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: " R${seller.bid?.toInt() ?? 0}",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: RichText(
              text: TextSpan(
                text: 'Radius/Distance: ',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: "${seller.radius}Km",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: 'Comments: ',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: seller.comment,

                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Constants.ftaColorLight,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Rating: ${seller.rating ?? 0}/${seller.maxRating ?? 5}",
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      Spacer(),
                      OutlinedButton.icon(
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
                                  request.id.toString(),
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
                                      uuid: request.id.toString(),
                                      request: ProductRequest(
                                        description: _getRequestDescription(
                                          request,
                                        ),
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
                        icon: Icon(
                          HugeIcons.strokeRoundedBubbleChat,
                          color: Constants.ctaColorLight,
                          size: 18,
                        ),
                        label: Text(
                          "Group Chat",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 11,
                          ),
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
    );
  }

  // Confirmation Dialog
  void _showConfirmationDialog(BuildContext context, Seller seller) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Are You Sure !",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "By clicking the pay button you accept the offer made by this seller",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          "Cancel",
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
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showPaymentDialog(context, seller);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                        ),
                        child: Text(
                          "Pay",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
  }

  // Payment processing and order creation
  Future<void> _processPaymentAndCreateOrder(Seller seller) async {
    try {
      // Show loading indicator
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
                  'Processing Payment...',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Create order data
      final orderData = {
        'seller_id': seller.id,
        'buyer_id': 1, // You should replace this with actual buyer ID
        'total_amount': seller.bid,
        'status': 'ONGOING',
        'status_display': 'Ongoing',
        'payment_status': 'PAID',
        'payment_status_display': 'Paid',
        'payment_method': 'CARD', // Or based on user selection
        'currency': 'ZAR',
        'delivery_cost': 0.0,
        'installation_cost': 0.0,
        'quote_total': seller.bid,
        'request_title': 'New Order from Payment',
        'request_category': 'VEHICLE_SPARES',
        'payment_date': DateTime.now().toIso8601String(),
        'is_active': true,
        'can_cancel': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Submit to backend
      final response = await http.post(
        Uri.parse(
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/orders/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(orderData),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Order created successfully: ${response.body}');

        // Navigate to Transaction Management > Order tab > Ongoing tab
        setState(() {
          _selectedTopTab = 1; // Order tab
          _selectedTab = 0; // Ongoing tab
        });

        // Refresh orders to show the new one
        await _loadOrdersFromAPI();

        // Show success dialog
        _showPaymentSuccessfulDialog(context);
      } else {
        throw Exception(
          'Failed to create order: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showPaymentSuccessfulDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Center(
                    child: Image.asset(
                      "lib/assets/images/bag_logo.png",
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Center(
                    child: Image.asset(
                      "lib/assets/images/pay_image.png",
                      width: 250,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Payment Done",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Your Payment Has Been Successfully Done",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(360),
                          ),
                        ),
                        child: Text(
                          "Done",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
  }

  // Payment Dialog
  void _showPaymentDialog(BuildContext context, Seller seller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Payment",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey, size: 22),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Credit Card Payments
                Text(
                  "Credit Card Payments",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPaymentIcon("lib/assets/images/Visa.png"),
                    _buildPaymentIcon("lib/assets/images/Mastercard.png"),
                    _buildPaymentIcon("lib/assets/images/DinnersClub.png"),
                    _buildPaymentIcon("lib/assets/images/American-Express.png"),
                  ],
                ),
                SizedBox(height: 16),

                // Instant EFT
                Text(
                  "Instant EFT",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPaymentIcon("lib/assets/images/absa.png"),
                    _buildPaymentIcon("lib/assets/images/sid.png"),
                    _buildPaymentIcon("lib/assets/images/standard.png"),
                    _buildPaymentIcon("lib/assets/images/nedbank.png"),
                  ],
                ),
                SizedBox(height: 16),

                // QR Code Payments
                Text(
                  "QR Code Payments",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPaymentIcon("lib/assets/images/zapper.png"),
                    _buildPaymentIcon("lib/assets/images/snapscan.png"),
                  ],
                ),
                SizedBox(height: 16),

                // UPI
                Text(
                  "UPI",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPaymentIcon("lib/assets/images/applePay.png"),
                    _buildPaymentIcon("lib/assets/images/GPay.png"),
                    _buildPaymentIcon("lib/assets/images/SamsungPay.png"),
                    _buildPaymentIcon("lib/assets/images/mobi.png"),
                  ],
                ),
                SizedBox(height: 16),

                // Debit Cards
                Text(
                  "Debit Cards",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPaymentIcon("lib/assets/images/Mastercard.png"),
                    _buildPaymentIcon("lib/assets/images/visa2.png"),
                    _buildPaymentIcon("lib/assets/images/American-Express.png"),
                  ],
                ),
                SizedBox(height: 20),

                // Total and Continue Button
                Container(
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "R${seller.bid.toStringAsFixed(2)}",
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                "Total Amount",
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "View Details",
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            // Handle payment completion and order creation
                            await _processPaymentAndCreateOrder(seller);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(360),
                            ),
                          ),
                          child: Text(
                            "Continue",
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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

  Widget _buildPaymentIcon(String assetPath) {
    return Container(
      width: 50,
      height: 35,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          width: 35,
          height: 20,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String _formatBidDateTime(DateTime? bidTime) {
    if (bidTime == null) return "Time unavailable";

    return "${bidTime.day.toString().padLeft(2, '0')}/${bidTime.month.toString().padLeft(2, '0')}/${bidTime.year} - ${bidTime.hour.toString().padLeft(2, '0')}:${bidTime.minute.toString().padLeft(2, '0')} ${bidTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: GradientGlowBorder.normalGradient(
            borderRadius: BorderRadius.circular(360),
            blurRadius: 1,
            spreadRadius: 1,
            colors: [
              Colors.transparent,
              Constants.ftaColorLight.withOpacity(0.4),
            ],
            glowOpacity: 1,
            duration: Duration(milliseconds: 800),
            thickness: 2,
            child: Center(
              child: Text(
                time,
                style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        Text(
          letter.toString(),
          style: GoogleFonts.manrope(
            color: Constants.ftaColorLight,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(TypographyConfig typography, SpacingConfig spacing) {
    // Show loading state

    List<Order> orders;
    switch (_selectedTab) {
      case 0:
        orders = onGoingOrders;
        break;
      case 1:
        orders = purchasedOrders;
        break;
      case 2:
        orders = returnsRefundsOrders;
        break;
      case 3:
        orders = cancelledOrders;
        break;
      default:
        orders = onGoingOrders;
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Column(
        children: [
          Container(
            color: Constants.ftaColorLight,
            width: MediaQuery.of(context).size.width,
            height: 50,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusTab("On Going", 0),
                  _buildStatusTab("Purchased", 1),
                  _buildStatusTab("Returns/Refunds", 2),
                  _buildStatusTab("Cancelled", 3),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          if (_isLoadingOrders) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Constants.ctaColorLight,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Loading orders...",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_orderLoadingError != null) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  SizedBox(height: 16),
                  Text(
                    "Failed to load orders",
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _orderLoadingError!,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrdersFromAPI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Retry",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (orders.isEmpty) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No orders found",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadOrdersFromAPI,
                      child: Text(
                        "Refresh",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Constants.ctaColorLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Wrap(
                key: ValueKey<int>(_selectedTab),
                runSpacing: 16,
                spacing: 16,
                children: [
                  ...orders.map((order) {
                    return _buildOrderCard(order);
                  }),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Add these variables to your _TransactionDashboardState class
  String uniqueIdentifierNumber = '';

  // Return and Refund form controllers
  final TextEditingController _returnReasonController = TextEditingController();
  final TextEditingController _returnDescriptionController =
      TextEditingController();
  String _selectedReturnReason = '';
  final List<String> _returnReasons = [
    'Product defective/damaged',
    'Not as described',
    'Wrong item received',
    'Product quality issues',
    'Size/fit issues',
    'Changed mind',
    'Order was placed by mistake',
    'Product arrived too late',
    'Other',
  ];

  // Method to generate random 4-digit number
  void _generateUniqueIdentifier() {
    Random random = Random();
    List<int> digits = [];
    for (int i = 0; i < 4; i++) {
      digits.add(random.nextInt(10)); // Generate random digit 0-9
    }
    setState(() {
      uniqueIdentifierNumber = digits.join(
        ' ',
      ); // Join with spaces like "9 9 8 2"
    });
  }

  // Method to show the collect goods dialog
  Future<void> _showCollectGoodsDialog([Order? order]) async {
    // Get or create collection code when dialog opens
    if (order != null) {
      await _getCollectionCode(
        order.orderNumber,
      ); // Use order number as identifier and wait for completion
    } else {
      _generateLocalPinCode(); // Fallback for cases where no order is provided
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
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
            padding: EdgeInsets.all(20),
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
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: Constants.ctaColorLight,
                    size: 50,
                  ),

                  SizedBox(height: 16),

                  // Title
                  Text(
                    'Are You Sure !',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2B3A5C),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 12),

                  // Description
                  Text(
                    'By clicking the Conclude Deal button, you accept that the items are in good condition and that it meets your requirements.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 16),

                  // Unique Identifier Text
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Share your ',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextSpan(
                          text: 'Unique Identifier Number',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Color(0xFF2B3A5C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: ' with the seller to confirm the order',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // 4-Digit Code Display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      uniqueIdentifierNumber,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B3A5C),
                        letterSpacing: 6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Conclude Deal Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle conclude deal logic here
                        Navigator.of(context).pop();
                        _verifyCollectionPINDialog(context, order);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Conclude Deal',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Cancel Button (optional)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[600],
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

  // Method to show the return and refund dialog
  void _showReturnAndRefundDialog(dynamic order) {
    // Reset form fields
    _selectedReturnReason = '';
    _returnReasonController.clear();
    _returnDescriptionController.clear();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                ),
                padding: EdgeInsets.all(20),
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
                        CupertinoIcons.return_icon,
                        color: Colors.red[600],
                        size: 50,
                      ),
                      SizedBox(height: 16),

                      // Title
                      Text(
                        'Request Return & Refund',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B3A5C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),

                      // Description
                      Text(
                        'Please provide details about why you want to return this product. This will help us process your request efficiently.',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),

                      // Order Info
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order Details',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2B3A5C),
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Order #${order.orderNumber.length > 8 ? order.orderNumber.substring(0, 8).toUpperCase() : order.orderNumber.toUpperCase()}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              'Amount: R${order.price.toStringAsFixed(2)}',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Return Reason Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason for Return *',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B3A5C),
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedReturnReason.isEmpty
                                    ? null
                                    : _selectedReturnReason,
                                hint: Text(
                                  'Select a reason',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                items: _returnReasons.map((String reason) {
                                  return DropdownMenuItem<String>(
                                    value: reason,
                                    child: Text(
                                      reason,
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        color: Color(0xFF2B3A5C),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setDialogState(() {
                                    _selectedReturnReason = newValue ?? '';
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Description Text Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Additional Details *',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B3A5C),
                            ),
                          ),
                          SizedBox(height: 6),
                          TextField(
                            controller: _returnDescriptionController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText:
                                  'Please provide detailed information about the issue...',
                              hintStyle: GoogleFonts.manrope(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Constants.ctaColorLight,
                                ),
                              ),
                              contentPadding: EdgeInsets.all(12),
                            ),
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: Color(0xFF2B3A5C),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Photos/Evidence Section (Suggestion)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photos/Evidence (Optional)',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B3A5C),
                            ),
                          ),
                          SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[300]!,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  CupertinoIcons.camera,
                                  color: Colors.grey[600],
                                  size: 28,
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Upload photos to support your return request',
                                  style: GoogleFonts.manrope(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Preferred Resolution Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred Resolution',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2B3A5C),
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        CupertinoIcons.money_dollar_circle,
                                        color: Colors.red[600],
                                        size: 20,
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Full Refund',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        CupertinoIcons.refresh,
                                        color: Colors.blue[600],
                                        size: 20,
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Exchange',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[600],
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
                      SizedBox(height: 20),

                      // Submit Return Request Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_selectedReturnReason.isNotEmpty &&
                                  _returnDescriptionController.text
                                      .trim()
                                      .isNotEmpty)
                              ? () {
                                  // Handle return request submission
                                  _submitReturnRequest(order);
                                  Navigator.of(context).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (_selectedReturnReason.isNotEmpty &&
                                    _returnDescriptionController.text
                                        .trim()
                                        .isNotEmpty)
                                ? Colors.red[600]
                                : Colors.grey[400],
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(360),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Submit Return Request',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Cancel Button
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey[600],
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
      },
    );
  }

  Future<void> _getCollectionCode(String orderId) async {
    try {
      // Call backend API to get or create collection code
      final response = await http.post(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/collection-codes/get-or-create/',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'order_id': orderId}),
      );
      print("dfggf ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          uniqueIdentifierNumber = data['pin_code'];
          // Format with spaces for display: "1234" -> "1 2 3 4"
          uniqueIdentifierNumber = uniqueIdentifierNumber.split('').join(' ');
        });
      } else {
        // Fallback to local generation if API fails
        _generateLocalPinCode();
      }
    } catch (e) {
      print('Error getting collection code: $e');
      // Fallback to local generation
      _generateLocalPinCode();
    }
  }

  void _generateLocalPinCode() {
    Random random = Random();
    List<int> digits = [];
    for (int i = 0; i < 4; i++) {
      digits.add(random.nextInt(10)); // Generate random digit 0-9
    }
    setState(() {
      uniqueIdentifierNumber = digits.join(
        ' ',
      ); // Join with spaces like "9 9 8 2"
    });
  }

  // Method to handle return request submission

  void _verifyCollectionPINDialog(BuildContext context, [Order? order]) {
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
            constraints: BoxConstraints(maxWidth: 450, maxHeight: 450),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, //
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _congratulationDialog(context, order);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Constants.ftaColorLight,
                        minimumSize: Size(40, 40),
                        shadowColor: Colors.grey.shade100,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(8),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.back,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Center(
                      child: Image.asset(
                        "lib/assets/images/bidr23.png",
                        width: 100,
                        height: 100,
                      ),
                    ),
                    Container(width: 50, height: 40),
                  ],
                ),
                SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    "lib/assets/images/confirmed.png",
                    width: 140,
                    height: 140,
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    "Your Unique Identifier Number has been matched",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
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

  Future<void> _updateOrderStatusToCompleted(Order order) async {
    try {
      final updateResult = await ApiService.updateOrderStatus(
        orderId: order.orderNumber,
        status: 'COMPLETED',
        userId: Constants.currentUser?.uid,
      );

      if (updateResult['success'] == true) {
        print('Order status updated to COMPLETED successfully');
        // Refresh the orders list to show updated status
        loadOrdersFromAPI();
      } else {
        print('Failed to update order status: ${updateResult['message']}');
      }
    } catch (e) {
      print('Error updating order status to COMPLETED: $e');
    }
  }

  void _congratulationDialog(BuildContext context, [Order? order]) {
    // Update order status to COMPLETED when collection is confirmed
    if (order != null) {
      _updateOrderStatusToCompleted(order);
    }

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
            constraints: BoxConstraints(maxWidth: 450, maxHeight: 450),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, //
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Constants.ftaColorLight,
                        minimumSize: Size(40, 40),
                        shadowColor: Colors.grey.shade100,
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(8),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.back,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Center(
                      child: Image.asset(
                        "lib/assets/images/bidr23.png",
                        width: 100,
                        height: 100,
                      ),
                    ),
                    Container(width: 50, height: 40),
                  ],
                ),
                SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    "lib/assets/images/like.png",
                    width: 140,
                    height: 140,
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    "Congratulations on successfully concluding the transaction.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
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

  Widget _buildOrderCard(Order order) {
    return order.status ==
            "Cancelled" //
        ? Container(
            padding: EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: 300),
            decoration: BoxDecoration(
              color: Constants.dtaColorLight.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.ctaColorLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date and actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(order.dateTime),
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0XFFD62828),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Request title
                Text(
                  "REQUEST #",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 8),
                // Description label
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Constants.ctaColorLight,
                        width: 3,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.only(left: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Description -",
                            style: GoogleFonts.manrope(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "View Details",
                              style: GoogleFonts.manrope(
                                color: Color(0xFF2B3A5C),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${order.product} ${order.vehicle}",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),

                // View Details button
              ],
            ),
          )
        : Container(
            margin: EdgeInsets.only(bottom: 16),
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Constants.ftaColorLight.withOpacity(0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.vendorName,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              order.product,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
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
                            order.orderNumber,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: order.status.toLowerCase() == "refunded"
                                  ? Color(0XFF0045BD)
                                  : order.status.toLowerCase() ==
                                        "refund_requested"
                                  ? Colors.orange.shade600
                                  : order.status.toLowerCase() == "cancelled"
                                  ? Color(0XFFD62828)
                                  : Constants.ctaColorLight.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color:
                                    order.status.toLowerCase() == "refunded" ||
                                        order.status.toLowerCase() ==
                                            "refund_requested"
                                    ? Colors.white
                                    : Constants.ftaColorLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy - HH:mm').format(order.dateTime),
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Constants.ftaColorLight,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _showOrderDetailsDialog(order);
                        },
                        child: Text(
                          "View Details",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Constants.ftaColorLight,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),
                Divider(),
                SizedBox(height: 8),

                // Order Details
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: _buildDetailRow(
                    "Purchased Price:",
                    "R${order.price.toInt()}",
                  ),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: _buildDetailRow(
                    "Rating:",
                    "${order.rating.toInt()}/5",
                  ),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: _buildDetailRow(
                    "Radius/Distance:",
                    "${order.distanceInKm.toInt()}KM",
                  ),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: _buildDetailRow("Location:", order.location),
                ),
                SizedBox(height: 6),

                // Comments - show order comments or local reviews
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.comments.isNotEmpty
                                ? "Comments:"
                                : "Reviews:",
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          if ((order.status.toLowerCase() == "delivered" ||
                                  order.status.toLowerCase() == "purchased") &&
                              reviews.isNotEmpty)
                            InkWell(
                              onTap: () => _showAllReviewsDialog(order),
                              child: Text(
                                "View Reviews",
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Constants.ctaColorLight,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      // Show order comments if available, otherwise show local reviews
                      if (order.comments.isNotEmpty) ...[
                        ...order.comments
                            .map(
                              (comment) => Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "• ",
                                      style: GoogleFonts.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        comment.description,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ] else if (reviews.isNotEmpty) ...[
                        ...reviews
                            .map(
                              (review) => Padding(
                                padding: EdgeInsets.only(left: 8, bottom: 4),
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (index) => Icon(
                                              Icons.star,
                                              size: 14,
                                              color: index < review.rating
                                                  ? Constants.ctaColorLight
                                                  : Colors.grey[300],
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "${review.rating}/5",
                                            style: GoogleFonts.manrope(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Constants.ftaColorLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        review.comment,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ] else ...[
                        Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 2),
                          child: Text(
                            "No reviews available",
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Conditional UI based on order status and review state
                if (order.status.toLowerCase() == "delivered" ||
                    order.status.toLowerCase() == "purchased") ...[
                  // Show rating and reviews
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.star,
                          color: Constants.ctaColorLight,
                          size: 16,
                        ),
                        Text(
                          "${_getAverageRating().toStringAsFixed(1)}",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "$totalReviews Reviews",
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showAddReviewDialog(order);
                            },
                            icon: Icon(
                              Icons.star_outline,
                              size: 18,
                              color: Constants.ctaColorLight,
                            ),
                            label: Text(
                              "Write Review",
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Constants.ctaColorLight,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Constants.ctaColorLight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Return & Refund button
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle return & refund
                              _showReturnAndRefundDialog(order);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorLight,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(360),
                              ),
                            ),
                            child: Text(
                              "Return & Refund",
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (order.status.toLowerCase().contains('ongoing') ||
                    order.status.toLowerCase().contains('pending') ||
                    order.status.toLowerCase().contains('paid') ||
                    order.status.toLowerCase().contains('payment confirmed') ||
                    order.status.toLowerCase().contains('processing') ||
                    order.status.toLowerCase().contains('shipped') ||
                    order.status.toLowerCase().contains('completed')) ...[
                  // Collect Goods Button for all ongoing orders
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showCollectGoodsDialog(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorLight,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(360),
                              ),
                            ),
                            child: Text(
                              "Collect Goods",
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Add Cancel button for PAID orders
                        if (order.status.toLowerCase().contains('paid') ||
                            order.status.toLowerCase().contains(
                              'payment confirmed',
                            )) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _showCancelOrderDialog(order),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.red, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(360),
                                ),
                              ),
                              child: Text(
                                "Cancel Order",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: Constants.ctaColorLight,
                            borderRadius: BorderRadius.circular(360),
                          ),
                          child: IconButton(
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
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
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
                                // Create or get conversation for this request (without auth)
                                final conversationData =
                                    await ChatService.createOrGetConversationForRequest(
                                      _getRequestId(order),
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
                                          uuid: _getRequestId(order),
                                          request: ProductRequest(
                                            description: _getRequestDescription(
                                              order,
                                            ),
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
                            icon: Icon(
                              CupertinoIcons.chat_bubble_2_fill,
                              color: Constants.ftaColorLight,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (order.status.toLowerCase() == "refunded" ||
                    order.status.toLowerCase() == "refund_requested") ...[
                  // Show rating for refunded/refund requested orders
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (order.status.toLowerCase() == "refund_requested")
                          Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Colors.orange.shade700,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Refund request is being reviewed. We'll update you within 24-48 hours.",
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.star,
                              color: Constants.ctaColorLight,
                              size: 16,
                            ),
                            Text(
                              "${_getAverageRating().toStringAsFixed(1)}",
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "$totalReviews Reviews",
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 16),
              ],
            ),
          );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

// Model classes (as provided)
