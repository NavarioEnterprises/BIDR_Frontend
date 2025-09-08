
import 'package:flutter/material.dart';

class BuyerDashboard extends StatelessWidget {
  const BuyerDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5A623), // Orange background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5A623),
        elevation: 0,
        toolbarHeight: 80, // Increased height for better proportions
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buyer Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'BIDR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                IconButton(
                  onPressed: () {
                    // Handle notification tap
                  },
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                // Notification dot
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // First row with Profile and Categories
            Row(
              children: [
                Expanded(
                  child: _buildDashboardCard(
                    icon: Icons.person_outline,
                    title: 'Profile',
                    onTap: () {
                      // Handle profile tap
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDashboardCard(
                    icon: Icons.grid_view_rounded,
                    title: 'Categories',
                    onTap: () {
                      // Handle categories tap
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Second row with Refer A Friend / Business
            _buildDashboardCard(
              icon: Icons.person_add_outlined,
              title: 'Refer A Friend / Business',
              isFullWidth: true,
              onTap: () {
                // Handle refer tap
              },
            ),
            const SizedBox(height: 16),
            // Third row with Transaction Management
            _buildDashboardCard(
              icon: Icons.check_circle_outline,
              title: 'Transaction Management',
              isFullWidth: true,
              onTap: () {
                // Handle transaction management tap
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50), // Dark blue color
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}