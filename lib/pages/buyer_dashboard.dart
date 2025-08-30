import 'package:bidr/constants/Constants.dart';
import 'package:bidr/customWdget/customCard.dart';
import 'package:bidr/global_values.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/request_models.dart';
import '../models/product_request_api.dart';
import '../services/chat_service.dart';
import '../services/products_management_api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'buyer/account_management.dart';
import 'buyer/share_with_friends.dart';
import 'buyer/transaction_management.dart';
import 'group_chat.dart';

class BuyerDashboardScreen extends StatefulWidget {
  @override
  _BuyerDashboardScreenState createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  List<ProductRequestItem> _productRequests = [];
  bool _isLoading = true;
  String? _error;
  Map<String, String> _bidSortOptions = {}; // Track sort option per request ID
  Set<String> _cancelledRequests = {}; // Track cancelled request IDs

  // Filter state variables
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Status';
  String _selectedSort = 'recent'; // Default sort by recent
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _fetchProductRequests();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int dashboardIndex = 0;
  bool isActive = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                Padding(
                  padding: const EdgeInsets.only(left: 68, right: 68),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(maxWidth: 1600),
                      height: 600,
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
                                Expanded(child: TransactionDashboard()),
                              ],
                            )
                          : dashboardIndex == 3
                          ? AccountManagementPage()
                          : Container(),
                    ),
                  ),
                ),
                SizedBox(height: 24),
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
      // Show loading state
      if (_isLoading) {
        cards.add(_buildLoadingCard());
        return cards;
      }

      // Show error state
      if (_error != null) {
        cards.add(_buildErrorCard(_error!));
        return cards;
      }

      // Build cards from converted GlobalVariables data (not raw API data)
      List<dynamic> allRequests = [
        ...GlobalVariables.combinedRequest.autoSparesRequest,
        ...GlobalVariables.combinedRequest.rimTyreRequest,
        ...GlobalVariables.combinedRequest.consumerElectronicsRequest,
      ];

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
    // Handle loading state
    if (_isLoading) {
      return Center(child: _buildLoadingCard());
    }

    // Handle error state
    if (_error != null) {
      return Center(child: _buildErrorCard(_error!));
    }

    // Get all requests
    List<dynamic> allRequests = [
      ...GlobalVariables.combinedRequest.autoSparesRequest,
      ...GlobalVariables.combinedRequest.rimTyreRequest,
      ...GlobalVariables.combinedRequest.consumerElectronicsRequest,
    ];

    if (allRequests.isEmpty) {
      return Center(child: _buildEmptyStateCard());
    }

    // Filter requests based on current filters
    final filteredRequests = _filterRequests(allRequests);

    if (filteredRequests.isEmpty) {
      return Center(child: _buildEmptyStateCard());
    }

    return Column(
      children: [
        // Filter and Sort Controls
        Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: _buildFilterSortControls(filteredRequests.length),
        ),
        SizedBox(height: 16),
        // Custom Grid with dynamic row heights
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildCustomGrid(filteredRequests),
          ),
        ),
      ],
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

  /// Build custom grid with dynamic row heights
  Widget _buildCustomGrid(List<dynamic> requests) {
    const int cardsPerRow = 4;
    const double horizontalSpacing = 16;
    const double verticalSpacing = 16;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth =
            (constraints.maxWidth - (horizontalSpacing * (cardsPerRow - 1))) /
            cardsPerRow;

        return SingleChildScrollView(
          child: Column(
            children: _buildRows(
              requests,
              cardsPerRow,
              cardWidth,
              horizontalSpacing,
              verticalSpacing,
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
    // Updated height calculations for modern card design
    const double baseHeight = 350.0; // Base height for new design
    const double bidCardHeight = 88.0; // Height per bid card in new design
    const double viewMoreButtonHeight = 50.0;

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
            List<dynamic> allRequests = [
              ...GlobalVariables.combinedRequest.autoSparesRequest,
              ...GlobalVariables.combinedRequest.rimTyreRequest,
              ...GlobalVariables.combinedRequest.consumerElectronicsRequest,
            ];

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Constants.ftaColorLight),
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

  Widget _buildEmptyStateCard() {
    return Container(
      width: 350,
      height: 400,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
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
              'No Requests Yet',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start creating product requests to see them here',
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
                    _fetchProductRequests();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ftaColorLight,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Refresh'),
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
        if (request.rimTyre?.productDetails != null) {
          final tyreType = request.rimTyre.productDetails.tyreType ?? "Tyres";
          final tyreWidth = request.rimTyre.productDetails.tyreWidthMm ?? 0;
          final sidewall = request.rimTyre.productDetails.sidewallProfile ?? "";
          final rimDiameter =
              request.rimTyre.productDetails.wheelRimDiameterInches ?? "";
          final brand =
              request.rimTyre.moreFields?.preferredBrand ?? "Various Brands";
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
          // Use tyres_rims_summary from API or fallback to title/description
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

  void _navigateToDetailScreen(dynamic request) {
    try {
      if (request?.category == null) {
        _showErrorSnackBar("Cannot open request details: Invalid request data");
        return;
      }

      switch (request.category) {
        case "VEHICLE_SPARES":
        case "Vehicle Spares":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SparesDetailScreen(
                request: request,
                autoSpare: request.autoSpares ?? request.autoSpare,
                bids: request.sellerOffers ?? [],
              ),
            ),
          );
          break;

        case "TYRES_RIMS":
        case "Vehicle Tyres and Rims":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RimTyreDetailScreen(
                request: request,
                rimTyre: request.rimTyre,
                bids: request.sellerOffers ?? [],
              ),
            ),
          );
          break;

        case "ELECTRONICS":
        case "Consumer Electronics":
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsumerElectronicsDetailScreen(
                request: request,
                consumerElectronics: request.consumerElectronics,
                bids: request.sellerOffers ?? [],
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
    );
  }

  Widget _buildActiveRequestCard(dynamic request, int index) {
    // This version is for compatibility - redirects to the height-specific version
    final bids = _getSortedBids(request);
    final hasMoreThanTwoBids = bids.length > 2;
    final bidsToShow = bids.take(2).toList(); // Match new design

    // Use same constants as _calculateMaxRowHeight for consistency
    const double baseHeight = 300.0; // Base height for new design
    const double bidCardHeight = 88.0; // Height per bid card in new design
    final double dynamicHeight =
        baseHeight +
        (bidsToShow.length * bidCardHeight) +
        (hasMoreThanTwoBids ? 50.0 : 0.0);

    return _buildActiveRequestCardWithHeight(request, dynamicHeight, index);
  }

  Widget _buildActiveRequestCardWithHeight(
    dynamic request,
    double fixedHeight,
    int index,
  ) {
    final bids = _getSortedBids(request);
    final hasMoreThanTwoBids = bids.length > 2;
    final bidsToShow = bids
        .take(2)
        .toList(); // Show only 2 bids like in screenshot

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
            // Header with date, cancel button, and filter icon
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
                Column(
                  children: [
                    Row(
                      children: [
                        if (!_cancelledRequests.contains(
                          _getRequestId(request),
                        ))
                          InkWell(
                            onTap: () {
                              _showCancelRequestDialog(request);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red.shade300),
                                borderRadius: BorderRadius.circular(20),
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
                        Icon(
                          Icons.filter_alt_outlined,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _navigateToDetailScreen(request),
                        child: Text(
                          "View Details",
                          style: GoogleFonts.manrope(
                            color: Color(0xFF2B3A5C),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // View Details link
            SizedBox(height: 12),

            // Description section with orange border
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.orange.shade500, width: 4),
                ),
              ),
              padding: EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description -",
                    style: GoogleFonts.manrope(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getRequestDescription(request),
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Countdown Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimerCircle("0", "D"),
                SizedBox(width: 12),
                _buildTimerCircle(
                  _getElapsedTime(request.createdAt, 'hours'),
                  "H",
                ),
                SizedBox(width: 12),
                _buildTimerCircle(
                  _getElapsedTime(request.createdAt, 'minutes'),
                  "M",
                ),
                SizedBox(width: 12),
                _buildTimerCircle(
                  _getElapsedTime(request.createdAt, 'seconds'),
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
                      ...bidsToShow.map(
                        (bid) => _buildModernSellerBid(bid, request),
                      ),
                      if (hasMoreThanTwoBids) ...[
                        SizedBox(height: 16),
                        _buildViewAllBidsButton(bids.length),
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
                backgroundColor: Colors.orange.shade50,
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

  // Modern seller bid card matching screenshot
  Widget _buildModernSellerBid(dynamic bid, dynamic request) {
    String sellerName = _getSellerName(bid);
    double bidAmount = _getBidAmount(bid);
    DateTime bidTime = _getBidTime(bid);
    double rating = _getBidRating(bid);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Seller info and bid details
          Container(
            padding: EdgeInsets.all(16),
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
                            sellerName,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _formatDateTime(bidTime),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Expand/Collapse icon
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Bid amount and accept button
                Row(
                  children: [
                    Text(
                      'Bid: ',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      'R${bidAmount.toInt()}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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
              color: Color(0xFF2B3A5C), // Dark orange background
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Rating: ${rating.toStringAsFixed(1)}/5',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
                        Icons.chat_bubble_outline,
                        color: Colors.orange.shade500,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Group Chat',
                        style: GoogleFonts.manrope(
                          color: Colors.orange.shade500,
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
  Widget _buildViewAllBidsButton(int totalBids) {
    return GestureDetector(
      onTap: () {
        // Handle view all bids action
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF2B3A5C)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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

  Widget _buildSellerBid(dynamic bid, dynamic request) {
    if (bid == null) return SizedBox.shrink();

    // Extract data using helper methods to handle both Seller and QuoteItem
    String sellerName = _getSellerName(bid);
    double bidAmount = _getBidAmount(bid);
    DateTime bidTime = _getBidTime(bid);
    double rating = _getBidRating(bid);
    String comments = _getBidComments(bid);
    double distance = _getBidDistance(bid);

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
                    sellerName,
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
                    _showConfirmationDialog(context, bid, request);
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
              _formatBidDateTime(bidTime),
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
                    text: " R${bidAmount.toInt()}",
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
                    text: "${distance.toInt()}Km",
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
                    text: comments,
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
                        "Rating: ${rating.toInt()}/5",
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

  /// Compact version of seller bid for card display (max 5 visible)
  Widget _buildCompactSellerBid(dynamic bid, dynamic request) {
    if (bid == null) return SizedBox.shrink();

    // Extract data using helper methods to handle both Seller and QuoteItem
    String sellerName = _getSellerName(bid);
    double bidAmount = _getBidAmount(bid);
    DateTime bidTime = _getBidTime(bid);
    double rating = _getBidRating(bid);
    String comments = _getBidComments(bid);
    double distance = _getBidDistance(bid);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Constants.ftaColorLight.withValues(alpha: 0.3),
        ),
        color: Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with seller name and accept button
          Row(
            children: [
              Expanded(
                child: Text(
                  sellerName,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B3A5C),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  _showConfirmationDialog(context, bid, request);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(60, 24),
                ),
                child: Text(
                  "Accept",
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          // Bid info row
          Row(
            children: [
              Text(
                'R${bidAmount.toInt()}',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${distance.toInt()}km',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Spacer(),
              // Star rating
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 12,
                    color: index < rating.toInt()
                        ? Colors.orange
                        : Colors.grey[300],
                  );
                }),
              ),
            ],
          ),
          if (comments.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              comments,
              style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  /// Dialog showing all bids with full actions
  void _showAllBidsDialog(dynamic request) {
    final allBids = _getSortedBids(request);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'All Bids for Request #${_getRequestId(request)}',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Bid count and filter
                Row(
                  children: [
                    Text(
                      '${allBids.length} bids received',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Spacer(),
                    // Bid filter dropdown for dialog
                    _buildBidFilterDropdown(_getRequestId(request)),
                  ],
                ),
                SizedBox(height: 16),
                // List of all bids
                Expanded(
                  child: ListView.builder(
                    itemCount: allBids.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        child: _buildSellerBid(allBids[index], request),
                      );
                    },
                  ),
                ),
                // Dialog actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.manrope(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _navigateToDetailScreen(request);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ftaColorLight,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'View Request Details',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
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
  Future<void> _processPaymentAndCreateOrder(
    dynamic seller,
    dynamic request,
  ) async {
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

      // Create order data required by backend
      final orderData = {
        'request_id': _getRequestId(request),
        'quote_id': _getQuoteId(seller),
        // Optionals
        'delivery_address': null,
        'special_instructions': null,
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

        // Navigate to Transaction Management tab
        setState(() {
          dashboardIndex = 2; // Transaction Management tab
        });

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
                        Text(
                          "View Details",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.orange,
                            decoration: TextDecoration.underline,
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

  Future<void> _fetchProductRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
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
        });

        // Populate GlobalVariables with API data
        for (var item in apiResponse.results) {
          _populateGlobalVariables(item);
        }

        print('Successfully loaded ${_productRequests.length} requests');
      } else {
        print('API Error: ${result['message']}');
        setState(() {
          _error = 'Failed to load requests: ${result['message']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception occurred: $e');
      setState(() {
        _error = 'Network Error3: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testApiConnection() async {
    print('=== Testing API Connection ===');

    // Test 1: Basic connectivity
    try {
      final response = await http
          .get(Uri.parse('http://108.141.192.60/'))
          .timeout(Duration(seconds: 5));
      print('Base URL test - Status: ${response.statusCode}');
    } catch (e) {
      print('Base URL test failed: $e');
    }

    // Test 2: Try without /products/
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://108.141.192.60/api/v1/product-requests/requests/',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 5));
      print('Without /products/ - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('SUCCESS: Alternative URL works!');
        // Try to parse this response
        try {
          final jsonData = json.decode(response.body);
          final apiResponse = ProductRequestApiResponse.fromJson(jsonData);
          setState(() {
            _productRequests = apiResponse.results;
            _isLoading = false;
            _error = null;
          });
        } catch (parseError) {
          print('Parse error: $parseError');
        }
      }
    } catch (e) {
      print('Alternative URL test failed: $e');
    }

    // Test 3: Original URL with different headers
    try {
      final response = await http
          .get(
            Uri.parse(
              'http://127.0.0.1:8005/api/v1/product-requests/requests/',
            ),
            headers: {'User-Agent': 'Flutter App', 'Accept': '*/*'},
          )
          .timeout(Duration(seconds: 5));
      print(
        'Original URL with different headers - Status: ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        print('SUCCESS: Original URL with different headers works!');
      }
    } catch (e) {
      print('Original URL with different headers failed: $e');
    }

    print('=== End API Test ===');
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
    // Parse vehicle spares summary to extract vehicle details
    final parts = item.vehicleSparesSummary?.split(' - ') ?? ['', ''];
    final vehiclePart = parts.length > 0 ? parts[0] : '';
    final partName = parts.length > 1 ? parts[1] : item.title;

    final vehicleDetails = VehicleDetails(
      vin: '',
      manufacturer: vehiclePart.split(' ').first,
      makeModel: vehiclePart.split(' ').skip(1).take(1).join(' '),
      type: 'Unknown',
      condition: item.conditionPreference ?? 'NEW',
      year: vehiclePart.contains(RegExp(r'\d{4}'))
          ? RegExp(r'\d{4}').firstMatch(vehiclePart)?.group(0) ?? '2020'
          : '2020',
    );

    final partDetails = PartDetails(
      partName: partName,
      quantity: item.quantity ?? 1,
      location: 'Unknown',
      maxDistanceKm: 50.0,
      urgency: _mapUrgencyTimeline(item.urgencyTimeline),
      productDescription: item.description,
      imageUrls: [],
    );

    final moreFields = MoreFields(
      partNumber: '',
      transmissionType: 'Unknown',
      mileage: '0',
      fuelType: 'Unknown',
      bodyType: 'Unknown',
    );

    final autoSpares = AutoSpares(
      vehicleDetails: vehicleDetails,
      partDetails: partDetails,
      moreFields: moreFields,
    );

    return AutoSparesRequest(
      id: item.requestId, // Keep as string UUID
      status: item.status,
      category: item.category,
      createdAt: item.createdAt,
      autoSpares: autoSpares,
      sellerOffers: item.quotes, // Use real quotes from API
    );
  }

  RimTyreRequest _createRimTyreRequest(ProductRequestItem item) {
    // Parse tyres rims summary
    final tyreSizePattern = RegExp(r'(\d+)/(\d+)R(\d+)');
    final match = tyreSizePattern.firstMatch(item.tyresRimsSummary ?? '');

    final productDetails = RimTyreProductDetails(
      tyreWidthMm: match != null ? int.tryParse(match.group(1)!) ?? 205 : 205,
      sidewallProfile: match != null ? match.group(2)! : '55',
      wheelRimDiameterInches: match != null ? match.group(3)! : '16',
      tyreType: item.title.contains('RIMS')
          ? 'Rims'
          : item.title.contains('TYRES')
          ? 'Tyres'
          : 'Both',
      quantity: item.quantity ?? 4,
      urgency: _mapUrgencyTimeline(item.urgencyTimeline),
    );

    final moreFields = RimTyreMoreFields(
      description: item.description,
      vehicleType: 'Passenger Car',
      pitchCircleDiameter: '114.3',
      preferredBrand: _extractBrandFromTitle(item.title),
      tyreConstructionType: 'Radial',
      fitmentRequired: true,
      balancingRequired: true,
      tyreRotationRequired: false,
      imageUrls: [],
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
    );
  }

  ConsumerElectronicsRequest _createElectronicsRequest(
    ProductRequestItem item,
  ) {
    // Parse consumer electronics summary
    final parts =
        item.consumerElectronicsSummary?.split(' - ') ?? [item.title, ''];
    final productType = parts.length > 0 ? parts[0] : item.title;
    final brand = _extractBrandFromTitle(item.title);

    final productDetails = ProductDetails(
      typeOfElectronics: productType,
      brandPreference: brand,
      modelSeries: _extractModelFromSummary(item.consumerElectronicsSummary),
      quantityNeeded: item.quantity ?? 1,
    );

    final budgetTimeline = BudgetTimeline(
      minPrice: null,
      maxPrice: item.maxBudget,
      urgency: _mapUrgencyTimeline(item.urgencyTimeline),
      needsInstallation: false,
    );

    final featuresAndSpecs = FeaturesAndSpecs(
      requiredFeatures: null,
      conditionPreference: item.conditionPreference ?? 'NEW',
      purpose: 'Home Use',
      documentsOrImages: [],
      additionalComments: item.description,
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
  int _getSellerId(dynamic bid) {
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
  }

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
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Request ID: ${_getRequestId(request)}",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
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
          'http://127.0.0.1:8005/api/v1/product-requests/requests/$requestId/',
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
          _fetchProductRequests();
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
  final AutoSparesRequest request;
  final AutoSpares autoSpare;
  final List<dynamic> bids;

  const SparesDetailScreen({
    Key? key,
    required this.request,
    required this.autoSpare,
    required this.bids,
  }) : super(key: key);

  @override
  State<SparesDetailScreen> createState() => _SparesDetailScreenState();
}

class _SparesDetailScreenState extends State<SparesDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Request Header Card
            SizedBox(height: 32),
            Container(
              height: 60,
              width: MediaQuery.of(context).size.width,
              color: Constants.ctaColorLight,
              padding: EdgeInsets.only(left: 64, right: 64, top: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Request ',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '2',
                    style: GoogleFonts.manrope(
                      color: Constants.ftaColorLight,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    '\t\t\tInformation',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 64, right: 64),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatDate(widget.request.createdAt),
                                    style: GoogleFonts.manrope(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Spacer(),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showCancelRequestDialog(),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              360,
                                            ),
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
                                "REQUEST ID: ${_getRequestId(widget.request)}",
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
                                      color: Colors.orange,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Description -",
                                          style: GoogleFonts.manrope(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextButton(
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
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _getRequestDescription(
                                        widget.request,
                                        widget.autoSpare,
                                      ),
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      widget.request.category ??
                                          "Unknown Category",
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
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'days',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "H",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'hours',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "M",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'minutes',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "S",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'seconds',
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
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
                                      widget.autoSpare.moreFields.partNumber,
                                    ),
                                    _buildDetailItem(
                                      "Transmission Type",
                                      widget
                                          .autoSpare
                                          .moreFields
                                          .transmissionType,
                                    ),
                                    _buildDetailItem(
                                      "Mileage of Vehicle",
                                      widget.autoSpare.moreFields.mileage,
                                    ),
                                    _buildDetailItem(
                                      "Fuel Type",
                                      widget.autoSpare.moreFields.fuelType,
                                    ),
                                    _buildDetailItem(
                                      "Body Type",
                                      widget.autoSpare.moreFields.bodyType,
                                    ),
                                    _buildDetailItem(
                                      "Enquiry Time",
                                      "24 Hours",
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
                    FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRequestDescription(dynamic request, dynamic item) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (item?.partDetails?.partName != null &&
              item?.vehicleDetails?.makeModel != null &&
              item?.vehicleDetails?.year != null) {
            return "${item.partDetails.partName}, ${item.vehicleDetails.makeModel}, ${item.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (item?.productDetails != null) {
            final typeOfElectronics =
                item.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference =
                item.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = item.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (item?.productDetails != null) {
            final tyreType = item.productDetails.tyreType ?? "Tyres";
            final tyreWidth = item.productDetails.tyreWidthMm ?? 0;
            final sidewall = item.productDetails.sidewallProfile ?? "";
            final rimDiameter =
                item.productDetails.wheelRimDiameterInches ?? "";
            final brand = item.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${_getRequestId(request)}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable2";
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
            // Show placeholder image for VIN
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
                  'assets/images/mechanic_working.jpg', // You would replace this with actual image
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
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/mechanic_working.jpg', // You would replace this with actual image
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(
                              Icons.image,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Navigation arrows
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.arrow_back_ios,
                              color: Constants.ftaColorLight,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: IconButton(
                            onPressed: () {
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: Constants.ftaColorLight,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!showImage) ...[
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
                  "This feature is not available in detail view. Please return to the main dashboard to cancel requests.",
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Got It",
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
}

class ConsumerElectronicsDetailScreen extends StatefulWidget {
  final ConsumerElectronicsRequest request;
  final ConsumerElectronics consumerElectronics;
  final List<dynamic> bids;

  const ConsumerElectronicsDetailScreen({
    super.key,
    required this.request,
    required this.consumerElectronics,
    required this.bids,
  });

  @override
  State<ConsumerElectronicsDetailScreen> createState() =>
      _ConsumerElectronicsDetailScreenState();
}

class _ConsumerElectronicsDetailScreenState
    extends State<ConsumerElectronicsDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Request Header Card
            SizedBox(height: 32),
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              color: Constants.ctaColorLight,
              padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Request ',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_getRequestId(widget.request)}',
                    style: GoogleFonts.manrope(
                      color: Constants.ftaColorLight,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    '\t\t\tInformation',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 64, right: 64),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatDate(widget.request.createdAt),
                                    style: GoogleFonts.manrope(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Spacer(),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showCancelRequestDialog(),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              360,
                                            ),
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
                                "REQUEST ID: ${_getRequestId(widget.request)}",
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
                                      color: Colors.orange,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Description -",
                                          style: GoogleFonts.manrope(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextButton(
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
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _getRequestDescription(
                                        widget.request,
                                        widget.consumerElectronics,
                                      ),
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      widget.request.category ??
                                          "Unknown Category",
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
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'days',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "H",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'hours',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "M",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'minutes',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "S",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'seconds',
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
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
                                          ? "\$${widget.consumerElectronics.budgetTimeline.minPrice!.toStringAsFixed(2)}"
                                          : "-",
                                    ),
                                    _buildDetailItem(
                                      "Max Price",
                                      widget
                                                  .consumerElectronics
                                                  .budgetTimeline
                                                  .maxPrice !=
                                              null
                                          ? "\$${widget.consumerElectronics.budgetTimeline.maxPrice!.toStringAsFixed(2)}"
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
                    FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRequestDescription(dynamic request, dynamic item) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (item?.partDetails?.partName != null &&
              item?.vehicleDetails?.makeModel != null &&
              item?.vehicleDetails?.year != null) {
            return "${item.partDetails.partName}, ${item.vehicleDetails.makeModel}, ${item.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (item?.productDetails != null) {
            final typeOfElectronics =
                item.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference =
                item.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = item.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (item?.productDetails != null) {
            final tyreType = item.productDetails.tyreType ?? "Tyres";
            final tyreWidth = item.productDetails.tyreWidthMm ?? 0;
            final sidewall = item.productDetails.sidewallProfile ?? "";
            final rimDiameter =
                item.productDetails.wheelRimDiameterInches ?? "";
            final brand = item.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${_getRequestId(request)}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable3";
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
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageList.first, // Show first image
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.grey[400],
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Image counter
                    if (imageList.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "1/${imageList.length}",
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // No images available
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (!showImage) ...[
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
      ),
    );
  }

  void _showCancelRequestDialog() {
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
                  "This feature is not available in detail view. Please return to the main dashboard to cancel requests.",
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Got It",
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

class RimTyreDetailScreen extends StatefulWidget {
  final RimTyreRequest request;
  final RimTyre rimTyre;
  final List<dynamic> bids;

  const RimTyreDetailScreen({
    Key? key,
    required this.request,
    required this.rimTyre,
    required this.bids,
  }) : super(key: key);

  @override
  State<RimTyreDetailScreen> createState() => _RimTyreDetailScreenState();
}

class _RimTyreDetailScreenState extends State<RimTyreDetailScreen> {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Request Header Card
            SizedBox(height: 32),
            Container(
              height: 60,
              width: MediaQuery.of(context).size.width,
              color: Constants.ctaColorLight,
              padding: EdgeInsets.only(left: 64, right: 64, top: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {});
                    },
                    icon: Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Request ',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_getRequestId(widget.request)}',
                    style: GoogleFonts.manrope(
                      color: Constants.ftaColorLight,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    '\t\t\tInformation',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 64, right: 64),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatDate(widget.request.createdAt),
                                    style: GoogleFonts.manrope(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Spacer(),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => _showCancelRequestDialog(),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red[300]!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              360,
                                            ),
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
                                "REQUEST ID: ${_getRequestId(widget.request)}",
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
                                      color: Colors.orange,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Description -",
                                          style: GoogleFonts.manrope(
                                            color: Colors.black54,
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextButton(
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
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _getRequestDescription(
                                        widget.request,
                                        widget.rimTyre,
                                      ),
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      widget.request.category ??
                                          "Unknown Category",
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
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'days',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "H",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'hours',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "M",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'minutes',
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildStatusDot(
                                    "S",
                                    _getElapsedTime(
                                      widget.request.createdAt,
                                      'seconds',
                                    ),
                                  ),
                                  Spacer(),
                                ],
                              ),
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
                                      "Tyre Width (mm)",
                                      widget.rimTyre.productDetails.tyreWidthMm
                                          .toString(),
                                    ),
                                    _buildDetailItem(
                                      "Sidewall Profile",
                                      widget
                                          .rimTyre
                                          .productDetails
                                          .sidewallProfile,
                                    ),
                                    _buildDetailItem(
                                      "Wheel Rim Diameter (inches)",
                                      widget
                                          .rimTyre
                                          .productDetails
                                          .wheelRimDiameterInches,
                                    ),
                                    _buildDetailItem(
                                      "Tyre Type",
                                      widget.rimTyre.productDetails.tyreType,
                                    ),
                                    _buildDetailItem(
                                      "Quantity",
                                      widget.rimTyre.productDetails.quantity
                                          .toString(),
                                    ),
                                    _buildDetailItem(
                                      "Urgency",
                                      widget.rimTyre.productDetails.urgency,
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
                                      widget.rimTyre.moreFields.vehicleType,
                                    ),
                                    _buildDetailItem(
                                      "Preferred Brand",
                                      widget.rimTyre.moreFields.preferredBrand,
                                    ),
                                    _buildDetailItem(
                                      "Pitch Circle Diameter",
                                      widget
                                          .rimTyre
                                          .moreFields
                                          .pitchCircleDiameter,
                                    ),
                                    _buildDetailItem(
                                      "Tyre Construction Type",
                                      widget
                                          .rimTyre
                                          .moreFields
                                          .tyreConstructionType,
                                    ),
                                    _buildDetailItem(
                                      "Description",
                                      widget.rimTyre.moreFields.description,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 32),
                              Expanded(
                                child: _buildDetailCard(
                                  "Service Requirements",
                                  Colors.orange,
                                  [
                                    _buildDetailItem(
                                      "Fitment Required",
                                      widget.rimTyre.moreFields.fitmentRequired
                                          ? "Yes"
                                          : "No",
                                    ),
                                    _buildDetailItem(
                                      "Balancing Required",
                                      widget
                                              .rimTyre
                                              .moreFields
                                              .balancingRequired
                                          ? "Yes"
                                          : "No",
                                    ),
                                    _buildDetailItem(
                                      "Tyre Rotation Required",
                                      widget
                                              .rimTyre
                                              .moreFields
                                              .tyreRotationRequired
                                          ? "Yes"
                                          : "No",
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
                    FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRequestDescription(dynamic request, dynamic item) {
    try {
      if (request?.category == null) return "No description available";

      switch (request.category) {
        case "Vehicle Spares":
          if (item?.partDetails?.partName != null &&
              item?.vehicleDetails?.makeModel != null &&
              item?.vehicleDetails?.year != null) {
            return "${item.partDetails.partName}, ${item.vehicleDetails.makeModel}, ${item.vehicleDetails.year}";
          }
          return "Vehicle Spares Request";

        case "Vehicle Tyres and Rims":
          if (item?.productDetails != null) {
            final typeOfElectronics =
                item.productDetails.typeOfElectronics ?? "Electronics";
            final brandPreference =
                item.productDetails.brandPreference ?? "Various Brands";
            final modelSeries = item.productDetails.modelSeries;
            return "$typeOfElectronics, $brandPreference${modelSeries != null ? ', $modelSeries' : ''}";
          }
          return "Electronics Request";

        case "Consumer Electronics":
          if (item?.productDetails != null) {
            final tyreType = item.productDetails.tyreType ?? "Tyres";
            final tyreWidth = item.productDetails.tyreWidthMm ?? 0;
            final sidewall = item.productDetails.sidewallProfile ?? "";
            final rimDiameter =
                item.productDetails.wheelRimDiameterInches ?? "";
            final brand = item.moreFields?.preferredBrand ?? "Various Brands";
            return "$tyreType, $tyreWidth/$sidewall" + "R$rimDiameter, $brand";
          }
          return "Tyre/Rim Request";

        default:
          return "Request #${_getRequestId(request)}";
      }
    } catch (e) {
      print('Error getting description: $e');
      return "Request information unavailable3";
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
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageList.first, // Show first image
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Icon(
                                Icons.tire_repair,
                                color: Colors.grey[400],
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Image counter
                    if (imageList.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "1/${imageList.length}",
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // No images available
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Color(0xFFE0E0E0)),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                    // Navigation arrows
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_back_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: Constants.ftaColorLight,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else if (!showImage) ...[
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
      ),
    );
  }

  void _showCancelRequestDialog() {
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
                  "This feature is not available in detail view. Please return to the main dashboard to cancel requests.",
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Got It",
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

  // Helper method to calculate bid statistics
  Map<String, int> _calculateBidStatistics() {
    List<dynamic> allRequests = [
      ...GlobalVariables.combinedRequest.autoSparesRequest,
      ...GlobalVariables.combinedRequest.rimTyreRequest,
      ...GlobalVariables.combinedRequest.consumerElectronicsRequest,
    ];

    int total = allRequests.length;
    int withBids = 0;
    int withoutBids = 0;
    int vehicleSpares = 0;
    int tyresRims = 0;
    int electronics = 0;
    int active = 0;
    int cancelled = 0;

    for (var request in allRequests) {
      // Count by bid status
      if (request.sellerOffers != null && request.sellerOffers.isNotEmpty) {
        withBids++;
      } else {
        withoutBids++;
      }

      // Count by category
      String category = request.category ?? 'Unknown';
      if (category == 'VEHICLE_SPARES')
        vehicleSpares++;
      else if (category == 'TYRES_RIMS')
        tyresRims++;
      else if (category == 'ELECTRONICS')
        electronics++;

      // Count by status
      //if (_cancelledRequests.contains(_getRequestId(request))) {
      //  cancelled++;
      // } else {
      //  active++;
      // }
    }

    return {
      'total': total,
      'withBids': withBids,
      'withoutBids': withoutBids,
      'vehicleSpares': vehicleSpares,
      'tyresRims': tyresRims,
      'electronics': electronics,
      'active': active,
      'cancelled': cancelled,
    };
  }

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
