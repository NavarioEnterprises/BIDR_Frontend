import 'package:bidr/constants/Constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iconsax/iconsax.dart';

import '../pages/mobileView/landingPage/landingMobileController.dart';
import '../pages/mobileView/landingPage/landingMobileViewPage.dart';

class BottomMobileBar extends StatefulWidget {
  const BottomMobileBar({super.key});

  @override
  _BottomMobileBarState createState() => _BottomMobileBarState();
}

int currentIndex = 0;
String selectedTitle = "";

class _BottomMobileBarState extends State<BottomMobileBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      body: Column(
        children: [
          // Main content area
          Expanded(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Logo
                Image.asset('lib/assets/images/bidr_logo.png', height: 50),
                const SizedBox(height: 16),
                // Navigation links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, //
                  children: [
                    _buildTopNavLink(
                      'FAQs',
                      () => setState(() {
                        selectedTitle = "FAQs";
                        Constants.buyerAppBarValue = 1;
                        buyerHomeMobileValueNotifier.value++;
                      }),
                    ),
                    const SizedBox(width: 20),
                    _buildTopNavLink(
                      'Policies',
                      () => setState(() {
                        selectedTitle = "Policies";
                        Constants.buyerAppBarValue = 2;
                        buyerHomeMobileValueNotifier.value++;
                      }),
                    ),
                    const SizedBox(width: 20),
                    _buildTopNavLink(
                      'Blogs',
                      () => setState(() {
                        selectedTitle = "Blogs";
                        Constants.buyerAppBarValue = 3;
                        buyerHomeMobileValueNotifier.value++;
                      }),
                    ),
                    const SizedBox(width: 20),
                    _buildTopNavLink(
                      'Contact Us',
                      () => setState(() {
                        selectedTitle = "Contact Us";
                        Constants.buyerAppBarValue = 4;
                        buyerHomeMobileValueNotifier.value++;
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(),
                const SizedBox(height: 8),
                // Copyright text
                Text(
                  '© 2025 BIDR. All rights reserved.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Social media icons
                Column(
                  children: [
                    Wrap(
                      runSpacing: 16,
                      spacing: 16,
                      children: [
                        SocialMediaMobileButton(
                          imagePath: 'lib/assets/images/facebook.png',
                          url: 'https://www.facebook.com',
                        ),
                        SocialMediaMobileButton(
                          imagePath: 'lib/assets/images/instagram.png',
                          url: 'https://www.instagram.com',
                        ),
                        SocialMediaMobileButton(
                          imagePath: 'lib/assets/images/twitter.png',
                          url: 'https://www.x.com',
                        ),
                        SocialMediaMobileButton(
                          imagePath: 'lib/assets/images/linked.png',
                          url: 'https://www.linkedin.com',
                        ),
                        SocialMediaMobileButton(
                          imagePath: 'lib/assets/images/tik2.png',
                          url: 'https://www.tiktok.com',
                        ),
                      ],
                    ),
                  ],
                ), // Space for the curved nav
              ],
            ),
          ),
          CustomBottomNavBar(
            currentIndex: currentIndex,
            onTap: (index) {
              setState(() {
                currentIndex = index;
                currentControllerValueNotifier.value++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavLink(String text, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,

      child: Text(
        text,
        style: GoogleFonts.manrope(
          color: text == selectedTitle
              ? Constants.ctaColorLight
              : Colors.black87,
          fontSize: 12,
          fontWeight: text == selectedTitle ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      child: Stack(
        children: [
          // Orange curved background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 90),
              painter: CurvedPainter(),
            ),
          ),
          // Navigation items
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Iconsax.home, 'Home'),
                  _buildNavItem(
                    1,
                    HugeIcons.strokeRoundedDashboardSquare01,
                    'Categories',
                  ),
                  const SizedBox(width: 70), // Space for center button
                  _buildNavItem(
                    3,
                    HugeIcons.strokeRoundedCustomerSupport,
                    'Support',
                  ),
                  _buildNavItem(4, HugeIcons.strokeRoundedUser, 'Profile'),
                ],
              ),
            ),
          ),
          // Center notification button
          Positioned(
            bottom: 35,
            left: MediaQuery.of(context).size.width / 2 - 18,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFFF6B00), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.bell_fill,
                    color: Constants.ftaColorLight,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          // Bottom white bar indicator
          Positioned(
            bottom: 5,
            left: MediaQuery.of(context).size.width / 2 - 70,
            child: Container(
              width: 140,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the curved background
class CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6B00)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom left
    path.moveTo(0, size.height);
    path.lineTo(0, 10);

    // Create smooth downward curve
    path.quadraticBezierTo(
      size.width * 0.5,
      45, // Control point at center, pushed down
      size.width,
      10,
    );

    // Complete the shape
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
