import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/shared_preferences.dart';
import 'buyer_home.dart';
import 'seller/seller_home_dashboard.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: Sharedprefs.getUserRoleSharedPreference(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userRole = snapshot.data;

        // If no role is found, redirect to login
        if (userRole == null || userRole.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
          return const SizedBox.shrink();
        }

        // Route based on user role
        switch (userRole.toLowerCase()) {
          case 'buyer':
            return BuyerHomePage();
          case 'seller':
            return SellerDashboard();
          case 'admin':
            // For now, show a placeholder for admin
            return AdminDashboard();
          default:
            // Unknown role, redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/');
            });
            return const SizedBox.shrink();
        }
      },
    );
  }
}

// Placeholder Admin Dashboard
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear shared preferences
              await Sharedprefs.saveUserLoggedInSharedPreference(false);
              await Sharedprefs.saveUserAccessTokenSharedPreference('');
              await Sharedprefs.saveUserRefreshTokenSharedPreference('');
              await Sharedprefs.saveUserRoleSharedPreference('');
              
              // Navigate to login
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 80),
            SizedBox(height: 20),
            Text(
              'Admin Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Admin features coming soon...'),
          ],
        ),
      ),
    );
  }
}