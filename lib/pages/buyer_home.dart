import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;

import 'package:bidr/pages/seller/seller_home_dashboard.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../authentication/login.dart';
import '../constants/Constants.dart';
import '../customWdget/appbar.dart';
import '../customWdget/custom_input2.dart';
import '../models/alert.dart';
import '../notifier/my_notifier.dart';
import '../services/products_management_api_service.dart';
import 'buyer/blog.dart';
import 'buyer/contact_form.dart';
import 'buyer/join_as_business.dart';
import 'buyer/join_as_buyer.dart';
import 'buyer/support.dart';
import 'buyer/video.dart';
import 'buyer_dashboard.dart';
import 'faq_screen.dart';
import 'mobileView/breakpoints.dart';
import 'mobileView/buyerDashboard/buyerMobileDashboard.dart';
import 'mobileView/landingPage/landingMobileController.dart';
import 'notification.dart';
import 'policies_screen.dart';

class BuyerHomePage extends StatefulWidget {
  @override
  _BuyerHomePageState createState() => _BuyerHomePageState();
}

MyNotifier? myNotifier;
MyNotifier? mySellerNotifier;
final buyerHomeValueNotifier = ValueNotifier<int>(0);
final sellerHomeValueNotifier = ValueNotifier<int>(0);
double _maxDistance = 1.0;
double _maxDistance2 = 1.0;
double _maxDistance3 = 1.0;

