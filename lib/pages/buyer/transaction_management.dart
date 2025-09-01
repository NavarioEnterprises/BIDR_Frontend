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
import 'package:shared_preferences/shared_preferences.dart';

import '../../customWdget/custom_input2.dart';
import '../../models/order.dart';
import '../../models/product_request_api.dart';
import '../../models/request_models.dart';
import '../../models/review_item.dart';
import '../../services/chat_service.dart';
import '../buyer_dashboard.dart';
import '../group_chat.dart';

class TransactionDashboard extends StatefulWidget {
  @override
  _TransactionDashboardState createState() => _TransactionDashboardState();
}

class _TransactionDashboardState extends State<TransactionDashboard>
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
        Uri.parse('${Constants.bidrBaseUrl}api/v1/product-requests/orders/'),
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
              apiReviews.add(ReviewItem(
                uuid: Constants.myUid.isNotEmpty ? Constants.myUid : DateTime.now().millisecondsSinceEpoch.toString(),
                customerName: Constants.myDisplayname,
                description: comment.description,
                rating: order.rating.toInt(), // Use order rating
                comment: comment.description,
                createdAt:_formatDate(order.dateTime),
                type: 'review',
              ));
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
                    order.status.toLowerCase().contains('processing') ||
                    order.status.toLowerCase().contains('shipped'),
              )
              .toList();
          purchasedOrders = allOrders
              .where(
                (order) =>
                    order.status.toLowerCase().contains('purchased') ||
                    order.status.toLowerCase().contains('delivered') ||
                    order.status.toLowerCase().contains('completed'),
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

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Excellent';
    if (rating >= 4) return 'Very Good';
    if (rating >= 3) return 'Good';
    if (rating >= 2) return 'Fair';
    return 'Poor';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green[700]!;
    if (rating >= 3) return Colors.blue[700]!;
    if (rating >= 2) return Colors.orange[700]!;
    return Colors.red[700]!;
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
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            width: 550,
            constraints: BoxConstraints(
              maxWidth: 550,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: Constants.ctaColorLight,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Details',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            "Order #${order.orderNumber}",
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status and Date Row
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.status.toUpperCase(),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat(
                                  'dd/MM/yyyy - HH:mm',
                                ).format(order.dateTime),
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24),

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

                        SizedBox(height: 20),

                        // Product Information Section
                        _buildDetailSection("Product Information", [
                          _buildDetailItem("Product", order.product),
                          _buildDetailItem("Vehicle", order.vehicle),
                        ]),

                        SizedBox(height: 20),

                        // Pricing Information Section
                        _buildDetailSection("Pricing Information", [
                          _buildDetailItem(
                            "Total Amount",
                            "R${order.price.toStringAsFixed(2)}",
                            isHighlighted: true,
                          ),
                        ]),

                        SizedBox(height: 20),

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
                                  (review) =>
                                      _buildCommentItem("${review.comment} (Rating: ${review.rating}/5)"),
                                )
                                .toList(),
                          ),
                        ],

                        SizedBox(height: 32),

                        // Action Buttons
                        Row(
                          children: [
                            if (order.status.toLowerCase() == "Pending Payment".toLowerCase() ) ...[
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _showCollectGoodsDialog,
                                  icon: Icon(
                                    CupertinoIcons.cube_box,
                                    size: 18,
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
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Handle chat action
                                },
                                icon: Icon(
                                  CupertinoIcons.chat_bubble_2,
                                  size: 18,
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
                                  padding: EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 24,
                                  ),
                                  side: BorderSide(
                                    color: Constants.ctaColorLight,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ]
                            else if (order.status.toLowerCase()  == "Delivered".toLowerCase() ) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showAddReviewDialog,
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
                                    side: BorderSide(
                                      color: Constants.ctaColorLight,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Handle return & refund
                                  },
                                  icon: Icon(
                                    Icons.refresh,
                                    size: 18,
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
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                            else ...[
                              Expanded(
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
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                ),
              ],
            ),
          ),
        );
      },
    );
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
      FocusNode focusNode)

  {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      maxLines: 5,
      textInputAction: TextInputAction.next,
      isPasswordField: false,
      onChanged: (value) {},
      onSubmitted: (value) {

      },
    );
  }

  void _showAddReviewDialog() {
    bool _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
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
                                'Rating & Review',
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
                          //height: 200,
                          width: MediaQuery.of(context).size.width * 0.3,
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.black87,side: BorderSide(color: Colors.black87,width: 1.4)),
                                    icon: Icon(
                                      Icons.close,
                                      color:Colors.black87,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),

                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: RatingBar.builder(
                                  initialRating: _currentRating,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: false,
                                  itemCount: 5,
                                  itemPadding: EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  itemBuilder: (context, _) =>
                                      Icon(Iconsax.star1, color: Colors.amber,size: 16,),
                                  onRatingUpdate: (rating) {
                                    setState(() {
                                      _currentRating = rating;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                              Center(
                                child: Text(
                                  _getRatingText(_currentRating),
                                  style: GoogleFonts.manrope(
                                    textStyle: TextStyle(
                                      fontSize: 13,
                                      color: _getRatingColor(_currentRating),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                             // _buildCustomTextField("Description",_commentController,_commentFocusNode),
                              //SizedBox(height: 8),
                              Form(
                                key: _formKey,
                                child: TextFormField(
                                  controller: _commentController,
                                  maxLines: 5,
                                  maxLength: 500,
                                  decoration: InputDecoration(
                                    labelText: 'Description',  // Changed from hintText to labelText
                                    labelStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    floatingLabelStyle: TextStyle(  // Style when label is floating
                                      color: Constants.ftaColorLight,
                                      fontSize: 14,
                                    ),
                                    hintText: 'Enter your description here',  // Optional: still show hint when focused
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    floatingLabelBehavior: FloatingLabelBehavior.always,
                                    fillColor: Colors.grey[50],
                                    contentPadding: EdgeInsets.all(16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: Constants.ftaColorLight,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide(
                                        color: Colors.red[400]!,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your review';
                                    } else if (value.trim().length < 10) {
                                      return 'Review must be at least 10 characters';
                                    }
                                    return null;
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
                                        horizontal: 16,
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
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        setState(() {
                                          _isSubmitting = true;
                                        });
                                        try {
                                          // Create new review item
                                          final newReview = ReviewItem(
                                            uuid: Constants.myUid.isNotEmpty ? Constants.myUid : DateTime.now().millisecondsSinceEpoch.toString(),
                                            customerName: Constants.myDisplayname,
                                            description: _commentController.text,
                                            rating: _currentRating.toInt(),
                                            comment: _commentController.text,
                                            createdAt: DateTime.now().toIso8601String(),
                                            type: 'review',
                                          );

                                          // Add review to local storage
                                          await _addReviewLocally(newReview);
                                          
                                          // Clear form
                                          _commentController.clear();
                                          _currentRating = 0.0;
                                          
                                          Navigator.of(context).pop();
                                          setState(() {});
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Review added successfully',
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
                                        } catch (e) {
                                          setState(() {
                                            _isSubmitting = false;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Failed to add review: $e',
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
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Constants.ctaColorLight,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'SUBMIT',
                                      style: GoogleFonts.manrope(
                                        textStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Tab Bar (Request/Order)
        Container(
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
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedTopTab == 0
                          ? Colors.orange.withOpacity(0.05)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTopTab == 0
                              ? Colors.orange
                              : Colors.grey[300]!,
                          width: _selectedTopTab == 0 ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Request",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: _selectedTopTab == 0
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _selectedTopTab == 0
                              ? Colors.orange
                              : Colors.grey[500],
                        ),
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
                          ? Colors.orange.withOpacity(0.05)
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTopTab == 1
                              ? Colors.orange
                              : Colors.grey[300]!,
                          width: _selectedTopTab == 1 ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Order",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: _selectedTopTab == 1
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: _selectedTopTab == 1
                              ? Colors.orange
                              : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Show Order Status Tabs only when Order tab is selected
        if (_selectedTopTab == 1) ...[
          Container(
            color: Colors.white,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2B3A5C),
                borderRadius: BorderRadius.circular(25),
              ),
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
        ],

        SizedBox(height: 24),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _selectedTopTab == 0
                    ? _buildRequestContent()
                    : _buildContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /*Widget _buildStatusTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }*/

  Widget _buildRequestContent() {
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
                bids: request.sellerOffers ?? [], index: 1,
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
                bids: request.sellerOffers ?? [], index: 1,
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
                bids: request.sellerOffers ?? [], index: 1,
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
        Uri.parse('${Constants.bidrBaseUrl}api/v1/product-requests/orders/'),
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
          width: MediaQuery.of(context).size.width * 0.3,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.all(20),
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Credit Card Payments
              Text(
                "Credit Card Payments",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/Visa.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/Mastercard.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/DinnersClub.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/American-Express.png"),
                ],
              ),
              SizedBox(height: 20),

              // Instant EFT
              Text(
                "Instant EFT",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/absa.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/sid.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/standard.png"),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/sid.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/nedbank.png"),
                ],
              ),
              SizedBox(height: 20),

              // QR Code Payments
              Text(
                "QR Code Payments",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/zapper.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/snapscan.png"),
                ],
              ),
              SizedBox(height: 20),

              // UPI
              Text(
                "UPI",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/applePay.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/GPay.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/SamsungPay.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/mobi.png"),
                ],
              ),
              SizedBox(height: 20),

              // Debit Cards
              Text(
                "Debit Cards",
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Constants.ftaColorLight,
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildPaymentIcon("lib/assets/images/Mastercard.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/visa2.png"),
                  SizedBox(width: 12),
                  _buildPaymentIcon("lib/assets/images/American-Express.png"),
                ],
              ),
              SizedBox(height: 20),

              // Total and Continue Button
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "R${seller.bid.toStringAsFixed(2)}",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          "Total Amount",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          "View Details",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // Handle payment completion and order creation
                        await _processPaymentAndCreateOrder(seller);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentIcon(String assetPath) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Image.asset(
          assetPath,
          width: 40,
          height: 25,
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

  Widget _buildContent() {
    // Show loading state
    if (_isLoadingOrders) {
      return Center(
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
              style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (_orderLoadingError != null) {
      return Center(
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
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOrdersFromAPI,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
      );
    }

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

    if (orders.isEmpty) {
      return Center(
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
              style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey[500]),
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
      );
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: Wrap(
        key: ValueKey<int>(_selectedTab),
        runSpacing: 24,
        spacing: 24,
        children: [
          ...orders.map((order) {
            return _buildOrderCard(order);
          }),
        ],
      ),
    );
  }

  // Add these variables to your _TransactionDashboardState class
  String uniqueIdentifierNumber = '';

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
  void _showCollectGoodsDialog() {
    _generateUniqueIdentifier(); // Generate new code when dialog opens

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.3,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: Constants.ctaColorLight,
                  size: 60,
                ),

                SizedBox(height: 20),

                // Title
                Text(
                  'Are You Sure !',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B3A5C),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                // Description
                Text(
                  'By clicking the Conclude Deal button, you accept that the items are in good condition and that it meets your requirements.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),

                // Unique Identifier Text
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Share your ',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      TextSpan(
                        text: 'Unique Identifier Number',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Color(0xFF2B3A5C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' with the seller to confirm the order',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // 4-Digit Code Display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    uniqueIdentifierNumber,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2B3A5C),
                      letterSpacing: 8,
                    ),
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
                      _verifyCollectionPINDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(360),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Conclude Deal',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 12),

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
        );
      },
    );
  }
  void _verifyCollectionPINDialog(BuildContext context) {
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
            constraints: BoxConstraints(maxWidth: 450,maxHeight: 450),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,//
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        Navigator.pop(context);
                        _congratulationDialog(context);
                        setState(() {

                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Constants.ftaColorLight,
                          minimumSize: Size(40, 40),
                          shadowColor: Colors.grey.shade100,
                          elevation: 5,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8))
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
                    Container(
                      width: 50,
                      height: 40,
                    )
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
  void _congratulationDialog(BuildContext context) {
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
            constraints: BoxConstraints(maxWidth: 450,maxHeight: 450),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,//
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(8))
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
                    Container(width:50,height:40)
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
    return order.status == "Cancelled" //
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
                              color: order.status.toLowerCase()  == "Refunded".toLowerCase()
                                  ? Color(0XFF0045BD)
                                  : order.status.toLowerCase()  == "Cancelled".toLowerCase()
                                  ? Color(0XFFD62828)
                                  : Constants.ctaColorLight.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.status,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: order.status.toLowerCase()  == "Refunded".toLowerCase()
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
                      Text(
                        order.comments.isNotEmpty ? "Comments:" : "Reviews:",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
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
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ...List.generate(5, (index) =>
                                            Icon(
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
                if (order.status.toLowerCase()  == "Delivered".toLowerCase())...[
                  // Show rating and reviews
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child:  Row(
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
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showAddReviewDialog,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: BorderSide.none,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(360),
                            ),
                          ),
                          child: Text(
                            "Give Order Review & Rating",
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                ]
                else if (order.status.toLowerCase()  == "Pending Payment".toLowerCase() ) ...[
                  // Collect Goods Button for ongoing orders
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showCollectGoodsDialog,
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
                        Container(
                          decoration: BoxDecoration(
                            color: Constants.ctaColorLight,
                            borderRadius: BorderRadius.circular(360),
                          ),
                          child: IconButton(
                            onPressed:() async {
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
                                            description: _getRequestDescription(order),
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
                ]
                  else if (order.status.toLowerCase()  == "Refunded".toLowerCase() )...[
                  // Show rating for refunded orders
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
                            fontWeight: FontWeight.w300,
                            color: Colors.black54,
                          ),
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
