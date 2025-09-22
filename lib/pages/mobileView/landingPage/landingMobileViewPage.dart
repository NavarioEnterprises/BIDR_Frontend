import 'dart:async';
import 'dart:convert';

import 'package:bidr/pages/mobileView/landingPage/policiesMobileView.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/js.dart' as js;
import 'package:url_launcher/url_launcher.dart';

import '../../../authentication/login.dart';
import '../../../constants/Constants.dart';
import '../../../customWdget/appbar.dart';
import '../../../customWdget/custom_input2.dart';
import '../../../models/alert.dart';
import '../../../notifier/my_notifier.dart';
import '../../../services/auth_api_service.dart';
import '../../../services/products_management_api_service.dart';
import '../../buyer/join_as_business.dart';
import '../../buyer_home.dart';
import '../../notification.dart';
import '../breakpoints.dart';
import 'blogcardMobileView.dart';
import 'contactUsMobileView.dart';
import 'faqMobileView.dart';
import 'mobileBusinessLandingPage.dart';
import 'mobileBuyerLandingPage.dart';

class BuyerHomeMobilePage extends StatefulWidget {
  @override
  _BuyerHomeMobilePageState createState() => _BuyerHomeMobilePageState();
}

MyNotifier? myNotifier;
MyNotifier? mySellerMobileNotifier;
MyNotifier? myBuyerMobileNotifier;
final buyerHomeMobileValueNotifier = ValueNotifier<int>(0);
final buyerBackMobileButtonValueNotifier = ValueNotifier<int>(0);
final sellerHomeMobileValueNotifier = ValueNotifier<int>(0);
double _maxDistance = 1.0;
double _maxDistance2 = 1.0;
double _maxDistance3 = 1.0;
class _BuyerHomeMobilePageState extends State<BuyerHomeMobilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  int selectedIndex = -1;
  int index = 0;
  List<WebNotification> notifications = [];

  // Accordion expansion state
  Map<String, bool> _expandedSections = {
    'About Us': false,
    'How It Works': false,
  };

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _categoryController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _categoryAnimation;

  @override
  void initState() {
    super.initState();
    myNotifier = MyNotifier(buyerHomeValueNotifier, context);
    myBuyerMobileNotifier = MyNotifier(buyerHomeMobileValueNotifier, context);
    mySellerMobileNotifier = MyNotifier(sellerHomeMobileValueNotifier, context);
    buyerBackMobileButtonValueNotifier.addListener(() {
      Constants.buyerAppBarValue = 0;
      setState(() {});
    });
    sellerHomeMobileValueNotifier.addListener(() {
      setState(() {});
    });
    buyerHomeMobileValueNotifier.addListener(() {
      setState(() {});
    });
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _categoryController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    _categoryAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _categoryController, curve: Curves.easeOutBack),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 200));
    _fadeController.forward();

    await Future.delayed(Duration(milliseconds: 300));
    _slideController.forward();

    await Future.delayed(Duration(milliseconds: 400));
    _scaleController.forward();

    await Future.delayed(Duration(milliseconds: 500));
    _categoryController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _onCategoryTap(int index) {
    setState(() {
      selectedIndex = index;
    });

    // Add a small bounce animation when category is selected
    _scaleController.reset();
    _scaleController.forward();
  }

  final List<Map<String, String>> categories = [
    {
      "icon": "lib/assets/images/spares1.png",
      "icon2": "lib/assets/images/vehicle_light.png",
      "name": "Vehicle\nSpares",
    },
    {
      "icon": "lib/assets/images/rim&type.png",
      "icon2": "lib/assets/images/rims.png",
      "name": "Vehicle Tyres\nand Rims",
    },
    {
      "icon": "lib/assets/images/consumer.png",
      "icon2": "lib/assets/images/ele_light.png",
      "name": "Consumer \nElectronics",
    },
    {
      "icon": "lib/assets/images/auction.png",
      "icon2": "lib/assets/images/auction.png",
      "name": "Vehicle\nAuctions",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, //
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animated Header Section
            SizedBox(
              height: ResponsiveSpacing.getSpacing(context).spacingLarge,
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSpacing.getSpacing(
                      context,
                    ).paddingLarge,
                  ), //BlogCardsScreen
                  child: HeaderSection(),
                ),
              ),
            ),

            Constants.buyerAppBarValue == 0
                ? Expanded(
                    child: Container(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 1600),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: ResponsiveSpacing.getSpacing(
                                      context,
                                    ).spacingLarge,
                                  ),

                                  // Animated Banner Section
                                  ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                            ResponsiveSpacing.getSpacing(
                                              context,
                                            ).paddingLarge *
                                            2,
                                      ),
                                      child: Center(
                                        child: _buildAnimatedBannerSection(
                                          "lib/assets/images/competitive.png",
                                          true,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(
                                    height: ResponsiveSpacing.getSpacing(
                                      context,
                                    ).spacingLarge,
                                  ),

                                  // Animated Category Section
                                  Center(
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _categoryAnimation,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 16,
                                          ),
                                          child: Center(
                                            child: _buildCategoryItems(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Animated Form Section
                                  AnimatedSwitcher(
                                    duration: Duration(milliseconds: 500),
                                    transitionBuilder:
                                        (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: Offset(0.0, 0.3),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          );
                                        },
                                    child: Center(
                                      key: ValueKey(selectedIndex),
                                      child: selectedIndex == 0
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                              ),
                                              child:
                                                  VehicleDetailsQuoteMobileForm(),
                                            )
                                          : selectedIndex == 1
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                              ),
                                              child:
                                                  TireProductQuoteMobileForm(),
                                            )
                                          : selectedIndex == 2
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                left: 16,
                                                right: 16,
                                              ),
                                              child: ProductQuoteMobileForm(),
                                            )
                                          : selectedIndex == 3?_buildVehicleAuctionsComingSoon():SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Animated About Us Section
                            SizedBox(
                              height: ResponsiveSpacing.getSpacing(
                                context,
                              ).spacingLarge,
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 1000),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 50 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: Center(
                                      child: _buildAboutUsSection(),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(
                              height: ResponsiveSpacing.getSpacing(
                                context,
                              ).spacingLarge,
                            ),

                            // Animated Bottom Banner
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal:
                                      ResponsiveSpacing.getSpacing(
                                        context,
                                      ).paddingLarge *
                                      2,
                                ),
                                child: Center(
                                  child: _buildAnimatedBannerSection(
                                    "lib/assets/images/mask_group.png",
                                    false,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(
                              height: ResponsiveSpacing.getSpacing(
                                context,
                              ).spacingLarge,
                            ),
                            SizedBox(
                              height: ResponsiveSpacing.getSpacing(
                                context,
                              ).spacingMedium,
                            ),

                            // Animated Footer
                          ],
                        ),
                      ),
                    ),
                  )
                : Constants.buyerAppBarValue == 1
                ? Expanded(child: FAQMobileScreen())
                : Constants.buyerAppBarValue == 2
                ? Expanded(child: PoliciesMobileScreen())
                : Constants.buyerAppBarValue == 3
                ? Expanded(child: BlogCardsMobileScreen())
                : Constants.buyerAppBarValue == 4
                ? Expanded(child: ContactFormMobileScreen())
                : Constants.buyerAppBarValue == 8
                ? Expanded(
                    child: NotificationPage(notifications: notifications),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
  Widget _buildVehicleAuctionsComingSoon() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFF072744).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gavel, size: 30, color: Color(0xFF072744)),
          ),
          SizedBox(height: 16),
          Text(
            'Vehicle Auctions',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF072744),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFF9A825),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'COMING SOON',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Get ready for an exciting new way to buy vehicles through our auction platform.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Participate in live auctions with real-time bidding, secure transactions, and access to premium vehicles from trusted sellers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAboutUsSection() {
    return Container(
      width: MediaQuery.of(context).size.width,
      // constraints: BoxConstraints(minHeight: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1600),
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildAccordionSection(
                    "About Us",
                    "Created in 2024, BIDR™ is South Africa's newest e-commerce platform. Our unique buyer centric service makes searching for the best price for common goods easy. Headquartered in Johannesburg, we currently serve all of SA.BIDR was born out of its founders' frustrations of always trying to source the best deals for commonly required items such as vehicle tyres or spares, expensive mobile bills, and countless hours trying to negotiate with sellers to get the best deals.We have now taken our expertise and automated the process for you. Why not consider registering as a buyer or seller (as the case may be) and see how our system can save you time, money and stress.",
                    "Why Join As A Buyer?",
                    0,
                  ),
                  SizedBox(
                    height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                  ),
                  _buildAccordionSection(
                    "How It Works",
                    "Unlike catalogue-based online shops, BIDR allows buyers to send out a single request to multiple sellers that are registered on our platform.The buyer simply specifies the area to search and all sellers within that area are notified of therequest. If the seller has the product (or similar products), they will make an offer. The sellers are continuously updated of the current market price offered by other sellers in the area, and should they opt to do so, they will have the opportunity of revising their bid with a best and final offer. No more long repetitive phone calls, waiting in queues, or countless hours browsing for special deals. With BIDR the sellers come to you with their best price.",
                    "Why Join As A Business?",
                    1,
                  ),
                  SizedBox(height: 16),
                  _buildActionButton("Why Join As A Buyer?", () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            MobileBuyerLandingPage(),
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
                  }),
                  SizedBox(height: 12),
                  _buildActionButton("Why Join As A Business?", () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            MobileBusinessLandingPage(),
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
                  }),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSection(
    String title,
    String description,
    String buttonTitle,
    int index,
  )
  {
    // Determine if this is an expandable section (About Us, How It Works)
    bool isExpandable = title == "About Us" || title == "How It Works";
    bool isExpanded = _expandedSections[title] ?? false;

    // Determine button style based on title
    bool isDarkButton = title.contains("Buyer") || title.contains("Business");

    return Padding(
      padding: EdgeInsets.only(
        left: ResponsiveSpacing.getSpacing(context).paddingLarge,
        right: ResponsiveSpacing.getSpacing(context).paddingLarge,
        bottom: ResponsiveSpacing.getSpacing(context).paddingMedium,
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: isDarkButton ? Color(0xFF1B3B5C) : Color(0xFFFFF5E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkButton ? Color(0xFF1B3B5C) : Color(0xFFE8B366),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: isExpandable
                  ? () {
                      setState(() {
                        _expandedSections[title] = !isExpanded;
                      });
                    }
                  : null,
              borderRadius: BorderRadius.circular(25),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: ResponsiveTypography.getTypography(
                            context,
                          ).subHeading,
                          fontWeight: FontWeight.bold,
                          color: isDarkButton
                              ? Colors.white
                              : Color(0xFF1B3B5C),
                        ),
                      ),
                    ),
                    if (isExpandable) ...[
                      // Dropdown arrow for expandable sections
                      AnimatedRotation(
                        duration: Duration(milliseconds: 200),
                        turns: isExpanded ? 0.5 : 0,
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: isDarkButton
                              ? Colors.white
                              : Color(0xFF1B3B5C),
                          size: 24,
                        ),
                      ),
                    ] else ...[
                      // Arrow button for action sections
                      Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (title.contains("Business")) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) => BusinessLandingPage(),
                                  transitionsBuilder:
                                      (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
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
                            } else if (title.contains("Buyer")) {}
                            setState(() {});
                          },
                          style: IconButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(32, 32),
                          ),
                          icon: Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF1B3B5C),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Expandable content section
            if (isExpandable)
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Container(
                  width: double.infinity,
                  child: isExpanded
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 1,
                                color: isDarkButton
                                    ? Colors.white.withOpacity(0.2)
                                    : Color(0xFFE8B366).withOpacity(0.3),
                                margin: EdgeInsets.only(bottom: 16),
                              ),
                              Text(
                                description,
                                style: GoogleFonts.manrope(
                                  fontSize: ResponsiveTypography.getTypography(
                                    context,
                                  ).normal,
                                  color: isDarkButton
                                      ? Colors.white.withOpacity(0.9)
                                      : Color(0xFF1B3B5C),
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBannerSection(String image, bool? contain) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  height: 180,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _navButton(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: TextButton(
        onPressed: () {},
        child: Text(
          text,
          style: GoogleFonts.manrope(color: Colors.black45, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryItems() {
    return Container(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Text(
                    'Shop by Categories',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Please click on one of the categories to begin',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          Wrap(
            spacing: 16,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: List.generate(categories.length, (index) {
              var category = categories[index];
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800 + (index * 200)),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width:
                            (MediaQuery.of(context).size.width - 48 - 48) / 3.9,
                        child: _categoryCard(
                          category["icon"]!,
                          category["icon2"]!,
                          category["name"]!,
                          index,
                          selectedIndex,
                          () => _onCategoryTap(index),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
        ],
      ),
    );
  }

  Widget _categoryCard(
    String iconImage,
    String iconImage2,
    String name,
    int index,
    int selectedIndex,
    VoidCallback onPressed,
  ) {
    final bool isSelected = index == selectedIndex;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: InkWell(
        onTap: onPressed,
        highlightColor: Colors.white,
        hoverColor: Colors.white,
        splashColor: Colors.white,
        focusColor: Colors.white,
        borderRadius: BorderRadius.circular(360),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(isSelected ? 0.9 : 0.8),
          child: Column(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(360),

                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.05),
                            blurRadius: 6,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : [],
                ),
                child: AnimatedScale(
                  scale: isSelected ? 0.82 : 0.8,
                  duration: Duration(milliseconds: 200),
                  child: Image.asset(
                    isSelected ? iconImage : iconImage2,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(
                height: ResponsiveSpacing.getSpacing(context).spacingLarge,
              ),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: GoogleFonts.manrope(
                  color: isSelected
                      ? Constants.ftaColorLight
                      : Constants.ftaColorLight.withOpacity(0.85),
                  fontSize: isSelected ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(
                  name,
                  style: TextStyle(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSpacing.getSpacing(context).paddingLarge,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1B3B5C), // Dark blue color
            foregroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: ResponsiveTypography.getTypography(
                      context,
                    ).subHeading,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF1B3B5C),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Missing APIs from desktop version - High Priority
  Future<Map<String, dynamic>?> getRequestsByBuyer() async {
    try {
      final result = await ApiService.getRequestsByBuyer();
      return result;
    } catch (e) {
      print('Error getting buyer requests: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getQuotesForRequest(String requestId) async {
    try {
      final result = await ApiService.getQuotesForRequest(requestId);
      if (result['success'] == true && result['quotes'] != null) {
        return result['quotes'] as List<dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting quotes for request: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final profile = await AuthApiService().getUserProfile(
        uid: Constants.currentUser!.uid,
      );
      return profile;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final result = await AuthApiService().updateProfile(
        accessToken: '',
        firstName: '',
        lastName: '',
        phoneNumber: '',
      );
      return result != null;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<bool> signOut() async {
    try {
      final result = await AuthApiService().signOut(
        accessToken: '',
        refreshToken: '',
      );
      return result != null;
    } catch (e) {
      print('Error signing out: $e');
      return false;
    }
  }

  // Missing APIs - Medium Priority
  Future<Map<String, dynamic>?> getProductRequestDetails(
    String requestId,
  ) async {
    try {
      final details = await ApiService.getProductRequestDetails(requestId);
      return details;
    } catch (e) {
      print('Error getting product request details: $e');
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final result = await AuthApiService().changePassword(
        currentPassword: oldPassword,
        newPassword: newPassword,
      );
      return result != null;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    try {
      final result = await AuthApiService().requestPasswordReset(
        context,
        email: email,
      );
      return result != null;
    } catch (e) {
      print('Error requesting password reset: $e');
      return false;
    }
  }

  // Missing APIs - Low Priority (Advanced Features)
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final result = await ApiService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      return result != null;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Future<bool> flagRequest(String requestId, String reason) async {
    try {
      final result = await ApiService.flagRequest(
        requestId: requestId,
        reason: reason,
        authUserUid: Constants.currentUser?.uid ?? '',
      );
      return result['success'] == true;
    } catch (e) {
      print('Error flagging request: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getSellerOrdersSummary(String sellerId) async {
    try {
      final summary = await ApiService.getSellerOrdersSummary(
        authUserUid: sellerId,
      );
      return summary;
    } catch (e) {
      print('Error getting seller orders summary: $e');
      return null;
    }
  }
}

class VehicleDetailsQuoteMobileForm extends StatefulWidget {
  @override
  _VehicleDetailsQuoteMobileFormState createState() =>
      _VehicleDetailsQuoteMobileFormState();
}

class _VehicleDetailsQuoteMobileFormState
    extends State<VehicleDetailsQuoteMobileForm> {
  // Controllers
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _partNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

  // Location variables
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  static const String _googleMapsApiKey =
      'AIzaSyAegBp2UyTEJZnrmWBBPk0hU-C0bjR0cKA';

  // Focus Nodes
  final FocusNode _vinFocus = FocusNode();
  final FocusNode _partNameFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _partNumberFocus = FocusNode();
  final FocusNode _mileageFocus = FocusNode();

  // Dropdown values
  String? _selectedManufacturer;
  String? _selectedMakeModel;
  String? _selectedType;
  String? _selectedNewUsedPart;
  String? _selectedYear;
  String? _selectedQuantity;
  String? _selectedTimeframe;
  String? _selectedTransmissionType;
  String? _selectedFuelType;
  String? _selectedBodyType;

  // Range slider value

  final TextEditingController _maxDistanceController = TextEditingController();
  final FocusNode _maxDistanceFocus = FocusNode();

  // Checkbox values
  bool _agreeToTerms = false;
  bool _consentToContact = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  Map<String, Uint8List> _imageBytes = {};

  // VIN Image picker (image-only, no text input)
  List<XFile> _vinImages = [];
  Map<String, Uint8List> _vinImageBytes = {};

  // Size limit for images and videos (10MB in bytes)
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  // Autocomplete controllers
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _makeModelController = TextEditingController();
  final FocusNode _manufacturerFocus = FocusNode();
  final FocusNode _makeModelFocus = FocusNode();

  // Form submission state
  bool _isSubmitting = false;

  // Manufacturer to Models mapping
  final Map<String, List<String>> _manufacturerModels = {
    'Toyota': [
      'Select Model',
      'Corolla',
      'Camry',
      'Prius',
      'RAV4',
      'Highlander',
      'Tacoma',
      'Tundra',
      'Sienna',
      'Yaris',
      'Avalon',
      'Land Cruiser',
      'Prado',
      'Hilux',
      'Fortuner',
      'Avanza',
    ],
    'Honda': [
      'Select Model',
      'Civic',
      'Accord',
      'CR-V',
      'Pilot',
      'Odyssey',
      'Fit',
      'HR-V',
      'Passport',
      'Ridgeline',
      'Insight',
      'Jazz',
      'City',
    ],
    'Ford': [
      'Select Model',
      'Focus',
      'Mustang',
      'F-150',
      'Explorer',
      'Escape',
      'Fusion',
      'Edge',
      'Expedition',
      'Bronco',
      'Transit',
      'Ranger',
      'Fiesta',
      'EcoSport',
    ],
    'BMW': [
      'Select Model',
      '3 Series',
      '5 Series',
      '7 Series',
      'X1',
      'X3',
      'X5',
      'X7',
      'Z4',
      'i3',
      'i4',
      'iX',
      '1 Series',
      '2 Series',
      '4 Series',
      '6 Series',
      '8 Series',
    ],
    'Mercedes': [
      'Select Model',
      'A-Class',
      'C-Class',
      'E-Class',
      'S-Class',
      'GLA',
      'GLC',
      'GLE',
      'GLS',
      'CLA',
      'CLS',
      'AMG GT',
      'G-Class',
      'EQA',
      'EQC',
      'EQS',
    ],
    'Audi': [
      'Select Model',
      'A1',
      'A3',
      'A4',
      'A6',
      'A8',
      'Q2',
      'Q3',
      'Q5',
      'Q7',
      'Q8',
      'TT',
      'R8',
      'e-tron GT',
      'e-tron',
    ],
    'Volkswagen': [
      'Select Model',
      'Golf',
      'Passat',
      'Jetta',
      'Tiguan',
      'Atlas',
      'Arteon',
      'ID.4',
      'Touareg',
      'Amarok',
      'Polo',
      'T-Cross',
      'T-Roc',
    ],
  };

  // Manufacturers list for autocomplete
  final List<String> _manufacturers = [
    'Toyota',
    'Honda',
    'Ford',
    'BMW',
    'Mercedes',
    'Audi',
    'Volkswagen',
  ];

  // Get models for selected manufacturer
  List<String> _getModelsForManufacturer(String? manufacturer) {
    if (manufacturer == null || manufacturer == 'Select Manufacturer') {
      return ['Select Makes & Models'];
    }
    return _manufacturerModels[manufacturer] ?? ['Select Makes & Models'];
  }

  @override
  void initState() {
    super.initState();
    // Set initial values
    _maxDistanceController.text = _maxDistance.round().toString();

    // Add listener to manufacturer controller to update makes/models
    _manufacturerController.addListener(() {
      setState(() {
        // This will trigger a rebuild and update the makes/models options
      });
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _vinController.dispose();
    _partNameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _partNumberController.dispose();
    _mileageController.dispose();
    _maxDistanceController.dispose();
    _manufacturerController.dispose();
    _makeModelController.dispose();

    // Dispose focus nodes
    _vinFocus.dispose();
    _partNameFocus.dispose();
    _locationFocus.dispose();
    _descriptionFocus.dispose();
    _partNumberFocus.dispose();
    _mileageFocus.dispose();
    _maxDistanceFocus.dispose();
    _manufacturerFocus.dispose();
    _makeModelFocus.dispose();

    super.dispose();
  }

  // Helper method to check file size
  Future<bool> _isFileSizeValid(XFile file) async {
    try {
      final int fileSize = await file.length();
      return fileSize <= maxFileSizeBytes;
    } catch (e) {
      print('Error checking file size: $e');
      return false;
    }
  }

  // Helper method to format file size for display
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  // Helper function to create labels with red asterisk for required fields
  Widget _buildFormLabel(String label) {
    final isRequired = label.contains('*');
    final cleanLabel = label.replaceAll('*', '');

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: cleanLabel,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
          if (isRequired)
            TextSpan(
              text: '*',
              style: GoogleFonts.manrope(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomTextField(
      String hintText,
      TextEditingController controller,
      FocusNode focusNode,
      FocusNode? nextFocusNode, {
        Widget? suffixIcon,
        bool? integersOnly,
      }) {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      textInputAction: nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
      isPasswordField: false,
      integersOnly: integersOnly,
      suffix: suffixIcon,
      onChanged: (value) {},
      onSubmitted: (value) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildCustomDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged,
      ) {
    return Container(
      width: double.infinity,
      height: 48,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            menuMaxHeight: 200,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            value: value,
            hint: Text(
              label.replaceAll('*', ''),
              style: GoogleFonts.manrope(
                color: Colors.grey.withOpacity(0.35),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.manrope(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildAutocomplete(
      String label,
      TextEditingController controller,
      FocusNode focusNode,
      List<String> options,
      Function(String) onSelected,
      ) {
    return Container(
      width: double.infinity,
      height: 48,
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          final String query = textEditingValue.text.toLowerCase();
          return options
              .where((String option) {
            return option.toLowerCase().contains(query) &&
                option.toLowerCase() != query;
          })
              .take(5); // Limit to 5 suggestions
        },
        onSelected: onSelected,
        fieldViewBuilder:
            (
            BuildContext context,
            TextEditingController fieldController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
            ) {
          // Sync the field controller with our controller
          if (controller.text != fieldController.text) {
            fieldController.text = controller.text;
          }
          // Listen to changes in the field controller and update our controller
          fieldController.addListener(() {
            if (controller.text != fieldController.text) {
              controller.text = fieldController.text;
            }
          });

          return TextField(
            controller: fieldController,
            focusNode: fieldFocusNode,
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              labelStyle: TextStyle(
                color: Colors.black,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'YuGothic',
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(36),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(36),
              ),
              hintText: label.replaceAll('*', ''),
              hintStyle: GoogleFonts.manrope(
                color: Colors.grey.withOpacity(0.35),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),

            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
            onSubmitted: (String value) {
              onFieldSubmitted();
            },
          );
        },
        optionsViewBuilder:
            (
            BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options,
            ) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200, maxWidth: 400),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Constants.ftaColorLight.withOpacity(0.3),
                    ),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    itemCount: options.length,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return GestureDetector(
                        onTap: () {
                          onSelected(option);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          margin: EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.withOpacity(0.05),
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.manrope(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliderField(
      String label,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      ) {
    return TextField(
      controller: _maxDistanceController,
      focusNode: _maxDistanceFocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      style: GoogleFonts.manrope(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: 'Enter distance (1-1500 km)',
        hintStyle: GoogleFonts.manrope(color: Colors.grey[500], fontSize: 14),
        fillColor: Colors.transparent,
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(36),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(36),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(36),
        ),
        suffixIcon: Container(
          width: 200,
          padding: EdgeInsets.only(right: 16),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Constants.ctaColorLight,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Constants.ftaColorLight,
              overlayColor: Constants.ctaColorLight.withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (newValue) {
                onChanged(newValue);
                _maxDistanceController.text = newValue.round().toString();
              },
            ),
          ),
        ),
      ),
      onChanged: (text) {
        double? newValue = double.tryParse(text);
        if (newValue != null && newValue >= min && newValue <= max) {
          onChanged(newValue);
        }
      },
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload area with label on border
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(36),
              color: Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label on border using positioned widget
                Transform.translate(
                  offset: Offset(0, -32),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    color: Colors.white,
                    child: Text(
                      'Upload Images Of The Product You Require',
                      style: GoogleFonts.manrope(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                // Content area
                _selectedImages.isEmpty
                    ? Container(
                  height: 60,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 24,
                          color: Colors.grey[500],
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap to select images',
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : Column(
                  children: [
                    Container(
                      constraints: BoxConstraints(maxHeight: 250),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return _buildImagePreview(
                            _selectedImages[index],
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Constants.ctaColorLight,
                      ),
                      child: Text(
                        'Add More Images',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedImages.length} image(s) selected',
              style: GoogleFonts.manrope(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview(XFile image) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
              image.path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading web image: $error');
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
            )
                : _imageBytes.containsKey(image.path)
                ? Image.memory(
              _imageBytes[image.path]!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading memory image: $error');
                return Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
            )
                : FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Cache the bytes for future use
                  _imageBytes[image.path] = snapshot.data!;
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print('Error displaying image: $error');
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  print('Error reading image bytes: ${snapshot.error}');
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                }
                return Container(
                  color: Colors.grey[100],
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(image),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        List<XFile> validImages = [];
        List<String> oversizedFiles = [];

        // Check file sizes first
        for (final image in images) {
          final bool isValidSize = await _isFileSizeValid(image);
          if (isValidSize) {
            validImages.add(image);
          } else {
            final int fileSize = await image.length();
            oversizedFiles.add('${image.name} (${_formatFileSize(fileSize)})');
          }
        }

        // Show error for oversized files
        if (oversizedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The following files exceed 10MB limit and were not added:\n${oversizedFiles.join('\n')}',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Process valid images
        if (validImages.isNotEmpty) {
          if (kIsWeb) {
            // For web: keep XFile references directly (preserve blob URLs)
            setState(() {
              _selectedImages.addAll(validImages);
            });
          } else {
            // For mobile: use byte-based approach
            List<XFile> processedImages = [];

            for (final image in validImages) {
              try {
                final bytes = await image.readAsBytes();
                _imageBytes[image.path] = bytes;
                processedImages.add(image);
              } catch (e) {
                print('Failed to read image bytes: $e');
              }
            }

            if (processedImages.isNotEmpty) {
              setState(() {
                _selectedImages.addAll(processedImages);
              });
            }
          }

          // Show success message if any images were added
          if (validImages.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${validImages.length} image${validImages.length > 1 ? 's' : ''} added successfully',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else if (images.isNotEmpty && oversizedFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to load selected images. Please try again.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
      _imageBytes.remove(image.path);
    });
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Constants.ctaColorLight,
            ),
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        // Vehicle Details Section
        _buildSection('Vehicle Details', [
           Column(
                  children: [
                    _buildVinField(),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildAutocomplete(
                      'Manufacturer*',
                      _manufacturerController,
                      _manufacturerFocus,
                      _manufacturers,
                          (value) => setState(() {
                        _selectedManufacturer = value;
                        _manufacturerController.text = value;
                        // Reset model selection when manufacturer changes
                        _selectedMakeModel = null;
                        _makeModelController.clear();
                      }),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildAutocomplete(
                      'Makes & Models*',
                      _makeModelController,
                      _makeModelFocus,
                      _getModelsForManufacturer(
                        _manufacturerController.text.isNotEmpty
                            ? _manufacturerController.text
                            : _selectedManufacturer,
                      ).where((model) => model != 'Select Makes & Models').toList(),
                          (value) => setState(() {
                        _selectedMakeModel = value;
                        _makeModelController.text = value;
                      }),
                    ),
                  ],
                ),

          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          isMobile
              ? Column(
                  children: [
                    _buildCustomDropdown(
                      'Type*',
                      _selectedType,
                      [
                        'Select Type',
                        'Sedan',
                        'SUV',
                        'Hatchback',
                        'Coupe',
                        'Truck',
                        'Van',
                      ],
                      (value) => setState(() => _selectedType = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'New/Used Part*',
                      _selectedNewUsedPart,
                      ['Select New/Used Part', 'New', 'Used', 'Refurbished'],
                      (value) => setState(() => _selectedNewUsedPart = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Year*',
                      _selectedYear,
                      [
                        'Select Year',
                        '2024',
                        '2023',
                        '2022',
                        '2021',
                        '2020',
                        '2019',
                        '2018',
                        '2017',
                      ],
                      (value) => setState(() => _selectedYear = value),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomDropdown(
                        'Type*',
                        _selectedType,
                        [
                          'Select Type',
                          'Sedan',
                          'SUV',
                          'Hatchback',
                          'Coupe',
                          'Truck',
                          'Van',
                        ],
                        (value) => setState(() => _selectedType = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'New/Used Part*',
                        _selectedNewUsedPart,
                        ['Select New/Used Part', 'New', 'Used', 'Refurbished'],
                        (value) => setState(() => _selectedNewUsedPart = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Year*',
                        _selectedYear,
                        [
                          'Select Year',
                          '2024',
                          '2023',
                          '2022',
                          '2021',
                          '2020',
                          '2019',
                          '2018',
                          '2017',
                        ],
                        (value) => setState(() => _selectedYear = value),
                      ),
                    ),
                  ],
                ),
        ]),
        SizedBox(height: 24),

        // Part Details Section
        _buildSection('Part Details', [
          isMobile
              ? Column(
                  children: [
                    _buildCustomTextField(
                      'Part Name/Description*',
                      _partNameController,
                      _partNameFocus,
                      _locationFocus,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Quantity*',
                      _selectedQuantity,
                      [
                        'Select Quantity',
                        '1',
                        '2',
                        '3',
                        '4',
                        '5',
                        '6',
                        '7',
                        '8',
                      ],
                      (value) => setState(() => _selectedQuantity = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildLocationField(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        'Part Name/Description*',
                        _partNameController,
                        _partNameFocus,
                        _locationFocus,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Quantity*',
                        _selectedQuantity,
                        [
                          'Select Quantity',
                          '1',
                          '2',
                          '3',
                          '4',
                          '5',
                          '6',
                          '7',
                          '8',
                        ],
                        (value) => setState(() => _selectedQuantity = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(child: _buildLocationField()),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          isMobile
              ? Column(
                  children: [
                    _buildSliderField(
                      'Max Distance You Want to Travel (km)*',
                      _maxDistance,
                      0,
                      200,
                      (value) => setState(() => _maxDistance = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'How Soon Do You Need To Buy This Product?*',
                      _selectedTimeframe,
                      [
                        'Select Time',
                        '12 Hours',
                        '24 Hours',
                        '2-3 Days',
                        '1 Week',
                        '2 Weeks',
                        'Within a Month',
                      ],
                      (value) => setState(() => _selectedTimeframe = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomTextField(
                      'Description of the Product*',
                      _descriptionController,
                      _descriptionFocus,
                      null,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildSliderField(
                        'Max Distance You Want to Travel (km)*',
                        _maxDistance,
                        0,
                        200,
                        (value) => setState(() => _maxDistance = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'How Soon Do You Need To Buy This Product?*',
                        _selectedTimeframe,
                        [
                          'Select Time',
                          '12 Hours',
                          '24 Hours',
                          '2-3 Days',
                          '1 Week',
                          '2 Weeks',
                          'Within a Month',
                        ],
                        (value) => setState(() => _selectedTimeframe = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomTextField(
                        'Description of the Product*',
                        _descriptionController,
                        _descriptionFocus,
                        null,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          _buildImageUploadSection(),
        ]),
        SizedBox(height: 24),

        // More Fields Section
        _buildSection('More Fields', [
          isMobile
              ? Column(
                  children: [
                    _buildCustomTextField(
                      'Part Number',
                      _partNumberController,
                      _partNumberFocus,
                      _mileageFocus,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Transmission Type (Manual/Auto)',
                      _selectedTransmissionType,
                      [
                        'Select Type',
                        'Manual',
                        'Automatic',
                        'CVT',
                        'Semi-Automatic',
                      ],
                      (value) =>
                          setState(() => _selectedTransmissionType = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomTextField(
                      'Mileage of Vehicle',
                      _mileageController,
                      _mileageFocus,
                      null,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        'Part Number',
                        _partNumberController,
                        _partNumberFocus,
                        _mileageFocus,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Transmission Type (Manual/Auto)',
                        _selectedTransmissionType,
                        [
                          'Select Type',
                          'Manual',
                          'Automatic',
                          'CVT',
                          'Semi-Automatic',
                        ],
                        (value) =>
                            setState(() => _selectedTransmissionType = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomTextField(
                        'Mileage of Vehicle',
                        _mileageController,
                        _mileageFocus,
                        null,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          isMobile
              ? Column(
                  children: [
                    _buildCustomDropdown(
                      'Fuel Type',
                      _selectedFuelType,
                      [
                        'Select Type',
                        'Petrol',
                        'Diesel',
                        'Electric',
                        'Hybrid',
                        'LPG',
                      ],
                      (value) => setState(() => _selectedFuelType = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Body Type',
                      _selectedBodyType,
                      [
                        'Select Type',
                        'Sedan',
                        'Hatchback',
                        'SUV',
                        'Coupe',
                        'Convertible',
                        'Wagon',
                        'Pickup',
                      ],
                      (value) => setState(() => _selectedBodyType = value),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomDropdown(
                        'Fuel Type',
                        _selectedFuelType,
                        [
                          'Select Type',
                          'Petrol',
                          'Diesel',
                          'Electric',
                          'Hybrid',
                          'LPG',
                        ],
                        (value) => setState(() => _selectedFuelType = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Body Type',
                        _selectedBodyType,
                        [
                          'Select Type',
                          'Sedan',
                          'Hatchback',
                          'SUV',
                          'Coupe',
                          'Convertible',
                          'Wagon',
                          'Pickup',
                        ],
                        (value) => setState(() => _selectedBodyType = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(child: Container()), // Empty space for alignment
                  ],
                ),
        ]),
        SizedBox(height: 24),

        // Checkboxes
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            ResponsiveSpacing.getSpacing(context).paddingLarge,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) =>
                        setState(() => _agreeToTerms = value ?? false),
                    activeColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the terms and conditions.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _consentToContact,
                    onChanged: (value) =>
                        setState(() => _consentToContact = value ?? false),
                    activeColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I consent to being contacted for further details regarding my quote request.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Submit Button
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: 45,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_agreeToTerms && _consentToContact) {
                      _submitForm();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please agree to terms and consent to contact.',
                          ),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubmitting
                  ? Colors.grey
                  : Constants.ctaColorLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(360),
              ),
              elevation: 5,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit',
                    style: GoogleFonts.manrope(
                      fontSize: ResponsiveTypography.getTypography(
                        context,
                      ).normal,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Loading state

  // Authentication check method
  bool _checkAuthenticationAndProceed() {
    // Check if user is logged in using Constants.currentUser or isLoggedIn flag
    if (Constants.currentUser == null && !Constants.isLoggedIn) {
      // Show authentication dialog
      _showAuthenticationDialog();
      return false;
    }
    return true;
  }

  // Show authentication dialog
  void _showAuthenticationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.login, color: Constants.ctaColorLight),
              SizedBox(width: 8),
              Text(
                'Login Required',
                style: GoogleFonts.manrope(
                  fontSize: ResponsiveTypography.getTypography(
                    context,
                  ).subHeading,
                  fontWeight: FontWeight.bold,
                  color: Constants.ftaColorLight,
                ),
              ),
            ],
          ),
          content: Text(
            'You need to be logged in to submit a request. Would you like to login now?',
            style: GoogleFonts.manrope(
              fontSize: ResponsiveTypography.getTypography(context).normal,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLogin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Login',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Navigate to login page and return to submit after login
  void _navigateToLogin() async {
    // Navigate to login page
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );

    // After returning from login, check authentication and submit if successful
    // Small delay to ensure the login state is properly set
    await Future.delayed(Duration(milliseconds: 100));

    if (Constants.currentUser != null || Constants.isLoggedIn) {
      // User logged in successfully, now submit the form directly
      _submitFormDirectly();
    } else {
      // User cancelled login or login failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login is required to submit the request'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Direct form submission without authentication check (used after successful login)
  void _submitFormDirectly() async {
    // Basic validation
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ApiService.submitVehicleRequest(
        selectedManufacturer: _manufacturerController.text,
        selectedMakeModel: _makeModelController.text,
        selectedYear: _selectedYear,
        selectedType: _selectedType,
        selectedNewUsedPart: _selectedNewUsedPart,
        selectedQuantity: _selectedQuantity,
        selectedTimeframe: _selectedTimeframe,
        selectedTransmissionType: _selectedTransmissionType,
        selectedFuelType: _selectedFuelType,
        selectedBodyType: _selectedBodyType,
        vinNumber: _vinController.text,
        partName: _partNameController.text,
        partNumber: _partNumberController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        mileage: _mileageController.text,
        maxDistance: _maxDistance,
        images: _selectedImages,
        vinImages: _vinImages,
        locationLat: _selectedLocation?.latitude,
        locationLng: _selectedLocation?.longitude,
      );
      print("Form submitted after login: ${result}");

      if (result['success']) {
        // Show success dialog
        await _showVehicleRequestSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _submitForm() async {
    // Check authentication first
    if (!_checkAuthenticationAndProceed()) {
      return;
    }

    // Basic validation
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ApiService.submitVehicleRequest(
        selectedManufacturer: _manufacturerController.text,
        selectedMakeModel: _makeModelController.text,
        selectedYear: _selectedYear,
        selectedType: _selectedType,
        selectedNewUsedPart: _selectedNewUsedPart,
        selectedQuantity: _selectedQuantity,
        selectedTimeframe: _selectedTimeframe,
        selectedTransmissionType: _selectedTransmissionType,
        selectedFuelType: _selectedFuelType,
        selectedBodyType: _selectedBodyType,
        vinNumber: _vinController.text,
        partName: _partNameController.text,
        partNumber: _partNumberController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        mileage: _mileageController.text,
        maxDistance: _maxDistance,
        images: _selectedImages,
        vinImages: _vinImages,
        locationLat: _selectedLocation?.latitude,
        locationLng: _selectedLocation?.longitude,
      );
      print("sdhdshj ${result}");

      if (result['success']) {
        // Show success dialog
        await _showVehicleRequestSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Show styled success dialog for vehicle request submission
  Future<void> _showVehicleRequestSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                SizedBox(
                  height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                ),

                // Success Title
                Text(
                  'Request Submitted Successfully!',
                  style: GoogleFonts.manrope(
                    fontSize: ResponsiveTypography.getTypography(
                      context,
                    ).heading,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                ),

                // Success Message
                Text(
                  'Your vehicle spare parts request has been submitted successfully. You will receive quotes from suppliers soon.',
                  style: GoogleFonts.manrope(
                    fontSize: ResponsiveTypography.getTypography(
                      context,
                    ).medium,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Reset form
                          _resetForm();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Constants.ftaColorLight),
                          ),
                        ),
                        child: Text(
                          'Submit Another',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Reset form
                          _resetForm();
                          // Navigate to dashboard
                          if (mounted) {
                            context.go('/dashboard');
                            Constants.buyerAppBarValue = 6;
                            appBarValueNotifier.value++;
                            buyerHomeValueNotifier.value++;
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ftaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'View Requests',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _validateForm() {
    List<String> errors = [];

    if (_selectedManufacturer == null || _selectedManufacturer!.isEmpty) {
      errors.add('Manufacturer is required');
    }
    if (_selectedMakeModel == null || _selectedMakeModel!.isEmpty) {
      errors.add('Make & Model is required');
    }
    if (_selectedYear == null || _selectedYear!.isEmpty) {
      errors.add('Year is required');
    }
    if (_partNameController.text.trim().isEmpty) {
      errors.add('Part name is required');
    }
    if (_locationController.text.trim().isEmpty) {
      errors.add('Location is required');
    }
    if (_descriptionController.text.trim().isEmpty) {
      errors.add('Description is required');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in required fields: ${errors.join(', ')}'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  void _resetForm() {
    setState(() {
      // Clear controllers
      _vinController.clear();
      _partNameController.clear();
      _locationController.clear();
      _descriptionController.clear();
      _partNumberController.clear();
      _mileageController.clear();

      // Reset dropdowns
      _selectedManufacturer = null;
      _selectedMakeModel = null;
      _selectedType = null;
      _selectedNewUsedPart = null;
      _selectedYear = null;
      _selectedQuantity = null;
      _selectedTimeframe = null;
      _selectedTransmissionType = null;
      _selectedFuelType = null;
      _selectedBodyType = null;

      // Reset slider
      _maxDistance = 50.0;

      // Reset checkboxes
      _agreeToTerms = false;
      _consentToContact = false;

      // Clear images
      _selectedImages.clear();
      _vinImages.clear();
      _imageBytes.clear();
      _vinImageBytes.clear();
    });
  }

  Future<void> _pickVinImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        List<XFile> validImages = [];
        List<String> oversizedFiles = [];

        // Check file sizes first
        for (final image in images) {
          final bool isValidSize = await _isFileSizeValid(image);
          if (isValidSize) {
            validImages.add(image);
          } else {
            final int fileSize = await image.length();
            oversizedFiles.add('${image.name} (${_formatFileSize(fileSize)})');
          }
        }

        // Show error for oversized files
        if (oversizedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The following VIN image files exceed 10MB limit and were not added:\n${oversizedFiles.join('\n')}',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Process valid images
        if (validImages.isNotEmpty) {
          if (kIsWeb) {
            // For web: keep XFile references directly (preserve blob URLs)
            setState(() {
              _vinImages.addAll(validImages);
            });
          } else {
            // For mobile: use byte-based approach
            List<XFile> processedImages = [];

            for (final image in validImages) {
              try {
                final bytes = await image.readAsBytes();
                _vinImageBytes[image.path] = bytes;
                processedImages.add(image);
              } catch (e) {
                print('Failed to read image bytes: $e');
              }
            }

            if (processedImages.isNotEmpty) {
              setState(() {
                _vinImages.addAll(processedImages);
              });
            }
          }

          // Show success message if any images were added
          if (validImages.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${validImages.length} VIN image${validImages.length > 1 ? 's' : ''} added successfully',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else if (images.isNotEmpty && oversizedFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to load selected VIN images. Please try again.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeVinImage(XFile image) {
    setState(() {
      _vinImages.remove(image);
      _vinImageBytes.remove(image.path);
    });
  }

  void _showFullScreenImage(XFile image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                      image.path,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                        : _vinImageBytes.containsKey(image.path)
                        ? Image.memory(
                      _vinImageBytes[image.path]!,
                      fit: BoxFit.contain,
                    )
                        : Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Constants.ctaColorLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationPickerDialog(
          apiKey: _googleMapsApiKey,
          initialLocation: const LatLng(-26.2041, 28.0473), // Johannesburg
          onLocationSelected: (LatLng location, String address) {
            setState(() {
              _selectedLocation = location;
              _selectedAddress = address;
              _locationController.text = address;
            });
          },
        );
      },
    );
  }

  Widget _buildLocationField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        height: 55,
        child: TypeAheadField<Prediction>(
          controller: _locationController,
          focusNode: _locationFocus,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: 'Your Location*',
                labelStyle: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: 'Start typing your address...',
                hintStyle: GoogleFonts.manrope(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1),
                  borderRadius: BorderRadius.circular(36),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Constants.ctaColorLight,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red.shade600, width: 2),
                  borderRadius: BorderRadius.circular(36),
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.only(left: 16, right: 8),
                  child: Icon(
                    Icons.location_on,
                    color: Constants.ftaColorLight,
                    size: 22,
                  ),
                ),
                suffixIcon: _locationController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _locationController.clear();
                    setState(() {
                      _selectedLocation = null;
                      _selectedAddress = '';
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  splashRadius: 20,
                )
                    : GestureDetector(
                  onTap: _showLocationPicker,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight,
                      borderRadius: BorderRadius.circular(360),
                      boxShadow: [
                        BoxShadow(
                          color: Constants.ctaColorLight.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Select',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            if (pattern.length < 3) return [];
            return await _searchPlacesAutocomplete(pattern);
          },
          itemBuilder: (context, suggestion) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Constants.ctaColorLight,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.structuredFormatting?.mainText ??
                              suggestion.description ??
                              '',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (suggestion.structuredFormatting?.secondaryText !=
                            null) ...[
                          SizedBox(height: 2),
                          Text(
                            suggestion.structuredFormatting!.secondaryText!,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 16,
                  ),
                ],
              ),
            );
          },
          onSelected: (suggestion) async {
            await onLocationSelected(suggestion);
          },
          decorationBuilder: (context, child) {
            return Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black.withOpacity(0.15),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: child,
              ),
            );
          },
          offset: Offset(0, 8),
          constraints: BoxConstraints(maxHeight: 300),
          hideOnEmpty: true,
          hideOnError: true,
          hideOnLoading: false,
          loadingBuilder: (context) => Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Constants.ctaColorLight,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Searching locations...',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          errorBuilder: (context, error) => Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                SizedBox(width: 12),
                Text(
                  'Unable to search locations',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          emptyBuilder: (context) => Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.search_off, color: Colors.grey.shade400, size: 20),
                SizedBox(width: 12),
                Text(
                  'No locations found',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVinField() {
    return Container(
      height: 55,
      child: TextField(
        controller: _vinController,
        focusNode: _vinFocus,
        style: GoogleFonts.manrope(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w300,
        ),
        decoration: InputDecoration(
          labelText: 'VIN (Vehicle Identification Number)*',
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: 'Enter VIN Number',
          hintStyle: GoogleFonts.manrope(
            color: Colors.grey.withOpacity(0.35),
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
          prefixIcon: _vinImages.isNotEmpty
              ? InkWell(
            onTap: _showVinImages,
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(360),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '${_vinImages.length} image${_vinImages.length > 1 ? 's' : ''}',
                    style: GoogleFonts.manrope(
                      color: Colors.green.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  GestureDetector(
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.green.shade100,
                      ),
                      child: Icon(
                        Icons.visibility,
                        color: Colors.green.shade700,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : null,
          suffixIcon: GestureDetector(
            onTap: _pickVinImages,
            child: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(360),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Upload Photo',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVinImageField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _buildFormLabel(label),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickVinImages,
          child: Container(
            width: double.infinity,
            height: _vinImages.isEmpty ? 120 : null,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: _vinImages.isEmpty
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                SizedBox(height: 8),
                Text(
                  'Upload VIN Images',
                  style: GoogleFonts.manrope(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap to add images of VIN number',
                  style: GoogleFonts.manrope(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            )
                : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _vinImages
                    .map(
                      (image) => Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(
                            image.path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                              : _vinImageBytes.containsKey(image.path)
                              ? Image.memory(
                            _vinImageBytes[image.path]!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                              : FutureBuilder<Uint8List>(
                            future: image.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                // Cache the bytes for future use
                                _vinImageBytes[image.path] =
                                snapshot.data!;
                                return Image.memory(
                                  snapshot.data!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                );
                              }
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: -5,
                        right: -5,
                        child: GestureDetector(
                          onTap: () => _removeVinImage(image),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showVinImages() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: BoxConstraints(
                  maxWidth: 550,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern header with gradient background
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Constants.ctaColorLight.withOpacity(0.1),
                            Constants.dtaColorLight.withOpacity(0.3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Constants.ctaColorLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.image_outlined,
                              color: Constants.ctaColorLight,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'VIN Images',
                                  style: GoogleFonts.manrope(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Constants.ftaColorLight,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '${_vinImages.length} ${_vinImages.length == 1 ? 'image' : 'images'} uploaded',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: Constants.gtaColorLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Constants.gtaColorLight,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content area with white background
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            if (_vinImages.isEmpty)
                              Expanded(
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: Constants.dtaColorLight
                                              .withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          size: 64,
                                          color: Constants.ctaColorLight
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                      SizedBox(height: 24),
                                      Text(
                                        'No VIN Images Yet',
                                        style: GoogleFonts.manrope(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Constants.ftaColorLight,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Upload images of your vehicle identification number',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          color: Constants.gtaColorLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: GridView.builder(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _vinImages.length == 1
                                        ? 1
                                        : 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: _vinImages.length,
                                  itemBuilder: (context, index) {
                                    final image = _vinImages[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.05,
                                            ),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () =>
                                                _showFullScreenImage(image),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Constants.dtaColorLight
                                                      .withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(14),
                                                child: kIsWeb
                                                    ? Image.network(
                                                  image.path,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                      ) {
                                                    return Container(
                                                      decoration: BoxDecoration(
                                                        color: Constants
                                                            .dtaColorLight
                                                            .withOpacity(
                                                          0.2,
                                                        ),
                                                        borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .broken_image_outlined,
                                                            color: Constants
                                                                .ctaColorLight
                                                                .withOpacity(
                                                              0.7,
                                                            ),
                                                            size: 40,
                                                          ),
                                                          SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Failed to load',
                                                            style: GoogleFonts.manrope(
                                                              color: Constants
                                                                  .gtaColorLight,
                                                              fontSize:
                                                              12,
                                                              fontWeight:
                                                              FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                )
                                                    : _vinImageBytes
                                                    .containsKey(
                                                  image.path,
                                                )
                                                    ? Image.memory(
                                                  _vinImageBytes[image
                                                      .path]!,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                                    : Container(
                                                  decoration: BoxDecoration(
                                                    color: Constants
                                                        .dtaColorLight
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                      14,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      color: Constants
                                                          .ctaColorLight,
                                                      backgroundColor:
                                                      Constants
                                                          .dtaColorLight
                                                          .withOpacity(
                                                        0.3,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                _removeVinImage(image);
                                                setDialogState(
                                                      () {},
                                                ); // Update dialog state
                                                setState(
                                                      () {},
                                                ); // Update main widget state
                                                if (_vinImages.isEmpty) {
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade600,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.red
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                            // Modern "Add More Images" button
                            Container(
                              margin: EdgeInsets.only(top: 20),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _pickVinImages();
                                  },
                                  icon: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  label: Text(
                                    'Add More Images',
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Constants.ctaColorLight,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 18,
                                      horizontal: 24,
                                    ),
                                    elevation: 3,
                                    shadowColor: Constants.ctaColorLight
                                        .withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Autocomplete method for TypeAhead field
  Future<List<Prediction>> _searchPlacesAutocomplete(String pattern) async {
    if (pattern.length < 3) return [];

    try {
      // Use the updated API key
      const String apiKey = 'AIzaSyAegBp2UyTEJZnrmWBBPk0hU-C0bjR0cKA';

      // For web platform, use JavaScript interop to avoid CORS issues
      if (kIsWeb) {
        return await _getPlacePredictionsWeb(pattern);
      }

      // Mobile platform - use direct API call
      final String encodedQuery = Uri.encodeComponent(pattern.trim());
      final String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      final String request =
          '$baseURL?input=$encodedQuery&key=$apiKey&components=country:za&language=en&sessiontoken=${DateTime.now().millisecondsSinceEpoch}';

      final response = await http
          .get(
        Uri.parse(request),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['predictions'] != null) {
          final List<dynamic> predictions = data['predictions'];

          return predictions.take(8).map((prediction) {
            return Prediction(
              description: prediction['description'] ?? '',
              placeId: prediction['place_id'] ?? '',
              reference: prediction['reference'] ?? '',
              matchedSubstrings: [],
              terms: [],
              types: (prediction['types'] as List?)?.cast<String>() ?? [],
              structuredFormatting: null,
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error in _searchPlacesAutocomplete: $e');
      return [];
    }
  }

  // Web-specific method using JavaScript interop (for ProductQuoteForm)
  Future<List<Prediction>> _getPlacePredictionsWeb(String query) async {
    try {
      final Completer<List<Prediction>> completer =
      Completer<List<Prediction>>();

      // Wait for Google Maps API to be available with retries
      bool apiAvailable = await _waitForGoogleMapsAPI();
      if (!apiAvailable) {
        print('Google Places JavaScript API not available after waiting');
        return [];
      }

      // Call JavaScript function
      js.context.callMethod('getPlacePredictions', [
        query,
        js.allowInterop((dynamic jsResults) {
          try {
            // Convert JavaScript array to Dart list
            final List<dynamic> resultsList = List<dynamic>.from(jsResults);
            final List<Prediction> predictions = resultsList.map((jsResult) {
              // Convert each JavaScript object to Map safely
              final Map<String, dynamic> result = _convertJsObjectToMap(
                jsResult,
              );
              return Prediction(
                description: result['description']?.toString() ?? '',
                placeId: result['placeId']?.toString() ?? '',
                reference: result['reference']?.toString() ?? '',
                matchedSubstrings: [],
                terms: [],
                types: _convertToStringList(result['types']),
                structuredFormatting: null,
              );
            }).toList();

            if (!completer.isCompleted) {
              completer.complete(predictions);
            }
          } catch (e) {
            print('Error processing JavaScript results: $e');
            if (!completer.isCompleted) {
              completer.complete([]);
            }
          }
        }),
      ]);

      // Add timeout
      Timer(Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          print('Places API timeout');
          completer.complete([]);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error in _getPlacePredictionsWeb: $e');
      return [];
    }
  }

  // Helper methods for JavaScript object conversion
  Future<bool> _waitForGoogleMapsAPI() async {
    // Check if already available
    if (js.context.hasProperty('getPlacePredictions')) {
      return true;
    }

    // Manual check with retries
    for (int i = 0; i < 20; i++) {
      await Future.delayed(Duration(milliseconds: 500));
      if (js.context.hasProperty('getPlacePredictions')) {
        return true;
      }
    }

    return false;
  }

  Map<String, dynamic> _convertJsObjectToMap(dynamic jsObject) {
    try {
      if (jsObject == null) return {};

      // If it's already a Map, return it
      if (jsObject is Map<String, dynamic>) {
        return jsObject;
      }

      // Convert JavaScript object using JSON serialization
      final String jsonString = js.context['JSON'].callMethod('stringify', [
        jsObject,
      ]);
      return Map<String, dynamic>.from(json.decode(jsonString));
    } catch (e) {
      print('Error converting JavaScript object: $e');
      return {};
    }
  }

  List<String> _convertToStringList(dynamic value) {
    try {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').toList();
      }
      return [];
    } catch (e) {
      print('Error converting to string list: $e');
      return [];
    }
  }

  // Handle location selection from TypeAhead - Web compatible
  Future<void> onLocationSelected(Prediction suggestion) async {
    print("dgfgjh ${suggestion.lat}  ${suggestion.toJson()}");
    try {
      if (suggestion.placeId?.startsWith('geocoding_') == true) {
        // Handle old geocoding format (fallback)
        final coords = suggestion.placeId!
            .substring('geocoding_'.length)
            .split('_');
        if (coords.length == 2) {
          final lat = double.tryParse(coords[0]);
          final lng = double.tryParse(coords[1]);

          if (lat != null && lng != null) {
            final newLatLng = LatLng(lat, lng);
            setState(() {
              _selectedLocation = newLatLng;
              _selectedAddress = suggestion.description ?? '';
              _locationController.text = suggestion.description ?? '';
            });
          }
        }
      } else if (suggestion.placeId != null) {
        // For web platform, prioritize direct geocoding since Places API has issues
        if (kIsWeb) {
          // Try direct geocoding first since we have a good description
          try {
            print(
              'Trying direct geocoding for web with description: "${suggestion.description}"',
            );
            final coordinates = await _geocodeAddressWeb(
              suggestion.description ?? '',
            );
            if (coordinates != null) {
              setState(() {
                _selectedLocation = coordinates;
                _selectedAddress = suggestion.description ?? '';
                _locationController.text = suggestion.description ?? '';
              });
              return;
            }
          } catch (geocodeError) {
            print('Direct geocoding failed: $geocodeError');
          }

          // If geocoding failed, try JavaScript geocoding as backup
          try {
            print('Trying JavaScript geocoding as backup');
            final coordinates = await _geocodeAddressJS(
              suggestion.description ?? '',
            );
            if (coordinates != null) {
              setState(() {
                _selectedLocation = coordinates;
                _selectedAddress = suggestion.description ?? '';
                _locationController.text = suggestion.description ?? '';
              });
              return;
            }
          } catch (jsError) {
            print('JavaScript geocoding failed: $jsError');
          }

          // If JS geocoding failed, try JavaScript Places API as final backup
          try {
            print('Trying JavaScript Places API as final backup');
            final coordinates = await _getPlaceDetailsWeb(suggestion.placeId!);
            if (coordinates != null) {
              setState(() {
                _selectedLocation = coordinates;
                _selectedAddress = suggestion.description ?? '';
                _locationController.text = suggestion.description ?? '';
              });
              return;
            }
          } catch (webError) {
            print('All web methods failed: $webError');
          }
        } else {
          // For mobile platforms, use HTTP API
          try {
            final String baseURL =
                'https://maps.googleapis.com/maps/api/place/details/json';

            final String apiKey = 'AIzaSyAegBp2UyWBBPk0hU-C0bjR0cKA';

            final String request =
                '$baseURL?place_id=${suggestion.placeId}&key=$apiKey&fields=geometry';

            print('Making request to: $request');

            final response = await http.get(Uri.parse(request));

            print('Response status: ${response.statusCode}');
            print('Response body: ${response.body}');

            if (response.statusCode == 200) {
              final Map<String, dynamic> data = json.decode(response.body);

              if (data['status'] == 'OK' &&
                  data['result']?['geometry']?['location'] != null) {
                final location = data['result']['geometry']['location'];
                final lat = location['lat']?.toDouble();
                final lng = location['lng']?.toDouble();

                if (lat != null && lng != null) {
                  final newLatLng = LatLng(lat, lng);

                  setState(() {
                    _selectedLocation = newLatLng;
                    _selectedAddress = suggestion.description ?? '';
                    _locationController.text = suggestion.description ?? '';
                  });
                  return;
                }
              } else {
                print('API Error - Status: ${data['status']}');
                if (data['error_message'] != null) {
                  print('Error message: ${data['error_message']}');
                }
              }
            } else {
              print(
                'HTTP Error: ${response.statusCode} - ${response.reasonPhrase}',
              );
            }
          } catch (httpError) {
            print('HTTP request failed: $httpError');
            // Continue to fallback
          }
        }

        // Final fallback: use geocoding service (mainly for mobile now)
        if (!kIsWeb) {
          try {
            print('Mobile fallback: using geocoding package');
            final coordinates = await _geocodeAddressJS(
              suggestion.description ?? '',
            );
            if (coordinates != null) {
              setState(() {
                _selectedLocation = coordinates;
                _selectedAddress = suggestion.description ?? '';
                _locationController.text = suggestion.description ?? '';
              });
              return;
            }
          } catch (geocodeError) {
            print('Mobile geocoding fallback failed: $geocodeError');
          }
        }
      } else {
        // Fallback: just set the description
        setState(() {
          _selectedAddress = suggestion.description ?? '';
          _locationController.text = suggestion.description ?? '';
        });
      }
    } catch (e) {
      print('Error in onLocationSelected: $e');
      // Fallback: just set the description
      setState(() {
        _selectedAddress = suggestion.description ?? '';
        _locationController.text = suggestion.description ?? '';
      });
    }
  }

  // Web-specific method to get place details using JavaScript Places API
  Future<LatLng?> _getPlaceDetailsWeb(String placeId) async {
    if (!kIsWeb) return null;

    try {
      // Wait for Google Maps API to be available
      final bool apiAvailable = await _waitForGoogleMapsAPI();
      if (!apiAvailable) {
        print('Google Places JavaScript API not available');
        return null;
      }

      final Completer<LatLng?> completer = Completer<LatLng?>();

      // Call JavaScript function to get place details
      js.context.callMethod('getPlaceDetails', [
        placeId,
        js.allowInterop((result) {
          if (!completer.isCompleted) {
            if (result != null) {
              try {
                // Convert the JS object to a Map
                final Map<String, dynamic> resultMap = _convertJsObjectToMap(
                  result,
                );
                final double lat = resultMap['latitude']?.toDouble() ?? 0.0;
                final double lng = resultMap['longitude']?.toDouble() ?? 0.0;

                if (lat != 0.0 || lng != 0.0) {
                  completer.complete(LatLng(lat, lng));
                } else {
                  completer.complete(null);
                }
              } catch (e) {
                print('Error processing place details result: $e');
                completer.complete(null);
              }
            } else {
              completer.complete(null);
            }
          }
        }),
      ]);

      // Timeout after 10 seconds
      Timer(Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          print('getPlaceDetails timeout');
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error in _getPlaceDetailsWeb: $e');
      return null;
    }
  }

  // Web-specific geocoding method using Google Geocoding API
  Future<LatLng?> _geocodeAddressWeb(String address) async {
    if (!kIsWeb || address.isEmpty) return null;

    try {
      final String apiKey = 'AIzaSyAegBp2UyWBBPk0hU-C0bjR0cKA';
      final String encodedAddress = Uri.encodeComponent(address);
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

      print('Web geocoding request: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final double lat = location['lat']?.toDouble() ?? 0.0;
          final double lng = location['lng']?.toDouble() ?? 0.0;

          if (lat != 0.0 || lng != 0.0) {
            print('Web geocoding successful: LatLng($lat, $lng)');
            return LatLng(lat, lng);
          }
        } else {
          print('Web geocoding API error - Status: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
          if (data['status'] == 'REQUEST_DENIED') {
            print('API Key issue - check:');
            print('1. Geocoding API is enabled');
            print('2. API key has proper permissions');
            print('3. Billing is set up');
            print('4. Domain restrictions allow this request');
          }
        }
      } else {
        print('Web geocoding HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Web geocoding error in VehicleDetailsQuoteForm: $e');
    }

    return null;
  }

  // JavaScript-based geocoding method using Google Geocoder
  Future<LatLng?> _geocodeAddressJS(String address) async {
    if (!kIsWeb || address.isEmpty) return null;

    try {
      // Wait for Google Maps API to be available
      final bool apiAvailable = await _waitForGoogleMapsAPI();
      if (!apiAvailable) {
        print('Google Maps JavaScript API not available for geocoding');
        return null;
      }

      final Completer<LatLng?> completer = Completer<LatLng?>();

      // Call JavaScript function to geocode address
      js.context.callMethod('geocodeAddress', [
        address,
        js.allowInterop((results) {
          if (!completer.isCompleted) {
            if (results != null && results is List && results.isNotEmpty) {
              try {
                // Convert the JS object to a Map
                final Map<String, dynamic> resultMap = _convertJsObjectToMap(
                  results[0],
                );
                final double lat = resultMap['latitude']?.toDouble() ?? 0.0;
                final double lng = resultMap['longitude']?.toDouble() ?? 0.0;

                if (lat != 0.0 || lng != 0.0) {
                  print('JavaScript geocoding successful: LatLng($lat, $lng)');
                  completer.complete(LatLng(lat, lng));
                } else {
                  print('JavaScript geocoding returned 0,0 coordinates');
                  completer.complete(null);
                }
              } catch (e) {
                print('Error processing JS geocoding result: $e');
                completer.complete(null);
              }
            } else {
              print('JavaScript geocoding returned no results');
              completer.complete(null);
            }
          }
        }),
      ]);

      // Timeout after 10 seconds
      Timer(Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          print('JavaScript geocoding timeout');
          completer.complete(null);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error in _geocodeAddressJS: $e');
      return null;
    }
  }


}

class ProductQuoteMobileForm extends StatefulWidget {
  @override
  _ProductQuoteMobileFormState createState() => _ProductQuoteMobileFormState();
}

class _ProductQuoteMobileFormState extends State<ProductQuoteMobileForm> {
  // Controllers
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _featuresController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Location variables
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  static const String _googleMapsApiKey =
      'AIzaSyAegBp2UyTEJZnrmWBBPk0hU-C0bjR0cKA';

  // Focus Nodes
  final FocusNode _typeFocus = FocusNode();
  final FocusNode _brandFocus = FocusNode();
  final FocusNode _modelFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _minPriceFocus = FocusNode();
  final FocusNode _maxPriceFocus = FocusNode();
  final FocusNode _featuresFocus = FocusNode();
  final FocusNode _commentsFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  // Dropdown values
  String? _selectedTimeframe;
  String? _selectedInstallation;
  String? _selectedCondition;
  String? _selectedPurpose;

  final TextEditingController _maxDistanceController = TextEditingController();
  final FocusNode _maxDistanceFocus = FocusNode();

  // Checkbox values
  bool _agreeToTerms = false;
  bool _consentToContact = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  Map<String, Uint8List> _imageBytes = {};

  // Loading state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Set initial values
    _maxDistanceController.text = _maxDistance.round().toString();
  }

  @override
  void dispose() {
    // Dispose controllers
    _typeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _featuresController.dispose();
    _commentsController.dispose();
    _locationController.dispose();
    _maxDistanceController.dispose();

    // Dispose focus nodes
    _typeFocus.dispose();
    _brandFocus.dispose();
    _modelFocus.dispose();
    _quantityFocus.dispose();
    _minPriceFocus.dispose();
    _maxPriceFocus.dispose();
    _featuresFocus.dispose();
    _commentsFocus.dispose();
    _locationFocus.dispose();
    _maxDistanceFocus.dispose();

    super.dispose();
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Documents or Images',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: _selectedImages.isEmpty ? 120 : null,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: _selectedImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 24,
                          color: Colors.grey[500],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload Documents or Images',
                          style: GoogleFonts.manrope(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedImages
                              .map((image) => _buildImagePreview(image))
                              .toList(),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Constants.ctaColorLight),
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(
                              'Add More Images',
                              style: GoogleFonts.manrope(
                                color: Constants.ctaColorLight,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedImages.length} image(s) selected',
              style: GoogleFonts.manrope(
                color: Colors.grey[600],
                fontSize: ResponsiveTypography.getTypography(context).normal,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview(XFile image) {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            onTap: () => _removeImage(image),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  void _removeImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
      _imageBytes.remove(image.path);
    });
  }

  Widget _buildCustomTextField(
      String hintText,
      TextEditingController controller,
      FocusNode focusNode,
      FocusNode? nextFocusNode, {
        Widget? suffixIcon,
        bool? integersOnly,
      }) {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      textInputAction: nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
      isPasswordField: false,
      integersOnly: integersOnly,
      suffix: suffixIcon,
      onChanged: (value) {},
      onSubmitted: (value) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildCustomDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            menuMaxHeight: 200,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            value: value,
            hint: Text(
              label.replaceAll('*', ''),
              style: GoogleFonts.manrope(
                color: Colors.grey.withOpacity(0.35),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.manrope(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: typography.subHeading,
              fontWeight: FontWeight.w600,
              color: Constants.ctaColorLight,
            ),
          ),
          SizedBox(height: spacing.spacingLarge),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        // Product Details Section
        _buildSection('Product Details', [
          isMobile
              ? Column(
                  children: [
                    _buildCustomTextField(
                      'Type of Electronics',
                      _typeController,
                      _typeFocus,
                      _brandFocus,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomTextField(
                      'Brand Preference',
                      _brandController,
                      _brandFocus,
                      _modelFocus,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        'Type of Electronics',
                        _typeController,
                        _typeFocus,
                        _brandFocus,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomTextField(
                        'Brand Preference',
                        _brandController,
                        _brandFocus,
                        _modelFocus,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          isMobile
              ? Column(
                  children: [
                    _buildCustomTextField(
                      'Model/Series (if known)',
                      _modelController,
                      _modelFocus,
                      _quantityFocus,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomTextField(
                      'Quantity Needed',
                      _quantityController,
                      _quantityFocus,
                      _minPriceFocus,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        'Model/Series (if known)',
                        _modelController,
                        _modelFocus,
                        _quantityFocus,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomTextField(
                        'Quantity Needed',
                        _quantityController,
                        _quantityFocus,
                        _minPriceFocus,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          _buildLocationField(),
        ]),
        SizedBox(height: 24),

        // Budget And Timeline Section
        _buildSection('Budget And Timeline', [
          isMobile
              ? Column(
                  children: [
                    _buildCustomTextField(
                      'Min Price',
                      _minPriceController,
                      _minPriceFocus,
                      _maxPriceFocus,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomTextField(
                      'Max Price',
                      _maxPriceController,
                      _maxPriceFocus,
                      null,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        'Min Price',
                        _minPriceController,
                        _minPriceFocus,
                        _maxPriceFocus,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomTextField(
                        'Max Price',
                        _maxPriceController,
                        _maxPriceFocus,
                        null,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          isMobile
              ? Column(
                  children: [
                    _buildCustomDropdown(
                      'How Soon Do You Need the Product?',
                      _selectedTimeframe,
                      [
                        'Within a week',
                        'Within 2 weeks',
                        'Within a month',
                        'Within 3 months',
                        'No rush',
                      ],
                      (value) => setState(() => _selectedTimeframe = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Do You Need Installation Services?',
                      _selectedInstallation,
                      ['Yes', 'No', 'Maybe'],
                      (value) => setState(() => _selectedInstallation = value),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomDropdown(
                        'How Soon Do You Need the Product?',
                        _selectedTimeframe,
                        [
                          'Within a week',
                          'Within 2 weeks',
                          'Within a month',
                          'Within 3 months',
                          'No rush',
                        ],
                        (value) => setState(() => _selectedTimeframe = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Do You Need Installation Services?',
                        _selectedInstallation,
                        ['Yes', 'No', 'Maybe'],
                        (value) =>
                            setState(() => _selectedInstallation = value),
                      ),
                    ),
                  ],
                ),
        ]),
        SizedBox(height: 24),

        // Features and Specifications Section
        _buildSection('Features and Specifications', [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Features or Specifications',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _featuresController,
                  focusNode: _featuresFocus,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Required Features or Specifications',
                    hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          isMobile
              ? Column(
                  children: [
                    _buildCustomDropdown(
                      'Condition Preference',
                      _selectedCondition,
                      [
                        'New / Refurbished',
                        'New only',
                        'Refurbished only',
                        'Used acceptable',
                      ],
                      (value) => setState(() => _selectedCondition = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Purpose of Purchase',
                      _selectedPurpose,
                      [
                        'Home Use',
                        'Business Use',
                        'Commercial Use',
                        'Industrial Use',
                      ],
                      (value) => setState(() => _selectedPurpose = value),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomDropdown(
                        'Condition Preference',
                        _selectedCondition,
                        [
                          'New / Refurbished',
                          'New only',
                          'Refurbished only',
                          'Used acceptable',
                        ],
                        (value) => setState(() => _selectedCondition = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Purpose of Purchase',
                        _selectedPurpose,
                        [
                          'Home Use',
                          'Business Use',
                          'Commercial Use',
                          'Industrial Use',
                        ],
                        (value) => setState(() => _selectedPurpose = value),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          _buildImageUploadSection(),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Additional Comments',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _commentsController,
                  focusNode: _commentsFocus,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional Comments',
                    hintStyle: GoogleFonts.manrope(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          _buildSliderField(
            'Max Distance You Want to Travel (km)*',
            _maxDistance3,
            0,
            200,
                (value) => setState(() => _maxDistance3 = value),
          ),
        ]),
        SizedBox(height: 24),


        // Checkboxes
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            ResponsiveSpacing.getSpacing(context).paddingLarge,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) =>
                        setState(() => _agreeToTerms = value ?? false),
                    activeColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the terms and conditions.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _consentToContact,
                    onChanged: (value) =>
                        setState(() => _consentToContact = value ?? false),
                    activeColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I consent to being contacted for further details regarding my quote request.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Submit Button
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: 45,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_agreeToTerms && _consentToContact) {
                      _submitElectronicsForm();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please agree to terms and consent to contact.',
                          ),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubmitting
                  ? Colors.grey
                  : Constants.ctaColorLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(360),
              ),
              elevation: 5,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _submitElectronicsForm() async {
    // Basic validation
    if (!_validateElectronicsForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ApiService.submitElectronicsRequest(
        electronicsType: _typeController.text,
        brandPreference: _brandController.text,
        modelSeries: _modelController.text,
        quantityNeeded: _quantityController.text,
        minPrice: _minPriceController.text,
        maxPrice: _maxPriceController.text,
        timeframe: _selectedTimeframe ?? 'Within a week',
        installationRequired: _selectedInstallation ?? 'No',
        conditionPreference: _selectedCondition ?? 'New / Refurbished',
        purposeOfPurchase: _selectedPurpose ?? 'Home Use',
        requiredFeatures: _featuresController.text,
        additionalComments: _commentsController.text,
        images: _selectedImages,
        locationLat: _selectedLocation?.latitude,
        locationLng: _selectedLocation?.longitude,
        locationAddress: _locationController.text.isNotEmpty
            ? _locationController.text
            : _selectedAddress,
        maxDistance: _maxDistance3,
      );

      if (result['success']) {
        // Show success dialog
        await _showElectronicsRequestSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Show styled success dialog for electronics request submission
  Future<void> _showElectronicsRequestSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                SizedBox(
                  height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                ),

                // Success Title
                Text(
                  'Electronics Request Submitted!',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                ),

                // Success Message
                Text(
                  'Your electronics request has been submitted successfully. Suppliers will contact you with their best offers.',
                  style: GoogleFonts.manrope(
                    fontSize: ResponsiveTypography.getTypography(
                      context,
                    ).medium,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Reset form
                          _resetElectronicsForm();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Constants.ftaColorLight),
                          ),
                        ),
                        child: Text(
                          'Submit Another',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Reset form
                          _resetElectronicsForm();
                          // Navigate to dashboard
                          if (mounted) {
                            context.go('/dashboard');
                            Constants.buyerAppBarValue = 6;
                            appBarValueNotifier.value++;
                            buyerHomeValueNotifier.value++;
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ftaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'View Requests',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _validateElectronicsForm() {
    List<String> errors = [];

    if (_typeController.text.trim().isEmpty) {
      errors.add('Electronics type is required');
    }
    if (_quantityController.text.trim().isEmpty) {
      errors.add('Quantity is required');
    }
    if (_locationController.text.trim().isEmpty) {
      errors.add('Location is required');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in required fields: ${errors.join(', ')}'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  void _resetElectronicsForm() {
    setState(() {
      // Clear controllers
      _typeController.clear();
      _brandController.clear();
      _modelController.clear();
      _quantityController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _featuresController.clear();
      _commentsController.clear();
      _maxDistance3 =1;

      // Reset dropdowns
      _selectedTimeframe = 'Within a week';
      _selectedInstallation = 'Yes';
      _selectedCondition = 'New / Refurbished';
      _selectedPurpose = 'Home Use';

      // Reset checkboxes
      _agreeToTerms = false;
      _consentToContact = false;

      // Clear images
      _selectedImages.clear();
      _imageBytes.clear();
      _locationController.clear();

      // Reset location
      _selectedLocation = null;
      _selectedAddress = '';
    });
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationPickerDialog(
          apiKey: _googleMapsApiKey,
          initialLocation: const LatLng(-26.2041, 28.0473), // Johannesburg
          onLocationSelected: (LatLng location, String address) {
            setState(() {
              _selectedLocation = location;
              _selectedAddress = address;
              _locationController.text = address;
            });
          },
        );
      },
    );
  }

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: _showLocationPicker,
      child: Container(
        height: 55,
        child: TextField(
          controller: _locationController,
          focusNode: _locationFocus,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Your Location*',
            labelStyle: TextStyle(
              color: Colors.black,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: 'Tap to select location',
            hintStyle: GoogleFonts.manrope(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(36),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(36),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(36),
            ),
            suffixIcon: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(360),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Select Location',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderField(
      String label,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      ) {
    return TextField(
      controller: _maxDistanceController,
      focusNode: _maxDistanceFocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      style: GoogleFonts.manrope(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: 'Enter distance (1-1500 km)',
        hintStyle: GoogleFonts.manrope(color: Colors.grey[500], fontSize: 14),
        fillColor: Colors.transparent,
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(36),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(36),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(36),
        ),
        suffixIcon: Container(
          width: 200,
          padding: EdgeInsets.only(right: 16),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Constants.ctaColorLight,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Constants.ftaColorLight,
              overlayColor: Constants.ctaColorLight.withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (newValue) {
                onChanged(newValue);
                _maxDistanceController.text = newValue.round().toString();
              },
            ),
          ),
        ),
      ),
      onChanged: (text) {
        double? newValue = double.tryParse(text);
        if (newValue != null && newValue >= min && newValue <= max) {
          onChanged(newValue);
        }
      },
    );
  }
}



class TireProductQuoteMobileForm extends StatefulWidget {
  @override
  _TireProductQuoteMobileFormState createState() =>
      _TireProductQuoteMobileFormState();
}

class _TireProductQuoteMobileFormState
    extends State<TireProductQuoteMobileForm> {
  // Controllers
  final TextEditingController _tyreWidthController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _preferredBrandController =
      TextEditingController();
  final TextEditingController _pcdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Location variables
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  static const String _googleMapsApiKey =
      'AIzaSyAegBp2UyTEJZnrmWBBPk0hU-C0bjR0cKA';

  // Focus Nodes
  final FocusNode _tyreWidthFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _preferredBrandFocus = FocusNode();
  final FocusNode _pcdFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  // Dropdown values
  String? _selectedSidewallProfile;
  String? _selectedWheelRimDiameter;
  String? _selectedTyresRims;
  String? _selectedQuantity;
  String? _selectedTimeframe;
  String? _selectedVehicleType;
  String? _selectedTyreConstruction;
  String? _selectedFitmentRequired;
  String? _selectedBalancingRequired;
  String? _selectedTyreRotation;
  final TextEditingController _maxDistanceController = TextEditingController();
  final FocusNode _maxDistanceFocus = FocusNode();

  // Checkbox values
  bool _agreeToTerms = false;
  bool _consentToContact = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  Map<String, Uint8List> _imageBytes = {};

  // Loading state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Set initial values
    _maxDistanceController.text = _maxDistance.round().toString();
  }

  @override
  void dispose() {
    // Dispose controllers
    _tyreWidthController.dispose();
    _descriptionController.dispose();
    _preferredBrandController.dispose();
    _pcdController.dispose();
    _locationController.dispose();
    _maxDistanceController.dispose();

    // Dispose focus nodes
    _tyreWidthFocus.dispose();
    _descriptionFocus.dispose();
    _preferredBrandFocus.dispose();
    _pcdFocus.dispose();
    _locationFocus.dispose();
    _maxDistanceFocus.dispose();

    super.dispose();
  }

  Widget _buildCustomTextField(
      String hintText,
      TextEditingController controller,
      FocusNode focusNode,
      FocusNode? nextFocusNode, {
        Widget? suffixIcon,
        bool? integersOnly,
      }) {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      textInputAction: nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
      isPasswordField: false,
      integersOnly: integersOnly,
      suffix: suffixIcon,
      onChanged: (value) {},
      onSubmitted: (value) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildCustomDropdown(
      String label,
      String? value,
      List<String> items,
      Function(String?) onChanged,
      ) {
    return Container(
      width: double.infinity,
      height: 48,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'YuGothic',
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Constants.ctaColorLight),
            borderRadius: BorderRadius.circular(36),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            menuMaxHeight: 200,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            value: value,
            hint: Text(
              label.replaceAll('*', ''),
              style: GoogleFonts.manrope(
                color: Colors.grey.withOpacity(0.35),
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.manrope(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Images Of The Product You Require',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: _selectedImages.isEmpty ? 120 : null,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: _selectedImages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: Colors.grey[500],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Upload Images',
                    style: GoogleFonts.manrope(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to select images from gallery',
                    style: GoogleFonts.manrope(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
                : Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedImages
                        .map((image) => _buildImagePreview(image))
                        .toList(),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Constants.ctaColorLight),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Text(
                        'Add More Images',
                        style: GoogleFonts.manrope(
                          color: Constants.ctaColorLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '${_selectedImages.length} image(s) selected',
              style: GoogleFonts.manrope(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview(XFile image) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<Uint8List>(
              future: image.readAsBytes(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: GestureDetector(
            onTap: () => _removeImage(image),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _isFileSizeValid(XFile file) async {
    final int fileSize = await file.length();
    return fileSize <= 10 * 1024 * 1024; // 10MB limit
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        List<XFile> validImages = [];
        List<String> oversizedFiles = [];

        // Check file sizes first
        for (final image in images) {
          final bool isValidSize = await _isFileSizeValid(image);
          if (isValidSize) {
            validImages.add(image);
          } else {
            final int fileSize = await image.length();
            oversizedFiles.add('${image.name} (${_formatFileSize(fileSize)})');
          }
        }

        // Show error for oversized files
        if (oversizedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The following files exceed 10MB limit and were not added:\n${oversizedFiles.join('\n')}',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Process valid images
        if (validImages.isNotEmpty) {
          if (kIsWeb) {
            // For web: keep XFile references directly (preserve blob URLs)
            setState(() {
              _selectedImages.addAll(validImages);
            });
          } else {
            // For mobile: use byte-based approach
            List<XFile> processedImages = [];

            for (final image in validImages) {
              try {
                final bytes = await image.readAsBytes();
                _imageBytes[image.path] = bytes;
                processedImages.add(image);
              } catch (e) {
                print('Failed to read image bytes: $e');
              }
            }

            if (processedImages.isNotEmpty) {
              setState(() {
                _selectedImages.addAll(processedImages);
              });
            }
          }

          // Show success message if any images were added
          if (validImages.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${validImages.length} image${validImages.length > 1 ? 's' : ''} added successfully',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else if (images.isNotEmpty && oversizedFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to load selected images. Please try again.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(XFile image) {
    setState(() {
      _selectedImages.remove(image);
      _imageBytes.remove(image.path);
    });
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Constants.ctaColorLight,
            ),
          ),
          SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderField(
      String label,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      ) {
    return TextField(
      controller: _maxDistanceController,
      focusNode: _maxDistanceFocus,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
      style: GoogleFonts.manrope(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: 'Enter distance (1-1500 km)',
        hintStyle: GoogleFonts.manrope(color: Colors.grey[500], fontSize: 14),
        fillColor: Colors.transparent,
        filled: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.circular(36),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.55)),
          borderRadius: BorderRadius.circular(36),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(36),
        ),
        suffixIcon: Container(
          width: 200,
          padding: EdgeInsets.only(right: 16),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Constants.ctaColorLight,
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Constants.ftaColorLight,
              overlayColor: Constants.ctaColorLight.withOpacity(0.2),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: (newValue) {
                onChanged(newValue);
                _maxDistanceController.text = newValue.round().toString();
              },
            ),
          ),
        ),
      ),
      onChanged: (text) {
        double? newValue = double.tryParse(text);
        if (newValue != null && newValue >= min && newValue <= max) {
          onChanged(newValue);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);

    return Column(
      children: [
        // Product Details Section
        _buildSection('Product Details', [
          isMobile
              ? Column(
                  children: [
                    _buildCustomTextField(
                      'Tyre width (mm)*',
                      _tyreWidthController,
                      _tyreWidthFocus,
                      null,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Sidewall Profile*',
                      _selectedSidewallProfile,
                      ['35', '40', '45', '50', '55', '60', '65', '70', '75'],
                      (value) =>
                          setState(() => _selectedSidewallProfile = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Wheel Rim Diameter (inches)*',
                      _selectedWheelRimDiameter,
                      [
                        '13',
                        '14',
                        '15',
                        '16',
                        '17',
                        '18',
                        '19',
                        '20',
                        '21',
                        '22',
                      ],
                      (value) =>
                          setState(() => _selectedWheelRimDiameter = value),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        'Tyre width (mm)*',
                        _tyreWidthController,
                        _tyreWidthFocus,
                        null,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Sidewall Profile*',
                        _selectedSidewallProfile,
                        ['35', '40', '45', '50', '55', '60', '65', '70', '75'],
                        (value) =>
                            setState(() => _selectedSidewallProfile = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Wheel Rim Diameter (inches)*',
                        _selectedWheelRimDiameter,
                        [
                          '13',
                          '14',
                          '15',
                          '16',
                          '17',
                          '18',
                          '19',
                          '20',
                          '21',
                          '22',
                        ],
                        (value) =>
                            setState(() => _selectedWheelRimDiameter = value),
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          isMobile
              ? Column(
                  children: [
                    _buildCustomDropdown(
                      'Select Tyres/Rims*',
                      _selectedTyresRims,
                      ['Tyres', 'Rims', 'Tyres & Rims'],
                      (value) => setState(() => _selectedTyresRims = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Quantity*',
                      _selectedQuantity,
                      ['1', '2', '3', '4', '5', '6', '7', '8'],
                      (value) => setState(() => _selectedQuantity = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'How Soon Do You Need To Buy This Product?*',
                      _selectedTimeframe,
                      [
                        '12 Hours',
                        '24 Hours',
                        '2-3 Days',
                        '1 Week',
                        '2 Weeks',
                        'Within a Month',
                      ],
                      (value) => setState(() => _selectedTimeframe = value),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomDropdown(
                        'Select Tyres/Rims*',
                        _selectedTyresRims,
                        ['Tyres', 'Rims', 'Tyres & Rims'],
                        (value) => setState(() => _selectedTyresRims = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Quantity*',
                        _selectedQuantity,
                        ['1', '2', '3', '4', '5', '6', '7', '8'],
                        (value) => setState(() => _selectedQuantity = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'How Soon Do You Need To Buy This Product?*',
                        _selectedTimeframe,
                        [
                          '12 Hours',
                          '24 Hours',
                          '2-3 Days',
                          '1 Week',
                          '2 Weeks',
                          'Within a Month',
                        ],
                        (value) => setState(() => _selectedTimeframe = value),
                      ),
                    ),
                  ],
                ),
        ]),
        SizedBox(height: 24),

        // More Fields Section
        _buildSection('More Fields', [
          isMobile
              ? Column(
                  children: [
                    _buildCustomTextField(
                      'Description Of Item',
                      _descriptionController,
                      _descriptionFocus,
                      _preferredBrandFocus,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Vehicle Type',
                      _selectedVehicleType,
                      [
                        'Passenger Car',
                        'SUV',
                        'Truck',
                        'Van',
                        'Motorcycle',
                        'Bus',
                      ],
                      (value) => setState(() => _selectedVehicleType = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomTextField(
                      'Pitch Circle Diameter (PCD)',
                      _pcdController,
                      _pcdFocus,
                      null,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _buildCustomTextField(
                        'Description Of Item',
                        _descriptionController,
                        _descriptionFocus,
                        _preferredBrandFocus,
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomDropdown(
                        'Vehicle Type',
                        _selectedVehicleType,
                        [
                          'Passenger Car',
                          'SUV',
                          'Truck',
                          'Van',
                          'Motorcycle',
                          'Bus',
                        ],
                        (value) => setState(() => _selectedVehicleType = value),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: _buildCustomTextField(
                        'Pitch Circle Diameter (PCD)',
                        _pcdController,
                        _pcdFocus,
                        null,
                      ),
                    ),
                  ],
                ),
          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
          Column(
                  children: [
                    _buildCustomTextField(
                      'Preferred Brand',
                      _preferredBrandController,
                      _preferredBrandFocus,
                      null,
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Tyre Construction Type',
                      _selectedTyreConstruction,
                      ['Radial', 'Bias', 'Bias-Belted'],
                      (value) =>
                          setState(() => _selectedTyreConstruction = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Fitment Required',
                      _selectedFitmentRequired,
                      ['Yes', 'No'],
                      (value) =>
                          setState(() => _selectedFitmentRequired = value),
                    ),
                  ],
                ),

          SizedBox(height: ResponsiveSpacing.getSpacing(context).spacingLarge),
           Column(
                  children: [
                    _buildCustomDropdown(
                      'Balancing Required',
                      _selectedBalancingRequired,
                      ['Yes', 'No'],
                      (value) =>
                          setState(() => _selectedBalancingRequired = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildCustomDropdown(
                      'Tyre Rotation Required',
                      _selectedTyreRotation,
                      ['Yes', 'No'],
                      (value) => setState(() => _selectedTyreRotation = value),
                    ),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildImageUploadSection(),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildLocationField(),
                    SizedBox(
                      height: ResponsiveSpacing.getSpacing(
                        context,
                      ).spacingLarge,
                    ),
                    _buildSliderField(
                      'Max Distance You Want to Travel (km)*',
                      _maxDistance2,
                      0,
                      200,
                          (value) => setState(() => _maxDistance2 = value),
                    ),
                  ],
                )

        ]),

        SizedBox(height: 24),

        // Checkboxes
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(
            ResponsiveSpacing.getSpacing(context).paddingLarge,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) =>
                        setState(() => _agreeToTerms = value ?? false),
                    activeColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the terms and conditions.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Checkbox(
                    value: _consentToContact,
                    onChanged: (value) =>
                        setState(() => _consentToContact = value ?? false),
                    activeColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I consent to being contacted for further details regarding my quote request.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 20),

        // Submit Button
        Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: 45,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_agreeToTerms && _consentToContact) {
                      _submitTyresRimsForm();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please agree to terms and consent to contact.',
                          ),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSubmitting
                  ? Colors.grey
                  : Constants.ctaColorLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(360),
              ),
              elevation: 5,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Submit',
                    style: GoogleFonts.manrope(
                      fontSize: ResponsiveTypography.getTypography(
                        context,
                      ).normal,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _submitTyresRimsForm() async {
    // Basic validation
    if (!_validateTyresRimsForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ApiService.submitTyresRimsRequest(
        tyreWidth: _tyreWidthController.text,
        sidewallProfile: _selectedSidewallProfile ?? '55',
        wheelRimDiameter: _selectedWheelRimDiameter ?? '16',
        tyresRims: _selectedTyresRims ?? 'Tyres',
        quantity: _selectedQuantity ?? '1',
        timeframe: _selectedTimeframe ?? '12 Hours',
        description: _descriptionController.text,
        vehicleType: _selectedVehicleType ?? 'Passenger Car',
        pcd: _pcdController.text,
        preferredBrand: _preferredBrandController.text,
        tyreConstruction: _selectedTyreConstruction ?? 'Radial',
        fitmentRequired: _selectedFitmentRequired ?? 'Yes',
        balancingRequired: _selectedBalancingRequired ?? 'Yes',
        tyreRotation: _selectedTyreRotation ?? 'No',
        images: _selectedImages,
        locationLat: _selectedLocation?.latitude,
        locationLng: _selectedLocation?.longitude,
        locationAddress: _locationController.text.isNotEmpty
            ? _locationController.text
            : _selectedAddress,
        maxDistance: _maxDistance2,
      );

      if (result['success']) {
        // Show success dialog
        await _showTyresRimsRequestSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Show styled success dialog for tyres/rims request submission
  Future<void> _showTyresRimsRequestSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            width: 400,
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 50,
                  ),
                ),
                SizedBox(
                  height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                ),

                // Success Title
                Text(
                  'Tyres & Rims Request Submitted!',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                ),

                // Success Message
                Text(
                  'Your tyres and rims request has been submitted successfully. Suppliers will provide you with competitive quotes soon.',
                  style: GoogleFonts.manrope(
                    fontSize: ResponsiveTypography.getTypography(
                      context,
                    ).medium,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Reset form
                          _resetTyresRimsForm();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Constants.ftaColorLight),
                          ),
                        ),
                        child: Text(
                          'Submit Another',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: ResponsiveSpacing.getSpacing(context).spacingLarge,
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Reset form
                          _resetTyresRimsForm();
                          // Navigate to dashboard
                          if (mounted) {
                            context.go('/dashboard');
                            Constants.buyerAppBarValue = 6;
                            appBarValueNotifier.value++;
                            buyerHomeValueNotifier.value++;
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ftaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'View Requests',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _validateTyresRimsForm() {
    List<String> errors = [];

    if (_tyreWidthController.text.trim().isEmpty) {
      errors.add('Tyre width is required');
    }
    if (_selectedSidewallProfile == null || _selectedSidewallProfile!.isEmpty) {
      errors.add('Sidewall profile is required');
    }
    if (_selectedWheelRimDiameter == null ||
        _selectedWheelRimDiameter!.isEmpty) {
      errors.add('Wheel rim diameter is required');
    }
    if (_locationController.text.trim().isEmpty) {
      errors.add('Location is required');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in required fields: ${errors.join(', ')}'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return false;
    }

    return true;
  }

  void _resetTyresRimsForm() {
    setState(() {
      // Clear controllers
      _tyreWidthController.clear();
      _descriptionController.clear();
      _preferredBrandController.clear();
      _pcdController.clear();
      _locationController.clear();

      // Reset location
      _selectedLocation = null;
      _selectedAddress = '';
      _maxDistance2 =1;

      // Reset dropdowns
      _selectedSidewallProfile = '55';
      _selectedWheelRimDiameter = '16';
      _selectedTyresRims = 'Tyres';
      _selectedQuantity = '1';
      _selectedTimeframe = '12 Hours';
      _selectedVehicleType = 'Passenger Car';
      _selectedTyreConstruction = 'Radial';
      _selectedFitmentRequired = 'Yes';
      _selectedBalancingRequired = 'Yes';
      _selectedTyreRotation = 'No';

      // Reset checkboxes
      _agreeToTerms = false;
      _consentToContact = false;

      // Clear images
      _selectedImages.clear();
      _imageBytes.clear();
    });
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LocationPickerDialog(
          apiKey: _googleMapsApiKey,
          initialLocation: const LatLng(-26.2041, 28.0473), // Johannesburg
          onLocationSelected: (LatLng location, String address) {
            setState(() {
              _selectedLocation = location;
              _selectedAddress = address;
              _locationController.text = address;
            });
          },
        );
      },
    );
  }

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: _showLocationPicker,
      child: Container(
        height: 55,
        child: TextField(
          controller: _locationController,
          focusNode: _locationFocus,
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Your Location*',
            labelStyle: TextStyle(
              color: Colors.black,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'YuGothic',
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            hintText: 'Tap to select location',
            hintStyle: GoogleFonts.manrope(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(36),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(36),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
              borderRadius: BorderRadius.circular(36),
            ),
            suffixIcon: Container(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(360),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Select Location',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


}

class FooterMobileSection extends StatelessWidget {
  final String logo;
  final Function(String)? onFooterLinkTap;

  const FooterMobileSection({
    Key? key,
    required this.logo,
    this.onFooterLinkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(color: Constants.ftaColorLight),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Image.asset(logo, fit: BoxFit.contain),
                SizedBox(
                  height: ResponsiveSpacing.getSpacing(context).spacingLarge,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _footerLink('Home'),
                    _footerLink('Support'),
                    _footerLink('FAQs'),
                    _footerLink('Policies'),
                    _footerLink('Blogs'),
                    _footerLink('Contact Us'),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  '© 2024 BIDR. All rights reserved.',
                  style: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  children: [
                    Wrap(
                      runSpacing: 24,
                      spacing: 24,
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
                          imagePath: 'lib/assets/images/youTube.png',
                          url: 'https://www.youTube.com',
                        ),
                      ],
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

  Widget _footerLink(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: TextButton(
        onPressed: onFooterLinkTap != null
            ? () => onFooterLinkTap!(text)
            : () {},
        child: Text(
          text,
          style: GoogleFonts.manrope(color: Colors.white.withOpacity(0.7)),
        ),
      ),
    );
  }
}

class SocialMediaMobileButton extends StatelessWidget {
  final String imagePath;
  final String url;
  final double? size;

  const SocialMediaMobileButton({
    Key? key,
    required this.imagePath,
    required this.url,
    this.size = 30.0,
  }) : super(key: key);

  Future<void> _launchUrl() async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchUrl,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(360.0),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          width: 30,
          height: 30,
        ),
      ),
    );
  }
}

class LocationPickerMobileDialog extends StatefulWidget {
  final String apiKey;
  final LatLng initialLocation;
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerMobileDialog({
    Key? key,
    required this.apiKey,
    required this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationPickerMobileDialog> createState() =>
      _LocationPickerMobileDialogState();
}

class _LocationPickerMobileDialogState
    extends State<LocationPickerMobileDialog> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(-26.2041, 28.0473);
  String _selectedAddress = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    // Get initial address for the default location
    _getAddressFromLocation(_selectedLocation);
  }

  // Get address from location coordinates
  void _getAddressFromLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address.isNotEmpty
              ? address
              : 'Johannesburg, South Africa';
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Johannesburg, South Africa';
      });
    }
  }

  // Search for a location by name
  void _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(query);

      if (locations.isNotEmpty) {
        final location = locations.first;
        final newLatLng = LatLng(location.latitude, location.longitude);

        // Update the map and get the address
        setState(() {
          _selectedLocation = newLatLng;
        });

        // Move the camera to the new location
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: newLatLng, zoom: 16.0),
            ),
          );
        }

        // Get the formatted address
        _getAddressFromLocation(newLatLng);
      } else {
        // Show error if location not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location not found: $query'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _selectedAddress = 'Getting address...'; // Show loading state
    });

    // Get address from coordinates (reverse geocoding)
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address.isNotEmpty
              ? address
              : '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        });
      } else {
        setState(() {
          _selectedAddress =
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress =
            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      });
      print('Geocoding error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Select Location',
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildCustomTextField(
                "Search for a location...",
                _searchController,
                searchFocusNode,
                _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),

            // Map
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation,
                      zoom: 14.0,
                    ),
                    onTap: _onMapTapped,
                    markers: {
                      Marker(
                        markerId: MarkerId('selected_location'),
                        position: _selectedLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueOrange,
                        ),
                        infoWindow: InfoWindow(
                          title: 'Selected Location',
                          snippet: _selectedAddress.isNotEmpty
                              ? _selectedAddress
                              : 'Tap to select location',
                        ),
                      ),
                    },
                  ),
                ),
              ),
            ),

            // Selected location info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  if (_selectedAddress.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Location:',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _selectedAddress,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Constants.ctaColorLight,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap on the map to select a location',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: Constants.ctaColorLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                          side: BorderSide(color: Constants.ftaColorLight),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 22),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final address = _selectedAddress.isNotEmpty
                            ? _selectedAddress
                            : 'Location: ${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}';
                        widget.onLocationSelected(_selectedLocation, address);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,

                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                        ),
                      ),
                      child: Text(
                        'Select Location',
                        style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    Widget? suffixIcon,
  ) {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      isPasswordField: false,
      suffix: suffixIcon,
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          _searchLocation(value);
        }
      },
      onChanged: (value) {
        setState(() {}); // To show/hide clear button
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
