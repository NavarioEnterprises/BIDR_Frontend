import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../authentication/login.dart';
import '../../../constants/Constants.dart';

class MobileBusinessLandingPage extends StatefulWidget {
  @override
  _MobileBusinessLandingPageState createState() => _MobileBusinessLandingPageState();
}

class _MobileBusinessLandingPageState extends State<MobileBusinessLandingPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _heroAnimationController;
  late AnimationController _benefitsAnimationController;
  late AnimationController _contentAnimationController;

  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _benefitsFadeAnimation;
  late Animation<Offset> _benefitsSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  bool _heroVisible = false;
  bool _benefitsVisible = false;
  bool _contentVisible = false;
  double _titleOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize animation controllers
    _heroAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _benefitsAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _contentAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut),
    );
    _heroSlideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _heroAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _benefitsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _benefitsAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _benefitsSlideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _benefitsAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _contentSlideAnimation =
        Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _contentAnimationController,
            curve: Curves.easeOut,
          ),
        );

    _scrollController.addListener(_onScroll);

    // Start animations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroAnimationController.forward();
      setState(() {
        _heroVisible = true;
      });

      // Start benefits animation after hero
      Future.delayed(Duration(milliseconds: 400), () {
        _benefitsAnimationController.forward();
        setState(() {
          _benefitsVisible = true;
        });
      });
    });
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;

    // Update title opacity based on scroll position
    double newOpacity;
    if (scrollOffset <= 0) {
      newOpacity = 1.0;
    } else if (scrollOffset >= 200) {
      newOpacity = 0.0;
    } else {
      newOpacity = 1.0 - (scrollOffset / 200);
    }

    if (_titleOpacity != newOpacity) {
      setState(() {
        _titleOpacity = newOpacity;
      });
    }

    // Trigger content animation
    if (scrollOffset > 200 && !_contentVisible) {
      _contentAnimationController.forward();
      setState(() {
        _contentVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAnimationController.dispose();
    _benefitsAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading:IconButton(
          onPressed:(){
            Navigator.pop(context);
            setState(() {

            });
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Constants.ftaColorLight,
            elevation: 5,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(
            CupertinoIcons.back,
            color: Constants.ftaColorLight,
          ),
        ),
        title: Opacity(
          opacity: _titleOpacity,
          child: Text(
            'Why Join As A Business',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [
                Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            // Hero Section with Gradient Background
            Stack(
              children: [
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.7, -0.3), // Right 30% position
                      radius: 0.3,
                      colors: [
                        Color(0x451B3B5C),
                        Colors.transparent, // Fade to transparent
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: SlideTransition(
                      position: _heroSlideAnimation,
                      child: FadeTransition(
                        opacity: _heroFadeAnimation,
                        child: _buildMobileHeroSection(),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.7, 0.3), // Right 30% position
                      radius: 0.8,
                      colors: [
                        Color(0x45E8B366),
                        Colors.transparent, // Fade to transparent
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: SlideTransition(
                      position: _heroSlideAnimation,
                      child: FadeTransition(
                        opacity: _heroFadeAnimation,
                        child: _buildMobileHeroSection(),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Benefits and Content Sections (same animation)
            SlideTransition(
              position: _benefitsSlideAnimation,
              child: FadeTransition(
                opacity: _benefitsFadeAnimation,
                child: Column(
                  children: [
                    _buildMobileBenefitsSection(),
                    SizedBox(height: 20),
                    _buildMobileContentSection(),
                    SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.height * 0.5,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        LoginPage(),
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
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Join as a Business',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHeroSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
      child: Column(
        children: [
          // Hero Image
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1200),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.9 + (0.1 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    height: 260,
                    width: double.infinity,
                    child: Image.asset(
                      "lib/assets/images/business.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBenefitsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 16),
          _buildMobileBenefitCard(
            title: 'Competitive Edge',
            description:
                'Stand Out By Providing The Best Quotes And Winning More Deals.',
            icon: Icons.emoji_events,
            delay: Duration(milliseconds: 0),
          ),
          SizedBox(height: 16),
          _buildMobileBenefitCard(
            title: 'Seamless Communication',
            description:
                'Chat Directly With Buyers To Clarify Requirements And Finalize Deals.',
            icon: Icons.chat_bubble_outline,
            delay: Duration(milliseconds: 200),
          ),
          SizedBox(height: 16),
          _buildMobileBenefitCard(
            title: 'Trust & Credibility',
            description:
                'Build Your Reputation Through Ratings, Reviews, And Successful Transactions.',
            icon: Icons.verified_user,
            delay: Duration(milliseconds: 400),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBenefitCard({
    required String title,
    required String description,
    required IconData icon,
    required Duration delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                //  color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Constants.ctaColorLight, size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B3B5C),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          description,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.4,
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

  Widget _buildMobileContentSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          border: Border(
            top: BorderSide(color: Constants.ctaColorLight, width: 8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildMobileContentParagraph(
              text:
                  "Lead Generation Is Becoming A Tougher Task These Days. Several Companies Offer Similar Goods And Buyers Are Pressed To Go Out And Source The Best Deals For Themselves. Online Sales Are Now A Necessity. B2OR Provides You A New Channel To Corner New Leads As Well As Offer A Simple And Safe Online Sales Platform.",
              delay: Duration(milliseconds: 0),
            ),
            SizedBox(height: 12),
            _buildMobileContentParagraph(
              text:
                  "Businesses Are Charged An Annual Registration Fee To Use The Platform And A Small Percentage For The Processing Of The Transaction. We Do Not Bill The Client Anything About The Price That You Quote. All Transactions Are Transparent, And Our Financial System Utilises Industry Standard E-Commerce Best Practices Safety.",
              delay: Duration(milliseconds: 200),
            ),
            SizedBox(height: 12),
            _buildMobileContentParagraph(
              text:
                  "Our Platform Allows You To Easily Interact With Clients That Do Not Have To Take Up Your Time On The Phone Or Walking-In To Your Counter. Registered Sellers Will Be Automatically Notified When Applicable Request Are Made. You Can Then Tender A Bid For Their Consideration.",
              delay: Duration(milliseconds: 400),
            ),
            SizedBox(height: 12),
            _buildMobileContentParagraph(
              text:
                  "Our Solution Has The Potential Of Bringing You New Customers That May Not Have Known Of Your Company, Allows You To Be More Competitively Priced And To Corner Market Trends In The Geographic And Product Sectors That You Service.",
              delay: Duration(milliseconds: 600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileContentParagraph({
    required String text,
    required Duration delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                text,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
        );
      },
    );
  }
}