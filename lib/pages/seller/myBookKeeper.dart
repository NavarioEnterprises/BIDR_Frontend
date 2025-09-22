import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../config/environment_config.dart';
import '../../constants/Constants.dart';
import '../../services/products_management_api_service.dart';

class MyBookkeeperScreen extends StatefulWidget {
  @override
  _MyBookkeeperScreenState createState() => _MyBookkeeperScreenState();
}

class _MyBookkeeperScreenState extends State<MyBookkeeperScreen> {
  int selectedBookkeeperTab = -1; // -1 means no selection initially
  int selectedSubIndex = 0; // For sub-tabs in transaction history

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

  // Orders summary state variables
  Map<String, dynamic>? ordersSummary;
  bool isLoadingOrdersSummary = true;
  String? ordersSummaryError;
  String selectedTimeframe = 'monthly'; // daily, weekly, monthly, yearly

  final List<BookkeeperMenuItem> menuItems = [
    BookkeeperMenuItem(
      title: 'Revenue\nTracker',
      icon: Icons.trending_up,
      isEnabled: true,
      color: Constants.ctaColorLight, // Orange color matching the image
    ),
    BookkeeperMenuItem(
      title: 'Transaction\nHistory',
      icon: Icons.history,
      isEnabled: true,
      color: Constants.ctaColorLight, // Orange color matching the image
    ),
    BookkeeperMenuItem(
      title: 'Manage\nDisputes',
      icon: Icons.gavel,
      isEnabled: true,
      color: Constants.ctaColorLight, // Orange color matching the image
    ),
    BookkeeperMenuItem(
      title: 'Analytics',
      icon: Icons.analytics,
      isEnabled: true, // Disabled as shown in the image (grayed out)
      color: Constants.ctaColorLight,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrdersSummary();
    _fetchQuotesData();
    _fetchRequestsData();
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

  Future<void> _fetchOrdersSummary({String? timeframe}) async {
    final String requestedTimeframe = timeframe ?? selectedTimeframe;

    try {
      setState(() {
        isLoadingOrdersSummary = true;
        ordersSummaryError = null;
        // Update the selectedTimeframe if a specific timeframe was requested
        if (timeframe != null) {
          selectedTimeframe = timeframe;
        }
      });

      final response = await ApiService.getSellerOrdersSummary(
        authUserUid: Constants.myUid,
        timeframe: requestedTimeframe,
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

  /* Future<void> _fetchOrdersSummary() async {
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
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "My Bookkeeper",
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Grid of menu items
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _buildBookkeeperMenuItem(menuItems[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookkeeperMenuItem(BookkeeperMenuItem item, int index) {
    bool isSelected = selectedBookkeeperTab == index;
    bool isEnabled = item.isEnabled;

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEnabled
              ? () {
                  print('Bookkeeper tab clicked: $index, title: ${item.title}');
                  setState(() {
                    selectedBookkeeperTab = isSelected ? -1 : index;
                  });

                  // Handle menu item tap to show content
                  _handleMenuItemTap(item, index);
                }
              : null,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isSelected ? Colors.grey.shade400 : item.color,
              border: Border.all(color: Colors.white, width: 5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                // Title
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuItemTap(BookkeeperMenuItem item, int index) {
    // Handle different menu item actions - navigate to new pages
    switch (index) {
      case 0: // Revenue Tracker
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                RevenueTrackerPage(),
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
      case 1: // Transaction History
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                TransactionHistoryPage(
                  quotes: myQuotes,
                  isLoadingQuotes: isLoadingQuotes,
                  quotesError: quotesError,
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
      case 2: // Manage Disputes
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ManageDisputesPage(),
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
      case 3: // Analytics (disabled)
        if (item.isEnabled) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AnalyticsPage(),
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
        } else {
          _showAnalyticsComingSoon();
        }
        break;
    }
  }

  void _showAnalyticsComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('Analytics feature coming soon!'),
          ],
        ),
        backgroundColor: Colors.grey[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class BookkeeperMenuItem {
  final String title;
  final IconData icon;
  final bool isEnabled;
  final Color color;

  BookkeeperMenuItem({
    required this.title,
    required this.icon,
    required this.isEnabled,
    required this.color,
  });
}

// Revenue Tracker Page
class RevenueTrackerPage extends StatefulWidget {
  const RevenueTrackerPage({Key? key}) : super(key: key);

  @override
  _RevenueTrackerPageState createState() => _RevenueTrackerPageState();
}

class _RevenueTrackerPageState extends State<RevenueTrackerPage> {
  String selectedTimeframe = 'monthly'; // Default timeframe
  Map<String, dynamic>? ordersSummary;
  bool isLoadingOrdersSummary = true;
  String? ordersSummaryError;

  // Additional data for quotes if needed
  List<dynamic> myQuotes = [];
  bool isLoadingQuotes = true;
  String? quotesError;

  @override
  void initState() {
    super.initState();
    _fetchOrdersSummary();
    _fetchQuotesData();
  }

  Future<void> _fetchOrdersSummary({String? timeframe}) async {
    final String requestedTimeframe = timeframe ?? selectedTimeframe;

    try {
      setState(() {
        isLoadingOrdersSummary = true;
        ordersSummaryError = null;
        if (timeframe != null) {
          selectedTimeframe = timeframe;
        }
      });

      final response = await ApiService.getSellerOrdersSummary(
        authUserUid: Constants.myUid,
        timeframe: requestedTimeframe,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Revenue Tracker',
          style: GoogleFonts.manrope(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(padding: EdgeInsets.all(20), child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (isLoadingOrdersSummary) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Color(0xFFE67E22),
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
              onPressed: () => _fetchOrdersSummary(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    final summary = ordersSummary?['summary'] ?? {};

    // Filter data based on selected timeframe
    final filteredData = _filterDataByTimeframe(summary);
    final totalRevenue = (filteredData['total_revenue'] ?? 0.0) as double;
    final totalOrders = (filteredData['total_orders'] ?? 0) as int;
    final avgOrderValue =
        (filteredData['average_order_value'] ?? 0.0) as double;
    final ordersByStatus = (filteredData['orders_by_status'] ?? []) as List;
    final chartData = (filteredData['chart_data'] ?? []) as List;

    return SingleChildScrollView(
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Revenue Display with Charts
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFE8E8E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Revenue',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showTimeframeSelector,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFFE67E22).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color(0xFFE67E22).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getTimeframeLabel(selectedTimeframe),
                                style: GoogleFonts.manrope(
                                  color: Color(0xFFE67E22),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFFE67E22),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
                          color: Color(0xFFE67E22),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMetricItem('Orders', totalOrders.toString()),
                      SizedBox(width: 24),
                      _buildMetricItem(
                        'Avg Value',
                        'R${avgOrderValue.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (chartData.isNotEmpty) ...[
              SizedBox(height: 16),
              Container(
                height: 200,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Revenue Card with Animation
                // Pie Chart with Legend
                if (ordersByStatus.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 200,
                      child: Row(
                        children: [
                          // Pie Chart
                          Expanded(
                            flex: 2,
                            child: PieChart(
                              PieChartData(
                                sections: _buildPieChartSections(
                                  ordersByStatus,
                                ),
                                centerSpaceRadius: 40,
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
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: Color(0xFF7F8C8D),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
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
          color: Color(0xFFE67E22),
          width: 24,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
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

    final statusColors = {
      'PENDING': Color(0xFF3498DB),
      'PAID': Color(0xFF2ECC71),
      'COMPLETED': Color(0xFFE67E22),
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
      'COMPLETED': Color(0xFFE67E22),
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

  Widget _buildLegendItem(Color color, String value, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
            ],
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
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
    bool isSelected = selectedTimeframe == value;
    return SimpleDialogOption(
      onPressed: () async {
        Navigator.pop(context);
        // Refresh data with new timeframe
        await _fetchOrdersSummary(timeframe: value);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Color(0xFFE67E22) : Colors.grey,
              size: 20,
            ),
            SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Color(0xFFE67E22) : Colors.black87,
              ),
            ),
          ],
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

  Map<String, dynamic> _filterDataByTimeframe(Map<String, dynamic> summary) {
    if (summary.isEmpty) return summary;

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    // Define date range based on selected timeframe
    switch (selectedTimeframe) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'weekly':
        final weekday = now.weekday;
        startDate = now.subtract(Duration(days: weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(
          Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case 'yearly':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case 'monthly':
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    // Filter chart data
    final List<dynamic> originalChartData = summary['chart_data'] ?? [];
    final List<dynamic> filteredChartData = originalChartData.where((item) {
      if (item['period'] == null) return false;

      try {
        DateTime periodDate;

        // Parse different period formats based on timeframe
        switch (selectedTimeframe) {
          case 'daily':
            // Format: "2024-01-15" or similar
            periodDate = DateTime.parse(item['period'].toString());
            break;
          case 'weekly':
            // Format: "Week 1" or "2024-W01"
            if (item['period'].toString().contains('Week')) {
              // For now, include all weeks in range
              return true;
            }
            periodDate = DateTime.parse(item['period'].toString());
            break;
          case 'yearly':
            // Format: "2024" or similar
            if (item['period'].toString().length == 4) {
              final year = int.parse(item['period'].toString());
              return year == now.year;
            }
            periodDate = DateTime.parse(item['period'].toString());
            break;
          case 'monthly':
          default:
            // Format: "2024-01" or "January" or similar
            if (item['period'].toString().contains('-')) {
              periodDate = DateTime.parse('${item['period']}-01');
            } else {
              // For month names, assume current year
              periodDate = DateTime.parse(item['period'].toString());
            }
            break;
        }

        return periodDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            periodDate.isBefore(endDate.add(Duration(days: 1)));
      } catch (e) {
        // If parsing fails, include the item to be safe
        return true;
      }
    }).toList();

    // Calculate filtered totals
    double filteredRevenue = 0.0;
    int filteredOrders = 0;

    for (final item in filteredChartData) {
      filteredRevenue += (item['revenue'] ?? 0.0) as double;
      filteredOrders += (item['orders'] ?? 0) as int;
    }

    final double avgOrderValue = filteredOrders > 0
        ? filteredRevenue / filteredOrders
        : 0.0;

    // Return filtered data structure
    return {
      'total_revenue': filteredRevenue,
      'total_orders': filteredOrders,
      'average_order_value': avgOrderValue,
      'orders_by_status':
          summary['orders_by_status'] ?? [], // Keep original status data
      'chart_data': filteredChartData,
    };
  }
}

// Transaction History Page
class TransactionHistoryPage extends StatefulWidget {
  final List<dynamic> quotes;
  final bool isLoadingQuotes;
  final String? quotesError;

  const TransactionHistoryPage({
    Key? key,
    required this.quotes,
    required this.isLoadingQuotes,
    this.quotesError,
  }) : super(key: key);

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  int selectedSubIndex = 0; // 0: Earnings, 1: Withdraw

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

  @override
  void initState() {
    super.initState();
    // Load earning history by default
    _loadEarningHistory();
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

          currentEarningsPage = page;
          totalEarningsCount = data['count'] ?? 0;
          hasNextEarningsPage = data['next'] != null;
          isLoadingEarnings = false;
          earningsError = null;
        });
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

          currentWithdrawsPage = page;
          totalWithdrawsCount = data['count'] ?? 0;
          hasNextWithdrawsPage = data['next'] != null;
          isLoadingWithdraws = false;
          withdrawsError = null;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Transaction History",
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Tab Navigation
            Row(
              children: [
                _buildSubTab('Earning History', 0),
                _buildSubTab('Withdraw History', 1),
              ],
            ),
            SizedBox(height: 16),
            // Transaction List
            Expanded(
              child: selectedSubIndex == 0
                  ? _buildEarningHistoryContent()
                  : _buildWithdrawHistoryContent(),
            ),
          ],
        ),
      ),
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
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Color(0xFFE67E22) : Colors.transparent,
                width: 2.2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              color: isSelected ? Color(0xFFE67E22) : Color(0xFF7F8C8D),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
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
            color: Color(0xFFE67E22),
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
                  backgroundColor: Color(0xFFE67E22),
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
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Column(
            children: earningHistory.asMap().entries.map((entry) {
              final earning = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: _buildEarningTransactionItem(earning),
              );
            }).toList(),
          ),
        ),

        // Load more button if there are more pages
        if (hasNextEarningsPage)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: () =>
                  _loadEarningHistory(page: currentEarningsPage + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE67E22),
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
                color: Color(0xFFE67E22),
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
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadWithdrawHistory(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE67E22),
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
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Column(
            children: withdrawHistory.asMap().entries.map((entry) {
              final withdraw = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                child: _buildWithdrawTransactionItem(withdraw),
              );
            }).toList(),
          ),
        ),

        // Load more button if there are more pages
        if (hasNextWithdrawsPage)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: () =>
                  _loadWithdrawHistory(page: currentWithdrawsPage + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE67E22),
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

  Widget _buildEarningTransactionItem(Map<String, dynamic> earning) {
    final amount = earning['total_amount']?.toString() ?? '0.00';
    final currency = earning['currency'] ?? 'ZAR';
    final paymentDate = earning['payment_date'] ?? earning['created_at'] ?? '';
    final buyerId = earning['buyer_id']?.toString() ?? '';
    final buyerName = buyerId.isNotEmpty
        ? 'Buyer ${buyerId.substring(0, 8)}...'
        : 'Unknown Buyer';
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
    Color statusColor = Color(0xFFE67E22);
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
        statusColor = Color(0xFFE67E22);
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
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawTransactionItem(Map<String, dynamic> withdraw) {
    final amount = withdraw['total_amount']?.toString() ?? '0.00';
    final currency = withdraw['currency'] ?? 'ZAR';
    final refundDate = withdraw['refunded_at'] ?? withdraw['created_at'] ?? '';
    final withdrawStatus = withdraw['status'] ?? 'REFUNDED';
    final productInfo = withdraw['request_title'] ?? 'Product/Service';

    // Format the date
    String formattedDate = '';
    try {
      final dateTime = DateTime.parse(refundDate);
      formattedDate = DateFormat('dd MMM yyyy, h:mm a').format(dateTime);
    } catch (e) {
      formattedDate = refundDate;
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
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.remove_circle, color: Colors.red, size: 20),
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
                        'Refund Processed',
                        style: GoogleFonts.manrope(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '-$currency $amount',
                      style: GoogleFonts.manrope(
                        color: Colors.red,
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
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                    SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: GoogleFonts.manrope(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}

// Manage Disputes Page
class ManageDisputesPage extends StatefulWidget {
  const ManageDisputesPage({Key? key}) : super(key: key);

  @override
  _ManageDisputesPageState createState() => _ManageDisputesPageState();
}

class _ManageDisputesPageState extends State<ManageDisputesPage> {
  // Disputed orders data state variables
  List<dynamic> disputedOrders = [];
  bool isLoadingDisputes = true;
  String? disputesError;

  // Resolved disputes data state variables
  List<dynamic> resolvedDisputes = [];
  bool isLoadingResolvedDisputes = true;
  String? resolvedDisputesError;

  int selectedDisputeTab = 0; // 0: Active, 1: Resolved

  @override
  void initState() {
    super.initState();
    _fetchDisputedOrders();
    _fetchResolvedDisputes();
  }

  Future<void> _fetchDisputedOrders() async {
    try {
      setState(() {
        isLoadingDisputes = true;
        disputesError = null;
      });

      final response = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=REFUND_REQUESTED',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] ?? [];

        setState(() {
          disputedOrders = results;
          isLoadingDisputes = false;
        });
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
    }
  }

  Future<void> _fetchResolvedDisputes() async {
    try {
      setState(() {
        isLoadingResolvedDisputes = true;
        resolvedDisputesError = null;
      });

      final refundedResponse = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=REFUNDED',
        ),
        headers: {'Content-Type': 'application/json'},
      );
      final cancelledResponse = await http.get(
        Uri.parse(
          '${AppConfig.productsServiceUrl}api/v1/product-requests/orders/?seller_id=${Constants.myUid}&status=CANCELLED',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      List<dynamic> allResolvedOrders = [];

      if (refundedResponse.statusCode == 200) {
        final refundedData = json.decode(refundedResponse.body);
        final refundedResults = refundedData['results'] ?? [];
        allResolvedOrders.addAll(refundedResults);
      }

      if (cancelledResponse.statusCode == 200) {
        final cancelledData = json.decode(cancelledResponse.body);
        final cancelledResults = cancelledData['results'] ?? [];
        allResolvedOrders.addAll(cancelledResults);
      }

      // Sort by updated_at (most recent first)
      allResolvedOrders.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['updated_at'] ?? '') ?? DateTime.now();
        final bDate =
            DateTime.tryParse(b['updated_at'] ?? '') ?? DateTime.now();
        return bDate.compareTo(aDate);
      });

      setState(() {
        resolvedDisputes = allResolvedOrders;
        isLoadingResolvedDisputes = false;
      });
    } catch (e) {
      setState(() {
        resolvedDisputesError = 'Network error: ${e.toString()}';
        isLoadingResolvedDisputes = false;
      });
    }
  }

  String _extractBuyerName(dynamic order) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Manage Disputes",
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Tab Navigation
            Row(
              children: [
                Expanded(
                  child: _buildDisputeTab(
                    'Active Disputes (${disputedOrders.length})',
                    0,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(child: _buildDisputeTab('Resolved (${resolvedDisputes.length})', 1)),
              ],
            ),
            SizedBox(height: 20),
            // Content based on selected tab
            Expanded(
              child: selectedDisputeTab == 0
                  ? _buildActiveDisputesContent()
                  : _buildResolvedDisputesContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeTab(String title, int index) {
    bool isSelected = selectedDisputeTab == index;
    Color tabColor = index == 0 ? Colors.red : Colors.green;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedDisputeTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? tabColor.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? tabColor : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              index == 0 ? Icons.warning : Icons.check_circle,
              color: isSelected ? tabColor : Colors.grey[600],
              size: 14,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  color: isSelected ? tabColor : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDisputesContent() {
    if (isLoadingDisputes) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
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
                backgroundColor: Color(0xFFE67E22),
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
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No Active Disputes',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All your transactions are running smoothly!',
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: disputedOrders.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildDisputeCard(disputedOrders[index]);
      },
    );
  }

  Widget _buildResolvedDisputesContent() {
    if (isLoadingResolvedDisputes) {
      return Center(child: CircularProgressIndicator(color: Color(0xFFE67E22)));
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
                backgroundColor: Color(0xFFE67E22),
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
            Icon(Icons.assignment_turned_in, size: 80, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No Resolved Disputes',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Resolved disputes will appear here',
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: resolvedDisputes.length,
      separatorBuilder: (context, index) => SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildResolvedDisputeCard(resolvedDisputes[index]);
      },
    );
  }

  Widget _buildDisputeCard(dynamic order) {
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
    final double amount = double.parse(order['total_amount']);
    final String status = order['status'] ?? 'REFUND_REQUESTED';

    return Container(
      width: double.infinity,
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
          // Header
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
                    color: Color(0xFFE67E22),
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(360),
                      topLeft: Radius.circular(360),
                    ),
                  ),
                  child: Text(
                    'DISPUTED',
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
          // Content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      buyerName,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      'ZAR ${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      '$date at $time',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showDeclineDialog(order),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.red[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                        onPressed: () => _showApproveDialog(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
        ],
      ),
    );
  }

  Widget _buildResolvedDisputeCard(dynamic order) {
    final String orderId = order['order_number'] ?? 'N/A';
    final String orderIdFormatted =
        'RD-${orderId.replaceAll('-', '').toUpperCase()}';
    final String buyerName = _extractBuyerName(order);
    final DateTime updatedAt =
        DateTime.tryParse(order['updated_at'] ?? '') ?? DateTime.now();
    final String date =
        '${updatedAt.day} ${_getMonthName(updatedAt.month)} ${updatedAt.year}';
    final double amount = double.parse(order['total_amount'] ?? 0.0);
    final String status = order['status'] ?? 'RESOLVED';

    Color statusColor = status == 'REFUNDED' ? Colors.red : Colors.orange;
    String statusText = status == 'REFUNDED' ? 'REFUNDED' : 'CANCELLED';

    return Container(
      width: double.infinity,
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
          // Header
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
                    color: statusColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(360),
                      topLeft: Radius.circular(360),
                    ),
                  ),
                  child: Text(
                    statusText,
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
          // Content
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      buyerName,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedPayment01,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ZAR ${amount.toStringAsFixed(2)}',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Resolved on $date',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(dynamic order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Approve Dispute'),
          ],
        ),
        content: Text(
          'Are you sure you want to approve this dispute? The buyer will receive a full refund.',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would call the API to approve the dispute
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dispute approved - Refund will be processed'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(dynamic order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Decline Dispute'),
          ],
        ),
        content: Text(
          'Are you sure you want to decline this dispute? Please ensure you have valid reasons.',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Here you would call the API to decline the dispute
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dispute declined'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Decline'),
          ),
        ],
      ),
    );
  }
}

// Analytics Page - Mobile Optimized
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
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
          "Analytics Plans",
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your Analytics Plan',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Unlock powerful insights to grow your business',
              style: GoogleFonts.manrope(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 30),
            // Mobile-optimized vertical layout
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Starter Plan with Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: _buildPricingCard(
                            'Starter Plan',
                            'R199',
                            '/month',
                            _getStarterFeatures(),
                            false,
                            0,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    // Advanced Plan with Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 800),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: _buildPricingCard(
                            'Advanced Plan',
                            'R299',
                            '/month',
                            _getAdvanceFeatures(),
                            true,
                            1,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    // Enterprise Plan with Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: _buildPricingCard(
                            'Enterprise Plan',
                            'R499',
                            '/month',
                            _getEnterpriseFeatures(),
                            false,
                            2,
                          ),
                        );
                      },
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

  Widget _buildPricingCard(
    String title,
    String price,
    String period,
    List<String> features,
    bool isPopular,
    int index,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular ? Color(0xFFE67E22) : Colors.grey[200]!,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isPopular ? 0.15 : 0.05),
            blurRadius: isPopular ? 20 : 8,
            offset: Offset(0, isPopular ? 8 : 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Popular badge
          if (isPopular)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Color(0xFFE67E22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'MOST POPULAR',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          // Plan title
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          // Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67E22),
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
          // Features list
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features.asMap().entries.map((entry) {
              int featureIndex = entry.key;
              String feature = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (featureIndex * 100)),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset((1 - value) * 20, 0),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
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
            }).toList(),
          ),
          SizedBox(height: 24),
          // Choose plan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPlanDialog(title),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular
                    ? Color(0xFFE67E22)
                    : Colors.grey[100],
                foregroundColor: isPopular ? Colors.white : Colors.grey[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isPopular ? 4 : 0,
              ),
              child: Text(
                isPopular ? 'Get Started' : 'Choose Plan',
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

  void _showPlanDialog(String planName) {
    // This would typically integrate with payment processing
    print('Selected plan: $planName');
  }

  List<String> _getStarterFeatures() {
    return [
      'Basic analytics dashboard',
      'Monthly revenue reports',
      'Transaction history (last 30 days)',
      'Email support',
      'Export to PDF',
    ];
  }

  List<String> _getAdvanceFeatures() {
    return [
      'Advanced analytics dashboard',
      'Real-time reports & insights',
      'Custom date ranges',
      'Export to PDF/Excel',
      'Priority support',
      'API access',
      'Customer behavior analytics',
      'Revenue forecasting',
    ];
  }

  List<String> _getEnterpriseFeatures() {
    return [
      'Complete analytics suite',
      'White-label reports',
      'Advanced integrations',
      'Dedicated account manager',
      'Custom reporting',
      'Multi-user access',
      'Advanced security',
      'Custom API endpoints',
      'Business intelligence tools',
    ];
  }
}
