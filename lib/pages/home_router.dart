import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/shared_preferences.dart';
import '../constants/Constants.dart';
import '../models/user.dart';
import 'buyer_home.dart';
import 'seller/seller_home_dashboard.dart';
import 'dart:convert';

class HomeRouter extends StatelessWidget {
  const HomeRouter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAuthenticationData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final authData = snapshot.data ?? {};
        final bool isLoggedIn = authData['isLoggedIn'] ?? false;
        final String? userRole = authData['userRole'];
        final String? loginData = authData['loginData'];

        // If not logged in, show login prompt
        if (!isLoggedIn) {
          return _buildLoginPrompt(context);
        }

        // If logged in but no role, try to get from complete login data
        if (userRole == null || userRole.isEmpty) {
          if (loginData != null && loginData.isNotEmpty) {
            try {
              final loginResponse = LoginResponse.fromJsonString(loginData);
              Constants.currentUser = loginResponse.user;
              
              // Route based on user role from login data
              switch (loginResponse.user.role.toLowerCase()) {
                case 'buyer':
                  return BuyerHomePage();
                case 'seller':
                  return SellerDashboard();
                case 'admin':
                  return AdminDashboard();
                default:
                  return _buildLoginPrompt(context);
              }
            } catch (e) {
              // Invalid login data, show login prompt
              return _buildLoginPrompt(context);
            }
          }
          return _buildLoginPrompt(context);
        }

        // Set current user if we have complete login data
        if (loginData != null && loginData.isNotEmpty && Constants.currentUser == null) {
          try {
            final loginResponse = LoginResponse.fromJsonString(loginData);
            Constants.currentUser = loginResponse.user;
          } catch (e) {
            print('Error parsing login data: $e');
          }
        }

        // Route based on user role
        switch (userRole.toLowerCase()) {
          case 'buyer':
            return BuyerHomePage();
          case 'seller':
            return SellerDashboard();
          case 'admin':
            return AdminDashboard();
          default:
            return _buildLoginPrompt(context);
        }
      },
    );
  }

  Future<Map<String, dynamic>> _getAuthenticationData() async {
    final isLoggedIn = await Sharedprefs.getUserLoggedInSharedPreference() ?? false;
    final userRole = await Sharedprefs.getUserRoleSharedPreference();
    final loginData = await Sharedprefs.getCompleteLoginDataSharedPreference();
    
    return {
      'isLoggedIn': isLoggedIn,
      'userRole': userRole,
      'loginData': loginData,
    };
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                child: Image.asset(
                  "lib/assets/images/bidr_logo_with_text.png",
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              
              // Welcome message
              Text(
                'Welcome to Bidr',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Constants.ftaColorLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                'Please sign in to access your dashboard',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Login button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Sign In',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Register link
              TextButton(
                onPressed: () {
                  context.go('/register');
                },
                child: Text(
                  'Don\'t have an account? Sign Up',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Constants.ftaColorLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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