class _BuyerHomePageState extends State<BuyerHomePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  int selectedIndex = -1;
  int index = 0;
  List<WebNotification> notifications = [];
  double _maxDistance = 0;
  Map<int, bool> _categoryHoverStates = {};
  bool _imagesPreloaded = false;

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
    mySellerNotifier = MyNotifier(sellerHomeValueNotifier, context);
    buyerHomeValueNotifier.addListener(_onBuyerValueChanged);
    sellerHomeValueNotifier.addListener(_onSellerValueChanged);
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Preload category images only once to prevent flickering
    if (!_imagesPreloaded) {
      _preloadCategoryImages();
      _imagesPreloaded = true;
    }
  }

  void _preloadCategoryImages() {
    for (var category in categories) {
      precacheImage(AssetImage(category["icon"]!), context);
      precacheImage(AssetImage(category["icon2"]!), context);
    }
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

  void _onBuyerValueChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSellerValueChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    buyerHomeValueNotifier.removeListener(_onBuyerValueChanged);
    sellerHomeValueNotifier.removeListener(_onSellerValueChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _categoryController.dispose();
    _scrollController.dispose();
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
      "icon": "lib/assets/images/rim_and_type.png",
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
      "icon2": "lib/assets/images/auction_light.png",
      "name": "Vehicle\nAuctions",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Breakpoints.isMobile(context)
        ? LandingMobileController()
        : Scaffold(
            backgroundColor: Colors.white, //
            body: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Header Section
                  SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 32,
                        ), //BlogCardsScreen
                        child: HeaderSection(),
                      ),
                    ),
                  ),

                  Constants.buyerAppBarValue == 0
                      ? Expanded(
                          child: Container(
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              thickness: 12,
                              radius: Radius.circular(6),
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                physics: BouncingScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 1600,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(height: 24),

                                          // Animated Banner Section
                                          ScaleTransition(
                                            scale: _scaleAnimation,
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                left:
                                                    Breakpoints.isTablet(
                                                      context,
                                                    )
                                                    ? 24
                                                    : 32,
                                                right:
                                                    Breakpoints.isTablet(
                                                      context,
                                                    )
                                                    ? 24
                                                    : 32,
                                              ),
                                              child: Center(
                                                child: _buildAnimatedBannerSection(
                                                  "lib/assets/images/competitive.png",
                                                ),
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: 36),

                                          // Animated Category Section
                                          Center(
                                            child: SlideTransition(
                                              position: _slideAnimation,
                                              child: FadeTransition(
                                                opacity: _categoryAnimation,
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    left:
                                                        Breakpoints.isTablet(
                                                          context,
                                                        )
                                                        ? 24
                                                        : 64,
                                                    right:
                                                        Breakpoints.isTablet(
                                                          context,
                                                        )
                                                        ? 24
                                                        : 64,
                                                  ),
                                                  child: Center(
                                                    child:
                                                        _buildCategoryItems(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Animated Form Section
                                          AnimatedSwitcher(
                                            duration: Duration(
                                              milliseconds: 500,
                                            ),
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
                                                      padding: EdgeInsets.only(
                                                        left:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? 24
                                                            : 64,
                                                        right: 64,
                                                      ),
                                                      child:
                                                          VehicleDetailsQuoteForm(),
                                                    )
                                                  : selectedIndex == 1
                                                  ? Padding(
                                                      padding: EdgeInsets.only(
                                                        left:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? 24
                                                            : 64,
                                                        right:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? 24
                                                            : 64,
                                                      ),
                                                      child:
                                                          TireProductQuoteForm(),
                                                    )
                                                  : selectedIndex == 2
                                                  ? Padding(
                                                      padding: EdgeInsets.only(
                                                        left:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? 24
                                                            : 64,
                                                        right:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? 24
                                                            : 64,
                                                      ),
                                                      child: ProductQuoteForm(),
                                                    )
                                                  : selectedIndex == 3
                                                  ? Padding(
                                                      padding: EdgeInsets.only(
                                                        left:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? 24
                                                            : 64,
                                                        right:
                                                            Breakpoints.isTablet(
                                                              context,
                                                            )
                                                            ? 24
                                                            : 64,
                                                      ),
                                                      child:
                                                          _buildVehicleAuctionsComingSoon(),
                                                    )
                                                  : SizedBox.shrink(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Animated About Us Section
                                    selectedIndex < 0
                                        ? SizedBox.shrink()
                                        : SizedBox(height: 60),
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0.0,
                                        end: 1.0,
                                      ),
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

                                    SizedBox(height: 24),

                                    // Animated Bottom Banner
                                    /* FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth: 1600,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: Breakpoints.isTablet(context)
                                              ? 24
                                              : 64,
                                          right: Breakpoints.isTablet(context)
                                              ? 24
                                              : 64,
                                        ),
                                        child: Center(
                                          child: _buildAnimatedBannerSection(
                                            "lib/assets/images/mask_group.png",
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),*/
                                    SizedBox(height: 24),

                                    // Animated Footer
                                    SlideTransition(
                                      position: Tween<Offset>(
                                        begin: Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(_slideController),
                                      child: Center(
                                        child: FooterSection(
                                          logo:
                                              "lib/assets/images/bidr_logo2.png",
                                          onFooterLinkTap: (String text) {
                                            switch (text) {
                                              case 'Home':
                                                setState(() {
                                                  Constants.buyerAppBarValue =
                                                      0;
                                                  buyerHomeValueNotifier
                                                      .value++;
                                                });
                                                break;
                                              case 'Support':
                                                setState(() {
                                                  Constants.buyerAppBarValue =
                                                      1;
                                                  buyerHomeValueNotifier
                                                      .value++;
                                                });
                                                break;
                                              case 'FAQs':
                                                setState(() {
                                                  Constants.buyerAppBarValue =
                                                      2;
                                                  buyerHomeValueNotifier
                                                      .value++;
                                                });
                                                break;
                                              case 'Policies':
                                                setState(() {
                                                  Constants.buyerAppBarValue =
                                                      3;
                                                  buyerHomeValueNotifier
                                                      .value++;
                                                });
                                                break;
                                              case 'Blogs':
                                                setState(() {
                                                  Constants.buyerAppBarValue =
                                                      4;
                                                  buyerHomeValueNotifier
                                                      .value++;
                                                });
                                                break;
                                              case 'Contact Us':
                                                setState(() {
                                                  Constants.buyerAppBarValue =
                                                      5;
                                                  buyerHomeValueNotifier
                                                      .value++;
                                                });
                                                break;
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : Constants.buyerAppBarValue == 1
                      ? Expanded(child: Support())
                      : Constants.buyerAppBarValue == 2
                      ? Expanded(child: FAQScreen())
                      : Constants.buyerAppBarValue == 3
                      ? Expanded(child: PoliciesScreen())
                      : Constants.buyerAppBarValue == 4
                      ? Expanded(child: BlogCardsScreen())
                      : Constants.buyerAppBarValue == 5
                      ? Expanded(child: ContactFormScreen())
                      : Constants.buyerAppBarValue == 6
                      ? Expanded(
                          child: Breakpoints.isMobile(context)
                              ? BuyerMobileDashboard()
                              : BuyerDashboardScreen(),
                        )
                      : Constants.buyerAppBarValue == 7
                      ? Expanded(child: SellerDashboard())
                      : Constants.buyerAppBarValue == 8
                      ? Expanded(
                          child: NotificationPage(notifications: notifications),
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Constants.ctaColorLight,
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 28,
              ),
              tooltip: 'Scroll to top',
            ),
          );
  }

  Widget _buildAboutUsSection() {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(maxWidth: 1200),
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          // Section Title
          Text(
            'Why Choose BIDR?',
            style: GoogleFonts.manrope(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Constants.ftaColorLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),

          // Grid View with 3 cards
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            children: [
              _buildInfoCard(
                icon: HugeIcons.strokeRoundedHelpCircle,
                title: 'How it Works?',
                subtitle:
                    'Simple process: Create a request, receive bids from multiple sellers, choose the best offer. No more endless searching.',
                color: Colors.orange,
                index: 0,
              ),
              _buildInfoCard(
                icon: HugeIcons.strokeRoundedShoppingCart01,
                title: 'Why buyers should use this service?',
                subtitle:
                    'Save time and money. Get competitive prices from verified sellers. One request, multiple offers, best deals.',
                color: Colors.blue,
                index: 1,
              ),
              _buildInfoCard(
                icon: HugeIcons.strokeRoundedBuilding05,
                title: 'Why join as a business?',
                subtitle:
                    'Reach more customers, increase sales, compete fairly. Join our network of trusted sellers and grow your business.',
                color: Colors.green,
                index: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                // Beautiful gradient background
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, color.withOpacity(0.02), Colors.white],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.08), width: 1.2),
                boxShadow: [
                  // Primary shadow
                  BoxShadow(
                    color: color.withOpacity(0.06),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: Offset(0, 4),
                  ),
                  // Secondary subtle shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                // Inner glow effect
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon with subtle background
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          icon,
                          size: 32,
                          color: color.withOpacity(0.9),
                        ),
                      ),
                      SizedBox(height: 24),
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      // Subtitle
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedVideoSection(
    String title,
    String description,
    String buttonTitle,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 800 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: EdgeInsets.only(left: 32, right: 32, bottom: 32),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.35,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Constants.dtaColorLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Constants.ctaColorLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 2,
                            spreadRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Constants.ftaColorLight,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  description,
                                  textAlign: TextAlign.justify,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 8,
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Constants.ftaColorLight.withOpacity(
                                      0.65,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          if (title == "About Us") ...[
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomVideoPlayerWidget(
                                      videoUrl:
                                          'assets/videos/4058080-sd_426_226_25fps.mp4',
                                      autoPlay: false,
                                      looping: true,
                                      placeholder: 'Loading awesome video...',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: CustomVideoPlayerWidget(
                                      videoUrl:
                                          'assets/videos/5585948-hd_1920_1080_25fps.mp4',
                                      autoPlay: false,
                                      looping: true,
                                      placeholder: 'Loading awesome video...',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (title == "How It Works") ...[
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: CustomVideoPlayerWidget(
                                      videoUrl:
                                          'assets/videos/6353353-hd_1080_1920_30fps.mp4',
                                      autoPlay: false,
                                      looping: true,
                                      placeholder: 'Loading awesome video...',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.only(left: 12, right: 12),
                    height: 55,
                    width: MediaQuery.of(context).size.width * 0.35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(360),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            buttonTitle,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Constants.ftaColorLight,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          height: 23,
                          width: 23,
                          child: Center(
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              child: IconButton(
                                onPressed: () {
                                  if (title == "How It Works") {
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
                                  } else {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder:
                                            (
                                              context,
                                              animation,
                                              secondaryAnimation,
                                            ) => BuyerLandingPage(),
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
                                  }
                                  setState(() {});
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Constants.ftaColorLight,
                                ),
                                icon: Center(
                                  child: Icon(
                                    size: 10,
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBannerSection(String image) {
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
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  height: 400,
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
    final bool isMobile = Breakpoints.isMobile(context);
    final bool isTablet = Breakpoints.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive width for category cards
    double cardWidth;
    if (isMobile) {
      // 2 columns on mobile
      cardWidth = (screenWidth - 48 - 16) / 2;
    } else if (isTablet) {
      // 3-4 columns on tablet
      cardWidth = (screenWidth - 48 - 32) / 3.5;
    } else {
      // Original desktop layout
      cardWidth = (screenWidth - 48 - 48) / 6.8;
    }

    // Responsive font sizes
    final double titleFontSize = isMobile
        ? 24
        : isTablet
        ? 28
        : 34;
    final double subtitleFontSize = isMobile
        ? 13
        : isTablet
        ? 14
        : 15.5;

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
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                  ),
                ),
              );
            },
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
                  child: Text(
                    'Please click on one of the categories to begin',
                    style: GoogleFonts.manrope(
                      fontSize: subtitleFontSize,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isMobile ? 24 : 36),
          Wrap(
            spacing: isMobile ? 12 : 16,
            runSpacing: isMobile ? 16 : 24,
            alignment: WrapAlignment.center,
            children: List.generate(categories.length, (index) {
              var category = categories[index];
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.01, end: 1.0),
                duration: Duration(milliseconds: 800 + (index * 200)),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Container(
                        width: cardWidth,
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
          SizedBox(height: 24),
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
    final bool isHovering = _categoryHoverStates[index] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _categoryHoverStates[index] = true),
      onExit: (_) => setState(() => _categoryHoverStates[index] = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
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

                    boxShadow: isSelected || isHovering
                        ? [
                            BoxShadow(
                              color: isHovering && !isSelected
                                  ? Constants.ctaColorLight.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.05),
                              blurRadius: isHovering && !isSelected ? 12 : 6,
                              spreadRadius: isHovering && !isSelected ? 2 : 0,
                              offset: Offset(
                                0,
                                isHovering && !isSelected ? 3 : 1,
                              ),
                            ),
                          ]
                        : [],
                  ),
                  child: AnimatedScale(
                    scale: isSelected ? 0.82 : 0.8,
                    duration: Duration(milliseconds: 200),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedOpacity(
                          opacity: isSelected || isHovering ? 0.0 : 1.0,
                          duration: Duration(milliseconds: 200),
                          child: Image.asset(iconImage2, fit: BoxFit.contain),
                        ),
                        AnimatedOpacity(
                          opacity: isSelected || isHovering ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 200),
                          child: Image.asset(iconImage, fit: BoxFit.contain),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 200),
                  style: GoogleFonts.manrope(
                    color: isSelected
                        ? Constants.ftaColorLight
                        : isHovering
                        ? Constants.ctaColorLight
                        : Constants.ftaColorLight.withOpacity(0.85),
                    fontSize: isSelected ? 24 : 20,
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF072744).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.gavel, size: 40, color: Color(0xFF072744)),
          ),
          SizedBox(height: 24),
          Text(
            'Vehicle Auctions',
            style: GoogleFonts.manrope(
              fontSize: 28,
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
                fontSize: 12,
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
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Participate in live auctions with real-time bidding, secure transactions, and access to premium vehicles from trusted sellers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleDetailsQuoteForm extends StatefulWidget {
  @override
  _VehicleDetailsQuoteFormState createState() =>
      _VehicleDetailsQuoteFormState();
}

class _VehicleDetailsQuoteFormState extends State<VehicleDetailsQuoteForm> {
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

  // Autocomplete controllers
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _makeModelController = TextEditingController();
  final FocusNode _manufacturerFocus = FocusNode();
  final FocusNode _makeModelFocus = FocusNode();

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

  // Form validation state variables
  Map<String, bool> _fieldErrors = {};
  bool _showValidationErrors = false;

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
    String? validationKey,
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
      hasError: _showValidationErrors && 
                validationKey != null && 
                _fieldErrors[validationKey] == true,
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
    Function(String?) onChanged, {
    String? validationKey,
  }) {
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
            borderSide: BorderSide(
              color: _showValidationErrors && 
                     validationKey != null && 
                     _fieldErrors[validationKey] == true
                  ? Colors.red
                  : Constants.ftaColorLight,
            ),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: _showValidationErrors && 
                     validationKey != null && 
                     _fieldErrors[validationKey] == true
                  ? Colors.red
                  : Constants.ctaColorLight,
            ),
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
    Function(String) onSelected, {
    String? validationKey,
  }) {
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
                    borderSide: BorderSide(
                      color: _showValidationErrors && 
                             validationKey != null && 
                             _fieldErrors[validationKey] == true
                          ? Colors.red
                          : Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _showValidationErrors && 
                             validationKey != null && 
                             _fieldErrors[validationKey] == true
                          ? Colors.red
                          : Colors.black,
                    ),
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
    return Column(
      children: [
        // Vehicle Details Section
        _buildSection('Vehicle Details', [
          Row(
            children: [
              Expanded(child: _buildVinField()),
              SizedBox(width: 16),
              Expanded(
                child: _buildAutocomplete(
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
                  validationKey: 'manufacturer',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAutocomplete(
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
                  validationKey: 'makeModel',
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
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
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'New/Used Part*',
                  _selectedNewUsedPart,
                  ['Select New/Used Part', 'New', 'Used', 'Refurbished'],
                  (value) => setState(() => _selectedNewUsedPart = value),
                ),
              ),
              SizedBox(width: 16),
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
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Part Name/Description*',
                  _partNameController,
                  _partNameFocus,
                  _locationFocus,
                  validationKey: 'partName',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Quantity*',
                  _selectedQuantity,
                  ['Select Quantity', '1', '2', '3', '4', '5', '6', '7', '8'],
                  (value) => setState(() => _selectedQuantity = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(child: _buildLocationField()),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSliderField(
                  'Max Distance You Want to Travel (km)*',
                  _maxDistance,
                  1,
                  1500,
                  (value) => setState(() => _maxDistance = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'How Soon Do You Need To Buy This Product?*',
                  _selectedTimeframe,
                  [
                    'Select Time',
                    '1 Hour',
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
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomTextField(
                  'Description of the Product*',
                  _descriptionController,
                  _descriptionFocus,
                  null,
                  validationKey: 'description',
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildImageUploadSection(),
        ]),
        SizedBox(height: 24),

        // More Fields Section
        _buildSection('More Fields', [
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Part Number',
                  _partNumberController,
                  _partNumberFocus,
                  _mileageFocus,
                ),
              ),
              SizedBox(width: 16),
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
                  (value) => setState(() => _selectedTransmissionType = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomTextField(
                  'Mileage of Vehicle',
                  _mileageController,
                  _mileageFocus,
                  null,
                  integersOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
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
              SizedBox(width: 16),
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
              SizedBox(width: 16),
              const Expanded(
                child: SizedBox.shrink(),
              ), // Empty space for alignment
            ],
          ),
        ]),
        SizedBox(height: 24),

        // Checkboxes
        Container(
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
                      fontSize: 14,
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
  bool _isSubmitting = false;

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

  // Show modern authentication dialog
  void _showAuthenticationDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Authentication Dialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated icon
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 0.0, end: 1.0),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Constants.ctaColorLight,
                                      Constants.ctaColorLight.withOpacity(0.8),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.login_outlined,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Title
                        Text(
                          'Login Required',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        Text(
                          'You need to be logged in to submit a product request.\nWould you like to sign in now?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Action buttons
                        Row(
                          children: [
                            // Cancel button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey[300]!),
                                ),
                                child: Text(
                                  'Later',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Login button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _navigateToLogin();
                                },
                                icon: Icon(Icons.login, size: 20),
                                label: Text(
                                  'Sign In',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.ctaColorLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
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
      // Geocode address if coordinates are not available
      double? lat = _selectedLocation?.latitude;
      double? lng = _selectedLocation?.longitude;

      print('=== LOCATION COORDINATE DEBUG ===');
      print('Initial lat from _selectedLocation: $lat');
      print('Initial lng from _selectedLocation: $lng');
      print('Location text from controller: "${_locationController.text}"');

      if (lat == null && lng == null && _locationController.text.isNotEmpty) {
        print(
          'Attempting geocoding because coordinates are null but address text exists',
        );
        try {
          final coordinates = await _geocodeAddress(_locationController.text);
          lat = coordinates?.latitude;
          lng = coordinates?.longitude;
          print('After geocoding - lat: $lat, lng: $lng');
        } catch (e) {
          print('Geocoding failed: $e');
          // Continue with null coordinates if geocoding fails
        }
      }

      print('Final coordinates to be sent - lat: $lat, lng: $lng');
      print('=== END COORDINATE DEBUG ===');

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
        locationLat: lat,
        locationLng: lng,
      );
      print("Form submitted after login: ${result}");

      if (result['success']) {
        // Show success dialog
        await _showVehicleRequestSuccessDialog();
      } else {
        // Show failure dialog with error message
        await _showRequestFailureDialog(
          result['message'] ?? 'Failed to submit request. Please try again.',
        );
      }
    } catch (e) {
      // Show failure dialog with exception message
      await _showRequestFailureDialog(
        'Error submitting request: $e',
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
      // Geocode address if coordinates are not available
      double? lat = _selectedLocation?.latitude;
      double? lng = _selectedLocation?.longitude;

      print('=== LOCATION COORDINATE DEBUG ===');
      print('Initial lat from _selectedLocation: $lat');
      print('Initial lng from _selectedLocation: $lng');
      print('Location text from controller: "${_locationController.text}"');

      if (lat == null && lng == null && _locationController.text.isNotEmpty) {
        print(
          'Attempting geocoding because coordinates are null but address text exists',
        );
        try {
          final coordinates = await _geocodeAddress(_locationController.text);
          lat = coordinates?.latitude;
          lng = coordinates?.longitude;
          print('After geocoding - lat: $lat, lng: $lng');
        } catch (e) {
          print('Geocoding failed: $e');
          // Continue with null coordinates if geocoding fails
        }
      }

      print('Final coordinates to be sent - lat: $lat, lng: $lng');
      print('=== END COORDINATE DEBUG ===');

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
        locationLat: lat,
        locationLng: lng,
      );
      print("sdhdshj ${result}");

      if (result['success']) {
        // Show success dialog
        await _showVehicleRequestSuccessDialog();
      } else {
        // Show failure dialog with error message
        await _showRequestFailureDialog(
          result['message'] ?? 'Failed to submit request. Please try again.',
        );
      }
    } catch (e) {
      // Show failure dialog with exception message
      await _showRequestFailureDialog(
        'Error submitting request: $e',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  /// Show styled success dialog for vehicle request submission
  /// Show modern success dialog for vehicle request submission
  Future<void> _showVehicleRequestSuccessDialog() async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success Dialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Success Icon with gradient background
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Success Title
                        Text(
                          'Request Submitted Successfully!',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Constants.ftaColorLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Success Message
                        Text(
                          'Your vehicle spare parts request has been submitted successfully. You will receive quotes from suppliers soon.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _resetForm();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Constants.ftaColorLight),
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _resetForm();
                                  if (mounted) {
                                    context.go('/dashboard');
                                    Constants.buyerAppBarValue = 6;
                                    appBarValueNotifier.value++;
                                    buyerHomeValueNotifier.value++;
                                    setState(() {});
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.ctaColorLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show modern failure dialog for request submission
  Future<void> _showRequestFailureDialog(String errorMessage) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Failure Dialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Error Icon with gradient background
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Error Title
                        Text(
                          'Submission Failed',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Error Message
                        Text(
                          errorMessage.isNotEmpty
                              ? errorMessage
                              : 'An error occurred while submitting your request. Please try again.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _submitFormDirectly(); // Retry submission
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.ctaColorLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Try Again',
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _validateForm() {
    List<String> errors = [];
    _fieldErrors.clear();
    _showValidationErrors = true;

    if (_manufacturerController.text.trim().isEmpty) {
      errors.add('Manufacturer is required');
      _fieldErrors['manufacturer'] = true;
    }
    if (_makeModelController.text.trim().isEmpty) {
      errors.add('Make & Model is required');
      _fieldErrors['makeModel'] = true;
    }
    if (_selectedYear == null || _selectedYear!.isEmpty) {
      errors.add('Year is required');
      _fieldErrors['year'] = true;
    }
    if (_partNameController.text.trim().isEmpty) {
      errors.add('Part name is required');
      _fieldErrors['partName'] = true;
    }
    if (_locationController.text.trim().isEmpty) {
      errors.add('Location is required');
      _fieldErrors['location'] = true;
    }
    if (_descriptionController.text.trim().isEmpty) {
      errors.add('Description is required');
      _fieldErrors['description'] = true;
    }
    if (_maxDistance < 1.0 || _maxDistance > 1500.0) {
      errors.add(
        'Max Distance must be between 1 km and 1500 km (National coverage).',
      );
    }

    if (errors.isNotEmpty) {
      setState(() {}); // Trigger rebuild to show red borders
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
      _manufacturerController.clear();
      _makeModelController.clear();

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
      _maxDistance = 1.0;

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
                  borderSide: BorderSide(
                    color: _showValidationErrors && _fieldErrors['location'] == true
                        ? Colors.red
                        : Colors.black,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _showValidationErrors && _fieldErrors['location'] == true
                        ? Colors.red
                        : Constants.ctaColorLight,
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
            final coordinates = await _geocodeAddress(
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

// Geocode address text to coordinates
Future<LatLng?> _geocodeAddress(String address) async {
  print('=== GEOCODING DEBUG ===');
  print('Attempting to geocode address: "$address"');
  print('Platform: ${kIsWeb ? "Web" : "Mobile"}');

  if (address.isEmpty) {
    print('Address is empty');
    return null;
  }

  // For web platform, use Google Geocoding API via HTTP to avoid CORS issues
  if (kIsWeb) {
    try {
      print('Using Google Geocoding API for web platform');
      final String apiKey = 'AIzaSyAegBp2UyWBBPk0hU-C0bjR0cKA';
      final String encodedAddress = Uri.encodeComponent(address);
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

      print('Making geocoding request to: $url');

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
            final result = LatLng(lat, lng);
            print('Web geocoding successful: $result');
            return result;
          } else {
            print('Web geocoding returned 0,0 coordinates');
          }
        } else {
          print('Web geocoding API error - Status: ${data['status']}');
          if (data['error_message'] != null) {
            print('Error message: ${data['error_message']}');
          }
        }
      } else {
        print(
          'Web geocoding HTTP error: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Web geocoding error: $e');
      print('Error type: ${e.runtimeType}');
    }
  } else {
    // For mobile platforms, use the geocoding package
    try {
      print('Using geocoding package for mobile platform');
      List<Location> locations = await locationFromAddress(address);
      print('Geocoding service returned ${locations.length} locations');

      if (locations.isNotEmpty) {
        final location = locations.first;
        print(
          'First location coordinates: lat=${location.latitude}, lng=${location.longitude}',
        );

        // Verify coordinates are valid (not 0,0)
        if (location.latitude != 0.0 || location.longitude != 0.0) {
          LatLng result = LatLng(location.latitude, location.longitude);
          print('Mobile geocoding successful: $result');
          return result;
        } else {
          print('Mobile geocoding returned 0,0 coordinates');
        }
      } else {
        print('Mobile geocoding: No locations found for address');
      }
    } catch (e) {
      print('Mobile geocoding error: $e');
      print('Error type: ${e.runtimeType}');
    }
  }

  print('=== GEOCODING FAILED - RETURNING NULL ===');
  return null;
}

class ProductQuoteForm extends StatefulWidget {
  @override
  _ProductQuoteFormState createState() => _ProductQuoteFormState();
}

class _ProductQuoteFormState extends State<ProductQuoteForm> {
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
  final TextEditingController _maxDistance3Controller = TextEditingController();
  final FocusNode _maxDistance3Focus = FocusNode();

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

  // Checkbox values
  bool _agreeToTerms = false;
  bool _consentToContact = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  Map<String, Uint8List> _imageBytes = {};

  // Loading state
  bool _isSubmitting = false;

  // Form validation state variables
  Map<String, bool> _fieldErrors = {};
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    // Set initial values
    _maxDistance3Controller.text = _maxDistance3.round().toString();
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
    _maxDistance3Controller.dispose();
    _maxDistance3Controller.text = _maxDistance3.round().toString();
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
              style: GoogleFonts.manrope(color: Colors.grey[600], fontSize: 12),
            ),
          ),
      ],
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
      controller: _maxDistance3Controller,
      focusNode: _maxDistance3Focus,
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
                _maxDistance3Controller.text = newValue.round().toString();
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
            child: kIsWeb
                ? Image.network(
                    image.path,
                    width: 80,
                    height: 80,
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
                  )
                : _imageBytes.containsKey(image.path)
                ? Image.memory(
                    _imageBytes[image.path]!,
                    width: 80,
                    height: 80,
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
                  )
                : Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
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

  /// Show modern failure dialog for request submission
  Future<void> _showRequestFailureDialog(String errorMessage) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Failure Dialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Error Icon with gradient background
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Error Title
                        Text(
                          'Submission Failed',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Error Message
                        Text(
                          errorMessage.isNotEmpty
                              ? errorMessage
                              : 'An error occurred while submitting your request. Please try again.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Note: Each class would need its own submit method
                                  // _submitFormDirectly(); // This would be class-specific
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.ctaColorLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Try Again',
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
    bool? integersOnly,
    String? validationKey,
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
      hasError: _showValidationErrors && 
                validationKey != null && 
                _fieldErrors[validationKey] == true,
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
    Function(String?) onChanged, {
    String? validationKey,
  }) {
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
            borderSide: BorderSide(
              color: _showValidationErrors && 
                     validationKey != null && 
                     _fieldErrors[validationKey] == true
                  ? Colors.red
                  : Constants.ftaColorLight,
            ),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: _showValidationErrors && 
                     validationKey != null && 
                     _fieldErrors[validationKey] == true
                  ? Colors.red
                  : Constants.ctaColorLight,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Product Details Section
        _buildSection('Product Details', [
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Type of Electronics',
                  _typeController,
                  _typeFocus,
                  _brandFocus,
                  validationKey: 'electronicsType',
                ),
              ),
              SizedBox(width: 16),
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
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Model/Series (if known)',
                  _modelController,
                  _modelFocus,
                  _quantityFocus,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomTextField(
                  'Quantity Needed',
                  _quantityController,
                  _quantityFocus,
                  _minPriceFocus,
                  integersOnly: true,
                  validationKey: 'quantity',
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildLocationField()),
              SizedBox(width: 24),
              Expanded(
                child: _buildSliderField(
                  'Max Distance You Want to Travel (km)*',
                  _maxDistance3,
                  1,
                  1500,
                  (value) => setState(() => _maxDistance3 = value),
                ),
              ),
            ],
          ),
        ]),
        SizedBox(height: 24),

        // Budget And Timeline Section
        _buildSection('Budget And Timeline', [
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Min Price',
                  _minPriceController,
                  _minPriceFocus,
                  _maxPriceFocus,
                  integersOnly: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomTextField(
                  'Max Price',
                  _maxPriceController,
                  _maxPriceFocus,
                  null,
                  integersOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
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
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Do You Need Installation Services?',
                  _selectedInstallation,
                  ['Yes', 'No', 'Maybe'],
                  (value) => setState(() => _selectedInstallation = value),
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
          SizedBox(height: 24),
          Row(
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
              SizedBox(width: 16),
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
          SizedBox(height: 24),
          _buildImageUploadSection(),
          SizedBox(height: 24),
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
        ]),
        SizedBox(height: 24),

        // Checkboxes
        Container(
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
    // Check authentication first
    if (Constants.currentUser == null && !Constants.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to submit a request'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        // Show failure dialog with error message
        await _showRequestFailureDialog(
          result['message'] ?? 'Failed to submit request. Please try again.',
        );
      }
    } catch (e) {
      // Show failure dialog with exception message
      await _showRequestFailureDialog(
        'Error submitting request: $e',
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
                SizedBox(height: 24),

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
                SizedBox(height: 16),

                // Success Message
                Text(
                  'Your electronics request has been submitted successfully. Suppliers will contact you with their best offers.',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
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
                    SizedBox(width: 16),
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
    _fieldErrors.clear();
    _showValidationErrors = true;

    if (_typeController.text.trim().isEmpty) {
      errors.add('Electronics type is required');
      _fieldErrors['electronicsType'] = true;
    }
    if (_quantityController.text.trim().isEmpty) {
      errors.add('Quantity is required');
      _fieldErrors['quantity'] = true;
    }
    if (_locationController.text.trim().isEmpty) {
      errors.add('Location is required');
      _fieldErrors['location'] = true;
    }
    if (_maxDistance3 < 1.0 || _maxDistance3 > 1500.0) {
      errors.add(
        'Max Distance must be between 1 km and 1500 km (National coverage).',
      );
    }

    if (errors.isNotEmpty) {
      setState(() {}); // Trigger rebuild to show red borders
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
      _maxDistance3 = 1.0;
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
}

Widget? _buildFormLabel(String hintText) {
  return Text(hintText);
}

class TireProductQuoteForm extends StatefulWidget {
  @override
  _TireProductQuoteFormState createState() => _TireProductQuoteFormState();
}

class _TireProductQuoteFormState extends State<TireProductQuoteForm> {
  // Controllers
  final TextEditingController _tyreWidthController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _preferredBrandController =
      TextEditingController();
  final TextEditingController _pcdController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _maxDistance2Controller = TextEditingController();
  final FocusNode _maxDistance2Focus = FocusNode();

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

  // Checkbox values
  bool _agreeToTerms = false;
  bool _consentToContact = false;

  // Image picker
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  Map<String, Uint8List> _imageBytes = {};

  // Loading state
  bool _isSubmitting = false;

  // Form validation state variables
  Map<String, bool> _fieldErrors = {};
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();

    _maxDistance2Controller.text = _maxDistance2.round().toString();
  }

  @override
  void dispose() {
    // Dispose controllers
    _tyreWidthController.dispose();
    _descriptionController.dispose();
    _preferredBrandController.dispose();
    _pcdController.dispose();
    _locationController.dispose();
    _maxDistance2Controller.dispose();
    // Dispose focus nodes
    _tyreWidthFocus.dispose();
    _descriptionFocus.dispose();
    _preferredBrandFocus.dispose();
    _pcdFocus.dispose();
    _locationFocus.dispose();

    super.dispose();
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
    bool? integersOnly,
    String? validationKey,
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
      hasError: _showValidationErrors && 
                validationKey != null && 
                _fieldErrors[validationKey] == true,
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
    Function(String?) onChanged, {
    String? validationKey,
  }) {
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
            borderSide: BorderSide(
              color: _showValidationErrors && 
                     validationKey != null && 
                     _fieldErrors[validationKey] == true
                  ? Colors.red
                  : Constants.ftaColorLight,
            ),
            borderRadius: BorderRadius.circular(36),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: _showValidationErrors && 
                     validationKey != null && 
                     _fieldErrors[validationKey] == true
                  ? Colors.red
                  : Constants.ctaColorLight,
            ),
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

  /// Show modern failure dialog for request submission
  Future<void> _showRequestFailureDialog(String errorMessage) async {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Failure Dialog',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Error Icon with gradient background
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Error Title
                        Text(
                          'Submission Failed',
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        // Error Message
                        Text(
                          errorMessage.isNotEmpty
                              ? errorMessage
                              : 'An error occurred while submitting your request. Please try again.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Note: Each class would need its own submit method
                                  // _submitFormDirectly(); // This would be class-specific
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Constants.ctaColorLight,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Try Again',
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
                ),
              ),
            ),
          ),
        );
      },
    );
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
      controller: _maxDistance2Controller,
      focusNode: _maxDistance2Focus,
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
                _maxDistance2Controller.text = newValue.round().toString();
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
    return Column(
      children: [
        // Product Details Section
        _buildSection('Product Details', [
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Tyre width (mm)*',
                  _tyreWidthController,
                  _tyreWidthFocus,
                  null,
                  integersOnly: true,
                  validationKey: 'tyreWidth',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Sidewall Profile*',
                  _selectedSidewallProfile,
                  ['35', '40', '45', '50', '55', '60', '65', '70', '75'],
                  (value) => setState(() => _selectedSidewallProfile = value),
                  validationKey: 'sidewallProfile',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Wheel Rim Diameter (inches)*',
                  _selectedWheelRimDiameter,
                  ['13', '14', '15', '16', '17', '18', '19', '20', '21', '22'],
                  (value) => setState(() => _selectedWheelRimDiameter = value),
                  validationKey: 'wheelRimDiameter',
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildCustomDropdown(
                  'Select Tyres/Rims*',
                  _selectedTyresRims,
                  ['Tyres', 'Rims', 'Tyres & Rims'],
                  (value) => setState(() => _selectedTyresRims = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Quantity*',
                  _selectedQuantity,
                  ['1', '2', '3', '4', '5', '6', '7', '8'],
                  (value) => setState(() => _selectedQuantity = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'How Soon Do You Need To Buy This Product?*',
                  _selectedTimeframe,
                  [
                    '1 Hour',
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
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Description Of Item',
                  _descriptionController,
                  _descriptionFocus,
                  _preferredBrandFocus,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Vehicle Type',
                  _selectedVehicleType,
                  ['Passenger Car', 'SUV', 'Truck', 'Van', 'Motorcycle', 'Bus'],
                  (value) => setState(() => _selectedVehicleType = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomTextField(
                  'Pitch Circle Diameter (PCD)',
                  _pcdController,
                  _pcdFocus,
                  null,
                  integersOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  'Preferred Brand',
                  _preferredBrandController,
                  _preferredBrandFocus,
                  null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Tyre Construction Type',
                  _selectedTyreConstruction,
                  ['Radial', 'Bias', 'Bias-Belted'],
                  (value) => setState(() => _selectedTyreConstruction = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Fitment Required',
                  _selectedFitmentRequired,
                  ['Yes', 'No'],
                  (value) => setState(() => _selectedFitmentRequired = value),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCustomDropdown(
                  'Balancing Required',
                  _selectedBalancingRequired,
                  ['Yes', 'No'],
                  (value) => setState(() => _selectedBalancingRequired = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Tyre Rotation Required',
                  _selectedTyreRotation,
                  ['Yes', 'No'],
                  (value) => setState(() => _selectedTyreRotation = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(child: _buildImageUploadSection()),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildLocationField()),
              SizedBox(width: 16),
              Expanded(
                child: _buildSliderField(
                  'Max Distance You Want to Travel (km)*',
                  _maxDistance2,
                  1,
                  1500,
                  (value) => setState(() => _maxDistance2 = value),
                ),
              ),
              SizedBox(width: 16),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ]),
        SizedBox(height: 24),

        // Checkboxes
        Container(
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
                      fontSize: 14,
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
    // Check authentication first
    if (Constants.currentUser == null && !Constants.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to submit a request'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        // Show failure dialog with error message
        await _showRequestFailureDialog(
          result['message'] ?? 'Failed to submit request. Please try again.',
        );
      }
    } catch (e) {
      // Show failure dialog with exception message
      await _showRequestFailureDialog(
        'Error submitting request: $e',
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
                SizedBox(height: 24),

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
                SizedBox(height: 16),

                // Success Message
                Text(
                  'Your tyres and rims request has been submitted successfully. Suppliers will provide you with competitive quotes soon.',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
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
                    SizedBox(width: 16),
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
    _fieldErrors.clear();
    _showValidationErrors = true;

    if (_tyreWidthController.text.trim().isEmpty) {
      errors.add('Tyre width is required');
      _fieldErrors['tyreWidth'] = true;
    }
    if (_selectedSidewallProfile == null || _selectedSidewallProfile!.isEmpty) {
      errors.add('Sidewall profile is required');
      _fieldErrors['sidewallProfile'] = true;
    }
    if (_selectedWheelRimDiameter == null ||
        _selectedWheelRimDiameter!.isEmpty) {
      errors.add('Wheel rim diameter is required');
      _fieldErrors['wheelRimDiameter'] = true;
    }
    if (_locationController.text.trim().isEmpty) {
      errors.add('Location is required');
      _fieldErrors['location'] = true;
    }
    if (_maxDistance2 < 1.0 || _maxDistance2 > 1500.0) {
      errors.add(
        'Max Distance must be between 1 km and 1500 km (National coverage).',
      );
    }

    if (errors.isNotEmpty) {
      setState(() {}); // Trigger rebuild to show red borders
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
      _maxDistance2 = 1.0;

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

class FooterSection extends StatefulWidget {
  final String logo;
  final Function(String)? onFooterLinkTap;

  const FooterSection({Key? key, required this.logo, this.onFooterLinkTap})
    : super(key: key);

  @override
  State<FooterSection> createState() => _FooterSectionState();
}

class _FooterSectionState extends State<FooterSection> {
  bool _isHoveringLogo = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      //padding: EdgeInsets.all(Breakpoints.isMobile(context)?16:50),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(color: Constants.ftaColorLight),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(Breakpoints.isMobile(context) ? 16 : 50),
            child: Column(
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringLogo = true),
                  onExit: (_) => setState(() => _isHoveringLogo = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {},
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      transform: Matrix4.identity()
                        ..scale(_isHoveringLogo ? 1.05 : 1.0),
                      child: Image.asset(widget.logo, fit: BoxFit.contain),
                    ),
                  ),
                ),

                SizedBox(height: 24),
                Wrap(
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
                    fontSize: Breakpoints.isMobile(context) ? 12 : 14,
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  children: [
                    Wrap(
                      runSpacing: 24,
                      spacing: 24,
                      children: [
                        SocialMediaButton(
                          imagePath: 'lib/assets/images/facebook.png',
                          url: 'https://www.facebook.com',
                        ),
                        SocialMediaButton(
                          imagePath: 'lib/assets/images/instagram.png',
                          url: 'https://www.instagram.com',
                        ),
                        SocialMediaButton(
                          imagePath: 'lib/assets/images/twitter.png',
                          url: 'https://www.x.com',
                        ),
                        SocialMediaButton(
                          imagePath: 'lib/assets/images/linked.png',
                          url: 'https://www.linkedin.com',
                        ),
                        SocialMediaButton(
                          imagePath: 'lib/assets/images/tik2.png',
                          url: 'https://www.tiktok.com',
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
        onPressed: widget.onFooterLinkTap != null
            ? () => widget.onFooterLinkTap!(text)
            : () {},
        child: Text(
          text,
          style: GoogleFonts.manrope(color: Colors.white.withOpacity(0.7)),
        ),
      ),
    );
  }
}

class SocialMediaButton extends StatelessWidget {
  final String imagePath;
  final String url;
  final double? size;

  const SocialMediaButton({
    Key? key,
    required this.imagePath,
    required this.url,
    this.size = 50.0,
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
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(360.0),
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class LocationPickerDialog extends StatefulWidget {
  final String apiKey;
  final LatLng initialLocation;
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerDialog({
    Key? key,
    required this.apiKey,
    required this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(-26.2041, 28.0473);
  String _selectedAddress = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  List<Prediction> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

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

  // Search for places using Google Places API
  void _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _getPlacePredictions(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching places: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // Get place predictions from Google Places API
  Future<List<Prediction>> _getPlacePredictions(String query) async {
    try {
      List<Prediction> predictions = [];

      // Try multiple search variations to get more results
      List<String> searchQueries = [
        query,
        '$query, South Africa',
        '$query, SA',
      ];

      // Try different variations if query is short
      if (query.length < 10) {
        searchQueries.addAll([
          '$query street',
          '$query road',
          '$query city',
          '$query town',
        ]);
      }

      Set<String> uniqueResults = {}; // To avoid duplicates

      for (String searchQuery in searchQueries.take(3)) {
        try {
          List<Location> locations;

          // Use web-compatible geocoding
          if (kIsWeb) {
            // Use Google Geocoding API for web
            final webResult = await _geocodeAddressWeb(searchQuery);
            if (webResult != null) {
              locations = [
                Location(
                  latitude: webResult.latitude,
                  longitude: webResult.longitude,
                  timestamp: DateTime.now(),
                ),
              ];
            } else {
              locations = [];
            }
          } else {
            // Use geocoding package for mobile
            locations = await locationFromAddress(searchQuery);
          }

          for (final location in locations.take(3)) {
            try {
              List<Placemark> placemarks = await placemarkFromCoordinates(
                location.latitude,
                location.longitude,
              );

              String description;
              if (placemarks.isNotEmpty) {
                final placemark = placemarks.first;
                description = [
                  placemark.street,
                  placemark.subLocality,
                  placemark.locality,
                  placemark.administrativeArea,
                  placemark.country,
                ].where((s) => s != null && s.isNotEmpty).join(', ');
              } else {
                description =
                    '$searchQuery (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})';
              }

              // Check for duplicates
              if (uniqueResults.add(description)) {
                predictions.add(
                  Prediction(
                    description: description.isNotEmpty
                        ? description
                        : searchQuery,
                    placeId:
                        'geocoding_${location.latitude}_${location.longitude}',
                    reference: '',
                    matchedSubstrings: [],
                    terms: [],
                    types: [],
                    structuredFormatting: null,
                  ),
                );
              }

              // Stop if we have enough predictions
              if (predictions.length >= 5) break;
            } catch (e) {
              // Add basic result even if reverse geocoding fails
              final description =
                  '$searchQuery (${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)})';
              if (uniqueResults.add(description)) {
                predictions.add(
                  Prediction(
                    description: description,
                    placeId:
                        'geocoding_${location.latitude}_${location.longitude}',
                    reference: '',
                    matchedSubstrings: [],
                    terms: [],
                    types: [],
                    structuredFormatting: null,
                  ),
                );
              }
            }
          }

          if (predictions.length >= 5) break;
        } catch (e) {
          continue; // Try next search query
        }
      }

      return predictions;
    } catch (e) {
      print('Error getting place predictions: $e');
      return [];
    }
  }

  // Handle selection of a place from the search results
  void _onPlaceSelected(Prediction prediction) async {
    if (prediction.placeId?.startsWith('geocoding_') == true) {
      final coords = prediction.placeId!
          .substring('geocoding_'.length)
          .split('_');
      if (coords.length == 2) {
        final lat = double.tryParse(coords[0]);
        final lng = double.tryParse(coords[1]);

        if (lat != null && lng != null) {
          final newLatLng = LatLng(lat, lng);

          setState(() {
            _selectedLocation = newLatLng;
            _selectedAddress = prediction.description ?? '';
            _searchResults = [];
            _searchController.text = prediction.description ?? '';
          });

          // Move the camera to the new location
          if (_mapController != null) {
            await _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: newLatLng, zoom: 16.0),
              ),
            );
          }
        }
      }
    }
  }

  // TypeAhead-specific methods for LocationPickerDialog
  Future<List<Prediction>> _getPlacePredictionsTypeAhead(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      return [];
    }

    try {
      // Use the updated API key
      const String apiKey = 'AIzaSyAegBp2UyTEJZnrmWBBPk0hU-C0bjR0cKA';
      final String encodedQuery = Uri.encodeComponent(query.trim());

      // For web platform, use JavaScript interop to avoid CORS issues
      if (kIsWeb) {
        return await _getPlacePredictionsWeb(query);
      }

      // Mobile platform - use direct API call
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
        } else if (data['status'] == 'ZERO_RESULTS') {
          return [];
        } else {
          print(
            'Places API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}',
          );
          return await _getGeocodingFallback(query);
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.body}');
        return await _getGeocodingFallback(query);
      }

      return [];
    } catch (e) {
      print('Error in _getPlacePredictionsTypeAhead: $e');
      // Fallback to geocoding if Places API fails
      return await _getGeocodingFallback(query);
    }
  }

  // Geocoding fallback for when Places API is not available
  Future<List<Prediction>> _getGeocodingFallback(String query) async {
    try {
      const String apiKey = 'AIzaSyAegBp2UyTEJZnrmWBBPk0hU-C0bjR0cKA';
      final String encodedQuery = Uri.encodeComponent(query.trim());
      final String geocodingURL =
          'https://maps.googleapis.com/maps/api/geocode/json';
      final String request =
          '$geocodingURL?address=$encodedQuery&key=$apiKey&components=country:ZA&language=en';

      final response = await http
          .get(
            Uri.parse(request),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'] != null) {
          final List<dynamic> results = data['results'];

          return results.take(5).map((result) {
            final String description = result['formatted_address'] ?? query;
            final Map<String, dynamic> geometry = result['geometry'] ?? {};
            final Map<String, dynamic> location = geometry['location'] ?? {};
            final double lat = (location['lat'] ?? 0.0).toDouble();
            final double lng = (location['lng'] ?? 0.0).toDouble();

            return Prediction(
              description: description,
              placeId: 'geocoding_${lat}_$lng',
              reference: '',
              matchedSubstrings: [],
              terms: [],
              types: (result['types'] as List?)?.cast<String>() ?? [],
              structuredFormatting: null,
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error in geocoding fallback: $e');
      return [];
    }
  }

  // Wait for Google Maps API to be available
  Future<bool> _waitForGoogleMapsAPI() async {
    // Check if already available
    if (js.context.hasProperty('getPlacePredictions') &&
        js.context.hasProperty('geocodeAddress')) {
      return true;
    }

    // Try to initialize if the function exists
    if (js.context.hasProperty('waitForGoogleMaps')) {
      final Completer<bool> completer = Completer<bool>();

      try {
        js.context.callMethod('waitForGoogleMaps', [
          js.allowInterop((bool success) {
            if (!completer.isCompleted) {
              completer.complete(success);
            }
          }),
        ]);

        // Add timeout
        Timer(Duration(seconds: 10), () {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        });

        return await completer.future;
      } catch (e) {
        print('Error waiting for Google Maps API: $e');
        return false;
      }
    }

    // Manual check with retries
    for (int i = 0; i < 20; i++) {
      await Future.delayed(Duration(milliseconds: 500));
      if (js.context.hasProperty('getPlacePredictions') &&
          js.context.hasProperty('geocodeAddress')) {
        return true;
      }
    }

    return false;
  }

  // Helper method to convert JavaScript objects to Dart Maps
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

  // Helper method to safely convert to string list
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

  // Web-specific method using JavaScript interop
  Future<List<Prediction>> _getPlacePredictionsWeb(String query) async {
    try {
      final Completer<List<Prediction>> completer =
          Completer<List<Prediction>>();

      // Wait for Google Maps API to be available with retries
      bool apiAvailable = await _waitForGoogleMapsAPI();
      if (!apiAvailable) {
        print(
          'Google Places JavaScript API not available after waiting, falling back to geocoding',
        );
        return await _getGeocodingFallbackWeb(query);
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
          print('Places API timeout, falling back to geocoding');
          completer.complete([]);
        }
      });

      final results = await completer.future;

      // If no results from Places API, try geocoding fallback
      if (results.isEmpty) {
        return await _getGeocodingFallbackWeb(query);
      }

      return results;
    } catch (e) {
      print('Error in _getPlacePredictionsWeb: $e');
      return await _getGeocodingFallbackWeb(query);
    }
  }

  // Web-specific geocoding fallback using JavaScript interop
  Future<List<Prediction>> _getGeocodingFallbackWeb(String query) async {
    try {
      final Completer<List<Prediction>> completer =
          Completer<List<Prediction>>();

      // Wait for API if not already available
      if (!js.context.hasProperty('geocodeAddress')) {
        bool apiAvailable = await _waitForGoogleMapsAPI();
        if (!apiAvailable) {
          print('Google Maps JavaScript API not available for geocoding');
          return [];
        }
      }

      // Call JavaScript geocoding function
      js.context.callMethod('geocodeAddress', [
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
                description: result['formattedAddress']?.toString() ?? query,
                placeId:
                    'geocoding_${result['latitude']}_${result['longitude']}',
                reference: '',
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
            print('Error processing geocoding results: $e');
            if (!completer.isCompleted) {
              completer.complete([]);
            }
          }
        }),
      ]);

      // Add timeout
      Timer(Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('Geocoding timeout');
          completer.complete([]);
        }
      });

      return await completer.future;
    } catch (e) {
      print('Error in _getGeocodingFallbackWeb: $e');
      return [];
    }
  }

  // Handle location selection from TypeAhead - Web compatible
  void _onPlaceSelectedTypeAhead(Prediction prediction) async {
    try {
      if (prediction.placeId?.startsWith('geocoding_') == true) {
        // Handle old geocoding format (fallback)
        final coords = prediction.placeId!
            .substring('geocoding_'.length)
            .split('_');
        if (coords.length == 2) {
          final lat = double.tryParse(coords[0]);
          final lng = double.tryParse(coords[1]);

          if (lat != null && lng != null) {
            final newLatLng = LatLng(lat, lng);
            setState(() {
              _selectedLocation = newLatLng;
              _selectedAddress = prediction.description ?? '';
              _searchController.text = prediction.description ?? '';
            });

            if (_mapController != null) {
              await _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: newLatLng, zoom: 16.0),
                ),
              );
            }
          }
        }
      } else if (prediction.placeId != null) {
        // Handle Google Places API placeId using HTTP API
        final String baseURL =
            'https://maps.googleapis.com/maps/api/place/details/json';
        final String request =
            '$baseURL?place_id=${prediction.placeId}&key=AIzaSyAegBp2UyTEJZnrmWBBPk0hU-C0bjR0cKA&fields=geometry';

        final response = await http.get(Uri.parse(request));

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
                _selectedAddress = prediction.description ?? '';
                _searchController.text = prediction.description ?? '';
              });

              if (_mapController != null) {
                await _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: newLatLng, zoom: 16.0),
                  ),
                );
              }
            }
          }
        }
      } else {
        // Fallback: just set the description
        setState(() {
          _selectedAddress = prediction.description ?? '';
          _searchController.text = prediction.description ?? '';
        });
      }
    } catch (e) {
      print('Error in _onPlaceSelectedTypeAhead: $e');
      // Fallback: just set the description
      setState(() {
        _selectedAddress = prediction.description ?? '';
        _searchController.text = prediction.description ?? '';
      });
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
              padding: EdgeInsets.fromLTRB(20, 20, 12, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey[700],
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Select Location',
                    style: GoogleFonts.manrope(
                      color: Colors.grey[800],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: EdgeInsets.all(8),
                      minimumSize: Size(36, 36),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar with autocomplete
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TypeAheadField<Prediction>(
                    controller: _searchController,
                    focusNode: searchFocusNode,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for a location...',
                          hintStyle: GoogleFonts.manrope(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.grey[600]!,
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.search_outlined,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    controller.clear();
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                    suggestionsCallback: (pattern) async {
                      if (pattern.length < 3) return [];
                      return await _getPlacePredictionsTypeAhead(pattern);
                    },
                    itemBuilder: (context, suggestion) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: Colors.grey[500],
                              size: 18,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    suggestion.structuredFormatting?.mainText ??
                                        suggestion.description
                                            ?.split(',')
                                            .first ??
                                        '',
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (suggestion
                                          .structuredFormatting
                                          ?.secondaryText !=
                                      null) ...[
                                    SizedBox(height: 2),
                                    Text(
                                      suggestion
                                          .structuredFormatting!
                                          .secondaryText!,
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ] else ...[
                                    SizedBox(height: 2),
                                    Text(
                                      suggestion.description
                                              ?.split(',')
                                              .skip(1)
                                              .join(', ') ??
                                          '',
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
                    onSelected: (suggestion) {
                      _onPlaceSelectedTypeAhead(suggestion);
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
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    offset: Offset(0, 4),
                    constraints: BoxConstraints(maxHeight: 280),
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
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
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
                          Icon(
                            Icons.search_off,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
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
                ],
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
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[200]!),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final address = _selectedAddress.isNotEmpty
                          ? _selectedAddress
                          : 'Location: ${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}';
                      widget.onLocationSelected(_selectedLocation, address);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Select Location',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
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
    Widget? suffixIcon, {
    bool? integersOnly,
  }) {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.next,
      isPasswordField: false,
      integersOnly: integersOnly,
      suffix: suffixIcon,
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          _searchPlaces(value);
        }
      },
      onChanged: (value) {
        setState(() {}); // To show/hide clear button

        // Trigger search after user stops typing
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(Duration(milliseconds: 500), () {
          if (value.isNotEmpty) {
            _searchPlaces(value);
          } else {
            setState(() {
              _searchResults = [];
            });
          }
        });
      },
    );
  }

  // Web-specific geocoding method using Google Geocoding API
  Future<LatLng?> _geocodeAddressWeb(String address) async {
    if (!kIsWeb || address.isEmpty) return null;

    try {
      final String apiKey = 'AIzaSyAegBp2UyWBBPk0hU-C0bjR0cKA';
      final String encodedAddress = Uri.encodeComponent(address);
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("gffgfgfg ${data}");

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final double lat = location['lat']?.toDouble() ?? 0.0;
          final double lng = location['lng']?.toDouble() ?? 0.0;

          if (lat != 0.0 || lng != 0.0) {
            return LatLng(lat, lng);
          }
        }
      }
    } catch (e) {
      print('Web geocoding error in LocationPickerDialog: $e');
    }

    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
}
