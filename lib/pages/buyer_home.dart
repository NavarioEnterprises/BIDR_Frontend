import 'dart:io';
import 'dart:typed_data';
import 'package:bidr/pages/seller/seller_home_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';

import '../authentication/forgot_password.dart';
import '../constants/Constants.dart';
import '../customWdget/appbar.dart';
import '../customWdget/customCard.dart';
import '../customWdget/custom_input2.dart';
import '../services/api_service.dart';
import '../notifier/my_notifier.dart';
import 'buyer_dashboard.dart';
import 'buyer/blog.dart';
import 'buyer/contact_form.dart';
import 'buyer/join_as_business.dart';
import 'buyer/join_as_buyer.dart';
import 'buyer/support.dart';
import 'buyer/video.dart';
import 'faq_screen.dart';
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

class _BuyerHomePageState extends State<BuyerHomePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  int selectedIndex = -1;
  int index = 0;

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
    buyerHomeValueNotifier.addListener(() {
      setState(() {});
    });
    sellerHomeValueNotifier.addListener(() {
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
    {"icon": "lib/assets/images/spares1.png", "name": "Vehicle\nSpares"},
    {"icon": "lib/assets/images/rims.png", "name": "Vehicle Tyres\nand Rims"},
    {
      "icon": "lib/assets/images/consumer.png",
      "name": "Consumer \nElectronics",
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
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 1600),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: 24),

                                  // Animated Banner Section
                                  ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 64,
                                        right: 64,
                                      ),
                                      child: Center(
                                        child: _buildAnimatedBannerSection(
                                          "lib/assets/images/competitive.png",
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 24),

                                  // Animated Category Section
                                  Center(
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: FadeTransition(
                                        opacity: _categoryAnimation,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 64,
                                            right: 64,
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
                                                left: 64,
                                                right: 64,
                                              ),
                                              child: VehicleDetailsQuoteForm(),
                                            )
                                          : selectedIndex == 1
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                left: 64,
                                                right: 64,
                                              ),
                                              child: ProductQuoteForm(),
                                            )
                                          : selectedIndex == 2
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                left: 64,
                                                right: 64,
                                              ),
                                              child: TireProductQuoteForm(),
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

                            SizedBox(height: 24),

                            // Animated Bottom Banner
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: 1600),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 64,
                                    right: 64,
                                  ),
                                  child: Center(
                                    child: _buildAnimatedBannerSection(
                                      "lib/assets/images/mask_group.png",
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 24),

                            // Animated Footer
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0, 1),
                                end: Offset.zero,
                              ).animate(_slideController),
                              child: Center(
                                child: FooterSection(
                                  logo: "lib/assets/images/bidr_logo2.png",
                                  onFooterLinkTap: (String text) {
                                    switch (text) {
                                      case 'Home':
                                        setState(() {
                                          Constants.buyerAppBarValue = 0;
                                          buyerHomeValueNotifier.value++;
                                        });
                                        break;
                                      case 'Support':
                                        setState(() {
                                          Constants.buyerAppBarValue = 1;
                                          buyerHomeValueNotifier.value++;
                                        });
                                        break;
                                      case 'FAQs':
                                        setState(() {
                                          Constants.buyerAppBarValue = 2;
                                          buyerHomeValueNotifier.value++;
                                        });
                                        break;
                                      case 'Policies':
                                        setState(() {
                                          Constants.buyerAppBarValue = 3;
                                          buyerHomeValueNotifier.value++;
                                        });
                                        break;
                                      case 'Blogs':
                                        setState(() {
                                          Constants.buyerAppBarValue = 4;
                                          buyerHomeValueNotifier.value++;
                                        });
                                        break;
                                      case 'Contact Us':
                                        setState(() {
                                          Constants.buyerAppBarValue = 5;
                                          buyerHomeValueNotifier.value++;
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
                ? Expanded(child: BuyerDashboardScreen())
                : Constants.buyerAppBarValue == 7
                ? Expanded(child: SellerDashboard())
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

  Widget _buildAboutUsSection() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: 200,
                color: Colors.white,
              ),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 300,
                color: Constants.ftaColorLight,
              ),
            ],
          ),
          Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 1600),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedVideoSection(
                    "About Us",
                    "Created in 2024, BIDR™ is South Africa's newest e-commerce platform. Our unique buyer centric service makes searching for the best price for common goods easy. Headquartered in Johannesburg, we currently serve all of SA.BIDR was born out of its founders' frustrations of always trying to source the best deals for commonly required items such as vehicle tyres or spares, expensive mobile bills, and countless hours trying to negotiate with sellers to get the best deals.We have now taken our expertise and automated the process for you. Why not consider registering as a buyer or seller (as the case may be) and see how our system can save you time, money and stress.",
                    "Why Join As A Buyer?",
                    0,
                  ),
                  SizedBox(width: 16),
                  _buildAnimatedVideoSection(
                    "How It Works",
                    "Unlike catalogue-based online shops, BIDR allows buyers to send out a single request to multiple sellers that are registered on our platform.The buyer simply specifies the area to search and all sellers within that area are notified of therequest. If the seller has the product (or similar products), they will make an offer. The sellers are continuously updated of the current market price offered by other sellers in the area, and should they opt to do so, they will have the opportunity of revising their bid with a best and final offer. No more long repetitive phone calls, waiting in queues, or countless hours browsing for special deals. With BIDR the sellers come to you with their best price.",
                    "Why Join As A Business?",
                    1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                                          'https://videocdn.cdnpk.net/videos/83f87a00-c832-4e39-811f-df9ddde83898/horizontal/previews/clear/large.mp4?token=exp=1755697238~hmac=5202134e7d9eb8da3a24a10b5798bab437686787321e18dc3b710fc8aa4b6199',
                                      autoPlay: false,
                                      looping: true,
                                      placeholder: 'Loading awesome video...',
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: CustomVideoPlayerWidget(
                                      videoUrl:
                                          'https://videocdn.cdnpk.net/videos/1023b72a-f207-5513-9046-9e86aff44a23/horizontal/previews/clear/large.mp4?token=exp=1755697314~hmac=f8602bae3e1a7957fdf7bb67f723a230d3802e4d3542b8518e0d673fc34175d3',
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
                                          'https://videocdn.cdnpk.net/videos/45d47465-c3a1-54ef-aa83-466722d851ad/horizontal/previews/clear/large.mp4?token=exp=1755697358~hmac=426a8baec13e32ba767cbd9a89368f19f1af446166d941db9ac11d5662dc61f1',
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
                    height: 65,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Constants.ftaColorLight,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        AnimatedContainer(
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
                            icon: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
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
              height: 400,
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
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Text(
                  'Please click on one of the categories to begin',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),
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
                            (MediaQuery.of(context).size.width - 48 - 48) / 6.8,
                        child: _categoryCard(
                          category["icon"]!,
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
                  border: Border.all(
                    color: isSelected
                        ? Constants.ftaColorLight
                        : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Constants.ftaColorLight.withOpacity(0.1),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: AnimatedScale(
                  scale: isSelected ? 0.91 : 0.8,
                  duration: Duration(milliseconds: 200),
                  child: Image.asset(iconImage, fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 16),
              AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: GoogleFonts.manrope(
                  color: isSelected
                      ? Constants.ftaColorLight
                      : Constants.ftaColorLight.withOpacity(0.85),
                  fontSize: isSelected ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
                child: Text(name),
              ),
            ],
          ),
        ),
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
  static const String _googleMapsApiKey = 'AIzaSyAKFP-Mf1TQ1z2o8vEBjx2P-_5SwB0lA-k';

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
  double _maxDistance = 50.0;

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

  @override
  void initState() {
    super.initState();
    // Set initial values
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

    // Dispose focus nodes
    _vinFocus.dispose();
    _partNameFocus.dispose();
    _locationFocus.dispose();
    _descriptionFocus.dispose();
    _partNumberFocus.dispose();
    _mileageFocus.dispose();

    super.dispose();
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            hintText,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        SizedBox(height: 8),
        CustomInputTransparent4(
          hintText: hintText,
          controller: controller,
          focusNode: focusNode,
          textInputAction: nextFocusNode != null
              ? TextInputAction.next
              : TextInputAction.done,
          isPasswordField: false,
          suffix: suffixIcon,
          onChanged: (value) {},
          onSubmitted: (value) {
            if (nextFocusNode != null) {
              nextFocusNode.requestFocus();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(360),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              menuMaxHeight: 200,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              value: value,
              hint: Text(
                label,
                style: GoogleFonts.manrope(
                  color: Colors.black,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Enter Range',
                    style: GoogleFonts.manrope(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${value.round()} km',
                    style: GoogleFonts.manrope(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Constants.ctaColorLight,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Constants.ftaColorLight,
                  overlayColor: Constants.ctaColorLight.withOpacity(0.2),
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Upload Images Of The Product You Require',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),

        SizedBox(height: 8),
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 180,
          child: GestureDetector(
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
                              border: Border.all(
                                color: Constants.ctaColorLight,
                              ),
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
                child: _buildCustomDropdown(
                  'Manufacturer*',
                  _selectedManufacturer,
                  [
                    'Select Manufacturer',
                    'Toyota',
                    'Honda',
                    'Ford',
                    'BMW',
                    'Mercedes',
                    'Audi',
                    'Volkswagen',
                  ],
                  (value) => setState(() => _selectedManufacturer = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Makes & Models*',
                  _selectedMakeModel,
                  [
                    'Select Makes & Models',
                    'Corolla',
                    'Camry',
                    'Civic',
                    'Accord',
                    'Focus',
                    'Mustang',
                  ],
                  (value) => setState(() => _selectedMakeModel = value),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
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
        SizedBox(height: 20),

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
              Expanded(
                child: _buildLocationField(),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
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
              SizedBox(width: 16),
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
              SizedBox(width: 16),
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
          SizedBox(height: 16),
          _buildImageUploadSection(),
        ]),
        SizedBox(height: 20),

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
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
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
              Expanded(child: Container()), // Empty space for alignment
            ],
          ),
        ]),
        SizedBox(height: 20),

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

  void _submitForm() async {
    // Basic validation
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get JWT token first
      final token = await ApiService.getJWTToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to authenticate. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await ApiService.submitVehicleRequest(
        accessToken: token,
        selectedManufacturer: _selectedManufacturer,
        selectedMakeModel: _selectedMakeModel,
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

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle quote request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form after successful submission
        _resetForm();
        
        // Navigate to dashboard
        if (mounted) {
          context.go('/dashboard');
        }
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
        setState(() {
          _vinImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking VIN images: $e')));
    }
  }

  void _removeVinImage(XFile image) {
    setState(() {
      _vinImages.remove(image);
      _vinImageBytes.remove(image.path);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'Your Location*',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _showLocationPicker,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: TextField(
              controller: _locationController,
              focusNode: _locationFocus,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Tap to select location',
                hintStyle: GoogleFonts.manrope(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ),
      ],
    );
  }

  Widget _buildVinField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            'VIN (Vehicle Identification Number)*',
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickVinImages,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: TextField(
              controller: _vinController,
              focusNode: _vinFocus,
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Click to upload images or use upload button',
                hintStyle: GoogleFonts.manrope(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: _vinImages.isNotEmpty
                    ? Container(
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
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
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
                              onTap: _showVinImages,
                              child: Icon(
                                Icons.visibility,
                                color: Colors.green.shade700,
                                size: 16,
                              ),
                            ),
                          ],
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
          ),
        ),
      ],
    );
  }

  Widget _buildVinImageField(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
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
                                    child: Image.network(
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
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VIN Images (${_vinImages.length})',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  height: 300,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _vinImages.length,
                    itemBuilder: (context, index) {
                      final image = _vinImages[index];
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                image.path,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.image,
                                      color: Colors.grey[400],
                                      size: 40,
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
                              onTap: () {
                                _removeVinImage(image);
                                if (_vinImages.isEmpty) {
                                  Navigator.of(context).pop();
                                }
                                setState(() {});
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delete,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pickVinImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Add More Images',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
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

  // Focus Nodes
  final FocusNode _typeFocus = FocusNode();
  final FocusNode _brandFocus = FocusNode();
  final FocusNode _modelFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();
  final FocusNode _minPriceFocus = FocusNode();
  final FocusNode _maxPriceFocus = FocusNode();
  final FocusNode _featuresFocus = FocusNode();
  final FocusNode _commentsFocus = FocusNode();

  // Dropdown values
  String? _selectedTimeframe = 'Within a week';
  String? _selectedInstallation = 'Yes';
  String? _selectedCondition = 'New / Refurbished';
  String? _selectedPurpose = 'Home Use';

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

    // Dispose focus nodes
    _typeFocus.dispose();
    _brandFocus.dispose();
    _modelFocus.dispose();
    _quantityFocus.dispose();
    _minPriceFocus.dispose();
    _maxPriceFocus.dispose();
    _featuresFocus.dispose();
    _commentsFocus.dispose();

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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            hintText,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        SizedBox(height: 8),
        CustomInputTransparent4(
          hintText: hintText,
          controller: controller,
          focusNode: focusNode,
          textInputAction: nextFocusNode != null
              ? TextInputAction.next
              : TextInputAction.done,
          isPasswordField: false,
          suffix: suffixIcon,
          onChanged: (value) {},
          onSubmitted: (value) {
            if (nextFocusNode != null) {
              nextFocusNode.requestFocus();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(360),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              menuMaxHeight: 200,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              value: value,
              hint: Text(
                label,
                style: GoogleFonts.manrope(
                  color: Colors.black,
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
      ],
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
          SizedBox(height: 16),
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
                ),
              ),
            ],
          ),
        ]),
        SizedBox(height: 20),

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
                ),
              ),
              SizedBox(width: 16),
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
          SizedBox(height: 16),
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
        SizedBox(height: 20),

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
          SizedBox(height: 16),
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
          SizedBox(height: 16),
          _buildImageUploadSection(),
          SizedBox(height: 16),
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
        SizedBox(height: 20),

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
      // Get JWT token first
      final token = await ApiService.getJWTToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to authenticate. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await ApiService.submitElectronicsRequest(
        accessToken: token,
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
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Electronics request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form after successful submission
        _resetElectronicsForm();
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

  bool _validateElectronicsForm() {
    List<String> errors = [];

    if (_typeController.text.trim().isEmpty) {
      errors.add('Electronics type is required');
    }
    if (_quantityController.text.trim().isEmpty) {
      errors.add('Quantity is required');
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
    });
  }
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

  // Focus Nodes
  final FocusNode _tyreWidthFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _preferredBrandFocus = FocusNode();
  final FocusNode _pcdFocus = FocusNode();

  // Dropdown values
  String? _selectedSidewallProfile = '55';
  String? _selectedWheelRimDiameter = '16';
  String? _selectedTyresRims = 'Tyres';
  String? _selectedQuantity = '1';
  String? _selectedTimeframe = '12 Hours';
  String? _selectedVehicleType = 'Passenger Car';
  String? _selectedTyreConstruction = 'Radial';
  String? _selectedFitmentRequired = 'Yes';
  String? _selectedBalancingRequired = 'Yes';
  String? _selectedTyreRotation = 'No';

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
  }

  @override
  void dispose() {
    // Dispose controllers
    _tyreWidthController.dispose();
    _descriptionController.dispose();
    _preferredBrandController.dispose();
    _pcdController.dispose();

    // Dispose focus nodes
    _tyreWidthFocus.dispose();
    _descriptionFocus.dispose();
    _preferredBrandFocus.dispose();
    _pcdFocus.dispose();

    super.dispose();
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            hintText,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        SizedBox(height: 8),
        CustomInputTransparent4(
          hintText: hintText,
          controller: controller,
          focusNode: focusNode,
          textInputAction: nextFocusNode != null
              ? TextInputAction.next
              : TextInputAction.done,
          isPasswordField: false,
          suffix: suffixIcon,
          onChanged: (value) {},
          onSubmitted: (value) {
            if (nextFocusNode != null) {
              nextFocusNode.requestFocus();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCustomDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(360),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              menuMaxHeight: 200,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              value: value,
              hint: Text(
                label,
                style: GoogleFonts.manrope(
                  color: Colors.black,
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
      ],
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
                  'Tyre width (mm)*',
                  _tyreWidthController,
                  _tyreWidthFocus,
                  null,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Sidewall Profile*',
                  _selectedSidewallProfile,
                  ['35', '40', '45', '50', '55', '60', '65', '70', '75'],
                  (value) => setState(() => _selectedSidewallProfile = value),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCustomDropdown(
                  'Wheel Rim Diameter (inches)*',
                  _selectedWheelRimDiameter,
                  ['13', '14', '15', '16', '17', '18', '19', '20', '21', '22'],
                  (value) => setState(() => _selectedWheelRimDiameter = value),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
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
        SizedBox(height: 20),

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
        ]),
        SizedBox(height: 20),

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
    // Basic validation
    if (!_validateTyresRimsForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get JWT token first
      final token = await ApiService.getJWTToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to authenticate. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await ApiService.submitTyresRimsRequest(
        accessToken: token,
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
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tyres/Rims request submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form after successful submission
        _resetTyresRimsForm();
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

  bool _validateTyresRimsForm() {
    List<String> errors = [];

    if (_tyreWidthController.text.trim().isEmpty) {
      errors.add('Tyre width is required');
    }
    if (_selectedSidewallProfile == null || _selectedSidewallProfile!.isEmpty) {
      errors.add('Sidewall profile is required');
    }
    if (_selectedWheelRimDiameter == null || _selectedWheelRimDiameter!.isEmpty) {
      errors.add('Wheel rim diameter is required');
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
}

class FooterSection extends StatelessWidget {
  final String logo;
  final Function(String)? onFooterLinkTap;

  const FooterSection({Key? key, required this.logo, this.onFooterLinkTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(50),
      decoration: BoxDecoration(color: Constants.ftaColorLight),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(30),
            child: Column(
              children: [
                Image.asset(logo, fit: BoxFit.contain),
                SizedBox(height: 24),
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

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  void _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
    });
    
    // Get address from coordinates (reverse geocoding)
    // You can add geocoding package functionality here
    _selectedAddress = 'Selected Location: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Location',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Container(
              padding: EdgeInsets.all(16),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: _searchController,
                googleAPIKey: widget.apiKey,
                inputDecoration: InputDecoration(
                  hintText: 'Search for a location...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.search),
                ),
                debounceTime: 800,
                getPlaceDetailWithLatLng: (placeDetails) {
                  // Handle the response for place details with coordinates
                  // This will be called when a place is selected
                },
                itemClick: (prediction) {
                  _searchController.text = prediction.description ?? '';
                  // You can add logic here to get the coordinates for this prediction
                  setState(() {
                    _selectedAddress = prediction.description ?? '';
                  });
                },
              ),
            ),
            
            // Map
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
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
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                    ),
                  },
                ),
              ),
            ),
            
            // Selected location info
            if (_selectedAddress.isNotEmpty)
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  _selectedAddress,
                  style: GoogleFonts.manrope(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Action buttons
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black,
                    ),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final address = _selectedAddress.isNotEmpty 
                          ? _selectedAddress 
                          : 'Selected Location: ${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}';
                      widget.onLocationSelected(_selectedLocation, address);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2C3E50),
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Select Location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
