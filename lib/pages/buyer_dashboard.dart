import 'dart:async';
import 'dart:convert';

import 'package:bidr/constants/Constants.dart';
import 'package:bidr/customWdget/customCard.dart';
import 'package:bidr/global_values.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:motion_toast/motion_toast.dart';

import '../customWdget/appbar.dart';
import '../customWdget/dropdownMenu.dart';
import '../models/product_request_api.dart';
import '../models/request_models.dart';
import '../services/chat_service.dart';
import '../services/products_management_api_service.dart';
import 'buyer/account_management.dart';
import 'buyer/share_with_friends.dart';
import 'buyer/support.dart';
import 'buyer/transaction_management.dart';
import 'group_chat.dart';

class BuyerDashboardScreen extends StatefulWidget {
  @override
  _BuyerDashboardScreenState createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  List<ProductRequestItem> _productRequests = [];
  bool _isLoading = true;
  bool _isInitialLoad = true;
  bool buttonHoverStates = false;
  String? _error;
  bool _isUnauthorized = false; // Track if user needs to login
  Map<String, String> _bidSortOptions = {}; // Track sort option per request ID
  Set<String> _cancelledRequests = {}; // Track cancelled request IDs
  Map<String, bool> _expandedSellerNotes =
      {}; // Track expanded seller notes by quote ID
  Map<String, bool> _navItemHoverStates =
      {}; // Track hover states for nav items

  // Auto-refresh timer
  Timer? _refreshTimer;
  Timer? _countdownTimer;
  final GlobalKey _transactionKey = GlobalKey();

