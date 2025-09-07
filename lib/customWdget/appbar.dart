import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../constants/Constants.dart';
import '../notifier/my_notifier.dart';
import '../pages/buyer_home.dart';
import '../pages/mobileView/breakpoints.dart';
import '../services/shared_preferences.dart';

class HeaderSection extends StatefulWidget {
  const HeaderSection({Key? key}) : super(key: key);

  @override
  State<HeaderSection> createState() => _HeaderSectionState();

  static Widget buildDrawer(BuildContext context, Function setState) {
    return _HeaderSectionState().buildMobileDrawer(context, setState);
  }
}

MyNotifier? myNotifier1;
final appBarValueNotifier = ValueNotifier<int>(0);

class _HeaderSectionState extends State<HeaderSection> {
  void initState() {
    myNotifier1 = MyNotifier(appBarValueNotifier, context);
    appBarValueNotifier.addListener(_onValueChanged);
    super.initState();
  }

  void _onValueChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    appBarValueNotifier.removeListener(_onValueChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: spacing.paddingLarge,
        vertical: spacing.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (isMobile) ...[_buildMobileMenuIcon(), SizedBox(width: 16)],

          // Logo - responsive sizing
          _buildResponsiveLogo(context),

          // Navigation - show drawer icon on mobile, nav buttons on tablet+
          if (!isMobile) ...[Spacer(), _buildDesktopNavigation()],
          Spacer(),

          // Authentication buttons - always show but responsive
          _buildAuthenticationButtons(),
        ],
      ),
    );
  }

  Widget _buildResponsiveLogo(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);

    return Image.asset(
      "lib/assets/images/bidr_logo1.png",
      fit: BoxFit.contain,
      height: isMobile ? 40 : 50,
      width: isMobile ? 64 : 80,
    );
  }

  Widget _buildMobileMenuIcon() {
    return IconButton(
      onPressed: () => _showMobileDrawer(context),
      icon: Icon(
        Icons.menu_rounded,
        color: Constants.ftaColorLight,
        size: ResponsiveTypography.getTypography(context).large,
      ),
    );
  }

  Widget _buildDesktopNavigation() {
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Wrap(
      runSpacing: spacing.spacingMedium,
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
    );
  }

  void _showMobileDrawer(BuildContext context) {
    // Use Scaffold.maybeOf to safely check for a Scaffold
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      // Fallback to showing a dialog-style drawer if no Scaffold is available
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black54,
        transitionDuration: Duration(milliseconds: 300),
        pageBuilder: (context, animation1, animation2) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: double.infinity,
                child: buildMobileDrawer(context, setState),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(-1, 0), end: Offset(0, 0))
                .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                ),
            child: child,
          );
        },
      );
    }
  }

  Widget buildMobileDrawer(BuildContext context, Function setState) {
    final spacing = ResponsiveSpacing.getSpacing(context);
    final typography = ResponsiveTypography.getTypography(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header with Logo
            Container(
              padding: EdgeInsets.all(spacing.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (Constants.isLoggedIn == true)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.person_alt_circle_fill,
                          size: 50,
                          color: Constants.ftaColorLight,
                          weight: 2,
                        ),
                        SizedBox(height: spacing.spacingMedium),
                        Text(
                          Constants.myEmail == ""
                              ? "guest@gmail.com"
                              : Constants.myEmail,
                          style: GoogleFonts.manrope(
                            color: Constants.ftaColorLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Constants.ftaColorLight,
                      size: typography.large,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  SizedBox(height: spacing.spacingMedium),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedHome01,
                    title: 'Home',
                    index: 0,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        Constants.buyerAppBarValue = 0;
                        appBarValueNotifier.value++;
                        buyerHomeValueNotifier.value++;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedCustomerSupport,
                    title: 'Support',
                    index: 1,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        Constants.buyerAppBarValue = 1;
                        appBarValueNotifier.value++;
                        buyerHomeValueNotifier.value++;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedHelpCircle,
                    title: 'FAQs',
                    index: 2,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        Constants.buyerAppBarValue = 2;
                        appBarValueNotifier.value++;
                        buyerHomeValueNotifier.value++;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.policy_outlined,
                    title: 'Policies',
                    index: 3,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        Constants.buyerAppBarValue = 3;
                        appBarValueNotifier.value++;
                        buyerHomeValueNotifier.value++;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedBlogger,
                    title: 'Blogs',
                    index: 4,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        Constants.buyerAppBarValue = 4;
                        appBarValueNotifier.value++;
                        buyerHomeValueNotifier.value++;
                      });
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: HugeIcons.strokeRoundedContact01,
                    title: 'Contact Us',
                    index: 5,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        Constants.buyerAppBarValue = 5;
                        appBarValueNotifier.value++;
                        buyerHomeValueNotifier.value++;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Authentication Button at Bottom
            Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(spacing.paddingLarge),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Row(
                children: [Expanded(child: _buildAuthenticationButtons())],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    final bool isSelected = index == Constants.buyerAppBarValue;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: spacing.marginSmall,
        vertical: 0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        color: isSelected
            ? Constants.ftaColorLight.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? Constants.ctaColorLight : Colors.grey[600],
          size: typography.large,
        ),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            color: isSelected ? Constants.ftaColorLight : Colors.black87,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.paddingMedium,
          vertical: spacing.paddingSmall / 2,
        ),
      ),
    );
  }

  Widget _buildAuthenticationButtons() {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    final bool isMobile = Breakpoints.isMobile(context);

    // Check if user is logged in and get role
    final bool isLoggedIn = Constants.currentUser != null;
    final String? userRole = Constants.currentUser?.role;

    if (isLoggedIn && userRole != null) {
      // User is logged in - show appropriate dashboard based on role
      switch (userRole.toLowerCase()) {
        case 'seller':
          return ElevatedButton(
            onPressed: () {
              Constants.buyerAppBarValue = 7;
              appBarValueNotifier.value++;
              buyerHomeValueNotifier.value++;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.ctaColorLight,
              foregroundColor: Colors.white,
              elevation: 3,
              //minimumSize: Size(MediaQuery.of(context).size.width, 45),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile
                    ? spacing.paddingMedium
                    : spacing.paddingLarge,
                vertical: spacing.paddingSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              Constants.myDisplayname,
              style: GoogleFonts.manrope(fontSize: typography.normal),
            ),
          );
        case 'buyer':
          return Container(
            constraints: BoxConstraints(maxWidth: 250, maxHeight: 55),
            child: ElevatedButton(
              onPressed: () {
                if (mounted) {
                  Constants.buyerAppBarValue = 6;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                elevation: 3,
                // minimumSize: Size(MediaQuery.of(context).size.width, 45),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile
                      ? spacing.paddingMedium
                      : spacing.paddingLarge,
                  vertical: spacing.paddingSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                Constants.myDisplayname,
                style: GoogleFonts.manrope(
                  fontSize: typography.normal,
                  color: Colors.black,
                ),
                maxLines: 1,

                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        default:
          return SizedBox(
            //width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.width < 800 ? 35 : 40,
            child: _buildLoginButton(),
          );
      }
    } else {
      // User is not logged in - show login button
      return SizedBox(
        // width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width < 800 ? 35 : 40,
        child: _buildLoginButton(),
      );
    }
  }

  Widget _buildLoginButton() {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    final bool isMobile = Breakpoints.isMobile(context);

    return ElevatedButton(
      onPressed: () => context.go('/login'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Constants.ctaColorLight,
        //minimumSize: Size(MediaQuery.of(context).size.width, 45),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? spacing.paddingMedium : spacing.paddingLarge,
          vertical: spacing.paddingSmall,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'Login',
        style: GoogleFonts.manrope(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: typography.normal,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: () async {
        // Clear all authentication data from Constants
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Constants.ctaColorLight,
        foregroundColor: Colors.white,
        elevation: 3,
        //side: BorderSide(color: Constants.ftaColorLight, width: 1.4),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        Constants.myDisplayname,
        style: GoogleFonts.manrope(fontSize: 14),
      ),
    );
  }

  Widget _navButton(String text, int index, VoidCallback onPressed) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.paddingSmall),
      child: Row(
        children: [
          IntrinsicWidth(
            child: Container(
              constraints: BoxConstraints(minWidth: 65),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onPressed,
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
                      ? Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
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
