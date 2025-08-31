import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bidr/constants/Constants.dart';
import '../../models/rewards/rewards_models.dart';
import '../../services/rewards_service.dart';
import 'package:intl/intl.dart';

class RewardsHistoryWidget extends StatefulWidget {
  // TODO: Replace with actual user UUID from authentication
  final String userUuid;

  const RewardsHistoryWidget({
    Key? key,
    required this.userUuid,
  }) : super(key: key);

  @override
  _RewardsHistoryWidgetState createState() => _RewardsHistoryWidgetState();
}

class _RewardsHistoryWidgetState extends State<RewardsHistoryWidget> {
  final RewardsService _rewardsService = RewardsService();
  bool isLoading = false;
  String? errorMessage;
  RewardsDashboard? dashboard;
  List<RewardTransaction> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadRewardsData();
  }

  Future<void> _loadRewardsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final dashboardData = await _rewardsService.getDashboard(widget.userUuid);
      final transactionHistory =
          await _rewardsService.getTransactionHistory(widget.userUuid);

      setState(() {
        dashboard = dashboardData;
        transactions = transactionHistory;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load rewards data. Please try again.';
        isLoading = false;
      });
    }
  }

  Widget _buildRewardsSummary() {
    if (dashboard == null) return SizedBox.shrink();

    final summary = dashboard!.summary;
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rewards Points Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${summary.currentPointsBalance.toStringAsFixed(0)} points',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  summary.tierName,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Points Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatisticItem(
                'Total Earned',
                summary.totalPointsEarned.toStringAsFixed(0),
                Icons.add_circle_outline,
                Colors.green,
              ),
              _buildStatisticItem(
                'Total Spent',
                summary.totalPointsSpent.toStringAsFixed(0),
                Icons.remove_circle_outline,
                Colors.red,
              ),
              _buildStatisticItem(
                'Next Tier In',
                '${summary.pointsToNextTier} pts',
                Icons.trending_up,
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Constants.ftaColorLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No transactions yet. Start earning rewards!',
            style: GoogleFonts.manrope(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isPositive = transaction.pointsAmount >= 0;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),

              SizedBox(width: 16),

              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy h:mm a').format(transaction.createdAt),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Points Amount
              Text(
                '${isPositive ? '+' : ''}${transaction.pointsAmount.toStringAsFixed(0)} pts',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage!,
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRewardsData,
              child: Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.35,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRewardsSummary(),
            SizedBox(height: 24),
            Text(
              'Transaction History',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Constants.ftaColorLight,
              ),
              textAlign: TextAlign.left,
            ),
            SizedBox(height: 16),
            _buildTransactionsList(),
          ],
        ),
      ),
    );
  }
}
