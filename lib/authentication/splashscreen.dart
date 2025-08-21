import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../constants/Constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  String selectedAccountType = '';
  int selectedIndex = -1;

  final List<Map<String, dynamic>> accountTypes = [
    {
      'icon': HugeIcons.strokeRoundedUser,
      'name': 'BUYER',
      'value': 'buyer',
      'description': 'Purchase products through competitive bidding',
      'color': Colors.grey,
      'selectedColor': Colors.grey[600],
    },
    {
      'icon': HugeIcons.strokeRoundedStore01,
      'name': 'BUSINESS',
      'value': 'seller',
      'description': 'List products and receive buyer requests',
      'color': Colors.orange,
      'selectedColor': Color(0xFF1B4D72), // Dark blue from the image
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: Constants.gtaColorLight,width: 20),
        ),

        child: Row(
          children: [
            // Left side - Background image with overlay
            Expanded(
              flex: 2,
              child: Stack(
                fit: StackFit.loose,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      topLeft: Radius.circular(0),
                    ),
                    child: Image.asset(
                      "lib/assets/covers/Group 1171275363.png",
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.height,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: OutlinedButton.icon(
                        onPressed: (){
                          context.go('/login');
                        },
                        style: OutlinedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            foregroundColor: Constants.ftaColorLight
                        ),
                        icon: Icon(CupertinoIcons.back),
                        label: Text(
                          'Back',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,

                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // Right side - Registration form
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(0),
                    topRight: Radius.circular(0),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Image.asset(
                          "lib/assets/images/bidr_logo_with_text.png",
                          fit: BoxFit.contain,
                          width: 180,
                          height: 180,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'How would you like to\nregister your account?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Account type selection with horizontal layout
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: accountTypes.asMap().entries.map((
                              entry,
                              ) {
                            int index = entry.key;
                            var accountType = entry.value;
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(
                                milliseconds: 600 + (index * 200),
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 30 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.9 + (0.1 * value),
                                      child: _accountTypeCard(
                                        accountType["icon"]!,
                                        accountType["name"]!,
                                        accountType["description"]!,
                                        accountType["color"]!,
                                        accountType["selectedColor"]!,
                                        accountType["value"]!,
                                        index,
                                        selectedIndex,
                                            () => _onAccountTypeTap(
                                          index,
                                          accountType["value"]!,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Selected account description
                      Container(
                        height: 60,
                        child: selectedIndex != -1
                            ? AnimatedOpacity(
                          duration: Duration(milliseconds: 300),
                          opacity: 1.0,
                          child: Container(
                            width:
                            MediaQuery.of(context).size.width *
                                0.4,
                            child: Text(
                              accountTypes[selectedIndex]["description"]!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                height: 1.4,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                            : SizedBox(),
                      ),

                      const SizedBox(height: 20),

                      // Get Started button
                      SizedBox(
                        width: 420,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: selectedIndex != -1
                              ? () {
                            // Handle registration based on selected type
                            debugPrint(
                              'Selected account type: $selectedAccountType',
                            );
                            if (selectedAccountType == "seller") {
                              context.go('/register/seller');
                            } else {
                              context.go('/register/buyer');
                            }
                            setState(() {});
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedIndex != -1
                                ? Constants.ctaColorLight
                                : Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: selectedIndex != -1 ? 6 : 0,
                            shadowColor: Colors.black54,
                          ),
                          child: Text(
                            "Let's Get Started",
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: selectedIndex != -1
                                  ? Colors.white
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAccountTypeTap(int index, String value) {
    setState(() {
      selectedIndex = index;
      selectedAccountType = value;
    });
  }

  Widget _accountTypeCard(
    IconData icon,
    String name,
    String description,
    Color color,
    Color selectedColor,
    String value,
    int index,
    int selectedIndex,
    VoidCallback onTap,
  ) {
    final isSelected = index == selectedIndex;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Constants.ftaColorLight : Colors.grey,
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? Constants.ctaColorLight.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: isSelected ? 15 : 8,
                    offset: const Offset(0, 4),
                    spreadRadius: isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // color: isSelected ? Constants.ctaColorLight : Colors.grey[200],
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isSelected
                      ? Constants.ftaColorLight
                      : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Constants.ctaColorLight : Colors.grey[600]!,
                letterSpacing: 1.2,
              ),
              child: Text(name),
            ),
          ],
        ),
      ),
    );
  }
}
