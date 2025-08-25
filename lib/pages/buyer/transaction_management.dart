import 'dart:math';

import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';

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
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Sample data
  final List<Order> onGoingOrders = [
    Order(
      vendorName: "Midas",
      product: "Fuel Filter, Toyota Corolla, 2015",
      vehicle: "Toyota Corolla, 2015",
      orderNumber: "#BF7822626",
      status: "Ongoing",
      dateTime: DateTime(2025, 2, 22, 12, 45),
      price: 1400,
      rating: 4.0,
      distanceInKm: 30,
      location: "10 Daisy Street, Sandon, Gauteng",
      comments: [
        OrderComment(
          commentId: "1",
          description: "Fuel Filter With 12 MonthsGuarantee",
        ),
      ],
    ),
    Order(
      vendorName: "AutoZone",
      product: "Tyre, Toyota Corolla, 2022",
      vehicle: "Toyota Corolla, 2022",
      orderNumber: "#BF7822625",
      status: "Ongoing",
      dateTime: DateTime(2025, 2, 21, 12, 43),
      price: 1300,
      rating: 3.0,
      distanceInKm: 30,
      location: "25 Rivonia Road, Sandon, Gauteng",
      comments: [
        OrderComment(
          commentId: "1",
          description: "Free Tyre Insurance For 6 Months",
        ),
        OrderComment(
          commentId: "2",
          description: "Free Fitment And Wheel Alignment",
        ),
      ],
    ),
  ];

  final List<Order> purchasedOrders = [
    Order(
      vendorName: "TyreMax",
      product: "All Season Tyres, BMW X3, 2020",
      vehicle: "BMW X3, 2020",
      orderNumber: "#BF7822624",
      status: "Purchased",
      dateTime: DateTime(2025, 2, 20, 15, 30),
      price: 2800,
      rating: 5.0,
      distanceInKm: 25,
      location: "15 Main Road, Johannesburg, Gauteng",
      comments: [
        OrderComment(
          commentId: "1",
          description: "Premium quality tyres with 2-year warranty",
        ),
      ],
    ),
  ];

  final List<Order> returnsRefundsOrders = [
    Order(
      vendorName: "SpareMax",
      product: "Air Filter, Honda Civic, 2018",
      vehicle: "Honda Civic, 2018",
      orderNumber: "#BF7822623",
      status: "Refunded",
      dateTime: DateTime(2025, 2, 19, 11, 20),
      price: 350,
      rating: 2.0,
      distanceInKm: 40,
      location: "8 Industrial Street, Germiston, Gauteng",
      comments: [
        OrderComment(
          commentId: "1",
          description: "Wrong part delivered, refund processed",
        ),
      ],
    ),
  ];

  final List<Order> cancelledOrders = [
    Order(
      vendorName: "QuickParts",
      product: "Brake Pads, Ford Focus, 2019",
      vehicle: "Ford Focus, 2019",
      orderNumber: "#BF7822622",
      status: "Cancelled",
      dateTime: DateTime(2025, 2, 18, 9, 15),
      price: 890,
      rating: 0.0,
      distanceInKm: 35,
      location: "22 Commerce Street, Sandton, Gauteng",
      comments: [
        OrderComment(
          commentId: "1",
          description: "Order cancelled by customer",
        ),
      ],
    ),
  ];
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
                              color: Constants.ftaColorLight.withOpacity(0.55),
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
                    width: MediaQuery.of(context).size.width*0.3,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Write a Review',
                              style: GoogleFonts.manrope(
                                textStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Constants.ftaColorLight,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close,
                                  color: Colors.grey[600]),
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: 24),

                        // Rating section with label
                        Text(
                          'Your Rating',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Center(
                          child: RatingBar.builder(
                            initialRating: _currentRating,
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: false,
                            itemCount: 5,
                            itemPadding:
                            EdgeInsets.symmetric(horizontal: 4.0),
                            itemBuilder: (context, _) => Icon(
                              Icons.star,
                              color: Colors.amber,
                            ),
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
                        SizedBox(height: 24),

                        // Review content section
                        Text(
                          'Your Review',
                          style: GoogleFonts.manrope(
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: _commentController,
                            maxLines: 5,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText:
                              'What did you like or dislike about this product?',
                              hintStyle: TextStyle(
                                  color: Colors.grey[400], fontSize: 13),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: EdgeInsets.all(16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Constants.ctaColorLight,
                                    width: 1.5),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                BorderSide(color: Colors.grey[300]!),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.red[400]!, width: 1.5),
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
                                    horizontal: 16, vertical: 12),
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

                                    Navigator.of(context).pop();
                                    setState((){});
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Review added successfully'),
                                        backgroundColor: Colors.green[700],
                                        behavior: SnackBarBehavior.floating,
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
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to add review: $e'),
                                        backgroundColor: Colors.red[700],
                                        behavior: SnackBarBehavior.floating,
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
                                    horizontal: 20, vertical: 12),
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
                      color: _selectedTopTab == 0 ? Colors.orange.withOpacity(0.05) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTopTab == 0 ? Colors.orange : Colors.grey[300]!,
                          width: _selectedTopTab == 0 ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Request",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: _selectedTopTab == 0 ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedTopTab == 0 ? Colors.orange : Colors.grey[500],
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
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedTopTab == 1 ? Colors.orange.withOpacity(0.05) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedTopTab == 1 ? Colors.orange : Colors.grey[300]!,
                          width: _selectedTopTab == 1 ? 2 : 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Order",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: _selectedTopTab == 1 ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedTopTab == 1 ? Colors.orange : Colors.grey[500],
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

        SizedBox(height: 24,),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _selectedTopTab == 0 ? _buildRequestContent() : _buildContent(),
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

  Widget _buildRequestContent() {
    List<Widget> cards = _buildAllRequestCards();
    
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: SingleChildScrollView(
        key: ValueKey<int>(_selectedTopTab),
        child: Wrap(
          runSpacing: 24,
          spacing: 24,
          children: cards,
        ),
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
            if (tyre.status == "Waiting") {
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

  Widget _buildWaitingRequestCard(dynamic request) {
    return GestureDetector(
      onTap: () {
        // Handle navigation to detail screen
      },
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
                onPressed: () {
                  // Handle view details
                },
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
      onTap: () {
        // Handle navigation to detail screen
      },
      child: Container(
        padding: EdgeInsets.all(16),
        width: 350,
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
                        onPressed: () {
                          // Handle view details
                        },
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
            // Seller bids section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (request?.sellerOffers != null && request.sellerOffers.isNotEmpty) ...[
                      ...request.sellerOffers
                          .take(2)
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              "No offers yet",
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
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

  Widget _buildContent() {
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
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.grey[500],
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
          ...orders.map((order){
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
      uniqueIdentifierNumber = digits.join(' '); // Join with spaces like "9 9 8 2"
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
            width: MediaQuery.of(context).size.width*0.3,
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

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deal concluded successfully!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
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

  Widget _buildOrderCard(Order order) {
    return order.status =="Cancelled"?
    Container(
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
                onTap: (){},
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            "REQUEST #1",
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
              border: Border(left: BorderSide(color: Constants.ctaColorLight, width: 3)),
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
                      onPressed: (){},
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
    ):
    Container(
      margin: EdgeInsets.only(bottom: 16),
      width: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Constants.ftaColorLight.withOpacity(0.35)),
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
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2B3A5C),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2B3A5C),
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.status == "Refunded"?Color(0XFF0045BD):order.status == "Cancelled"?Color(0XFFD62828):Constants.ctaColorLight.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: order.status == "Refunded"?Colors.white:Constants.ftaColorLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 8),
          Divider(),
          SizedBox(height: 8),

          // Date and View Details
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(order.dateTime),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Handle view details
                  },
                  child: Text(
                    "View Details",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Order Details
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: _buildDetailRow("Purchased Price:", "R${order.price.toInt()}"),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: _buildDetailRow("Rating:", "${order.rating.toInt()}/5"),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: _buildDetailRow("Radius/Distance:", "${order.distanceInKm.toInt()}KM"),
          ),
          SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: _buildDetailRow("Location:", order.location),
          ),
          SizedBox(height: 6),

          // Comments
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Comments:",
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                ...order.comments.map((comment) => Padding(
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
                )).toList(),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Conditional UI based on order status and review state
          if (order.status == "Purchased" && _currentRating > 0.0 && _commentController.text.isNotEmpty) ...[
            // Show rating and reviews
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.star, color: Constants.ctaColorLight,size: 16,),
                  Text(
                    "$_currentRating",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Reviews",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.black54,
                    ),
                  )
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
          ] else if (order.status == "Ongoing") ...[
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
                      onPressed: () {
                        // Handle notification or action
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
          ] else if (order.status == "Purchased" && _currentRating == 0.0 && _commentController.text.isEmpty) ...[
            // Give review button for purchased orders without review
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
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
                          color: Constants.ctaColorLight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (order.status == "Refunded") ...[
            // Show rating for refunded orders
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.star, color: Constants.ctaColorLight,size: 16,),
                  Text(
                    "$_currentRating",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Reviews",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: Colors.black54,
                    ),
                  )
                ],
              ),
            ),
          ],

          SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _getRequestDescription(dynamic request) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (request?.autoSpares?.partDetails?.partName != null &&
              request?.autoSpares?.vehicleDetails?.makeModel != null &&
              request?.autoSpares?.vehicleDetails?.year != null) {
            return "${request.autoSpares.partDetails.partName}, ${request.autoSpares.vehicleDetails.makeModel}, ${request.autoSpares.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (request?.rimTyre?.productDetails != null) {
            final productDetails = request.rimTyre.productDetails;
            return "${productDetails.tyreType ?? 'Tyre'} ${productDetails.tyreWidthMm ?? ''}/${productDetails.sidewallProfile ?? ''} R${productDetails.wheelRimDiameterInches ?? ''} (Qty: ${productDetails.quantity ?? 1})";
          }
          return "Vehicle Tyres and Rims Request";

        case "Consumer Electronics":
          if (request?.consumerElectronics?.productDetails != null) {
            final productDetails = request.consumerElectronics.productDetails;
            return "${productDetails.typeOfElectronics ?? 'Electronics'} ${productDetails.brandPreference ?? ''} ${productDetails.modelSeries ?? ''} (Qty: ${productDetails.quantityNeeded ?? 1})";
          }
          return "Consumer Electronics Request";

        default:
          return "Request details not available";
      }
    } catch (e) {
      print('Error getting request description: $e');
      return "Error loading description";
    }
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

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Constants.ftaColorLight.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Constants.ftaColorLight.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.manrope(
                color: Constants.ftaColorLight,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          time,
          style: GoogleFonts.manrope(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerBid(dynamic bid, dynamic request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bid.name ?? 'Unknown Seller',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Constants.ftaColorLight,
                ),
              ),
              Text(
                "R${bid.bid?.toInt() ?? 0}",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Constants.ctaColorLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 14),
              SizedBox(width: 4),
              Text(
                "${bid.rating ?? 0}/${bid.maxRating ?? 5}",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.location_on, color: Colors.grey[500], size: 14),
              SizedBox(width: 4),
              Text(
                "${bid.radius?.toInt() ?? 0}km",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (bid.comment != null && bid.comment.isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              bid.comment,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