  // Filter state variables
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Status';
  String _selectedSort = 'recent'; // Default sort by recent
  String _sortBy = 'newest';
  SortOption? _currentSort;

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    _fetchProductRequests();
    _startAutoRefresh();
    _startCountdownTimer();
    print(
      "Buyer Dashboard Initialized ${Constants.myUid} xx ${Constants.currentUser!.uid}",
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  int dashboardIndex = 0;
  bool isActive = false;

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

  // Start auto-refresh timer for background updates every 20 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 60), (timer) {
      // Only refresh if the widget is still mounted and not loading
      if (mounted) {
        // Refresh data based on current tab
        if (dashboardIndex == 0) {
          // My Dashboard - refresh product requests without showing loading
          _fetchProductRequests(showLoading: false);
        } else if (dashboardIndex == 2) {
          // Transaction Management - refresh orders
          _refreshTransactionManagement();
        }
        // Reviews and other data can be added here as needed
      }
    });
  }

  // Method to refresh Transaction Management data
  void _refreshTransactionManagement() {
    // Call the transaction management refresh method if the widget is available
    final state = _transactionKey.currentState;
    if (state != null && state is State && state.mounted) {
      // Use dynamic typing to call the method
      try {
        (state as dynamic).loadOrdersFromAPI();
      } catch (e) {
        print('Error calling loadOrdersFromAPI: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 24),
        BuyerDashboardHeader(headerName: "Buyer's Dashboard"),
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 68, right: 68),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 1600),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Constants.ftaColorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    () {
                      dashboardIndex = 0;
                      setState(() {});
                      // Reload product requests when navigating to My Dashboard
                      _fetchProductRequests(showLoading: false);
                    },
                    HugeIcons.strokeRoundedDashboardSquare01,
                    "My Dashboard",
                    dashboardIndex == 0 ? true : false,
                  ),
                  _buildNavItem(
                    () {
                      dashboardIndex = 1;
                      setState(() {});
                    },
                    HugeIcons.strokeRoundedShare01,
                    "Refer A Friend/Business",
                    dashboardIndex == 1 ? true : false,
                  ),
                  _buildNavItem(
                    () {
                      dashboardIndex = 2;
                      setState(() {});
                      // Trigger refresh for Transaction Management when navigating to it
                      _refreshTransactionManagement();
                    },
                    HugeIcons.strokeRoundedTransaction,
                    "Transaction Management",
                    dashboardIndex == 2 ? true : false,
                  ),
                  _buildNavItem(
                    () {
                      dashboardIndex = 3;
                      setState(() {});
                    },
                    HugeIcons.strokeRoundedUserAccount,
                    "Account Management",
                    dashboardIndex == 3 ? true : false,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 24),
        // Requests Grid
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 68, right: 68),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1600),

                        child: dashboardIndex == 0
                            ? _buildRequestsGrid()
                            : dashboardIndex == 1
                            ? Container(
                                width: MediaQuery.of(context).size.width * 0.35,
                                height: 400,
                                child: ShareWidget(),
                              )
                            : dashboardIndex == 2
                            ? Column(
                                children: [
                                  Expanded(
                                    child: TransactionDashboard(
                                      key: _transactionKey,
                                    ),
                                  ),
                                ],
                              )
                            : dashboardIndex == 3
                            ? AccountManagementPage()
                            : Container(),
                      ),
                    ),
                  ),
                ),
                FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAllRequestCards() {
    List<Widget> cards = [];

    try {
      // Show loading state (only on initial load)
      if (_isLoading && _isInitialLoad) {
        cards.add(_buildLoadingCard());
        return cards;
      }

      // Show unauthorized state
      if (_isUnauthorized) {
        cards.add(_buildUnauthorizedStateCard());
        return cards;
      }

      // Show error state
      if (_error != null) {
        cards.add(_buildErrorCard(_error!));
        return cards;
      }

      // Build cards from converted GlobalVariables data (not raw API data)
      List<dynamic> allRequests = List<dynamic>.from(_productRequests);

      // Apply filters and sorting
      List<dynamic> filteredRequests = _applyFiltersAndSorting(allRequests);

      if (filteredRequests.isNotEmpty) {
        final requestCards = filteredRequests.map((request) {
          if (request.status == "Waiting") {
            return _buildWaitingRequestCard(request);
          } else {
            int index = filteredRequests.indexOf(request);
            return _buildActiveRequestCard(request, index);
          }
        }).toList();

        cards.addAll(requestCards);
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

  Widget _buildRequestsGrid() {
    // Handle loading state (only show loading indicator on initial load)
    if (_isLoading && _isInitialLoad) {
      return Center(child: _buildLoadingCard());
    }

    // Handle unauthorized state (no auth user)
    if (_isUnauthorized) {
      return Center(child: _buildUnauthorizedStateCard());
    }

    // Handle error state
    if (_error != null) {
      return Center(child: _buildErrorCard(_error!));
    }

    // Get all requests
    List<dynamic> allRequests = List<dynamic>.from(_productRequests);

    if (allRequests.isEmpty) {
      return Center(child: _buildEmptyStateCard());
    }

    // Filter requests based on current filters
    final filteredRequests = _filterRequests(allRequests);

    if (filteredRequests.isEmpty) {
      return Center(child: _buildEmptyStateCard());
    }

    // Calculate pagination
    final totalItems = filteredRequests.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    // Reset current page if it exceeds total pages
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = 1;
    }

    // Get items for current page
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalItems);
    final currentPageItems = filteredRequests.sublist(startIndex, endIndex);

    return Container(
      height: 1800,
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Filter and Sort Controls
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: _buildFilterSortControls(filteredRequests.length),
            ),
            SizedBox(height: 16),
            // Custom Grid with dynamic row heights
            Container(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _buildCustomGrid(currentPageItems),
              ),
            ),
            // Pagination Controls
            if (totalPages > 1) _buildPaginationControls(totalPages, 24.0, 16.0),
          ],
        ),
      ),
    );
  }

  /// Build pagination controls
  Widget _buildPaginationControls(int totalPages, double topSpacing, double bottomSpacing) {
    return Column(
      children: [
        SizedBox(height: topSpacing),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _buildPaginationButton(
            icon: Icons.chevron_left,
            text: 'Previous',
            onTap: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          SizedBox(width: 16),
          // Page numbers
          ...List.generate(totalPages, (index) {
            final pageNumber = index + 1;
            // Show max 5 page numbers with current page in center when possible
            if (totalPages <= 5 ||
                pageNumber == 1 ||
                pageNumber == totalPages ||
                (pageNumber >= _currentPage - 1 &&
                    pageNumber <= _currentPage + 1)) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: _buildPageNumberButton(pageNumber),
              );
            } else if (pageNumber == 2 && _currentPage > 3) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Colors.grey)),
              );
            } else if (pageNumber == totalPages - 1 &&
                _currentPage < totalPages - 2) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('...', style: TextStyle(color: Colors.grey)),
              );
            }
            return SizedBox.shrink();
          }),
          SizedBox(width: 16),
          // Next button
          _buildPaginationButton(
            icon: Icons.chevron_right,
            text: 'Next',
            onTap: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
        ),
        SizedBox(height: bottomSpacing),
      ],
    );
  }

  /// Build pagination button (Previous/Next)
  Widget _buildPaginationButton({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : Colors.grey.shade100,
          border: Border.all(
            color: isEnabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text == 'Previous') ...[
              Icon(
                icon,
                size: 16,
                color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
              SizedBox(width: 4),
            ],
            Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
            ),
            if (text == 'Next') ...[
              SizedBox(width: 4),
              Icon(
                icon,
                size: 16,
                color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build page number button
  Widget _buildPageNumberButton(int pageNumber) {
    final isCurrentPage = pageNumber == _currentPage;
    return InkWell(
      onTap: () {
        setState(() {
          _currentPage = pageNumber;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isCurrentPage ? Constants.ctaColorLight : Colors.white,
          border: Border.all(
            color: isCurrentPage
                ? Constants.ctaColorLight
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            pageNumber.toString(),
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isCurrentPage ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  /// Filter and sort requests based on current settings
  List<dynamic> _filterRequests(List<dynamic> requests) {
    // First, filter the requests
    var filteredRequests = requests.where((request) {
      // Apply category filter
      if (_selectedCategory != 'All Categories') {
        String requestCategory = request.category ?? 'Unknown';
        if (_selectedCategory == 'Vehicle Spares' &&
            requestCategory != 'VEHICLE_SPARES')
          return false;
        if (_selectedCategory == 'Tyres & Rims' &&
            requestCategory != 'TYRES_RIMS')
          return false;
        if (_selectedCategory == 'Electronics' &&
            requestCategory != 'ELECTRONICS')
          return false;
      }

      // Apply status filter
      if (_selectedStatus != 'All Status') {
        if (_selectedStatus == 'Active' &&
            _cancelledRequests.contains(_getRequestId(request)))
          return false;
        if (_selectedStatus == 'With Bids' &&
            (request.sellerOffers == null || request.sellerOffers.isEmpty))
          return false;
        if (_selectedStatus == 'Without Bids' &&
            (request.sellerOffers != null && request.sellerOffers.isNotEmpty))
          return false;
        if (_selectedStatus == 'Cancelled' &&
            !_cancelledRequests.contains(_getRequestId(request)))
          return false;
      }

      return true;
    }).toList();

    // Then, sort the filtered requests
    filteredRequests.sort((a, b) {
      switch (_sortBy) {
        case 'newest':
          final dateA = a.createdAt ?? DateTime(1900);
          final dateB = b.createdAt ?? DateTime(1900);
          return dateB.compareTo(dateA);
        case 'oldest':
          final dateA = a.createdAt ?? DateTime(1900);
          final dateB = b.createdAt ?? DateTime(1900);
          return dateA.compareTo(dateB);
        case 'mostBids':
          final bidsA = a.sellerOffers?.length ?? 0;
          final bidsB = b.sellerOffers?.length ?? 0;
          return bidsB.compareTo(bidsA);
        case 'leastBids':
          final bidsA = a.sellerOffers?.length ?? 0;
          final bidsB = b.sellerOffers?.length ?? 0;
          return bidsA.compareTo(bidsB);
        case 'urgent':
          // Sort by urgency level
          final urgencyOrder = {
            'ASAP': 0,
            '24_HOURS': 1,
            '1_WEEK': 2,
            '1_MONTH': 3,
          };
          final urgencyA = urgencyOrder[a.urgencyTimeline] ?? 99;
          final urgencyB = urgencyOrder[b.urgencyTimeline] ?? 99;
          return urgencyA.compareTo(urgencyB);
        default:
          return 0;
      }
    });

    return filteredRequests;
  }

  /// Build custom grid with dynamic row heights and responsive layout
  Widget _buildCustomGrid(List<dynamic> requests) {
    const double horizontalSpacing = 16;
    const double verticalSpacing = 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine cards per row based on screen width
        int cardsPerRow;
        if (constraints.maxWidth > 1200) {
          cardsPerRow = 4; // Desktop/Large screens
        } else if (constraints.maxWidth > 900) {
          cardsPerRow = 3; // Tablet landscape
        } else if (constraints.maxWidth > 600) {
          cardsPerRow = 2; // Tablet portrait/Small desktop
        } else {
          cardsPerRow = 1; // Mobile
        }

        final double cardWidth =
            (constraints.maxWidth - (horizontalSpacing * (cardsPerRow - 1))) /
            cardsPerRow;

        return SingleChildScrollView(
          child: Container(
            height: 2500,
            child: Column(
              children: _buildRows(
                requests,
                cardsPerRow,
                cardWidth,
                horizontalSpacing,
                verticalSpacing,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build rows of cards with dynamic heights
  List<Widget> _buildRows(
    List<dynamic> requests,
    int cardsPerRow,
    double cardWidth,
    double horizontalSpacing,
    double verticalSpacing,
  ) {
    List<Widget> rows = [];

    for (int i = 0; i < requests.length; i += cardsPerRow) {
      final rowRequests = requests.skip(i).take(cardsPerRow).toList();

      // Calculate the maximum height for this row
      double maxHeight = _calculateMaxRowHeight(rowRequests);

      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + cardsPerRow < requests.length ? verticalSpacing : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int j = 0; j < rowRequests.length; j++) ...[
                SizedBox(
                  width: cardWidth,
                  height: maxHeight,
                  child: _buildActiveRequestCardWithHeight(
                    rowRequests[j],
                    maxHeight,
                    j + 1,
                  ),
                ),
                if (j < rowRequests.length - 1)
                  SizedBox(width: horizontalSpacing),
              ],
              // Fill remaining spaces in the row with empty containers
              for (int k = rowRequests.length; k < cardsPerRow; k++) ...[
                if (k > 0) SizedBox(width: horizontalSpacing),
                SizedBox(width: cardWidth),
              ],
            ],
          ),
        ),
      );
    }

    return rows;
  }

  /// Calculate the maximum height needed for a row of cards
  double _calculateMaxRowHeight(List<dynamic> rowRequests) {
    // Updated height calculations for modern card design with more space
    const double baseHeight =
        450.0; // Increased base height to prevent overflow
    const double bidCardHeight = 120.0; // Increased height per bid card
    const double viewMoreButtonHeight = 60.0; // Increased button height

    double maxHeight = baseHeight;

    for (var request in rowRequests) {
      final bids = _getSortedBids(request);
      final bidsToShow = bids.take(2).length; // New design shows only 2 bids
      final hasMoreThanTwoBids = bids.length > 2;

      double cardHeight = baseHeight + (bidsToShow * bidCardHeight);
      if (hasMoreThanTwoBids) {
        cardHeight += viewMoreButtonHeight;
      }

      if (cardHeight > maxHeight) {
        maxHeight = cardHeight;
      }
    }

    return maxHeight;
  }

  Widget _buildFilterSortControls(int cardCount) {
    return Row(
      children: [
        // Filter Button
        ElevatedButton.icon(
          onPressed: _showFilterOptions,
          icon: Icon(Icons.filter_list, size: 18),
          label: Text('Filter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[700],
            elevation: 1,
            side: BorderSide(color: Colors.grey.shade300),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(width: 12),
        // Sort Button
        ElevatedButton.icon(
          onPressed: _showSortOptions,
          icon: Icon(Icons.sort, size: 18),
          label: Text('Sort'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey[700],
            elevation: 1,
            side: BorderSide(color: Colors.grey.shade300),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        Spacer(),
        // Results count
        Text(
          '$cardCount requests',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showFilterOptions() {
    String tempSelectedCategory = _selectedCategory;
    String tempSelectedStatus = _selectedStatus;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            // Calculate simple statistics
            List<dynamic> allRequests = List<dynamic>.from(_productRequests);

            Map<String, int> bidStatistics = {
              'total': allRequests.length,
              'withBids': allRequests
                  .where(
                    (r) => r.sellerOffers != null && r.sellerOffers.isNotEmpty,
                  )
                  .length,
              'withoutBids': allRequests
                  .where(
                    (r) => r.sellerOffers == null || r.sellerOffers.isEmpty,
                  )
                  .length,
              'vehicleSpares': allRequests
                  .where((r) => r.category == 'VEHICLE_SPARES')
                  .length,
              'tyresRims': allRequests
                  .where((r) => r.category == 'TYRES_RIMS')
                  .length,
              'electronics': allRequests
                  .where((r) => r.category == 'ELECTRONICS')
                  .length,
              'active': allRequests
                  .where((r) => !_cancelledRequests.contains(_getRequestId(r)))
                  .length,
              'cancelled': allRequests
                  .where((r) => _cancelledRequests.contains(_getRequestId(r)))
                  .length,
            };

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Container(
                width: 500,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Request Filters',
                            style: GoogleFonts.manrope(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(Icons.close, size: 24),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Container(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Statistics Summary
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[100]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          bidStatistics['total']!.toString(),
                                          style: GoogleFonts.manrope(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Total Requests',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.orange[200],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          bidStatistics['withBids']!.toString(),
                                          style: GoogleFonts.manrope(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'With Bids',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 40,
                                      width: 1,
                                      color: Colors.orange[200],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          bidStatistics['withoutBids']!
                                              .toString(),
                                          style: GoogleFonts.manrope(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Without Bids',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Category Filter Section
                          Text(
                            'Filter by Category:',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                      'All Categories',
                                      'Vehicle Spares',
                                      'Tyres & Rims',
                                      'Electronics',
                                    ]
                                    .map(
                                      (category) => _buildModernFilterChip(
                                        category,
                                        tempSelectedCategory == category,
                                        (selected) {
                                          setDialogState(() {
                                            tempSelectedCategory = category;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(),
                          ),

                          SizedBox(height: 24),

                          // Status Filter Section
                          Text(
                            'Filter by Status:',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                _buildFilterOption(
                                  icon: Icons.all_inclusive,
                                  title: 'All Status',
                                  count: bidStatistics['total']!,
                                  isSelected:
                                      tempSelectedStatus == 'All Status',
                                  onTap: () {
                                    setDialogState(() {
                                      tempSelectedStatus = 'All Status';
                                    });
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[300]),
                                _buildFilterOption(
                                  icon: Icons.check_circle,
                                  title: 'Active',
                                  count: bidStatistics['active']!,
                                  isSelected: tempSelectedStatus == 'Active',
                                  onTap: () {
                                    setDialogState(() {
                                      tempSelectedStatus = 'Active';
                                    });
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[300]),
                                _buildFilterOption(
                                  icon: Icons.local_offer,
                                  title: 'With Bids',
                                  count: bidStatistics['withBids']!,
                                  isSelected: tempSelectedStatus == 'With Bids',
                                  onTap: () {
                                    setDialogState(() {
                                      tempSelectedStatus = 'With Bids';
                                    });
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[300]),
                                _buildFilterOption(
                                  icon: Icons.inbox,
                                  title: 'Without Bids',
                                  count: bidStatistics['withoutBids']!,
                                  isSelected:
                                      tempSelectedStatus == 'Without Bids',
                                  onTap: () {
                                    setDialogState(() {
                                      tempSelectedStatus = 'Without Bids';
                                    });
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey[300]),
                                _buildFilterOption(
                                  icon: Icons.cancel,
                                  title: 'Cancelled',
                                  count: bidStatistics['cancelled']!,
                                  isSelected: tempSelectedStatus == 'Cancelled',
                                  onTap: () {
                                    setDialogState(() {
                                      tempSelectedStatus = 'Cancelled';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Footer with buttons
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                tempSelectedCategory = 'All Categories';
                                tempSelectedStatus = 'All Status';
                              });
                            },
                            child: Text(
                              'Reset All',
                              style: GoogleFonts.manrope(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedCategory = tempSelectedCategory;
                                _selectedStatus = tempSelectedStatus;
                                _currentPage =
                                    1; // Reset to first page when filters change
                              });
                              Navigator.of(context).pop();
                            },

                            child: Text(
                              'Apply Filters',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w600,
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
      },
    );
  }

  void _showSortOptions() {
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
            width: 350,
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
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.sort,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Sort Requests',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // Sort Options
                _buildModernSortOption(
                  Icons.access_time,
                  'Newest First',
                  'Show most recent requests first',
                  _sortBy == 'newest',
                  () {
                    _sortRequests('newest');
                    Navigator.of(context).pop();
                  },
                ),
                _buildModernSortOption(
                  Icons.history,
                  'Oldest First',
                  'Show oldest requests first',
                  _sortBy == 'oldest',
                  () {
                    _sortRequests('oldest');
                    Navigator.of(context).pop();
                  },
                ),
                _buildModernSortOption(
                  Icons.category,
                  'By Category',
                  'Group by request category',
                  _sortBy == 'category',
                  () {
                    _sortRequests('category');
                    Navigator.of(context).pop();
                  },
                ),
                _buildModernSortOption(
                  Icons.flag,
                  'By Status',
                  'Group by request status',
                  _sortBy == 'status',
                  () {
                    _sortRequests('status');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernSortOption(
    IconData icon,
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green.shade300 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green.shade100 : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.green.shade700 : Colors.grey[600],
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected
                          ? Colors.green.shade800
                          : Colors.grey[800],
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterChip(
    String label,
    bool isSelected,
    Function(bool) onSelected,
  ) {
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade600 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange.shade600 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _sortRequests(String sortType) {
    setState(() {
      _sortBy = sortType;
      _currentPage = 1; // Reset to first page when sort changes
    });
  }

  Widget _buildBidFilterDropdown(String requestId) {
    final currentSort = _bidSortOptions[requestId] ?? 'recent';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentSort,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, size: 16),
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[700]),
          items: [
            DropdownMenuItem(
              value: 'recent',
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text('Most Recent'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'lowest',
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 14,
                    color: Colors.green[600],
                  ),
                  SizedBox(width: 6),
                  Text('Lowest Price'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'highest',
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, size: 14, color: Colors.red[600]),
                  SizedBox(width: 6),
                  Text('Highest Price'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'rating',
              child: Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.amber[600]),
                  SizedBox(width: 6),
                  Text('Best Rating'),
                ],
              ),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _bidSortOptions[requestId] = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  List<dynamic> _getSortedBids(dynamic request) {
    if (request?.sellerOffers == null || request.sellerOffers.isEmpty) {
      return [];
    }

    List<dynamic> bids = List<dynamic>.from(request.sellerOffers);
    final requestId = _getRequestId(request);
    final sortOption = _bidSortOptions[requestId] ?? 'recent';

    switch (sortOption) {
      case 'lowest':
        bids.sort((a, b) => _getBidAmount(a).compareTo(_getBidAmount(b)));
        break;
      case 'highest':
        bids.sort((a, b) => _getBidAmount(b).compareTo(_getBidAmount(a)));
        break;
      case 'rating':
        bids.sort((a, b) => _getBidRating(b).compareTo(_getBidRating(a)));
        break;
      case 'recent':
      default:
        bids.sort((a, b) => _getBidTime(b).compareTo(_getBidTime(a)));
        break;
    }

    return bids;
  }

  List<dynamic> _applyFiltersAndSorting(List<dynamic> requests) {
    List<dynamic> filtered = requests.where((request) {
      // Filter by category
      bool categoryMatch =
          _selectedCategory == 'All Categories' ||
          _getCategoryDisplayName(request.category) == _selectedCategory;

      // Filter by status
      bool statusMatch =
          _selectedStatus == 'All Status' || request.status == _selectedStatus;

      return categoryMatch && statusMatch;
    }).toList();

    // Sort the filtered results
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'oldest':
          return a.createdAt.compareTo(b.createdAt);
        case 'category':
          return a.category.compareTo(b.category);
        case 'status':
          return a.status.compareTo(b.status);
        case 'newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return filtered;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'VEHICLE_SPARES':
        return 'Vehicle Spares';
      case 'TYRES_RIMS':
        return 'Tyres & Rims';
      case 'ELECTRONICS':
        return 'Electronics';
      default:
        return category;
    }
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: EdgeInsets.all(16),
      width: 350,
      height: 400,

      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Constants.ftaColorLight,
            ),
            SizedBox(height: 16),
            Text(
              'Loading Requests...',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
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

  Widget _buildUnauthorizedStateCard() {
    return Container(
      width: double.infinity,
      height: 500,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login_outlined, size: 64, color: Colors.blue.shade600),
            SizedBox(height: 24),
            Text(
              'Login Required..',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Please log in to view your product requests.\nYour requests will appear here once you\'re authenticated.',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to login page
                context.go('/login');
              },
              icon: Icon(Icons.login, color: Colors.white),
              label: Text(
                'Go to Login',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      height: 500,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'No Requests Available',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You haven\'t created any product requests yet.\nStart creating requests to see them here.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navigate to landing page
                    Constants.buyerAppBarValue = 0;
                    appBarValueNotifier.value++;
                    buyerHomeValueNotifier.value++;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ftaColorLight,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Add a Request'),
                ),
                /*SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _testApiConnection();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Test API'),
                ),*/
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Refresh',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Constants.ftaColorLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
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
    final bool isHovering = _navItemHoverStates[title] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _navItemHoverStates[title] = true),
      onExit: (_) => setState(() => _navItemHoverStates[title] = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isHovering ? 1.05 : 1.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: voidCallBack,
              icon: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: isHovering ? Colors.orange : Colors.white,
                  size: 22,
                ),
              ),
              label: AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: GoogleFonts.manrope(
                  color: isHovering ? Colors.orange : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: isHovering
                      ? [
                          Shadow(
                            color: Colors.orange.withOpacity(0.5),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(title),
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
        ),
      ),
    );
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
          // All requests are now ProductRequestItem objects
          ProductRequestItem productRequestItem = request as ProductRequestItem;
          dynamic autoSpareData = productRequestItem
              .toAutoSparesRequest()
              .autoSpares;

          SparesDetailScreen.showAsDialog(
            context,
            index: index,
            request: productRequestItem,
            autoSpare: autoSpareData,
            bids: productRequestItem.quotes,
            onRequestCancelled: _removeRequestFromGlobalState,
          );
          break;

        case "TYRES_RIMS":
        case "Vehicle Tyres and Rims":
          // All requests are now ProductRequestItem objects
          ProductRequestItem tyreRequestItem = request as ProductRequestItem;
          final rimTyreRequest = _createRimTyreRequest(tyreRequestItem);

          RimTyreDetailScreen.showAsDialog(
            context,
            index: index,
            request: rimTyreRequest,
            rimTyre: rimTyreRequest.rimTyre,
            bids: tyreRequestItem.quotes,
            onRequestCancelled: _removeRequestFromGlobalState,
          );
          break;

        case "ELECTRONICS":
        case "Consumer Electronics":
          // All requests are now ProductRequestItem objects
          ProductRequestItem electronicsRequestItem =
              request as ProductRequestItem;
          final electronicsRequest = _createElectronicsRequest(
            electronicsRequestItem,
          );

          ConsumerElectronicsDetailScreen.showAsDialog(
            context,
            index: index,
            request: electronicsRequest,
            consumerElectronics: electronicsRequest.consumerElectronics,
            bids: electronicsRequestItem.quotes,
            onRequestCancelled: _removeRequestFromGlobalState,
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

  void _navigateToDetailScreenMobile(dynamic request, int index) {
    try {
      if (request?.category == null) {
        _showErrorSnackBar("Cannot open request details: Invalid request data");
        return;
      }

      switch (request.category) {
        case "VEHICLE_SPARES":
        case "Vehicle Spares":
          // All requests are now ProductRequestItem objects
          ProductRequestItem productRequestItem = request as ProductRequestItem;
          dynamic autoSpareData = productRequestItem
              .toAutoSparesRequest()
              .autoSpares;

          // Navigate to mobile optimized detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SparesDetailScreen(
                index: index,
                request: productRequestItem,
                autoSpare: autoSpareData,
                bids: productRequestItem.quotes,
              ),
            ),
          );
          break;

        case "TYRES_RIMS":
        case "Vehicle Tyres and Rims":
          // All requests are now ProductRequestItem objects
          ProductRequestItem tyreRequestItem = request as ProductRequestItem;
          final rimTyreRequest = _createRimTyreRequest(tyreRequestItem);

          // Navigate to mobile optimized detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RimTyreDetailScreen(
                index: index,
                request: rimTyreRequest,
                rimTyre: rimTyreRequest.rimTyre,
                bids: tyreRequestItem.quotes,
              ),
            ),
          );
          break;

        case "ELECTRONICS":
        case "Consumer Electronics":
          // All requests are now ProductRequestItem objects
          ProductRequestItem electronicsRequestItem =
              request as ProductRequestItem;
          final electronicsRequest = _createElectronicsRequest(
            electronicsRequestItem,
          );

          // Navigate to mobile optimized detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsumerElectronicsDetailScreen(
                index: index,
                request: electronicsRequest,
                consumerElectronics: electronicsRequest.consumerElectronics,
                bids: electronicsRequestItem.quotes,
              ),
            ),
          );
          break;

        default:
          _showErrorSnackBar("Unknown request category: ${request.category}");
      }
    } catch (e) {
      print('Mobile Navigation error: $e');
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

  void _removeRequestFromGlobalState(String requestId) {
    if (requestId.isEmpty) return;

    int removedCount = 0;

    // Remove from AutoSparesRequest list
    final autoSparesCount =
        GlobalVariables.combinedRequest.autoSparesRequest.length;
    GlobalVariables.combinedRequest.autoSparesRequest.removeWhere(
      (request) => _getRequestId(request) == requestId,
    );
    removedCount +=
        autoSparesCount -
        GlobalVariables.combinedRequest.autoSparesRequest.length;

    // Remove from RimTyreRequest list
    final rimTyreCount = GlobalVariables.combinedRequest.rimTyreRequest.length;
    GlobalVariables.combinedRequest.rimTyreRequest.removeWhere(
      (request) => _getRequestId(request) == requestId,
    );
    removedCount +=
        rimTyreCount - GlobalVariables.combinedRequest.rimTyreRequest.length;

    // Remove from ConsumerElectronicsRequest list
    final electronicsCount =
        GlobalVariables.combinedRequest.consumerElectronicsRequest.length;
    GlobalVariables.combinedRequest.consumerElectronicsRequest.removeWhere(
      (request) => _getRequestId(request) == requestId,
    );
    removedCount +=
        electronicsCount -
        GlobalVariables.combinedRequest.consumerElectronicsRequest.length;

    // Add to cancelled requests set for tracking
    setState(() {
      _cancelledRequests.add(requestId);
    });

    print(
      'Removed $removedCount request(s) with ID $requestId from global state',
    );
  }

  Widget _buildWaitingRequestCard(dynamic request) {
    return Container(
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
                  if (!_cancelledRequests.contains(_getRequestId(request)))
                    GestureDetector(
                      onTap: () => _showCancelRequestDialog(request),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
            "REQUEST #${_getRequestId(request)}",
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
              border: Border(left: BorderSide(color: Colors.orange, width: 3)),
            ),
            padding: EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "Description -",
                  style: GoogleFonts.manrope(color: Colors.black, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  _getRequestDescription(request),
                  style: GoogleFonts.manrope(fontSize: 13, color: Colors.black),
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
              onPressed: () {},
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
    );
  }

  Widget _buildMobileRequestCard(dynamic request, int index) {
    final bids = _getSortedBids(request);
    final hasMoreThanTwoBids = bids.length > 2;
    final bidsToShow = bids.take(2).toList();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetailScreenMobile(request, index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(request.createdAt),
                        style: GoogleFonts.manrope(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "REQUEST #${index}",
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  if (!_cancelledRequests.contains(_getRequestId(request)))
                    InkWell(
                      onTap: () => _showCancelRequestDialog(request),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.manrope(
                            color: Colors.red.shade500,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: 12),

              // Category Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getCategoryDisplayName(request.category ?? ''),
                  style: GoogleFonts.manrope(
                    color: Constants.ctaColorLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Request Description
              Text(
                _getRequestDescription(request),
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: 12),

              // Bids Section
              if (bidsToShow.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 14,
                      color: Colors.green.shade600,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${bids.length} bid${bids.length != 1 ? 's' : ''}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600,
                      ),
                    ),
                    if (hasMoreThanTwoBids) ...[
                      SizedBox(width: 8),
                      Text(
                        '(+${bids.length - 2} more)',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),

                // Show first 2 bids in compact format
                ...bidsToShow.map(
                  (bid) => Container(
                    margin: EdgeInsets.only(bottom: 6),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Constants.ctaColorLight.withOpacity(
                            0.1,
                          ),
                          child: Text(
                            (bid.sellerId?.username ?? 'S')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Constants.ctaColorLight,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bid.sellerId?.username ?? 'Seller',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${bid.currency} ${bid.totalAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: Colors.green.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Waiting for seller responses',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 12),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _navigateToDetailScreenMobile(request, index),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Constants.ctaColorLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: Text(
                        'View Details',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Constants.ctaColorLight,
                        ),
                      ),
                    ),
                  ),
                  if (bidsToShow.isNotEmpty) ...[
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _navigateToDetailScreenMobile(request, index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          'Review Bids',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
    );
  }

  Widget _buildActiveRequestCard(dynamic request, int index) {
    // This version is for compatibility - redirects to the height-specific version
    final bids = _getSortedBids(request);
    final hasMoreThanTwoBids = bids.length > 2;
    final bidsToShow = bids.take(2).toList(); // Match new design

    // Use same constants as _calculateMaxRowHeight for consistency
    const double baseHeight =
        450.0; // Increased base height to prevent overflow
    const double bidCardHeight = 120.0; // Increased height per bid card
    final double dynamicHeight =
        baseHeight +
        (bidsToShow.length * bidCardHeight) +
        (hasMoreThanTwoBids ? 60.0 : 0.0); // Increased button height

    return _buildActiveRequestCardWithHeight(request, dynamicHeight, index);
  }

  Widget _buildActiveRequestCardWithHeight(
    dynamic request,
    double fixedHeight,
    int index,
  ) {
    final bids = _getSortedBids(request);
    final hasMoreThanTwoBids = bids.length > 1;
    final bidsToShow = bids
        .take(2)
        .toList(); // Show only 2 bids like in screenshot
    if (request is RimTyreRequest) {
      print("dhgdhdggdh ${request.rimTyre.moreFields.preferredBrand}");
    }

    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Container(
        padding: EdgeInsets.all(16),
        width: double.infinity,
        height: fixedHeight,
        constraints: BoxConstraints(
          //  minHeight: fixedHeight,
          // maxHeight: fixedHeight,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              // offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View Details link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(request.createdAt),
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "REQUEST #${index}",
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (!_cancelledRequests.contains(_getRequestId(request)))
                      InkWell(
                        onTap: () {
                          _showCancelRequestDialog(request);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.manrope(
                              color: Colors.red.shade500,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(width: 12),

                    SortDropdownMenu(
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
              ],
            ),
            SizedBox(height: 6),

            // View Details link
            // SizedBox(height: 12),

            // Description section with orange border
            IntrinsicHeight(
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight,
                        borderRadius: BorderRadius.circular(36),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Description -",
                              style: GoogleFonts.manrope(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  _navigateToDetailScreen(request, index),
                              child: Text(
                                "View Details",
                                style: GoogleFonts.manrope(
                                  color: Constants.ftaColorLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          _getRequestDescription(request),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),

                        // Category
                        Text(
                          _getCategoryDisplayName(request.category),
                          style: GoogleFonts.manrope(
                            color: Colors.orange.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Product Images Section
            if (_getRequestImages(request).isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _getRequestImages(request).length,
                  itemBuilder: (context, index) {
                    final imageUrl = _getRequestImages(request)[index];
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _getFullImageUrl(imageUrl),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            SizedBox(height: 20),

            // Countdown Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerCircle(
                  _getRemainingTime(
                    request.createdAt,
                    _getUrgencyForRequest(request),
                    'days',
                  ),
                  "D",
                ),
                SizedBox(width: 12),
                _buildTimerCircle(
                  _getRemainingTime(
                    request.createdAt,
                    _getUrgencyForRequest(request),
                    'hours',
                  ),
                  "H",
                ),
                SizedBox(width: 12),
                _buildTimerCircle(
                  _getRemainingTime(
                    request.createdAt,
                    _getUrgencyForRequest(request),
                    'minutes',
                  ),
                  "M",
                ),
                SizedBox(width: 12),
                _buildTimerCircle(
                  _getRemainingTime(
                    request.createdAt,
                    _getUrgencyForRequest(request),
                    'seconds',
                  ),
                  "S",
                ),
              ],
            ),
            SizedBox(height: 24),

            // Seller Bids Section
            Expanded(
              child: Container(
                child: Column(
                  children: [
                    if (bidsToShow.isNotEmpty) ...[
                      Expanded(
                        child: Column(
                          children: bidsToShow
                              .map((bid) {
                                int sellerId = _getSellerId(bid);
                                Map<int, int> sellerIndexMap =
                                    _createSellerIndexMapping(bidsToShow);
                                int sellerIndex = sellerIndexMap[sellerId] ?? 1;

                                return Expanded(
                                  child: _buildModernSellerBid(
                                    bid,
                                    request,
                                    sellerIndex,
                                  ),
                                );
                              })
                              .take(1)
                              .toList(),
                        ),
                      ),
                      if (hasMoreThanTwoBids) ...[
                        SizedBox(height: 16),
                        _buildViewAllBidsButton(bidsToShow, request),
                      ],
                    ] else ...[
                      Expanded(
                        child: Center(
                          child: Text(
                            "No bids yet",
                            style: GoogleFonts.manrope(
                              color: Colors.grey.shade500,
                              fontSize: 14,
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
  }

  // Timer circle widget for countdown
  Widget _buildTimerCircle(String value, String label) {
    // Parse the value to get current progress
    int currentValue = int.tryParse(value) ?? 0;

    // Determine max value based on label
    int maxValue;
    switch (label.toLowerCase()) {
      case 'd':
        maxValue = 31;
        break;
      case 'w':
        maxValue = 4;
        break;
      case 'y':
        maxValue = 365; // or whatever max you want for years
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

  // Add this method to create seller-to-index mapping

  // Then in your build method, replace the current mapping with:
  /*Widget build(BuildContext context) {
    // Create seller index mapping
    Map<int, int> sellerIndexMap = _createSellerIndexMapping(bidsToShow);

    return Column(
      children:
      bidsToShow.map((bid) {
        int sellerId = _getSellerId(bid);
        int sellerIndex = sellerIndexMap[sellerId] ?? 1;

        return _buildModernSellerBid(
          bid,
          request,
          sellerIndex,
        );
      }).toList(),
    );
  }*/

  // Add this method to create seller-to-index mapping
  // Add this method to create seller-to-index mapping
  Map<int, int> _createSellerIndexMapping(List<dynamic> bids) {
    Map<int, int> sellerToIndexMap = {};
    int currentIndex = 1;

    try {
      for (var bid in bids) {
        if (bid == null) continue;

        int sellerId = _getSellerId(bid);
        if (sellerId != 0 && !sellerToIndexMap.containsKey(sellerId)) {
          sellerToIndexMap[sellerId] = currentIndex++;
        }
      }
    } catch (e) {
      print('Error creating seller index mapping: $e');
    }

    return sellerToIndexMap;
  }

  // Add these helper methods to handle QuoteItem objects
  int _getSellerId(dynamic bid) {
    print("fgghhg ${bid.runtimeType} $bid");
    try {
      if (bid is QuoteItem) {
        // For QuoteItem objects, sellerId is an ApiUser object
        return bid.sellerId.id; // Assuming ApiUser has an id property
      }

      if (bid is Map<String, dynamic>) {
        // Try different possible field names for seller ID
        return bid['seller_id'] ??
            bid['id'] ??
            bid['user_id'] ??
            bid['userId'] ??
            0;
      }

      // If bid has an id property directly
      if (bid != null && bid.id != null) {
        return bid.id as int;
      }
      return 0;
    } catch (e) {
      print('Error getting seller ID: $e');
      return 0;
    }
  }

  void showAllBidDialog(
    BuildContext context,
    List<dynamic> allBids,
    dynamic request,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return AnimatedScale(
          scale: 1.0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Container(
                    padding: EdgeInsets.fromLTRB(24, 20, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Bids',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            letterSpacing: -0.5,
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.close,
                                size: 24,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    height: 1,
                    color: Colors.grey[200],
                  ),

                  // Content area with scroll
                  Flexible(
                    child: Container(
                      width: double.infinity,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...allBids.asMap().entries.map((entry) {
                                int index = entry.key;
                                dynamic bid = entry.value;

                                int sellerId = _getSellerId(bid);
                                Map<int, int> sellerIndexMap =
                                    _createSellerIndexMapping(allBids);
                                int sellerIndex = sellerIndexMap[sellerId] ?? 1;

                                return AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 300 + (index * 100),
                                  ),
                                  curve: Curves.easeOutQuart,
                                  transform: Matrix4.identity()
                                    ..translate(0.0, 0.0),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      bottom: index < allBids.length - 1
                                          ? 16
                                          : 0,
                                    ),
                                    child: _buildModernSellerBid(
                                      bid,
                                      request,
                                      sellerIndex,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
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
    );
  }

  Widget _buildViewAllBidsButton(List<dynamic> allBids, dynamic request) {
    return GestureDetector(
      onTap: () => showAllBidDialog(context, allBids, request),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF2B3A5C)),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Color(0xFF2B3A5C),
                shape: BoxShape.circle,
              ),
              child: Text(
                allBids.length.toString(),
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'View All Bids',
              style: GoogleFonts.manrope(
                color: Color(0xFF2B3A5C),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFF2B3A5C),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Your existing _buildModernSellerBid method with mobile optimizations
  /*Widget _buildModernSellerBid(dynamic bid, dynamic request, int? sellerIndex) {
    String sellerName = sellerIndex != null? "Seller" : _getSellerName(bid);
    double bidAmount = _getBidAmount(bid);
    String bidNote = _getBidNote(bid);
    DateTime bidTime = _getBidTime(bid);
    double rating = _getBidRating(bid);
    String quoteId = bid is Map
        ? (bid['quote_id'] ?? bid['quoteId'] ?? 'unknown')
        : 'unknown';
    bool isExpanded = _expandedSellerNotes[quoteId] ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Seller info and bid details
          Container(
            padding: EdgeInsets.all(14),
            child: Column(
              children: [
                // Header with seller name, timestamp, and accept button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${sellerName} $sellerIndex",
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatDateTime(bidTime),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Constants.ftaColorLight.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand/Collapse icon
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedSellerNotes[quoteId] = !isExpanded;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey.shade500,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                // Collapsible seller notes section
                if (isExpanded && bidNote.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Seller Notes:',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          bidNote.toString(),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Bid amount and accept button
                Row(
                  children: [
                    Text(
                      'Bid: ',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      'R${bidAmount.toInt()}',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    InkWell(
                      onTap: () {
                        _showConfirmationDialog(context, bid, request);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          'Accept',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 10,
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
          // Rating and Group Chat section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Constants.ftaColorLight,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Rating: ${rating.toStringAsFixed(1)}/5',
                  style: GoogleFonts.manrope(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Spacer(),
                InkWell(
                  onTap: () async {
                    // Show loading indicator while creating/getting conversation
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Constants.ctaColorLight,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Loading conversation...',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
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
                        _getRequestId(request),
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
                                uuid: _getRequestId(request),
                                request: ProductRequest(
                                  description: _getRequestDescription(request),
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
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: Constants.ctaColorLight,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Group Chat',
                        style: GoogleFonts.manrope(
                          color: Constants.ctaColorLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }*/

  // Modern seller bid card matching screenshot
  Widget _buildModernSellerBid(dynamic bid, dynamic request, int? sellerIndex) {
    String sellerName = sellerIndex != null ? "Seller" : _getSellerName(bid);
    double bidAmount = _getBidAmount(bid);
    String bidNote = _getBidNote(bid);
    DateTime bidTime = _getBidTime(bid);
    double rating = _getBidRating(bid);
    String quoteId = bid is Map
        ? (bid['quote_id'] ?? bid['quoteId'] ?? 'unknown')
        : 'unknown';
    bool isExpanded = _expandedSellerNotes[quoteId] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seller info and bid details
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with seller name, timestamp, and accept button
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${sellerName} $sellerIndex",
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatDateTime(bidTime),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Constants.ftaColorLight.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand/Collapse icon
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedSellerNotes[quoteId] = !isExpanded;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Collapsible seller notes section
                if (isExpanded && bidNote.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Seller Notes:',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          bidNote.toString(),
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Bid amount and accept button
                Row(
                  children: [
                    Text(
                      'Bid: ',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      'R${bidAmount.toInt()}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    InkWell(
                      onTap: () {
                        _showConfirmationDialog(context, bid, request);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Accept',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 11,
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
          // Rating and Group Chat section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Constants.ftaColorLight, // Dark orange background
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Rating: ${rating.toStringAsFixed(1)}/5',
                  style: GoogleFonts.manrope(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Spacer(),
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
                            _getRequestId(request),
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
                                uuid: _getRequestId(request),
                                request: ProductRequest(
                                  description: _getRequestDescription(request),
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
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.chat_bubble_2_fill,
                        color: Constants.ctaColorLight,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Group Chat',
                        style: GoogleFonts.manrope(
                          color: Constants.ctaColorLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // View All Bids button

  // Helper method to format date and time
  String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} - ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}";
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
        // Hours remaining after accounting for days (0-23)
        final remainingHours = difference.inHours % 24;
        return remainingHours.toString();
      case 'minutes':
        // Minutes remaining after accounting for hours (0-59)
        final remainingMinutes = difference.inMinutes % 60;
        return remainingMinutes.toString();
      case 'seconds':
        // Seconds remaining after accounting for minutes (0-59)
        final remainingSeconds = difference.inSeconds % 60;
        return remainingSeconds.toString();
      default:
        return "0";
    }
  }

  String _getRemainingTime(
    DateTime? createdAt,
    String urgencyTimeline,
    String unit,
  ) {
    if (createdAt == null) return "0";

    // Calculate the deadline based on urgency timeline
    DateTime deadline;
    switch (urgencyTimeline) {
      case 'ASAP':
        deadline = createdAt.add(Duration(hours: 12)); // ASAP is 12 hours
        break;
      case '12_HOURS':
        deadline = createdAt.add(Duration(hours: 12));
        break;
      case '24_HOURS':
        deadline = createdAt.add(Duration(hours: 24));
        break;
      case '2-3_DAYS':
        deadline = createdAt.add(
          Duration(days: 3),
        ); // Use 3 days for 2-3 days range
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
        deadline = createdAt.add(Duration(days: 7)); // Default to 1 week
    }

    // Calculate remaining time
    final remaining = deadline.difference(DateTime.now());

    // If time has expired, return 0
    if (remaining.isNegative) {
      return "0";
    }

    switch (unit) {
      case 'days':
        return remaining.inDays.toString();
      case 'hours':
        // Hours remaining after accounting for days (0-23)
        final remainingHours = remaining.inHours % 24;
        return remainingHours.toString();
      case 'minutes':
        // Minutes remaining after accounting for hours (0-59)
        final remainingMinutes = remaining.inMinutes % 60;
        return remainingMinutes.toString();
      case 'seconds':
        // Seconds remaining after accounting for minutes (0-59)
        final remainingSeconds = remaining.inSeconds % 60;
        return remainingSeconds.toString();
      default:
        return "0";
    }
  }

  // Helper function to normalize error messages
  String _normalizeErrorMessage(String errorMessage) {
    // Check for specific error patterns and normalize them
    if (errorMessage.contains(
      'Cannot create order for request with status: CLOSED',
    )) {
      return 'Cannot pay for a bid that has been closed.';
    }

    // Extract error details from JSON response if present
    if (errorMessage.contains('Failed to create order:') &&
        errorMessage.contains('"error"')) {
      try {
        // Try to extract the detailed error message
        final regex = RegExp(r'"message":"([^"]*)"');
        final match = regex.firstMatch(errorMessage);
        if (match != null) {
          String detailedMessage = match.group(1) ?? '';
          // Further normalize specific messages
          if (detailedMessage.contains(
            'Cannot create order for request with status',
          )) {
            return 'Cannot pay for a bid that has been closed.';
          }
          return detailedMessage;
        }

        // Try to extract from non_field_errors
        final nonFieldRegex = RegExp(r'"non_field_errors":\["([^"]*)"');
        final nonFieldMatch = nonFieldRegex.firstMatch(errorMessage);
        if (nonFieldMatch != null) {
          String detailedMessage = nonFieldMatch.group(1) ?? '';
          if (detailedMessage.contains(
            'Cannot create order for request with status',
          )) {
            return 'Cannot pay for a bid that has been closed.';
          }
          return detailedMessage;
        }
      } catch (e) {
        // If parsing fails, fall through to default handling
      }
    }

    // Handle other common error patterns
    if (errorMessage.contains('NetworkException') ||
        errorMessage.contains('SocketException')) {
      return 'Network connection error. Please check your internet connection.';
    }

    if (errorMessage.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    if (errorMessage.contains('FormatException')) {
      return 'Invalid response format. Please try again.';
    }

    // If no specific pattern matches, return a cleaned version
    // Remove "Exception: " prefix if present
    String cleanedMessage = errorMessage.replaceFirst('Exception: ', '');

    // Capitalize first letter if needed
    if (cleanedMessage.isNotEmpty) {
      cleanedMessage =
          cleanedMessage[0].toUpperCase() + cleanedMessage.substring(1);
    }

    return cleanedMessage.isNotEmpty
        ? cleanedMessage
        : 'An unexpected error occurred. Please try again.';
  }

  // Payment processing and order creation
  Future<void> _processPaymentAndCreateOrder(
    dynamic seller,
    dynamic request,
  ) async {
    try {
      // Show loading indicator
      ApiService apiService = ApiService();
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
      // Extract UID from username by removing 'seller_' prefix
      final sellerUid = seller.sellerId.username.startsWith('seller_')
          ? seller.sellerId.username.substring(7)
          : seller.sellerId.username;

      print("Processing payment for buyer: $sellerUid");

      // Create order data required by backend
      //ApiService.updateOrderStatus(orderId: '', status: '');
      final orderData = {
        'request_id': _getRequestId(request),
        'quote_id': _getQuoteId(seller),
        'seller_id': sellerUid,
        'buyer_id': Constants.currentUser!.uid,
        // Optionals
        'delivery_address': null,
        'special_instructions': null,
      };
      print('Order Data: $orderData');
      print(
        'Submitting order to: ${GlobalVariables.productsServiceUrl}api/v1/product-requests/orders/',
      );

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

        // Parse response to get order ID
        final responseData = json.decode(response.body);
        final orderId =
            responseData['id']?.toString() ??
            responseData['order_id']?.toString();

        if (orderId != null) {
          // Update order status to PAID
          try {
            final updateResult = await ApiService.updateOrderStatus(
              orderId: orderId,
              status: 'PAID',
              userId: Constants.currentUser?.uid,
            );

            if (updateResult['success']) {
              print('Order status updated to PAID successfully');

              // Navigate to Transaction Management tab
              setState(() {
                dashboardIndex = 2; // Transaction Management tab
              });

              // Show success dialog
              _showPaymentSuccessfulDialog(context);
            } else {
              print(
                'Failed to update order status: ${updateResult['message']}',
              );
              throw Exception(
                'Failed to update order status: ${updateResult['message']}',
              );
            }
          } catch (e) {
            print('Error updating order status: $e');
            throw Exception('Error updating order status: $e');
          }
        } else {
          throw Exception('Order ID not found in response');
        }
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

      print('Error processing payment1: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${_normalizeErrorMessage(e.toString())}',
          ),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Confirmation Dialog
  void _showConfirmationDialog(
    BuildContext context,
    dynamic seller,
    dynamic request,
  ) {
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
                          _showPaymentDialog(context, seller, request);
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
  void _showPaymentDialog(
    BuildContext context,
    dynamic seller,
    dynamic request,
  ) {
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
                "Credit Card Payments1",
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
                          "R${_getBidAmount(seller).toStringAsFixed(2)}",
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
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // Handle payment completion and order creation
                        await _processPaymentAndCreateOrder(seller, request);
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

  Future<void> _fetchProductRequests({bool showLoading = true}) async {
    setState(() {
      // Only show loading indicator on initial load
      _isLoading = _isInitialLoad;
      _error = null;
      _isUnauthorized = false;
    });

    try {
      // Clear existing data before loading new data
      GlobalVariables.combinedRequest.autoSparesRequest.clear();
      GlobalVariables.combinedRequest.rimTyreRequest.clear();
      GlobalVariables.combinedRequest.consumerElectronicsRequest.clear();

      print(
        'Attempting to fetch requests for auth_user_uid: ${Constants.myUid}',
      );

      // Use the new API service method
      final result = await ApiService.getRequestsByBuyer();

      if (result['success'] == true) {
        final jsonData = result['data'];
        final apiResponse = ProductRequestApiResponse.fromJson(jsonData);

        print('Parsed ${apiResponse.results.length} requests from API');

        // Clear existing requests
        GlobalVariables.combinedRequest.autoSparesRequest.clear();
        GlobalVariables.combinedRequest.rimTyreRequest.clear();
        GlobalVariables.combinedRequest.consumerElectronicsRequest.clear();

        setState(() {
          _productRequests = apiResponse.results;
          _isLoading = false;
          _isInitialLoad = false;
        });

        // Populate GlobalVariables with API data
        for (var item in apiResponse.results) {
          _populateGlobalVariables(item);
        }

        print('Successfully loaded ${_productRequests.length} requests');
      } else {
        print('API Error: ${result['message']}');

        // Check if it's an authentication issue
        String errorMessage = result['message']?.toString() ?? '';
        bool isAuthError =
            errorMessage.contains('auth_user_uid') ||
            errorMessage.contains('required') ||
            result['statusCode'] == 400;

        setState(() {
          if (isAuthError) {
            _isUnauthorized = true;
            _error = null;
          } else {
            _error = null; // Don't show "Failed to load requests"
            _isUnauthorized = false;
          }
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      print('Exception occurred: $e');
      setState(() {
        _error = 'Network Error3: $e';
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  // Helper method to build full image URLs from relative paths
  String _buildFullImageUrl(String imagePath) {
    // If it's already a full URL, return as is
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Remove leading slash if present
    final cleanPath = imagePath.startsWith('/')
        ? imagePath.substring(1)
        : imagePath;

    // Build full URL using the products service URL
    return '${GlobalVariables.productsServiceUrl}$cleanPath';
  }

  void _populateGlobalVariables(ProductRequestItem item) {
    switch (item.category) {
      case 'VEHICLE_SPARES':
        // Convert API item to AutoSparesRequest
        final autoSparesRequest = _createAutoSparesRequest(item);
        GlobalVariables.combinedRequest.autoSparesRequest.add(
          autoSparesRequest,
        );
        break;

      case 'TYRES_RIMS':
        // Convert API item to RimTyreRequest
        final rimTyreRequest = _createRimTyreRequest(item);
        GlobalVariables.combinedRequest.rimTyreRequest.add(rimTyreRequest);
        break;

      case 'ELECTRONICS':
        // Convert API item to ConsumerElectronicsRequest
        final electronicsRequest = _createElectronicsRequest(item);
        GlobalVariables.combinedRequest.consumerElectronicsRequest.add(
          electronicsRequest,
        );
        break;
    }
  }

  AutoSparesRequest _createAutoSparesRequest(ProductRequestItem item) {
    // Extract data from productSpecifications
    final specs = item.productSpecifications ?? {};

    // Parse vehicle spares summary to extract vehicle details as fallback
    final parts = item.vehicleSparesSummary?.split(' - ') ?? ['', ''];
    final vehiclePart = parts.length > 0 ? parts[0] : '';
    final partName = parts.length > 1 ? parts[1] : item.title;

    final vehicleDetails = VehicleDetails(
      vin: specs['vin_number']?.toString() ?? '',
      manufacturer:
          specs['vehicle_make']?.toString() ?? vehiclePart.split(' ').first,
      makeModel:
          specs['vehicle_model']?.toString() ??
          vehiclePart.split(' ').skip(1).take(1).join(' '),
      type: specs['vehicle_type']?.toString() ?? 'Unknown',
      condition: item.conditionPreference ?? 'NEW',
      year:
          specs['vehicle_year']?.toString() ??
          (vehiclePart.contains(RegExp(r'\d{4}'))
              ? RegExp(r'\d{4}').firstMatch(vehiclePart)?.group(0) ?? '2020'
              : '2020'),
    );

    // Extract location information from specifications
    final locationInfo = specs['location_info'] as Map<String, dynamic>? ?? {};
    final locationAddress = locationInfo['address']?.toString() ?? 'Unknown';

    // Extract and build full image URLs
    final productImageUrls = (item.productImages ?? [])
        .map((imagePath) => _buildFullImageUrl(imagePath))
        .toList();

    final partDetails = PartDetails(
      partName: specs['part_name']?.toString() ?? partName,
      quantity: item.quantity ?? 1,
      location: locationAddress,
      maxDistanceKm: 50.0,
      urgency: _mapUrgencyTimeline(item.urgencyTimeline),
      productDescription: item.description,
      imageUrls: productImageUrls,
    );

    final moreFields = MoreFields(
      partNumber: specs['part_number']?.toString() ?? '',
      transmissionType: specs['transmission_type']?.toString() ?? 'Unknown',
      mileage: specs['mileage']?.toString() ?? '0',
      fuelType: specs['fuel_type']?.toString() ?? '',
      bodyType: specs['body_type']?.toString() ?? '',
      preferredBrand: specs['preferred_brand']?.toString() ?? '',
      fitmentRequired: specs['fitment_required']?.toString() ?? '',
      balancingRequired: specs['balancing_required']?.toString() ?? '',
      tyreRotationRequired: specs['tyre_rotation_required']?.toString() ?? '',
    );

    final autoSpares = AutoSpares(
      vehicleDetails: vehicleDetails,
      partDetails: partDetails,
      moreFields: moreFields,
    );

    // Build VIN image URL if available
    final vinImageUrl = item.vinPhotoUrl != null && item.vinPhotoUrl!.isNotEmpty
        ? _buildFullImageUrl(item.vinPhotoUrl!)
        : (specs['vin_photo'] != null &&
                  specs['vin_photo'].toString().isNotEmpty
              ? _buildFullImageUrl(specs['vin_photo'].toString())
              : null);

    return AutoSparesRequest(
      id: item.requestId, // Keep as string UUID
      status: item.status,
      category: item.category,
      createdAt: item.createdAt,
      autoSpares: autoSpares,
      sellerOffers: item.quotes, // Use real quotes from API
      productImages: productImageUrls, // Use full URLs
      images: item.images,
      vinImageUrl: vinImageUrl, // Add VIN image URL
    );
  }

  RimTyreRequest _createRimTyreRequest(ProductRequestItem item) {
    // Extract data from productSpecifications and vehicleTyresRimsData
    final specs = item.productSpecifications ?? {};
    final tyresRimsData = item.vehicleTyresRimsData ?? {};

    // Parse tyres rims summary
    final tyreSizePattern = RegExp(r'(\d+)/(\d+)R(\d+)');
    final match = tyreSizePattern.firstMatch(item.tyresRimsSummary ?? '');

    final productDetails = RimTyreProductDetails(
      tyreWidthMm:
          tyresRimsData['tyre_width']?.toInt() ??
          specs['tyre_width']?.toInt() ??
          (match != null ? int.tryParse(match.group(1)!) ?? 205 : 205),
      sidewallProfile:
          tyresRimsData['sidewall_profile']?.toString() ??
          specs['sidewall_profile']?.toString() ??
          (match != null ? match.group(2)! : '55'),
      wheelRimDiameterInches:
          tyresRimsData['wheel_rim_diameter']?.toString() ??
          specs['wheel_rim_diameter']?.toString() ??
          (match != null ? match.group(3)! : '16'),
      tyreType:
          tyresRimsData['select_tyres_rims']?.toString() ??
          specs['select_tyres_rims']?.toString() ??
          item.title,
      quantity:
          tyresRimsData['quantity']?.toInt() ??
          specs['quantity']?.toInt() ??
          item.quantity ??
          4,
      urgency: _mapUrgencyTimeline(item.urgencyTimeline),
    );

    // Extract and build full image URLs
    final productImageUrls = (item.productImages ?? [])
        .map((imagePath) => _buildFullImageUrl(imagePath))
        .toList();

    final moreFields = RimTyreMoreFields(
      description: _buildTyreRimDescription(
        tyreType: productDetails.tyreType,
        width: productDetails.tyreWidthMm,
        sidewall: productDetails.sidewallProfile,
        diameter: productDetails.wheelRimDiameterInches,
        brand:
            tyresRimsData['preferred_brand']?.toString() ??
            specs['preferred_brand']?.toString() ??
            _extractBrandFromTitle(item.title),
      ),
      vehicleType:
          tyresRimsData['vehicle_type']?.toString() ??
          specs['vehicle_type']?.toString() ??
          'Passenger Car',
      pitchCircleDiameter:
          tyresRimsData['pitch_circle_diameter']?.toString() ??
          specs['pitch_circle_diameter']?.toString() ??
          '114.3',
      preferredBrand:
          tyresRimsData['preferred_brand']?.toString() ??
          specs['preferred_brand']?.toString() ??
          _extractBrandFromTitle(item.title),
      tyreConstructionType:
          tyresRimsData['tyre_construction_type']?.toString() ??
          specs['tyre_construction_type']?.toString() ??
          'Radial',
      fitmentRequired:
          tyresRimsData['fitment_required']?.toString() ??
          specs['fitment_required']?.toString() ??
          "NO",
      balancingRequired:
          tyresRimsData['balancing_required']?.toString() ??
          specs['balancing_required']?.toString() ??
          "NO",
      tyreRotationRequired:
          tyresRimsData['tyre_rotation_required']?.toString() ??
          specs['tyre_rotation_required']?.toString() ??
          "NO",
      imageUrls: productImageUrls,
    );

    final rimTyre = RimTyre(
      productDetails: productDetails,
      moreFields: moreFields,
    );

    return RimTyreRequest(
      id: item.requestId, // Keep as string UUID
      status: item.status,
      category: item.category,
      createdAt: item.createdAt,
      rimTyre: rimTyre,
      sellerOffers: item.quotes, // Use real quotes from API
      productImages: productImageUrls, // Use full URLs
      images: item.images,
    );
  }

  ConsumerElectronicsRequest _createElectronicsRequest(
    ProductRequestItem item,
  ) {
    // Extract data from productSpecifications and consumerElectronicsData
    final specs = item.productSpecifications ?? {};
    final electronicsData = item.consumerElectronicsData ?? {};

    // Parse consumer electronics summary
    final parts =
        item.consumerElectronicsSummary?.split(' - ') ?? [item.title, ''];
    final productType =
        electronicsData['electronics_type']?.toString() ??
        specs['electronics_type']?.toString() ??
        (parts.length > 0 ? parts[0] : item.title);
    final brand =
        electronicsData['brand_preference']?.toString() ??
        specs['brand_preference']?.toString() ??
        _extractBrandFromTitle(item.title);

    final productDetails = ProductDetails(
      typeOfElectronics: productType,
      brandPreference: brand,
      modelSeries:
          electronicsData['model_series']?.toString() ??
          specs['model_series']?.toString() ??
          _extractModelFromSummary(item.consumerElectronicsSummary),
      quantityNeeded:
          electronicsData['quantity_needed']?.toInt() ??
          specs['quantity_needed']?.toInt() ??
          item.quantity ??
          1,
    );

    // Extract min and max price from specs
    final minPrice = specs['min_price'] != null
        ? double.tryParse(specs['min_price'].toString())
        : null;
    final maxPrice = specs['max_price'] != null
        ? double.tryParse(specs['max_price'].toString())
        : item.maxBudget;

    final budgetTimeline = BudgetTimeline(
      minPrice: minPrice,
      maxPrice: maxPrice,
      urgency: _mapUrgencyTimeline(
        electronicsData['urgency']?.toString() ??
            specs['urgency']?.toString() ??
            item.urgencyTimeline,
      ),
      needsInstallation:
          (electronicsData['installation_required']?.toString() ??
              specs['installation_required']?.toString() ??
              'NO') ==
          'YES',
    );

    // Extract and build full image URLs
    final productImageUrls = (item.productImages ?? [])
        .map((imagePath) => _buildFullImageUrl(imagePath))
        .toList();

    final featuresAndSpecs = FeaturesAndSpecs(
      requiredFeatures:
          electronicsData['required_features']?.toString() ??
          specs['required_features']?.toString(),
      conditionPreference:
          electronicsData['condition_preference']?.toString() ??
          specs['condition_preference']?.toString() ??
          item.conditionPreference ??
          'NEW',
      purpose:
          electronicsData['purpose_of_purchase']?.toString() ??
          specs['purpose_of_purchase']?.toString() ??
          'Home Use',
      documentsOrImages: productImageUrls,
      additionalComments:
          electronicsData['additional_comments']?.toString() ??
          specs['additional_comments']?.toString() ??
          item.description,
    );

    final consumerElectronics = ConsumerElectronics(
      productDetails: productDetails,
      budgetTimeline: budgetTimeline,
      featuresAndSpecs: featuresAndSpecs,
    );

    return ConsumerElectronicsRequest(
      id: item.requestId, // Keep as string UUID
      status: item.status,
      category: item.category,
      createdAt: item.createdAt,
      consumerElectronics: consumerElectronics,
      sellerOffers: item.quotes, // Use real quotes from API
      productImages: productImageUrls, // Use full URLs
      images: item.images,
    );
  }

  String _mapUrgencyTimeline(String urgencyTimeline) {
    switch (urgencyTimeline) {
      case 'ASAP':
      case '12_HOURS':
        return 'Immediately';
      case '1_WEEK':
        return '1 Week';
      case '1_MONTH':
        return '1 Month';
      default:
        return '1 Week';
    }
  }

  String _getUrgencyForRequest(dynamic request) {
    // Handle ProductRequestItem from API response
    if (request is ProductRequestItem) {
      return request.urgencyTimeline;
    }

    // Handle transformed request models
    if (request is AutoSparesRequest) {
      // Get urgency from the nested structure and map it
      final urgencyText = request.autoSpares?.partDetails?.urgency;
      return _mapTimeframeToUrgency(urgencyText);
    } else if (request is ConsumerElectronicsRequest) {
      final urgencyText = request.consumerElectronics?.budgetTimeline?.urgency;
      return _mapTimeframeToUrgency(urgencyText);
    } else if (request is RimTyreRequest) {
      final urgencyText = request.rimTyre!.productDetails!.urgency;
      return _mapTimeframeToUrgency(urgencyText);
    }

    // Default fallback
    return '1_WEEK';
  }

  List<String> _getRequestImages(dynamic request) {
    // Handle ProductRequestItem from API response
    if (request is ProductRequestItem) {
      final List<String> allImages = [];

      // Add product images
      if (request.productImages != null) {
        allImages.addAll(request.productImages!);
      }

      // Add other images
      if (request.images != null) {
        allImages.addAll(request.images!);
      }

      return allImages;
    }

    // For other request types, return empty list for now
    // TODO: Add image handling for transformed request models if needed
    return [];
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

  String _extractBrandFromTitle(String title) {
    final brands = [
      'Toyota',
      'BMW',
      'Mercedes',
      'Honda',
      'Nissan',
      'Ford',
      'Apple',
      'Samsung',
      'LG',
      'Sony',
      'Canon',
      'Continental',
      'Michelin',
    ];
    for (final brand in brands) {
      if (title.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }
    return 'Unknown';
  }

  String? _extractModelFromSummary(String? summary) {
    if (summary == null) return null;
    final parts = summary.split(' ');
    return parts.length > 2 ? parts[2] : null;
  }

  String _buildTyreRimDescription({
    required String tyreType,
    required int width,
    required String sidewall,
    required String diameter,
    required String brand,
  }) {
    // Build formatted description like "Tyres, 300/40R14, Black" or "Rims, 300/40R14, BMW"
    final sizeSpec = "${width}/${sidewall}R${diameter}";
    return "$tyreType, $sizeSpec, $brand";
  }

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Constants.ftaColorLight.withOpacity(0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(360),
            boxShadow: [
              BoxShadow(
                color: Constants.ftaColorLight.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
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
        SizedBox(height: 4),
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

  // Helper methods to extract data from both Seller and QuoteItem objects
  /*int _getSellerId(dynamic bid) {
    if (bid is Seller) {
      return bid.id ?? 0;
    } else if (bid is QuoteItem) {
      return bid.sellerId.id;
    } else {
      // Handle API response format
      if (bid['seller_id'] != null) {
        if (bid['seller_id'] is Map) {
          return bid['seller_id']['id'] ?? 0;
        }
        return bid['seller_id'] ?? 0;
      }
      return 0;
    }
  }*/

  String _getQuoteId(dynamic bid) {
    if (bid is QuoteItem) {
      return bid.quoteId?.toString() ?? '';
    } else if (bid is Seller) {
      // Seller type may not carry quote_id; return empty
      return '';
    } else {
      // Handle API response format
      final q = bid['quote_id'];
      return q != null ? q.toString() : '';
    }
  }

  String _getBidNote(dynamic bid) {
    // Handle API response format
    final q = bid.sellerNotes;
    return q != null ? q.toString() : '';
  }

  double _getBidAmount(dynamic bid) {
    if (bid is Seller) {
      return bid.bid?.toDouble() ?? 0.0;
    } else if (bid is QuoteItem) {
      return bid.totalAmount ?? 0.0;
    } else {
      // Handle API response format
      return (bid['total_amount'] ?? bid['amount'] ?? 0.0).toDouble();
    }
  }

  double _getBidRating(dynamic bid) {
    if (bid is Seller) {
      return bid.rating.toDouble();
    } else if (bid is QuoteItem) {
      // For QuoteItem, assume a default rating or look elsewhere
      return 5.0; // Default rating for QuoteItem
    } else {
      // Handle API response format
      return (bid['rating'] ?? 5.0).toDouble();
    }
  }

  DateTime _getBidTime(dynamic bid) {
    if (bid is Seller) {
      return bid.bidTime ?? DateTime.now();
    } else if (bid is QuoteItem) {
      return bid.createdAt ?? DateTime.now();
    } else {
      // Handle API response format
      try {
        String? timeStr = bid['created_at'] ?? bid['bid_time'];
        if (timeStr != null) {
          return DateTime.parse(timeStr);
        }
      } catch (e) {
        print('Error parsing bid time: $e');
      }
      return DateTime.now();
    }
  }

  String _getSellerName(dynamic bid) {
    if (bid is Seller) {
      return bid.name;
    } else if (bid is QuoteItem) {
      // Combine username and first/last name if available
      if (bid.sellerId.firstName != null && bid.sellerId.lastName != null) {
        return "${bid.sellerId.firstName} ${bid.sellerId.lastName}";
      }
      return bid.sellerId.username; // Use username as fallback
    } else {
      // Handle API response format
      if (bid['seller_id'] != null) {
        if (bid['seller_id']['first_name'] != null &&
            bid['seller_id']['last_name'] != null) {
          return "${bid['seller_id']['first_name']} ${bid['seller_id']['last_name']}";
        }
        return bid['seller_id']['username'] ??
            bid['seller_name'] ??
            "Unknown Seller";
      }
      return bid['seller_name'] ?? "Unknown Seller";
    }
  }

  String _getBidComments(dynamic bid) {
    if (bid is Seller) {
      return bid.comment;
    } else if (bid is QuoteItem) {
      // QuoteItem doesn't have notes, use another field or status
      return "Quote ID: ${bid.quoteId}. Delivery: ${bid.estimatedDeliveryDays ?? 'Not specified'} days";
    } else {
      // Handle API response format
      return bid['comment'] ?? bid['notes'] ?? bid['comments'] ?? "No comments";
    }
  }

  double _getBidDistance(dynamic bid) {
    if (bid is Seller) {
      return bid.radius?.toDouble() ?? 0.0;
    } else if (bid is QuoteItem) {
      // For QuoteItem, distance might be in delivery details
      return bid.estimatedDeliveryDays?.toDouble() ??
          0.0; // Or use a different field
    } else {
      // Handle API response format
      return (bid['distance'] ?? bid['radius'] ?? 0.0).toDouble();
    }
  }

  // Cancel Request Dialog
  void _showCancelRequestDialog(dynamic request) {
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
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.red[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Cancel Request?",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Are you sure you want to cancel this product request? This action cannot be undone and all associated bids will be removed.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
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
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          "Keep Request",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _cancelRequest(request);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Yes, Cancel",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
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

  // Cancel Request API Call
  Future<void> _cancelRequest(dynamic request) async {
    final requestId = _getRequestId(request);

    print('=== DEBUG: Cancel Request ===');
    print('Request type: ${request.runtimeType}');
    print('Request ID: $requestId');
    print('Request details: ${request.toString()}');

    // Validate request ID before making API call
    if (requestId == 'Unknown' || requestId == '0') {
      _showErrorSnackBar("Invalid request ID: Cannot cancel request");
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Constants.ftaColorLight),
                SizedBox(height: 16),
                Text(
                  "Cancelling request...",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // API call to cancel the request
      final response = await http.delete(
        Uri.parse(
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/$requestId/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - add to cancelled requests set
        setState(() {
          _cancelledRequests.add(requestId);
        });

        // Show success dialog
        _showCancelSuccessDialog(requestId);

        // Refresh the grid after a short delay
        Future.delayed(Duration(seconds: 2), () {
          _fetchProductRequests(showLoading: false);
        });
      } else {
        // Handle API error
        _showErrorSnackBar(
          "Failed to cancel request: HTTP ${response.statusCode}",
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      Navigator.of(context).pop();

      print('Error cancelling request: $e');
      _showErrorSnackBar("Network error: Unable to cancel request");
    }
  }

  // Cancel Success Dialog
  void _showCancelSuccessDialog(String requestId) {
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
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.green[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Request Cancelled",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Your request #$requestId has been successfully cancelled. The grid will refresh automatically.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {});
                      // Remove the cancelled request from global state
                      // Note: This needs to be handled by parent widget via callback

                      // Trigger refresh of main dashboard after closing success dialog
                      Future.delayed(Duration(seconds: 1), () {
                        if (context.mounted) {
                          // Force a rebuild which will trigger parent refresh
                          setState(() {});
                        }
                      });

                      //onRequestCancelled!(requestId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Done",
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

  // Helper method to build filter option
  Widget _buildFilterOption({
    required IconData icon,
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? Colors.orange[50] : Colors.white,
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.orange[600] : Colors.grey[600],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.orange[700] : Colors.grey[800],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SparesDetailScreen extends StatefulWidget {
  final int index;
  final ProductRequestItem request;
  final AutoSpares autoSpare;
  final List<dynamic> bids;
  final Function(String)? onRequestCancelled;

  const SparesDetailScreen({
    Key? key,
    required this.request,
    required this.autoSpare,
    required this.bids,
    required this.index,
    this.onRequestCancelled,
  }) : super(key: key);

  @override
  State<SparesDetailScreen> createState() => _SparesDetailScreenState();

  static void showAsDialog(
    BuildContext context, {
    required int index,
    required ProductRequestItem request,
    required AutoSpares autoSpare,
    required List<dynamic> bids,
    Function(String)? onRequestCancelled,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        print("dggfgf ${request.toString()}");
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.9,
            child: SparesDetailScreen(
              index: index,
              request: request,
              autoSpare: autoSpare,
              bids: bids,
              onRequestCancelled: onRequestCancelled,
            ),
          ),
        );
      },
    );
  }
}

class _SparesDetailScreenState extends State<SparesDetailScreen> {
  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Start auto-refresh timer that updates every second
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild every second, updating timers and dynamic content
        });
      }
    });
  }

  String _getRequestId(dynamic request) {
    // Handle ProductRequestItem from API
    if (request is ProductRequestItem) {
      return request.requestId.isNotEmpty ? request.requestId : 'Unknown';
    }
    // Handle other request types that have 'id' property
    try {
      return request.id?.toString() ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  SortOption? _currentSort;
  final Set<String> _cancelledRequests = {};
  int _currentProductImageIndex = 0;
  Map<String, dynamic>? _getProductSpecifications() {
    try {
      // First try to get from request.productSpecifications (API data)
      if (widget.request.productSpecifications != null) {
        return widget.request.productSpecifications;
      }
      // Fallback to autoSpare.moreFields if available
      return widget.autoSpare.moreFields.toJson();
    } catch (e) {
      print('Error getting product specifications: $e');
      return widget.autoSpare.moreFields.toJson();
    }
  }

  // Helper method to get part number
  String _getPartNumber() {
    try {
      final specs = _getProductSpecifications();
      if (specs != null && specs['part_number'] != null) {
        final partNumber = specs['part_number'].toString().trim();
        if (partNumber.isEmpty) return "-";
        // Capitalize first letter
        return partNumber.substring(0, 1).toUpperCase() +
            partNumber.substring(1);
      }

      return "-";
    } catch (e) {
      print('Error getting part number: $e');
      return "-";
    }
  }

  // Helper method to get transmission type
  String _getTransmissionType() {
    try {
      final specs = _getProductSpecifications();
      if (specs != null && specs['transmission_type'] != null) {
        final transmissionType = specs['transmission_type'].toString().trim();
        if (transmissionType.isEmpty) return "-";
        // Capitalize first letter
        return transmissionType.substring(0, 1).toUpperCase() +
            transmissionType.substring(1);
      }

      // Check if there's a vehicle_type field that might indicate transmission
      if (specs != null && specs['vehicle_type'] != null) {
        final vehicleType = specs['vehicle_type'].toString().trim();
        if (vehicleType.isEmpty) return "-";
        // Capitalize first letter
        return vehicleType.substring(0, 1).toUpperCase() +
            vehicleType.substring(1);
      }

      return "-";
    } catch (e) {
      print('Error getting transmission type: $e');
      return "-";
    }
  }

  // Helper method to get mileage
  String _getMileage() {
    try {
      final specs = _getProductSpecifications();
      if (specs != null && specs['mileage'] != null) {
        final mileage = specs['mileage'].toString().trim();
        if (mileage.isEmpty || mileage == "0") return "-";
        return "$mileage km";
      }

      return "-";
    } catch (e) {
      print('Error getting mileage: $e');
      return "-";
    }
  }

  // Helper method to get fuel type
  String _getFuelType() {
    try {
      final specs = _getProductSpecifications();
      if (specs != null && specs['fuel_type'] != null) {
        final fuelType = specs['fuel_type'].toString().trim();
        if (fuelType.isEmpty) return "-";
        // Capitalize first letter
        return fuelType.substring(0, 1).toUpperCase() + fuelType.substring(1);
      }

      return "-";
    } catch (e) {
      print('Error getting fuel type: $e');
      return "-";
    }
  }

  // Helper method to get body type
  String _getBodyType() {
    try {
      final specs = _getProductSpecifications();
      if (specs != null && specs['body_type'] != null) {
        final bodyType = specs['body_type'].toString().trim();
        if (bodyType.isEmpty) return "-";
        // Capitalize first letter
        return bodyType.substring(0, 1).toUpperCase() + bodyType.substring(1);
      }

      return "-";
    } catch (e) {
      print('Error getting body type: $e');
      return "-";
    }
  }

  // Helper method to get engine size
  String _getEngineSize() {
    try {
      final specs = _getProductSpecifications();
      if (specs != null && specs['engine_size'] != null) {
        final engineSize = specs['engine_size'].toString().trim();
        if (engineSize.isEmpty) return "-";
        // Capitalize first letter
        return engineSize.substring(0, 1).toUpperCase() +
            engineSize.substring(1);
      }

      return "-";
    } catch (e) {
      print('Error getting engine size: $e');
      return "-";
    }
  }

  // Helper method to get vehicle type display name
  String _getVehicleTypeDisplay() {
    try {
      final specs = _getProductSpecifications();
      if (specs != null && specs['vehicle_type'] != null) {
        final vehicleType = specs['vehicle_type'].toString();
        switch (vehicleType) {
          case 'PASSENGER_CAR':
            return 'Passenger Car';
          case 'COMMERCIAL_VEHICLE':
            return 'Commercial Vehicle';
          case 'MOTORCYCLE':
            return 'Motorcycle';
          case 'TRUCK':
            return 'Truck';
          default:
            if (vehicleType.isEmpty) return "-";
            return vehicleType.substring(0, 1).toUpperCase() +
                vehicleType.substring(1);
        }
      }

      return "-";
    } catch (e) {
      print('Error getting vehicle type: $e');
      return "-";
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'VEHICLE_SPARES':
        return 'Vehicle Spares';
      case 'TYRES_RIMS':
        return 'Tyres & Rims';
      case 'ELECTRONICS':
        return 'Electronics';
      default:
        return category;
    }
  }

  // Helper method to get product images from request
  List<String> _getProductImages() {
    try {
      if (widget.request.productImages?.isNotEmpty == true) {
        return widget.request.productImages!;
      }
      if (widget.request.images?.isNotEmpty == true) {
        return widget.request.images!;
      }
      return [];
    } catch (e) {
      print('Error getting product images: $e');
      return [];
    }
  }

  // Image preview dialog method
  void _showImagePreview(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) {
            int currentIndex = initialIndex;
            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PageView.builder(
                    controller: PageController(initialPage: initialIndex),
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _getFullImageUrl(images[index]),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[900],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              (loadingProgress
                                                      .expectedTotalBytes ??
                                                  1)
                                        : null,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image Failed to Load',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 100),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} of ${images.length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  // Helper method to get VIN image URL
  String? _getVinImageUrl() {
    try {
      // Get VIN image from ProductRequestItem (API data)
      if (widget.request.vinPhotoUrl != null &&
          widget.request.vinPhotoUrl!.isNotEmpty) {
        return widget.request.vinPhotoUrl;
      }

      return null;
    } catch (e) {
      print('Error getting VIN image: $e');
      return null;
    }
  }

  // Helper method to get full image URL (using the existing method from parent)
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

  // Show VIN image in full screen preview
  void _showVinImagePreview() {
    final vinUrl = _getVinImageUrl();
    if (vinUrl == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VIN Image',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // VIN image
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _getFullImageUrl(vinUrl),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.white70,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load VIN image',
                                style: GoogleFonts.manrope(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCircle(String value, String label) {
    // Parse the value to get current progress
    int currentValue = int.tryParse(value) ?? 0;

    // Determine max value based on label
    int maxValue;
    switch (label.toLowerCase()) {
      case 'd':
        maxValue = 31;
        break;
      case 'w':
        maxValue = 4;
        break;
      case 'y':
        maxValue = 365; // or whatever max you want for years
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

  String _getRemainingTime(
    DateTime? createdAt,
    String urgencyTimeline,
    String unit,
  ) {
    if (createdAt == null) return "0";

    // Calculate the deadline based on urgency timeline
    DateTime deadline;
    switch (urgencyTimeline) {
      case 'ASAP':
        deadline = createdAt.add(Duration(hours: 12)); // ASAP is 12 hours
        break;
      case '12_HOURS':
        deadline = createdAt.add(Duration(hours: 12));
        break;
      case '24_HOURS':
        deadline = createdAt.add(Duration(hours: 24));
        break;
      case '2-3_DAYS':
        deadline = createdAt.add(
          Duration(days: 3),
        ); // Use 3 days for 2-3 days range
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
        deadline = createdAt.add(Duration(days: 7)); // Default to 1 week
    }

    // Calculate remaining time
    final remaining = deadline.difference(DateTime.now());

    // If time has expired, return 0
    if (remaining.isNegative) {
      return "0";
    }

    switch (unit) {
      case 'days':
        return remaining.inDays.toString();
      case 'hours':
        // Hours remaining after accounting for days (0-23)
        final remainingHours = remaining.inHours % 24;
        return remainingHours.toString();
      case 'minutes':
        // Minutes remaining after accounting for hours (0-59)
        final remainingMinutes = remaining.inMinutes % 60;
        return remainingMinutes.toString();
      case 'seconds':
        // Seconds remaining after accounting for minutes (0-59)
        final remainingSeconds = remaining.inSeconds % 60;
        return remainingSeconds.toString();
      default:
        return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Close button header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Spare Details - Request #${widget.index}",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 32),
                  Padding(
                    padding: EdgeInsets.only(left: 64, right: 64),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        constraints: BoxConstraints(maxWidth: 1600),
                        decoration: BoxDecoration(
                          color: Constants.dtaColorLight.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Constants.ctaColorLight,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(widget.request.createdAt),
                                      style: GoogleFonts.manrope(
                                        color: Colors.grey.shade600,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "REQUEST #${widget.index}",
                                      style: GoogleFonts.manrope(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (!_cancelledRequests.contains(
                                      _getRequestId(widget.request),
                                    ))
                                      InkWell(
                                        onTap: () {
                                          _showCancelRequestDialog();
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "Cancel",
                                            style: GoogleFonts.manrope(
                                              color: Colors.red.shade500,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    //SizedBox(width: 12),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: 8,
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    child: Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: Constants.ctaColorLight,
                                        borderRadius: BorderRadius.circular(36),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Description ",
                                              style: GoogleFonts.manrope(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),

                                            SizedBox(height: 12),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _getRequestDescription(
                                            widget.request,
                                          ),
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),

                                        // Category
                                        Text(
                                          _getCategoryDisplayName(
                                            widget.request.category,
                                          ),
                                          style: GoogleFonts.manrope(
                                            color: Colors.orange.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        _buildTimerCircle(
                                          _getRemainingTime(
                                            widget.request.createdAt,
                                            _mapTimeframeToUrgency(
                                              widget
                                                  .autoSpare
                                                  .partDetails
                                                  .urgency,
                                            ),
                                            'days',
                                          ),
                                          "D",
                                        ),
                                        SizedBox(width: 12),
                                        _buildTimerCircle(
                                          _getRemainingTime(
                                            widget.request.createdAt,
                                            _mapTimeframeToUrgency(
                                              widget
                                                  .autoSpare
                                                  .partDetails
                                                  .urgency,
                                            ),
                                            'hours',
                                          ),
                                          "H",
                                        ),
                                        SizedBox(width: 12),
                                        _buildTimerCircle(
                                          _getRemainingTime(
                                            widget.request.createdAt,
                                            _mapTimeframeToUrgency(
                                              widget
                                                  .autoSpare
                                                  .partDetails
                                                  .urgency,
                                            ),
                                            'minutes',
                                          ),
                                          "M",
                                        ),
                                        SizedBox(width: 12),

                                        _buildTimerCircle(
                                          _getRemainingTime(
                                            widget.request.createdAt,
                                            _mapTimeframeToUrgency(
                                              widget
                                                  .autoSpare
                                                  .partDetails
                                                  .urgency,
                                            ),
                                            'seconds',
                                          ),
                                          "S",
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // Status dots - showing remaining time
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  Padding(
                    padding: EdgeInsets.only(left: 64, right: 64),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1600),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vehicle Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Vehicle Details",
                                Constants.ctaColorLight,
                                [
                                  _buildDetailItem(
                                    "VIN Number",
                                    widget.autoSpare.vehicleDetails.vin,
                                    showImage: true,
                                  ),
                                  _buildDetailItem(
                                    "Manufacturer",
                                    widget
                                        .autoSpare
                                        .vehicleDetails
                                        .manufacturer,
                                  ),
                                  _buildDetailItem(
                                    "Makes & Models",
                                    widget.autoSpare.vehicleDetails.makeModel,
                                  ),
                                  _buildDetailItem(
                                    "Year",
                                    widget.autoSpare.vehicleDetails.year,
                                  ),
                                  _buildDetailItem(
                                    "Type",
                                    widget.autoSpare.vehicleDetails.type,
                                  ),
                                  _buildDetailItem(
                                    "Vehicle",
                                    "${widget.autoSpare.vehicleDetails.makeModel} ${widget.autoSpare.vehicleDetails.year}",
                                  ),
                                  _buildDetailItem(
                                    "New/Used Part",
                                    widget.autoSpare.vehicleDetails.condition,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Part Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Part Details",
                                Colors.orange,
                                [
                                  _buildDetailItem(
                                    "Part Name/Description",
                                    widget.autoSpare.partDetails.partName,
                                  ),
                                  _buildDetailItem(
                                    "Quantity",
                                    widget.autoSpare.partDetails.quantity
                                        .toString(),
                                  ),
                                  _buildDetailItem(
                                    "Your Location",
                                    widget.autoSpare.partDetails.location,
                                  ),
                                  _buildDetailItem(
                                    "Max Distance You Want to Travel (km)",
                                    widget.autoSpare.partDetails.maxDistanceKm
                                        .toString(),
                                  ),
                                  _buildDetailItem(
                                    "How soon do you need to buy this product?",
                                    widget.autoSpare.partDetails.urgency,
                                  ),
                                  _buildDetailItem(
                                    "Description of the Product",
                                    widget
                                        .autoSpare
                                        .partDetails
                                        .productDescription,
                                  ),
                                  _buildDetailItem(
                                    "Product Images",
                                    "",
                                    isProductImages: true,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // More Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "More Details",
                                Colors.orange,
                                [
                                  _buildDetailItem(
                                    "Part Number",
                                    _getPartNumber(), // Use helper method
                                  ),
                                  /* _buildDetailItem(
                                    "Engine Size",
                                    _getEngineSize(), // Add engine size
                                  ),*/
                                  _buildDetailItem(
                                    "Transmission Type",
                                    _getTransmissionType(), // Use helper method
                                  ),
                                  _buildDetailItem(
                                    "Mileage of Vehicle",
                                    _getMileage(), // Use helper method
                                  ),
                                  _buildDetailItem(
                                    "Fuel Type",
                                    _getFuelType(), // Use helper method
                                  ),
                                  _buildDetailItem(
                                    "Body Type",
                                    _getBodyType(), // Use helper method
                                  ),
                                  _buildDetailItem(
                                    "Enquiry Time",

                                    _formatDateAndTime(
                                      widget.request.createdAt,
                                    ),
                                    // Use helper for urgency
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  String _formatDateAndTime(DateTime? date) {
    if (date == null) return "Date unavailable";

    // Format date as DD/MM/YYYY
    String formattedDate =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

    // Format time as HH:MM
    String formattedTime =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return "$formattedDate at $formattedTime";
  }

  Widget _buildDetailCard(
    String title,
    Color borderColor,
    List<Widget> children,
  ) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          //border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored border
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
            // Content
            SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: borderColor),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool showImage = false,
    bool isProductImages = false,
  }) {
    print(
      '🔍 _buildDetailItem: label="$label", value="$value", showImage=$showImage, isProductImages=$isProductImages',
    );
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          if (showImage) ...[
            // Show actual VIN image - clickable
            GestureDetector(
              onTap: () {
                if (_getVinImageUrl() != null) {
                  _showVinImagePreview();
                }
              },
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _getVinImageUrl() != null
                      ? Stack(
                          children: [
                            Image.network(
                              _getFullImageUrl(_getVinImageUrl()!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                (loadingProgress
                                                        .expectedTotalBytes ??
                                                    1)
                                          : null,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[400],
                                          size: 24,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'VIN Image\nNot Available',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Add clickable indicator
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'No VIN Image\nProvided',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 6),
          ],
          if (isProductImages) ...[
            Builder(
              builder: (context) {
                final productImages = _getProductImages();

                if (productImages.isEmpty) {
                  return Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No Product Images\nProvided',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Container(
                  height: 120,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Responsive grid for images within cards
                      int crossAxisCount = constraints.maxWidth > 300
                          ? 4
                          : constraints.maxWidth > 200
                          ? 3
                          : 2;
                      return GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: productImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showImagePreview(
                              context,
                              productImages,
                              index,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(0xFFE0E0E0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _getFullImageUrl(productImages[index]),
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                              : null,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ],
          if (!showImage && !isProductImages) ...[
            Builder(
              builder: (context) {
                final displayValue = value.isEmpty ? "-" : value;
                print(
                  '🔍 Text Widget: Rendering "$displayValue" for label "$label"',
                );
                return Text(
                  displayValue,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Constants.ftaColorLight,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ],
          if ((showImage || isProductImages) && value.isNotEmpty) ...[
            Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Cancel Request Dialog for Detail Screens
  void _showCancelRequestDialog() {
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
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.red[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Cancel Request?",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Are you sure you want to cancel this product request? This action cannot be undone and all associated bids will be removed.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
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
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          "Keep Request",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _cancelRequest();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Yes, Cancel",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
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

  // Cancel Request API Call for SparesDetailScreen
  Future<void> _cancelRequest() async {
    final requestId = _getRequestId(widget.request);

    print('=== DEBUG: Cancel Request from SparesDetailScreen ===');
    print('Request type: ${widget.request.runtimeType}');
    print('Request ID: $requestId');

    // Validate request ID before making API call
    if (requestId == 'Unknown' || requestId == '0') {
      _showErrorSnackBar("Invalid request ID: Cannot cancel request");
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Constants.ftaColorLight),
                SizedBox(height: 16),
                Text(
                  "Cancelling request...",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // API call to cancel the request
      final response = await http.delete(
        Uri.parse(
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/$requestId/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Success - close detail screen and return to dashboard
        Navigator.of(context).pop(); // Close detail screen

        // Show success dialog
        _showCancelSuccessDialog(requestId);

        // Trigger refresh of main dashboard after closing success dialog
        Future.delayed(Duration(seconds: 2), () {
          if (context.mounted) {
            // Force a rebuild which will trigger parent refresh
            setState(() {});
          }
        });
      } else {
        throw Exception('Failed to cancel request: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error cancelling request: $e');
      _showErrorSnackBar("Failed to cancel request. Please try again.");
    }
  }

  // Helper method to get Request ID from different request types
  String _getRequestId2(dynamic request) {
    try {
      if (request is Map) {
        // Try various possible locations for the request ID
        return request['request_id']?.toString() ??
            request['id']?.toString() ??
            request['uuid']?.toString() ??
            'Unknown';
      } else {
        // Try accessing common properties
        if (request?.id != null) {
          return request.id.toString();
        }
        if (request?.requestId != null) {
          return request.requestId.toString();
        }
        if (request?.uuid != null) {
          return request.uuid.toString();
        }
      }
      return 'Unknown';
    } catch (e) {
      print('Error getting request ID: $e');
      return 'Unknown';
    }
  }

  // Helper method to show error messages
  void _showErrorSnackBar(String message) {
    MotionToast.error(
      title: Text(
        'Error',
        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      description: Text(
        message,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      width: 350,
      height: 80,
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }

  Widget _buildStatusDot(String letter, String time) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Constants.ftaColorLight.withOpacity(0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(360),
            boxShadow: [
              BoxShadow(
                color: Constants.ftaColorLight.withOpacity(0.2),
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 1),
              ),
            ],
          ),
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
        SizedBox(height: 4),
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

  String _getUrgencyDisplayName(dynamic request) {
    try {
      String urgencyTimeline = "";

      // Try to get from ProductRequestItem
      if (request.runtimeType.toString().contains('ProductRequestItem')) {
        urgencyTimeline = request.urgencyTimeline ?? "";
      }

      // If empty, try to get from autoSpare
      if (urgencyTimeline.isEmpty &&
          widget.autoSpare?.partDetails?.urgency != null) {
        urgencyTimeline = widget.autoSpare.partDetails.urgency;
      }

      switch (urgencyTimeline) {
        case 'ASAP':
          return 'ASAP (12 hours)';
        case '12_HOURS':
          return '12 Hours';
        case '24_HOURS':
          return '24 Hours';
        case '2-3_DAYS':
          return '2-3 Days';
        case '1_WEEK':
          return '1 Week';
        case '2_WEEKS':
          return '2 Weeks';
        case '1_MONTH':
          return '1 Month';
        default:
          if (urgencyTimeline.isEmpty) return "-";
          return urgencyTimeline.substring(0, 1).toUpperCase() +
              urgencyTimeline.substring(1);
      }
    } catch (e) {
      print('Error getting urgency display name: $e');
      return "-";
    }
  }

  void _showCancelSuccessDialog(String requestId) {
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
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.green[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Request Cancelled",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Your request #$requestId has been successfully cancelled. The grid will refresh automatically.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      // Remove the cancelled request from global state via callback
                      if (widget.onRequestCancelled != null) {
                        widget.onRequestCancelled!(requestId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Done",
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
}

class ConsumerElectronicsDetailScreen extends StatefulWidget {
  final int index;
  final ConsumerElectronicsRequest request;
  final ConsumerElectronics consumerElectronics;
  final List<dynamic> bids;
  final Function(String)? onRequestCancelled;

  const ConsumerElectronicsDetailScreen({
    super.key,
    required this.request,
    required this.consumerElectronics,
    required this.bids,
    required this.index,
    this.onRequestCancelled,
  });

  @override
  State<ConsumerElectronicsDetailScreen> createState() =>
      _ConsumerElectronicsDetailScreenState();

  static void showAsDialog(
    BuildContext context, {
    required int index,
    required ConsumerElectronicsRequest request,
    required ConsumerElectronics consumerElectronics,
    required List<dynamic> bids,
    Function(String)? onRequestCancelled,
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
            child: ConsumerElectronicsDetailScreen(
              index: index,
              request: request,
              consumerElectronics: consumerElectronics,
              bids: bids,
              onRequestCancelled: onRequestCancelled,
            ),
          ),
        );
      },
    );
  }

  static String _mapTimeframeToUrgency(String? timeframe) {
    switch (timeframe) {
      case 'ASAP':
        return 'ASAP';
      case '12 Hours':
        return '12_HOURS';
      case '24 Hours':
        return '12_HOURS'; // Map to 12_HOURS since 24_HOURS is not valid
      case '2-3 Days':
        return '1_WEEK';
      case '1 Week':
        return '1_WEEK';
      case '2 Weeks':
        return '1_MONTH'; // Map to 1_MONTH since 2_WEEKS is not valid
      case 'Within a Month':
        return '1_MONTH';
      case 'Immediately':
        return '12_HOURS';
      case 'Within a week':
        return '1_WEEK';
      case 'Within a month':
        return '1_MONTH';
      default:
        return '1_WEEK'; // Default to 1_WEEK
    }
  }
}

class _ConsumerElectronicsDetailScreenState
    extends State<ConsumerElectronicsDetailScreen> {
  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
    print(widget.request);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Start auto-refresh timer that updates every second
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild every second, updating timers and dynamic content
        });
      }
    });
  }

  SortOption? _currentSort;
  Set<String> _cancelledRequests = {};

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'VEHICLE_SPARES':
        return 'Vehicle Spares';
      case 'TYRES_RIMS':
        return 'Tyres & Rims';
      case 'ELECTRONICS':
        return 'Electronics';
      default:
        return category;
    }
  }

  // Image preview dialog method
  void _showImagePreview(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) {
            int currentIndex = initialIndex;
            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PageView.builder(
                    controller: PageController(initialPage: initialIndex),
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[900],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              (loadingProgress
                                                      .expectedTotalBytes ??
                                                  1)
                                        : null,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image Failed to Load',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 100),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} of ${images.length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  Widget _buildTimerCircle(String value, String label) {
    // Parse the value to get current progress
    int currentValue = int.tryParse(value) ?? 0;

    // Determine max value based on label
    int maxValue;
    switch (label.toLowerCase()) {
      case 'd':
        maxValue = 31;
        break;
      case 'w':
        maxValue = 4;
        break;
      case 'y':
        maxValue = 365; // or whatever max you want for years
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

  String _getRemainingTime(
    DateTime? createdAt,
    String urgencyTimeline,
    String unit,
  ) {
    if (createdAt == null) return "0";

    // Calculate the deadline based on urgency timeline
    DateTime deadline;
    switch (urgencyTimeline) {
      case 'ASAP':
        deadline = createdAt.add(Duration(hours: 12)); // ASAP is 12 hours
        break;
      case '12_HOURS':
        deadline = createdAt.add(Duration(hours: 12));
        break;
      case '24_HOURS':
        deadline = createdAt.add(Duration(hours: 24));
        break;
      case '2-3_DAYS':
        deadline = createdAt.add(
          Duration(days: 3),
        ); // Use 3 days for 2-3 days range
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
        deadline = createdAt.add(Duration(days: 7)); // Default to 1 week
    }

    // Calculate remaining time
    final remaining = deadline.difference(DateTime.now());

    // If time has expired, return 0
    if (remaining.isNegative) {
      return "0";
    }

    switch (unit) {
      case 'days':
        return remaining.inDays.toString();
      case 'hours':
        // Hours remaining after accounting for days (0-23)
        final remainingHours = remaining.inHours % 24;
        return remainingHours.toString();
      case 'minutes':
        // Minutes remaining after accounting for hours (0-59)
        final remainingMinutes = remaining.inMinutes % 60;
        return remainingMinutes.toString();
      case 'seconds':
        // Seconds remaining after accounting for minutes (0-59)
        final remainingSeconds = remaining.inSeconds % 60;
        return remainingSeconds.toString();
      default:
        return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Close button header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Electronics Details - Request #${widget.index}",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 32),
                  Padding(
                    padding: EdgeInsets.only(left: 64, right: 64),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        constraints: BoxConstraints(maxWidth: 1600),
                        decoration: BoxDecoration(
                          color: Constants.dtaColorLight.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Constants.ctaColorLight,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(widget.request.createdAt),
                                      style: GoogleFonts.manrope(
                                        color: Colors.grey.shade600,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "REQUEST #${widget.index}",
                                      style: GoogleFonts.manrope(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (!_cancelledRequests.contains(
                                      _getRequestId(widget.request),
                                    ))
                                      InkWell(
                                        onTap: () {
                                          _showCancelRequestDialog();
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "Cancel",
                                            style: GoogleFonts.manrope(
                                              color: Colors.red.shade500,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    //SizedBox(width: 12),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: 8,
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    child: Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: Constants.ctaColorLight,
                                        borderRadius: BorderRadius.circular(36),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Description -",
                                              style: GoogleFonts.manrope(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Spacer(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _buildTimerCircle(
                                                  _getRemainingTime(
                                                    widget.request.createdAt,
                                                    _mapTimeframeToUrgency(
                                                      widget
                                                          .consumerElectronics
                                                          .budgetTimeline
                                                          .urgency,
                                                    ),
                                                    'days',
                                                  ),
                                                  "D",
                                                ),
                                                SizedBox(width: 12),
                                                _buildTimerCircle(
                                                  _getRemainingTime(
                                                    widget.request.createdAt,
                                                    _mapTimeframeToUrgency(
                                                      widget
                                                          .consumerElectronics
                                                          .budgetTimeline
                                                          .urgency,
                                                    ),
                                                    'hours',
                                                  ),
                                                  "H",
                                                ),
                                                SizedBox(width: 12),
                                                _buildTimerCircle(
                                                  _getRemainingTime(
                                                    widget.request.createdAt,
                                                    _mapTimeframeToUrgency(
                                                      widget
                                                          .consumerElectronics
                                                          .budgetTimeline
                                                          .urgency,
                                                    ),
                                                    'minutes',
                                                  ),
                                                  "M",
                                                ),
                                                SizedBox(width: 12),
                                                _buildTimerCircle(
                                                  _getRemainingTime(
                                                    widget.request.createdAt,
                                                    _mapTimeframeToUrgency(
                                                      widget
                                                          .consumerElectronics
                                                          .budgetTimeline
                                                          .urgency,
                                                    ),
                                                    'seconds',
                                                  ),
                                                  "S",
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _getRequestDescription(
                                            widget.request,
                                          ),
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),

                                        // Category
                                        Text(
                                          _getCategoryDisplayName(
                                            widget.request.category,
                                          ),
                                          style: GoogleFonts.manrope(
                                            color: Colors.orange.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // Status dots - showing remaining time
                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Padding(
                    padding: EdgeInsets.only(left: 64, right: 64),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1600),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Product Details",
                                Constants.ctaColorLight,
                                [
                                  _buildDetailItem(
                                    "Type of Electronics",
                                    widget
                                        .consumerElectronics
                                        .productDetails
                                        .typeOfElectronics,
                                  ),
                                  _buildDetailItem(
                                    "Brand Preference",
                                    widget
                                        .consumerElectronics
                                        .productDetails
                                        .brandPreference,
                                  ),
                                  _buildDetailItem(
                                    "Model Series",
                                    widget
                                            .consumerElectronics
                                            .productDetails
                                            .modelSeries ??
                                        "-",
                                  ),
                                  _buildDetailItem(
                                    "Quantity Needed",
                                    widget
                                        .consumerElectronics
                                        .productDetails
                                        .quantityNeeded
                                        .toString(),
                                  ),
                                  _buildDetailItem(
                                    "Purpose",
                                    widget
                                        .consumerElectronics
                                        .featuresAndSpecs
                                        .purpose,
                                  ),
                                  _buildDetailItem(
                                    "Condition Preference",
                                    widget
                                        .consumerElectronics
                                        .featuresAndSpecs
                                        .conditionPreference,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Budget & Timeline Card
                            Expanded(
                              child: _buildDetailCard(
                                "Budget & Timeline",
                                Colors.orange,
                                [
                                  _buildDetailItem(
                                    "Min Price",
                                    widget
                                                .consumerElectronics
                                                .budgetTimeline
                                                .minPrice !=
                                            null
                                        ? "R${widget.consumerElectronics.budgetTimeline.minPrice!.toStringAsFixed(2)}"
                                        : "-",
                                  ),
                                  _buildDetailItem(
                                    "Max Price",
                                    widget
                                                .consumerElectronics
                                                .budgetTimeline
                                                .maxPrice !=
                                            null
                                        ? "R${widget.consumerElectronics.budgetTimeline.maxPrice!.toStringAsFixed(2)}"
                                        : "-",
                                  ),
                                  _buildDetailItem(
                                    "Urgency",
                                    widget
                                        .consumerElectronics
                                        .budgetTimeline
                                        .urgency,
                                  ),
                                  _buildDetailItem(
                                    "Needs Installation",
                                    widget
                                            .consumerElectronics
                                            .budgetTimeline
                                            .needsInstallation
                                        ? "Yes"
                                        : "No",
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Features & Specifications Card
                            Text(
                              widget
                                  .consumerElectronics
                                  .featuresAndSpecs
                                  .requiredFeatures
                                  .toString(),
                            ),
                            Expanded(
                              child: _buildDetailCard(
                                "Features & Specifications",
                                Colors.orange,
                                [
                                  _buildDetailItem(
                                    "Required Features",
                                    widget
                                            .consumerElectronics
                                            .featuresAndSpecs
                                            .requiredFeatures ??
                                        "-",
                                  ),
                                  _buildDetailItem(
                                    "Additional Comments",
                                    widget
                                            .consumerElectronics
                                            .featuresAndSpecs
                                            .additionalComments ??
                                        "-",
                                  ),
                                  _buildDetailItem(
                                    "Documents/Images",
                                    "",
                                    isProductImages: true,
                                    imageList: widget
                                        .consumerElectronics
                                        .featuresAndSpecs
                                        .documentsOrImages,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Widget _buildDetailCard(
    String title,
    Color borderColor,
    List<Widget> children,
  ) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          //border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored border
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
            // Content
            SizedBox(height: 16),

            IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: borderColor),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool showImage = false,
    bool isProductImages = false,
    List<String>? imageList,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Constants.ftaColorLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          if (showImage) ...[
            // Show placeholder image
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/mechanic_working.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6),
          ],
          if (isProductImages) ...[
            if (imageList != null && imageList.isNotEmpty) ...[
              Container(
                height: 120,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid for images within cards
                    int crossAxisCount = constraints.maxWidth > 300
                        ? 4
                        : constraints.maxWidth > 200
                        ? 3
                        : 2;
                    return GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: imageList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _showImagePreview(context, imageList, index),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFE0E0E0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageList[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                            : null,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ] else ...[
              // No images available
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'No Product Images\nProvided',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!showImage) ...[
              Text(
                value.isEmpty ? "-" : value,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Constants.ftaColorLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (showImage && value.isNotEmpty) ...[
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showCancelRequestDialog() {
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
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.red[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Cancel Request?",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Are you sure you want to cancel this product request? This action cannot be undone and all associated bids will be removed.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
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
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          "Keep Request",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog first
                          _cancelRequest(); // Then cancel
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Yes, Cancel",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
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

  void _showCancelSuccessDialog(String requestId) {
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
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.green[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Request Cancelled",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Your request #$requestId has been successfully cancelled. The grid will refresh automatically.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      // Remove the cancelled request from global state via callback
                      if (widget.onRequestCancelled != null) {
                        widget.onRequestCancelled!(requestId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Done",
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

  static String _mapTimeframeToUrgency(String? timeframe) {
    switch (timeframe) {
      case 'ASAP':
        return 'ASAP';
      case '12 Hours':
        return '12_HOURS';
      case '24 Hours':
        return '12_HOURS'; // Map to 12_HOURS since 24_HOURS is not valid
      case '2-3 Days':
        return '1_WEEK';
      case '1 Week':
        return '1_WEEK';
      case '2 Weeks':
        return '1_MONTH'; // Map to 1_MONTH since 2_WEEKS is not valid
      case 'Within a Month':
        return '1_MONTH';
      case 'Immediately':
        return '12_HOURS';
      case 'Within a week':
        return '1_WEEK';
      case 'Within a month':
        return '1_MONTH';
      default:
        return '1_WEEK'; // Default to 1_WEEK
    }
  }

  Future<void> _cancelRequest() async {
    final requestId = _getRequestId(widget.request);

    print('=== DEBUG: Cancel Request from SparesDetailScreen ===');
    print('Request type: ${widget.request.runtimeType}');
    print('Request ID: $requestId');

    // Validate request ID before making API call
    if (requestId == 'Unknown' || requestId == '0') {
      _showErrorSnackBar("Invalid request ID: Cannot cancel request");
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Constants.ftaColorLight),
                SizedBox(height: 16),
                Text(
                  "Cancelling request...",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // API call to cancel the request
      final response = await http.delete(
        Uri.parse(
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/$requestId/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Success - close detail screen and return to dashboard
        Navigator.of(context).pop(); // Close detail screen

        // Show success dialog
        _showCancelSuccessDialog(requestId);

        // Trigger refresh of main dashboard after closing success dialog
        Future.delayed(Duration(seconds: 2), () {
          if (context.mounted) {
            // Force a rebuild which will trigger parent refresh
            setState(() {});
          }
        });
      } else {
        throw Exception('Failed to cancel request: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error cancelling request: $e');
      _showErrorSnackBar("Failed to cancel request. Please try again.");
    }
  }

  void _showErrorSnackBar(String message) {
    MotionToast.error(
      title: Text(
        'Error',
        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      description: Text(
        message,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      width: 350,
      height: 80,
      toastDuration: const Duration(seconds: 3),
    ).show(context);
  }

  void _removeRequestFromGlobalState(String requestId) {}
}

class RimTyreDetailScreen extends StatefulWidget {
  final int index;
  final RimTyreRequest request;
  final RimTyre rimTyre;
  final List<dynamic> bids;
  final Function(String)? onRequestCancelled;

  const RimTyreDetailScreen({
    Key? key,
    required this.request,
    required this.rimTyre,
    required this.bids,
    required this.index,
    this.onRequestCancelled,
  }) : super(key: key);

  @override
  State<RimTyreDetailScreen> createState() => _RimTyreDetailScreenState();

  static void showAsDialog(
    BuildContext context, {
    required int index,
    required RimTyreRequest request,
    required RimTyre rimTyre,
    required List<dynamic> bids,
    Function(String)? onRequestCancelled,
  }) {
    print("fgggh " + request.toJson().toString());
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
            child: RimTyreDetailScreen(
              index: index,
              request: request,
              rimTyre: rimTyre,
              bids: bids,
              onRequestCancelled: onRequestCancelled,
            ),
          ),
        );
      },
    );
  }
}

class _RimTyreDetailScreenState extends State<RimTyreDetailScreen> {
  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Start auto-refresh timer that updates every second
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild every second, updating timers and dynamic content
        });
      }
    });
  }

  String _getRequestId(dynamic request) {
    // Handle ProductRequestItem from API
    if (request is RimTyreRequest) {
      return request.id ?? "";
    }
    // Handle other request types that have 'id' property
    try {
      return request.id?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  SortOption? _currentSort;
  Set<String> _cancelledRequests = {};

  // Image preview dialog method
  void _showImagePreview(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(20),
        child: StatefulBuilder(
          builder: (context, setState) {
            int currentIndex = initialIndex;
            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: PageView.builder(
                    controller: PageController(initialPage: initialIndex),
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[900],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              (loadingProgress
                                                      .expectedTotalBytes ??
                                                  1)
                                        : null,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[900],
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.tire_repair,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Image Failed to Load',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 100),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} of ${images.length}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'VEHICLE_SPARES':
        return 'Vehicle Spares';
      case 'TYRES_RIMS':
        return 'Tyres & Rims';
      case 'ELECTRONICS':
        return 'Electronics';
      default:
        return category;
    }
  }

  Widget _buildTimerCircle(String value, String label) {
    // Parse the value to get current progress
    int currentValue = int.tryParse(value) ?? 0;

    // Determine max value based on label
    int maxValue;
    switch (label.toLowerCase()) {
      case 'd':
        maxValue = 31;
        break;
      case 'w':
        maxValue = 4;
        break;
      case 'y':
        maxValue = 365; // or whatever max you want for years
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

  String _getRemainingTime(
    DateTime? createdAt,
    String urgencyTimeline,
    String unit,
  ) {
    if (createdAt == null) return "0";

    // Calculate the deadline based on urgency timeline
    DateTime deadline;
    switch (urgencyTimeline) {
      case 'ASAP':
        deadline = createdAt.add(Duration(hours: 12)); // ASAP is 12 hours
        break;
      case '12_HOURS':
        deadline = createdAt.add(Duration(hours: 12));
        break;
      case '24_HOURS':
        deadline = createdAt.add(Duration(hours: 24));
        break;
      case '2-3_DAYS':
        deadline = createdAt.add(
          Duration(days: 3),
        ); // Use 3 days for 2-3 days range
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
        deadline = createdAt.add(Duration(days: 7)); // Default to 1 week
    }

    // Calculate remaining time
    final remaining = deadline.difference(DateTime.now());

    // If time has expired, return 0
    if (remaining.isNegative) {
      return "0";
    }

    switch (unit) {
      case 'days':
        return remaining.inDays.toString();
      case 'hours':
        // Hours remaining after accounting for days (0-23)
        final remainingHours = remaining.inHours % 24;
        return remainingHours.toString();
      case 'minutes':
        // Minutes remaining after accounting for hours (0-59)
        final remainingMinutes = remaining.inMinutes % 60;
        return remainingMinutes.toString();
      case 'seconds':
        // Seconds remaining after accounting for minutes (0-59)
        final remainingSeconds = remaining.inSeconds % 60;
        return remainingSeconds.toString();
      default:
        return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Close button header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) {
                    print('🔍 HEADER: Building header with request data...');
                    print('🔍 HEADER: widget.rimTyre = ${widget.rimTyre}');
                    print(
                      '🔍 HEADER: widget.rimTyre.runtimeType = ${widget.rimTyre.runtimeType}',
                    );
                    print(
                      '🔍 HEADER: widget.rimTyre.runtimeType2 = ${widget.rimTyre}',
                    );
                    return Text(
                      "Rim/Tyre Details - Request #${widget.index}",
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 32),
                  Padding(
                    padding: EdgeInsets.only(left: 64, right: 64),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        constraints: BoxConstraints(maxWidth: 1600),
                        decoration: BoxDecoration(
                          color: Constants.dtaColorLight.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Constants.ctaColorLight,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(widget.request.createdAt),
                                      style: GoogleFonts.manrope(
                                        color: Colors.grey.shade600,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "REQUEST #${widget.index}",
                                      style: GoogleFonts.manrope(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    if (!_cancelledRequests.contains(
                                      _getRequestId(widget.request),
                                    ))
                                      InkWell(
                                        onTap: () {
                                          _showCancelRequestDialog();
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "Cancel ",
                                            style: GoogleFonts.manrope(
                                              color: Colors.red.shade500,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: 8,
                                      top: 4,
                                      bottom: 4,
                                    ),
                                    child: Container(
                                      width: 4,
                                      decoration: BoxDecoration(
                                        color: Constants.ctaColorLight,
                                        borderRadius: BorderRadius.circular(36),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Description -",
                                              style: GoogleFonts.manrope(
                                                color: Colors.grey.shade600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Spacer(),

                                            // Status dots - showing remaining time
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _getRequestDescription(
                                            widget.request,
                                          ),
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),

                                        // Category
                                        Text(
                                          _getCategoryDisplayName(
                                            widget.request.category,
                                          ),
                                          style: GoogleFonts.manrope(
                                            color: Colors.orange.shade600,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildTimerCircle(
                                        _getRemainingTime(
                                          widget.request.createdAt,
                                          _mapTimeframeToUrgency(
                                            widget
                                                .rimTyre
                                                .productDetails
                                                .urgency,
                                          ),
                                          'days',
                                        ),
                                        "D",
                                      ),
                                      SizedBox(width: 12),
                                      _buildTimerCircle(
                                        _getRemainingTime(
                                          widget.request.createdAt,
                                          _mapTimeframeToUrgency(
                                            widget
                                                .rimTyre
                                                .productDetails
                                                .urgency,
                                          ),
                                          'hours',
                                        ),
                                        "H",
                                      ),
                                      SizedBox(width: 12),
                                      _buildTimerCircle(
                                        _getRemainingTime(
                                          widget.request.createdAt,
                                          _mapTimeframeToUrgency(
                                            widget
                                                .rimTyre
                                                .productDetails
                                                .urgency,
                                          ),
                                          'minutes',
                                        ),
                                        "M",
                                      ),
                                      SizedBox(width: 12),
                                      _buildTimerCircle(
                                        _getRemainingTime(
                                          widget.request.createdAt,
                                          _mapTimeframeToUrgency(
                                            widget
                                                .rimTyre
                                                .productDetails
                                                .urgency,
                                          ),
                                          'seconds',
                                        ),
                                        "S",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Padding(
                    padding: EdgeInsets.only(left: 64, right: 64),
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 1600),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Product Details",
                                Constants.ctaColorLight,
                                [
                                  _buildDetailItem("Tyre Width (mm)", () {
                                    final value = widget
                                        .rimTyre
                                        .productDetails
                                        .tyreWidthMm;
                                    print(
                                      '🔍 UI: tyreWidthMm2 = $value (type: ${value.runtimeType})',
                                    );
                                    final result = value.toString() ?? 'null';
                                    print(
                                      '🔍 UI: tyreWidthMm result = "$result"',
                                    );
                                    return result;
                                  }()),
                                  _buildDetailItem("Sidewall Profile", () {
                                    final value = widget
                                        .rimTyre
                                        .productDetails
                                        .sidewallProfile;
                                    print(
                                      '🔍 UI: sidewallProfile = "$value" (type: ${value.runtimeType})',
                                    );
                                    final result = value ?? 'null';
                                    print(
                                      '🔍 UI: sidewallProfile result = "$result"',
                                    );
                                    return result;
                                  }()),
                                  _buildDetailItem(
                                    "Wheel Rim Diameter (inches)",
                                    () {
                                      final value = widget
                                          .rimTyre
                                          .productDetails
                                          .wheelRimDiameterInches;
                                      print(
                                        '🔍 UI: wheelRimDiameterInches = "$value" (type: ${value.runtimeType})',
                                      );
                                      final result = value ?? 'null';
                                      print(
                                        '🔍 UI: wheelRimDiameterInches result = "$result"',
                                      );
                                      return result;
                                    }(),
                                  ),
                                  _buildDetailItem("Tyre Type", () {
                                    final value =
                                        widget.rimTyre.productDetails.tyreType;
                                    print(
                                      '🔍 UI: tyreType = "$value" (type: ${value.runtimeType})',
                                    );
                                    final result = value ?? 'null';
                                    print('🔍 UI: tyreType result = "$result"');
                                    return result;
                                  }()),
                                  _buildDetailItem(
                                    "Quantity",
                                    widget.rimTyre.productDetails.quantity
                                            ?.toString() ??
                                        '0',
                                  ),
                                  _buildDetailItem(
                                    "Urgency",
                                    widget.rimTyre.productDetails.urgency ??
                                        'Not specified',
                                  ),
                                  _buildDetailItem(
                                    "Tyre Size",
                                    "${widget.rimTyre.productDetails.tyreWidthMm}/${widget.rimTyre.productDetails.sidewallProfile}R${widget.rimTyre.productDetails.wheelRimDiameterInches}",
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 32),
                            // Vehicle & Brand Details Card
                            Expanded(
                              child: _buildDetailCard(
                                "Vehicle & Brand Details",
                                Colors.orange,
                                [
                                  _buildDetailItem(
                                    "Vehicle Type",
                                    widget.rimTyre.moreFields.vehicleType ??
                                        'Not specified',
                                  ),
                                  _buildDetailItem("Preferred Brand", () {
                                    final value = widget
                                        .rimTyre
                                        .moreFields
                                        .preferredBrand;
                                    print(
                                      '🔍 UI: preferredBrand = "$value" (type: ${value.runtimeType})',
                                    );
                                    final result = value ?? 'null';
                                    print(
                                      '🔍 UI: preferredBrand result = "$result"',
                                    );
                                    return result;
                                  }()),
                                  _buildDetailItem(
                                    "Pitch Circle Diameter",
                                    widget
                                            .rimTyre
                                            .moreFields
                                            .pitchCircleDiameter ??
                                        'Not specified',
                                  ),
                                  _buildDetailItem(
                                    "Tyre Construction Type",
                                    widget
                                            .rimTyre
                                            .moreFields
                                            .tyreConstructionType ??
                                        'Not specified',
                                  ),
                                  _buildDetailItem(
                                    "Description",
                                    widget.rimTyre.moreFields.description ??
                                        'No description',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 32),
                            Expanded(
                              child: _buildDetailCard(
                                "Service Requirements1",
                                Colors.orange,
                                [
                                  _buildDetailItem(
                                    "Fitment Required",
                                    widget.rimTyre.moreFields.fitmentRequired ??
                                        'Not specified',
                                  ),
                                  _buildDetailItem(
                                    "Balancing Required",
                                    widget
                                            .rimTyre
                                            .moreFields
                                            .balancingRequired ??
                                        'Not specified',
                                  ),
                                  _buildDetailItem(
                                    "Tyre Rotation Required",
                                    widget
                                            .rimTyre
                                            .moreFields
                                            .tyreRotationRequired ??
                                        'Not specified',
                                  ),
                                  _buildDetailItem(
                                    "Product Images",
                                    "",
                                    isProductImages: true,
                                    imageList:
                                        widget.rimTyre.moreFields.imageUrls,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date unavailable";
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  Widget _buildDetailCard(
    String title,
    Color borderColor,
    List<Widget> children,
  ) {
    return CustomCard(
      elevation: 3,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          //border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with colored border
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
            // Content
            SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(width: 4, color: borderColor),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool showImage = false,
    bool isProductImages = false,
    List<String>? imageList,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              color: Constants.ftaColorLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          if (showImage) ...[
            // Show placeholder image
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/mechanic_working.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6),
          ],
          if (isProductImages) ...[
            if (imageList != null && imageList.isNotEmpty) ...[
              Container(
                height: 120,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive grid for images within cards
                    int crossAxisCount = constraints.maxWidth > 300
                        ? 4
                        : constraints.maxWidth > 200
                        ? 3
                        : 2;
                    return GridView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: imageList.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () =>
                              _showImagePreview(context, imageList, index),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Color(0xFFE0E0E0)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageList[index],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                            : null,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(
                                        Icons.tire_repair,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ] else ...[
              // No images available
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 30,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'No Product Images\nProvided',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!showImage) ...[
              Text(
                value.isEmpty ? "-" : value,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: Constants.ftaColorLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (showImage && value.isNotEmpty) ...[
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showCancelRequestDialog() {
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
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.red[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Cancel Request?",
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Are you sure you want to cancel this product request? This action cannot be undone and all associated bids will be removed.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
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
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          "Keep Request",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog first
                          _cancelRequest(); // Then cancel
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Yes, Cancel",
                          style: GoogleFonts.manrope(
                            fontSize: 14,
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

  Future<void> _cancelRequest() async {
    final requestId = _getRequestId(widget.request);

    // Show loading dialog
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
              CircularProgressIndicator(color: Constants.ctaColorLight),
              SizedBox(height: 16),
              Text(
                'Cancelling request...',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // API call to cancel the request
      final response = await http.delete(
        Uri.parse(
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/$requestId/',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Success - close detail screen and return to dashboard
        Navigator.of(context).pop(); // Close detail screen

        // Show success dialog
        _showCancelSuccessDialog(requestId);
      } else {
        throw Exception('Failed to cancel request: ${response.statusCode}');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error cancelling request: $e');
      _showErrorSnackBar("Failed to cancel request. Please try again.");
    }
  }

  void _showCancelSuccessDialog(String requestId) {
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
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Colors.green[600],
                    size: 30,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Request Cancelled",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  "Your request #$requestId has been successfully cancelled. The grid will refresh automatically.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();

                      // Remove the cancelled request from global state via callback
                      if (widget.onRequestCancelled != null) {
                        widget.onRequestCancelled!(requestId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Done",
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // REMOVED UNUSED METHODS - moved to correct scope if needed

  // Helper method to build stat item
  Widget _buildStatItem(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  // Helper method to build bid distribution chart
  Widget _buildBidDistributionChart(Map<String, int> stats) {
    final total = stats['total']!;
    if (total == 0) return SizedBox.shrink();

    final withBidsPercentage = (stats['withBids']! / total * 100)
        .roundToDouble();
    final withoutBidsPercentage = (stats['withoutBids']! / total * 100)
        .roundToDouble();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bid Distribution',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          // Pie chart representation
          SizedBox(
            height: 150,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: PieChartPainter(
                        withBidsPercentage: withBidsPercentage,
                        withoutBidsPercentage: withoutBidsPercentage,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${withBidsPercentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      Text(
                        'With Bids',
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
          ),
          SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('With Bids', Colors.orange[600]!),
              SizedBox(width: 24),
              _buildLegendItem('Without Bids', Colors.orange[600]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  static String _mapTimeframeToUrgency(String? timeframe) {
    switch (timeframe) {
      case 'ASAP':
        return 'ASAP';
      case '12 Hours':
        return '12_HOURS';
      case '24 Hours':
        return '12_HOURS'; // Map to 12_HOURS since 24_HOURS is not valid
      case '2-3 Days':
        return '1_WEEK';
      case '1 Week':
        return '1_WEEK';
      case '2 Weeks':
        return '1_MONTH'; // Map to 1_MONTH since 2_WEEKS is not valid
      case 'Within a Month':
        return '1_MONTH';
      case 'Immediately':
        return '12_HOURS';
      case 'Within a week':
        return '1_WEEK';
      case 'Within a month':
        return '1_MONTH';
      default:
        return '1_WEEK'; // Default to 1_WEEK
    }
  }
}

// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final double withBidsPercentage;
  final double withoutBidsPercentage;

  PieChartPainter({
    required this.withBidsPercentage,
    required this.withoutBidsPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Paint for with bids
    final withBidsPaint = Paint()
      ..color = Colors.orange[600]!
      ..style = PaintingStyle.fill;

    // Paint for without bids
    final withoutBidsPaint = Paint()
      ..color = Colors.orange[600]!
      ..style = PaintingStyle.fill;

    // Draw with bids arc
    final withBidsAngle = (withBidsPercentage / 100) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2, // Start from top
      withBidsAngle,
      true,
      withBidsPaint,
    );

    // Draw without bids arc
    final withoutBidsAngle = (withoutBidsPercentage / 100) * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2 + withBidsAngle,
      withoutBidsAngle,
      true,
      withoutBidsPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _mapTimeframeToUrgency(String? timeframe) {
  switch (timeframe) {
    case 'ASAP':
      return 'ASAP';
    case '12 Hours':
      return '12_HOURS';
    case '24 Hours':
      return '12_HOURS'; // Map to 12_HOURS since 24_HOURS is not valid
    case '2-3 Days':
      return '1_WEEK';
    case '1 Week':
      return '1_WEEK';
    case '2 Weeks':
      return '1_MONTH'; // Map to 1_MONTH since 2_WEEKS is not valid
    case 'Within a Month':
      return '1_MONTH';
    case 'Immediately':
      return '12_HOURS';
    case 'Within a week':
      return '1_WEEK';
    case 'Within a month':
      return '1_MONTH';
    default:
      return '1_WEEK'; // Default to 1_WEEK
  }
}

String _getRequestId(dynamic request) {
  try {
    if (request is Map) {
      // Try various possible locations for the request ID
      return request['request_id']?.toString() ??
          request['id']?.toString() ??
          request['uuid']?.toString() ??
          'Unknown';
    } else {
      // Try accessing common properties
      if (request?.id != null) {
        return request.id.toString();
      }
      if (request?.requestId != null) {
        return request.requestId.toString();
      }
      if (request?.uuid != null) {
        return request.uuid.toString();
      }
    }
    return 'Unknown';
  } catch (e) {
    print('Error getting request ID: $e');
    return 'Unknown';
  }
}

String _getRequestDescription(dynamic request) {
  //print("sakjsa $request ${request.runtimeType}");
  try {
    if (request?.category == null) return "No description available";

    // Handle different request types - either API response models or transformed models
    if (request is AutoSparesRequest) {
      // Transformed model
      if (request.autoSpares?.partDetails?.partName != null &&
          request.autoSpares?.vehicleDetails?.makeModel != null &&
          request.autoSpares?.vehicleDetails?.year != null) {
        return "${request.autoSpares.partDetails.partName}, ${request.autoSpares.vehicleDetails.makeModel}, ${request.autoSpares.vehicleDetails.year}";
      }
      return "Vehicle Spares Request";
    } else if (request is RimTyreRequest) {
      // Transformed model
      print("dfhgdfghdghdghdgh ${request}");
      if (request.rimTyre?.productDetails != null) {
        final tyreTypeRaw = request.rimTyre.productDetails.tyreType ?? "Tyres";
        // Replace "Both" with more descriptive text
        final tyreType = tyreTypeRaw == "Both" ? "Tyres & Rims" : tyreTypeRaw;
        final tyreWidth = request.rimTyre.productDetails.tyreWidthMm ?? 0;
        final sidewall = request.rimTyre.productDetails.sidewallProfile ?? "";
        final rimDiameter =
            request.rimTyre.productDetails.wheelRimDiameterInches ?? "";
        final brand =
            request.rimTyre.moreFields.preferredBrand ?? "Various Brands";
        return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
      }
      return "Tyre/Rim Request";
    } else if (request is ConsumerElectronicsRequest) {
      // Transformed model
      if (request.consumerElectronics?.productDetails != null) {
        final typeOfElectronics =
            request.consumerElectronics.productDetails.typeOfElectronics ??
            "Electronics";
        final brandPreference =
            request.consumerElectronics.productDetails.brandPreference ??
            "Various Brands";
        final modelSeries =
            request.consumerElectronics.productDetails.modelSeries;
        return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
      }
      return "Electronics Request";
    }

    // Handle API response category strings
    switch (request.category) {
      case "VEHICLE_SPARES":
        // Use vehicle_spares_summary from API or fallback to title/description
        if (request.vehicleSparesSummary != null &&
            request.vehicleSparesSummary.isNotEmpty) {
          return request.vehicleSparesSummary;
        } else if (request.title != null && request.title.isNotEmpty) {
          return "${request.title} - ${request.description ?? 'Vehicle Spares Request'}";
        }
        return "Vehicle Spares Request";

      case "TYRES_RIMS":
        // Extract detailed information from vehicleTyresRimsData or productSpecifications
        if (request.vehicleTyresRimsData != null ||
            request.productSpecifications != null) {
          final tyresData =
              request.vehicleTyresRimsData ??
              request.productSpecifications ??
              {};
          final tyreTypeRaw =
              tyresData['tyre_type']?.toString() ??
              tyresData['tyreType']?.toString() ??
              "Tyres";
          final tyreType = tyreTypeRaw == "Both" ? "Tyres & Rims" : tyreTypeRaw;
          final tyreWidth =
              tyresData['tyre_width_mm'] ?? tyresData['tyreWidthMm'] ?? 0;
          final sidewall =
              tyresData['sidewall_profile']?.toString() ??
              tyresData['sidewallProfile']?.toString() ??
              "";
          final rimDiameter =
              tyresData['wheel_rim_diameter_inches']?.toString() ??
              tyresData['wheelRimDiameterInches']?.toString() ??
              "";
          final brand =
              tyresData['preferred_brand']?.toString() ??
              tyresData['preferredBrand']?.toString() ??
              "Various Brands";

          if (tyreWidth != 0 && sidewall.isNotEmpty && rimDiameter.isNotEmpty) {
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
        }

        // Fallback to summary if detailed data is not available
        if (request.tyresRimsSummary != null &&
            request.tyresRimsSummary.isNotEmpty) {
          return "${request.tyresRimsSummary} - ${request.title ?? 'Tyre/Rim Request'}";
        } else if (request.title != null && request.title.isNotEmpty) {
          return "${request.title} - ${request.description ?? 'Tyre/Rim Request'}";
        }
        return "Tyre/Rim Request";

      case "ELECTRONICS":
        // Use consumer_electronics_summary from API or fallback to title/description
        if (request.consumerElectronicsSummary != null &&
            request.consumerElectronicsSummary.isNotEmpty) {
          return request.consumerElectronicsSummary;
        } else if (request.title != null && request.title.isNotEmpty) {
          return "${request.title} - ${request.description ?? 'Electronics Request'}";
        }
        return "Electronics Request";

      // Legacy categories for backward compatibility
      case "Vehicle Spares":
        if (request?.partDetails?.partName != null &&
            request?.vehicleDetails?.makeModel != null &&
            request?.vehicleDetails?.year != null) {
          return "${request.partDetails.partName}, ${request.vehicleDetails.makeModel}, ${request.vehicleDetails.year}";
        }
        return "Vehicle Spares Request";

      case "Vehicle Tyres and Rims":
        if (request?.productDetails != null) {
          final tyreTypeRaw = request.productDetails.tyreType ?? "Tyres";
          // Replace "Both" with more descriptive text
          final tyreType = tyreTypeRaw == "Both" ? "Tyres & Rims" : tyreTypeRaw;
          final tyreWidth = request.productDetails.tyreWidthMm ?? 0;
          final sidewall = request.productDetails.sidewallProfile ?? "";
          final rimDiameter =
              request.productDetails.wheelRimDiameterInches ?? "";
          final brand = request.moreFields?.preferredBrand ?? "Various Brands";
          return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
        }
        return "Tyre/Rim Request";

      case "Consumer Electronics":
        if (request?.productDetails != null) {
          final typeOfElectronics =
              request.productDetails.typeOfElectronics ?? "Electronics";
          final brandPreference =
              request.productDetails.brandPreference ?? "Various Brands";
          final modelSeries = request.productDetails.modelSeries;
          return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
        }
        return "Electronics Request";

      default:
        // Fallback to title and description from API
        if (request.title != null && request.title.isNotEmpty) {
          return "${request.title} - ${request.description ?? 'Request'}";
        }
        return "Request #${_getRequestId(request)}";
    }
  } catch (e) {
    print('Error getting description: $e');
    return "Request information unavailable";
  }
}

// Helper methods to convert ProductRequestItem to old request formats
RimTyreRequest _createRimTyreRequest(ProductRequestItem item) {
  print('🔧 DEBUG: Creating RimTyreRequest from ProductRequestItem');
  print('🔧 Item title: "${item.title}"');
  print('🔧 Item tyresRimsSummary: "${item.tyresRimsSummary}"');
  print('🔧 Item description: "${item.description}"');
  print('🔧 Item productSpecifications: ${item.productSpecifications}');

  // Parse tyres rims summary - try multiple sources
  String summaryText = item.tyresRimsSummary ?? item.title ?? '';
  final tyreSizePattern = RegExp(r'(\d+)/(\d+)R(\d+)');
  final match = tyreSizePattern.firstMatch(summaryText);

  print('🔧 Using summary text: "$summaryText"');
  print('🔧 Regex match found: ${match != null}');
  if (match != null) {
    print(
      '🔧 Match groups: ${match.group(1)}, ${match.group(2)}, ${match.group(3)}',
    );
  }

  final productDetails = RimTyreProductDetails(
    tyreWidthMm: match != null ? int.tryParse(match.group(1)!) ?? 205 : 205,
    sidewallProfile: match != null ? match.group(2)! : '55',
    wheelRimDiameterInches: match != null ? match.group(3)! : '16',
    tyreType: (item.title?.toUpperCase().contains('RIMS') == true)
        ? 'Rims'
        : (item.title?.toUpperCase().contains('TYRES') == true ||
              item.title?.toUpperCase().contains('TIRES') == true)
        ? 'Tyres'
        : 'Both',
    quantity: item.quantity ?? 4,
    urgency: _mapUrgencyTimeline(item.urgencyTimeline),
  );

  // Try to extract more info from productSpecifications
  String preferredBrand = _extractBrandFromTitle(item.title ?? '');
  if (item.productSpecifications != null) {
    preferredBrand =
        item.productSpecifications!['preferred_brand']?.toString() ??
        item.productSpecifications!['brand']?.toString() ??
        preferredBrand;
  }

  print('🔧 Extracted preferredBrand: "$preferredBrand"');

  final moreFields = RimTyreMoreFields(
    description: item.description ?? 'Tyre/Rim Request',
    vehicleType: 'Passenger Car',
    pitchCircleDiameter: '114.3',
    preferredBrand: preferredBrand,
    tyreConstructionType: 'Radial',
    fitmentRequired: "",
    balancingRequired: "",
    tyreRotationRequired: "",
    imageUrls: item.productImages ?? [],
  );

  final rimTyre = RimTyre(
    productDetails: productDetails,
    moreFields: moreFields,
  );

  final rimTyreRequest = RimTyreRequest(
    id: item.requestId,
    status: item.status,
    category: item.category,
    createdAt: item.createdAt,
    rimTyre: rimTyre,
    sellerOffers: item.quotes,
  );

  print('🔧 Created RimTyreRequest with:');
  print('🔧   - ID: ${rimTyreRequest.id}');
  print('🔧   - Category: ${rimTyreRequest.category}');
  print(
    '🔧   - RimTyre.productDetails.tyreType: ${rimTyre.productDetails.tyreType}',
  );
  print(
    '🔧   - RimTyre.productDetails.tyreWidthMm: ${rimTyre.productDetails.tyreWidthMm}',
  );
  print(
    '🔧   - RimTyre.moreFields.preferredBrand: ${rimTyre.moreFields.preferredBrand}',
  );

  return rimTyreRequest;
}

ConsumerElectronicsRequest _createElectronicsRequest(ProductRequestItem item) {
  // Extract data from consumerElectronicsData and productSpecifications
  final electronicsData = item.consumerElectronicsData ?? {};
  final specs = item.productSpecifications ?? {};

  print("🔍 DESKTOP ELECTRONICS MAPPING:");
  print("Electronics data: $electronicsData");
  print("Product specs: $specs");
  print("Title: ${item.title}");
  print("Description: ${item.description}");

  // Parse consumer electronics summary
  final parts =
      item.consumerElectronicsSummary?.split(' - ') ?? [item.title, ''];
  final productType =
      electronicsData['electronics_type']?.toString() ??
      electronicsData['type_of_electronics']?.toString() ??
      specs['electronics_type']?.toString() ??
      specs['type_of_electronics']?.toString() ??
      (parts.length > 0 ? parts[0] : item.title);
  final brand =
      electronicsData['brand_preference']?.toString() ??
      specs['brand_preference']?.toString() ??
      specs['preferred_brand']?.toString() ??
      _extractBrandFromTitle(item.title);

  final productDetails = ProductDetails(
    typeOfElectronics: productType,
    brandPreference: brand,
    modelSeries:
        electronicsData['model_series']?.toString() ??
        specs['model_series']?.toString() ??
        specs['model']?.toString() ??
        _extractModelFromSummary(item.consumerElectronicsSummary),
    quantityNeeded:
        electronicsData['quantity_needed']?.toInt() ??
        specs['quantity_needed']?.toInt() ??
        specs['quantity']?.toInt() ??
        item.quantity ??
        1,
  );

  final budgetTimeline = BudgetTimeline(
    minPrice: electronicsData['min_price'] != null
        ? double.tryParse(electronicsData['min_price'].toString())
        : specs['min_price'] != null
        ? double.tryParse(specs['min_price'].toString())
        : null,
    maxPrice: electronicsData['max_price'] != null
        ? double.tryParse(electronicsData['max_price'].toString())
        : specs['max_price'] != null
        ? double.tryParse(specs['max_price'].toString())
        : item.maxBudget,
    urgency:
        electronicsData['urgency']?.toString() ??
        specs['urgency']?.toString() ??
        _mapUrgencyTimeline(item.urgencyTimeline),
    needsInstallation:
        (electronicsData['installation_required']?.toString() ??
            electronicsData['needs_installation']?.toString() ??
            specs['installation_required']?.toString() ??
            specs['needs_installation']?.toString() ??
            'NO') ==
        'YES',
  );

  final featuresAndSpecs = FeaturesAndSpecs(
    requiredFeatures:
        electronicsData['required_features']?.toString() ??
        specs['required_features']?.toString() ??
        specs['features']?.toString(),
    conditionPreference:
        electronicsData['condition_preference']?.toString() ??
        specs['condition_preference']?.toString() ??
        item.conditionPreference ??
        'NEW',
    purpose:
        electronicsData['purpose_of_purchase']?.toString() ??
        electronicsData['purpose']?.toString() ??
        specs['purpose_of_purchase']?.toString() ??
        specs['purpose']?.toString() ??
        specs['usage']?.toString() ??
        'Home Use',
    documentsOrImages: item.productImages ?? [],
    additionalComments:
        electronicsData['additional_comments']?.toString() ??
        specs['additional_comments']?.toString() ??
        specs['notes']?.toString() ??
        item.description,
  );

  final consumerElectronics = ConsumerElectronics(
    productDetails: productDetails,
    budgetTimeline: budgetTimeline,
    featuresAndSpecs: featuresAndSpecs,
  );

  print("✅ DESKTOP MAPPED ELECTRONICS:");
  print("Type: ${productDetails.typeOfElectronics}");
  print("Brand: ${productDetails.brandPreference}");
  print("Model: ${productDetails.modelSeries}");
  print("Quantity: ${productDetails.quantityNeeded}");
  print("Purpose: ${featuresAndSpecs.purpose}");
  print("Condition: ${featuresAndSpecs.conditionPreference}");

  return ConsumerElectronicsRequest(
    id: item.requestId,
    status: item.status,
    category: item.category,
    createdAt: item.createdAt,
    consumerElectronics: consumerElectronics,
    sellerOffers: item.quotes,
  );
}

// Helper methods for parsing data
String _mapUrgencyTimeline(String urgencyTimeline) {
  switch (urgencyTimeline) {
    case 'ASAP':
    case '12_HOURS':
      return 'Immediately';
    case '1_WEEK':
      return '1 Week';
    case '1_MONTH':
      return '1 Month';
    default:
      return '1 Week';
  }
}

String _extractBrandFromTitle(String title) {
  final brands = [
    'Toyota',
    'BMW',
    'Mercedes',
    'Honda',
    'Nissan',
    'Ford',
    'Apple',
    'Samsung',
    'LG',
    'Sony',
    'Hisense',
    'Continental',
    'Bridgestone',
    'Michelin',
  ];
  for (final brand in brands) {
    if (title.toLowerCase().contains(brand.toLowerCase())) {
      return brand;
    }
  }
  return 'Unknown';
}

String? _extractModelFromSummary(String? summary) {
  if (summary == null) return null;
  final parts = summary.split(' ');
  return parts.length > 2 ? parts[2] : null;
}
