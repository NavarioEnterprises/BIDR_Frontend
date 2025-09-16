import 'package:bidr/pages/mobileView/landingPage/landingMobileViewPage.dart';
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
  bool _isHoveringLogo = false;
  Map<int, bool> _navButtonHoverStates = {};
  Map<String, bool> _buttonHoverStates = {};
  
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
    myNotifier1?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
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
          // Equal spacing before logo
          SizedBox(width: spacing.paddingLarge),

          // Logo - responsive sizing
          _buildResponsiveLogo(context),

          // Navigation - show drawer icon on mobile, nav buttons on tablet+
          if (!isMobile) ...[
            SizedBox(width: 32),
            _buildDesktopNavigation(),
            SizedBox(width: 32),
          ] else
            Spacer(),

          // Authentication buttons - always show but responsive
          _buildAuthenticationButtons(),

          // Equal spacing after authentication buttons
          SizedBox(width: spacing.paddingLarge),
        ],
      ),
    );
  }

  Widget _buildResponsiveLogo(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringLogo = true),
      onExit: (_) => setState(() => _isHoveringLogo = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Constants.buyerAppBarValue = 0;
          appBarValueNotifier.value++;
          buyerHomeValueNotifier.value++;
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..scale(_isHoveringLogo ? 1.05 : 1.0),
          child: Image.asset(
            "lib/assets/images/bidr_logo1.png",
            fit: BoxFit.contain,
            height: isMobile ? 50 : 60,
            width: isMobile ? 80 : 96,
          ),
        ),
      ),
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

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          Constants.myEmail == "" ? "guest" : Constants.myEmail,
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
    final String hoverKey = 'drawer_$index';
    final bool isHovering = _buttonHoverStates[hoverKey] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _buttonHoverStates[hoverKey] = true),
      onExit: (_) => setState(() => _buttonHoverStates[hoverKey] = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
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
              : isHovering
                ? Constants.ctaColorLight.withOpacity(0.05)
                : Colors.transparent,
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: isSelected 
              ? Constants.ctaColorLight 
              : isHovering 
                ? Constants.ctaColorLight
                : Colors.grey[600],
            size: typography.large,
          ),
          title: Text(
            title,
            style: GoogleFonts.manrope(
              color: isSelected 
                ? Constants.ftaColorLight 
                : isHovering
                  ? Constants.ctaColorLight
                  : Colors.black87,
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
          final bool isHoveringSellerBtn = _buttonHoverStates['seller'] ?? false;
          return MouseRegion(
            onEnter: (_) => setState(() => _buttonHoverStates['seller'] = true),
            onExit: (_) => setState(() => _buttonHoverStates['seller'] = false),
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(isHoveringSellerBtn ? 1.05 : 1.0),
              child: ElevatedButton(
                onPressed: () {
                  Constants.buyerAppBarValue = 7;
                  appBarValueNotifier.value++;
                  buyerHomeValueNotifier.value++;
                  sellerHomeMobileValueNotifier.value++;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHoveringSellerBtn
                    ? Constants.ctaColorLight.withOpacity(0.8)
                    : Constants.ctaColorLight,
                  foregroundColor: Colors.white,
                  elevation: isHoveringSellerBtn ? 6 : 3,
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
              ),
            ),
          );
        case 'buyer':
          final bool isHoveringBuyerBtn = _buttonHoverStates['buyer'] ?? false;
          return MouseRegion(
            onEnter: (_) => setState(() => _buttonHoverStates['buyer'] = true),
            onExit: (_) => setState(() => _buttonHoverStates['buyer'] = false),
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              transform: Matrix4.identity()
                ..scale(isHoveringBuyerBtn ? 1.05 : 1.0),
              constraints: BoxConstraints(maxWidth: 250, maxHeight: 55), //
              child: ElevatedButton(
                onPressed: () {
                  if (mounted) {
                    Constants.buyerAppBarValue = 6;
                    appBarValueNotifier.value++;
                    buyerHomeValueNotifier.value++;
                    buyerHomeMobileValueNotifier.value++;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHoveringBuyerBtn
                    ? Constants.ctaColorLight.withOpacity(0.8)
                    : Constants.ctaColorLight,
                  foregroundColor: Colors.white,
                  elevation: isHoveringBuyerBtn ? 6 : 3,
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
    final bool isHovering = _buttonHoverStates['login'] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _buttonHoverStates['login'] = true),
      onExit: (_) => setState(() => _buttonHoverStates['login'] = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        transform: Matrix4.identity()
          ..scale(isHovering ? 1.05 : 1.0),
        child: ElevatedButton(
          onPressed: () => context.go('/login'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isHovering 
              ? Constants.ctaColorLight.withOpacity(0.8)
              : Constants.ctaColorLight,
            //minimumSize: Size(MediaQuery.of(context).size.width, 45),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? spacing.paddingMedium : spacing.paddingLarge,
              vertical: spacing.paddingSmall,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: isHovering ? 6 : 3,
          ),
          child: Text(
            'Login',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: typography.normal,
            ),
          ),
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
    final bool isHovering = _navButtonHoverStates[index] ?? false;
    final bool isActive = index == Constants.buyerAppBarValue;

    return Flexible(
      child: MouseRegion(
        onEnter: (_) => setState(() => _navButtonHoverStates[index] = true),
        onExit: (_) => setState(() => _navButtonHoverStates[index] = false),
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            transform: Matrix4.identity()
              ..scale(isHovering ? 1.05 : 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: GoogleFonts.manrope(
                    color: isActive
                        ? Constants.ftaColorLight
                        : isHovering 
                          ? Constants.ctaColorLight
                          : Colors.black45,
                    fontSize: 15,
                    fontWeight: isActive
                        ? FontWeight.bold
                        : FontWeight.w600,
                    shadows: isHovering && !isActive ? [
                      Shadow(
                        color: Constants.ctaColorLight.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ] : [],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: 2,
                  width: isActive ? 40 : isHovering ? 20 : 0,
                  color: Constants.ctaColorLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
