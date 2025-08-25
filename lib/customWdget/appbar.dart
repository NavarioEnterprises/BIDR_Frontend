import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../constants/Constants.dart';
import '../notifier/my_notifier.dart';
import '../pages/buyer_home.dart';
import '../services/shared_preferences.dart';

class HeaderSection extends StatefulWidget {
  const HeaderSection({Key? key}) : super(key: key);

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

MyNotifier? myNotifier1;
final appBarValueNotifier = ValueNotifier<int>(0);

class _HeaderSectionState extends State<HeaderSection> {
  void initState() {
    myNotifier1 = MyNotifier(appBarValueNotifier, context);
    appBarValueNotifier.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        /*boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],*/
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            "lib/assets/images/bidr_logo1.png",
            fit: BoxFit.contain,
            height: 50,
            width: 80,
          ),

          Wrap(
            runSpacing: 16,
            children: [
              _navButton(
                'Home',
                0,
                () => setState(() {
                  Constants.buyerAppBarValue = 0;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                }),
              ),
              _navButton(
                'Support',
                1,
                () => setState(() {
                  Constants.buyerAppBarValue = 1;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                }),
              ),
              _navButton(
                'FAQs',
                2,
                () => setState(() {
                  Constants.buyerAppBarValue = 2;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                }),
              ),
              _navButton(
                'Policies',
                3,
                () => setState(() {
                  Constants.buyerAppBarValue = 3;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                }),
              ),
              _navButton(
                'Blogs',
                4,
                () => setState(() {
                  Constants.buyerAppBarValue = 4;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                }),
              ),
              _navButton(
                'Contact Us',
                5,
                () => setState(() {
                  Constants.buyerAppBarValue = 5;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                }),
              ),
            ],
          ),
          _buildAuthenticationButtons(),
        ],
      ),
    );
  }

  Widget _buildAuthenticationButtons() {
    // Check if user is logged in and get role
    final bool isLoggedIn = Constants.currentUser != null;
    final String? userRole = Constants.currentUser?.role;

    if (isLoggedIn && userRole != null) {
      // User is logged in - show appropriate dashboard based on role
      switch (userRole.toLowerCase()) {
        case 'seller':
          return Row(
            children: [
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Seller Dashboard',
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
              SizedBox(width: 12),
              _buildLogoutButton(),
            ],
          );
        case 'buyer':
          return Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    Constants.buyerAppBarValue = 6;
                    context.go('/dashboard');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Buyer Dashboard',
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
              SizedBox(width: 12),
              _buildLogoutButton(),
            ],
          );
        default:
          return _buildLoginButton();
      }
    } else {
      // User is not logged in - show login button
      return _buildLoginButton();
    }
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: () => context.go('/login'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Constants.ctaColorLight,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text('Login', style: GoogleFonts.manrope(color: Colors.white)),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () async {
        // Clear all authentication data from Constants
        Constants.currentUser = null;
        Constants.isLoggedIn = false;
        Constants.myUid = "";
        Constants.userId = -1;
        Constants.myDisplayname = "Guest";
        Constants.myCategoryRole = "";
        Constants.myEmail = "";
        Constants.myCell = "";

        // Clear SharedPreferences
        await Sharedprefs.saveUserLoggedInSharedPreference(false);
        await Sharedprefs.saveUserAccessTokenSharedPreference('');
        await Sharedprefs.saveUserRefreshTokenSharedPreference('');
        await Sharedprefs.saveUserRoleSharedPreference('');
        await Sharedprefs.saveCompleteLoginDataSharedPreference('');

        // Navigate to login
        if (mounted) {
          context.go('/');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: Constants.ftaColorLight, width: 1.4),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        'Logout',
        style: GoogleFonts.manrope(color: Constants.ftaColorLight),
      ),
    );
  }

  Widget _navButton(String text, int index, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IntrinsicWidth(
            child: Container(
              constraints: BoxConstraints(minWidth: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onPressed,
                    // style: TextButton.styleFrom(),
                    child: Text(
                      text,
                      style: GoogleFonts.manrope(
                        color: index == Constants.buyerAppBarValue
                            ? Constants.ftaColorLight
                            : Colors.black45,
                        fontSize: 13,
                        fontWeight: index == Constants.buyerAppBarValue
                            ? FontWeight.bold
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  index == Constants.buyerAppBarValue
                      ? SizedBox(height: 2)
                      : SizedBox.shrink(),
                  index == Constants.buyerAppBarValue
                      ? Padding(
                          padding: const EdgeInsets.only(left: 12, right: 12),
                          child: Container(
                            height: 2,
                            color: Constants.ctaColorLight,
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
