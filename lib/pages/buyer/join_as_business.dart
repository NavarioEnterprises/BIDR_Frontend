import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import '../../customWdget/appbar.dart';
import '../buyer_home.dart';

import 'package:google_fonts/google_fonts.dart';

class BusinessLandingPage extends StatefulWidget {
  @override
  _BusinessLandingPageState createState() => _BusinessLandingPageState();
}

class _BusinessLandingPageState extends State<BusinessLandingPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _headerAnimationController;
  late AnimationController _benefitsAnimationController;
  late AnimationController _descriptionAnimationController;
  late AnimationController _buttonAnimationController;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _benefitsFadeAnimation;
  late Animation<Offset> _benefitsSlideAnimation;
  late Animation<double> _descriptionFadeAnimation;
  late Animation<Offset> _descriptionSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _headerVisible = false;
  bool _benefitsVisible = false;
  bool _descriptionVisible = false;
  bool _buttonVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize animation controllers
    _headerAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _benefitsAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _descriptionAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut));

    _benefitsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _benefitsAnimationController, curve: Curves.easeOut),
    );
    _benefitsSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _benefitsAnimationController, curve: Curves.easeOut));

    _descriptionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _descriptionAnimationController, curve: Curves.easeOut),
    );
    _descriptionSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _descriptionAnimationController, curve: Curves.easeOut));

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeOut),
    );
    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.elasticOut),
    );

    _scrollController.addListener(_onScroll);

    // Start header animation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerAnimationController.forward();
      _benefitsAnimationController.forward();
      setState(() {
        _headerVisible = true;
        _benefitsVisible = true;
      });
    });
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;

    // Trigger description animation
    if (scrollOffset > 300 && !_descriptionVisible) {
      _descriptionAnimationController.forward();
      setState(() {
        _descriptionVisible = true;
      });
    }

    // Trigger button animation
    if (scrollOffset > 600 && !_buttonVisible) {
      _buttonAnimationController.forward();
      setState(() {
        _buttonVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    _benefitsAnimationController.dispose();
    _descriptionAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24),
            child: HeaderSection(),
          ),
          SizedBox(height: 24),
          Container(
            height: 60,
            width: MediaQuery.of(context).size.width,
            color: Constants.ctaColorLight,
            padding: EdgeInsets.only(left: 50, right: 50, top: 8, bottom: 8),
            child: Row(
              children: [
                TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                    setState(() {

                    });
                  },
                  child: Text(
                    'Home',
                    style: GoogleFonts.manrope(color: Colors.white, fontSize: 16),
                  ),
                ),
                Text(
                  ' > Why Join as a Business?',
                  style: GoogleFonts.manrope(color: Constants.ftaColorLight, fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Animated header section
                  SlideTransition(
                    position: _headerSlideAnimation,
                    child: FadeTransition(
                      opacity: _headerFadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 68, right: 68),
                        child: Center(
                          child: Container(
                            height: 400,
                            constraints: BoxConstraints(maxWidth: 1600),

                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left side - Illustration with animation
                                Expanded(
                                  child: TweenAnimationBuilder<double>(
                                    duration: Duration(milliseconds: 1200),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: 0.8 + (0.2 * value),
                                        child: Opacity(
                                          opacity: value,
                                          child: Image.asset(
                                            "lib/assets/images/business.png",
                                            fit: BoxFit.contain,
                                            width: MediaQuery.of(context).size.width,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 24),
                                // Right side - Benefits with staggered animation
                                Expanded(
                                  flex: 1,
                                  child: SlideTransition(
                                    position: _benefitsSlideAnimation,
                                    child: FadeTransition(
                                      opacity: _benefitsFadeAnimation,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AnimatedBenefitCard(
                                            title: 'Competitive Edge',
                                            description: 'Stand Out By Providing The Best Quotes And Winning More Deals.',
                                            icon: Icons.emoji_events,
                                            color: Colors.orange,
                                            delay: Duration(milliseconds: 0),
                                          ),
                                          SizedBox(height: 15),
                                          AnimatedBenefitCard(
                                            title: 'Seamless Communication',
                                            description: 'Chat Directly With Buyers To Clarify Requirements And Finalize Deals.',
                                            icon: Icons.chat_bubble_outline,
                                            color: Colors.blue,
                                            delay: Duration(milliseconds: 200),
                                          ),
                                          SizedBox(height: 15),
                                          AnimatedBenefitCard(
                                            title: 'Trust & Credibility',
                                            description: 'Build Your Reputation Through Ratings, Reviews, And Successful Transactions.',
                                            icon: Icons.verified_user,
                                            color: Colors.green,
                                            delay: Duration(milliseconds: 400),
                                          ),
                                        ],
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
                  ),
                  SizedBox(height: 24),

                  // Animated description section
                  SlideTransition(
                    position: _descriptionSlideAnimation,
                    child: FadeTransition(
                      opacity: _descriptionFadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 0, right: 0),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(24),
                            constraints: BoxConstraints(maxWidth: 1400),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedTextBlock(
                                  text: 'Lead Generation Is Becoming A Tougher Task These Days. Several Companies Offer Similar Goods And Buyers Are Pressed To Go Out And Source The Best Deals For Themselves. Online Sales Are Now A Necessity. B2OR Provides You A New Channel To Corner New Leads As Well As Offer A Simple And Safe Online Sales Platform. All In All - It\'s A Much More Convenient System With A Better Customer Convenience And Value Proposition.',
                                  delay: Duration(milliseconds: 0),
                                ),
                                SizedBox(height: 20),
                                AnimatedTextBlock(
                                  text: 'Businesses Are Charged An Annual Registration Fee To Use The Platform And A Small Percentage For The Processing Of The Transaction. We Do Not Bill The Client Anything About The Price That You Quote. All Transactions Are Transparent, And Our Financial System Utilises Industry Standard E-Commerce Best Practices Safety.',
                                  delay: Duration(milliseconds: 200),
                                ),
                                SizedBox(height: 20),
                                AnimatedTextBlock(
                                  text: 'Essentially, Our Platform Allows You To Easily Interact With Clients That Do Not Have To Take Up Your Time On The Phone Or Walking-In To Your Counter. In Fact, Our Solution Is Ideal For Store Less Businesses. Registered Sellers Will Be Automatically Notified When Applicable Request Are Made. Our Process Also Allows You To Connect With Buyers Who Are Currently On The Market For Your Goods, Hence You Get The Most Relevant Business Information. You Can Then Tender A Bid For Their Consideration. At The Same Time Other Sellers In The Area Will Also Tender Their Bids For The Same Request. Participating Sellers For That Specific Request, Will Be Informed Of The Best Deal Offered And Will Have The Opportunity Of Re-Tendering With A Better Price Or An Alternate Item. We Do Not Force Sellers To Re-Tender. Re-Tendering Is At The Discretion Of The Seller, Who May Opt Not To Do So. If The Buyer Accepts Your Bid, Then You Will Be Immediately Billed, And The Money Will Be Held In Escrow Until The Goods Are Physically Received Over To The Buyer. Once This Process Is Successfully Completed, The Funds Will Be Immediately Released To You.',
                                  delay: Duration(milliseconds: 400),
                                ),
                                SizedBox(height: 20),
                                AnimatedTextBlock(
                                  text: 'Our Solution Has The Potential Of Bringing You New Customers That May Not Have Known Of Your Company, Allows You To Be More Competitively Priced And To Corner Market Trends In The Geographic And Product Sectors That You Service. We Hope To Increase Your Competitiveness As Well As Turnover.',
                                  delay: Duration(milliseconds: 600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Animated call to action button
                  ScaleTransition(
                    scale: _buttonScaleAnimation,
                    child: FadeTransition(
                      opacity: _buttonFadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24, right: 24),
                        child: Center(
                          child: Container(
                            height: 45,
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: ElevatedButton(
                              onPressed: () {
                                print('Join as a Business pressed');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Constants.ctaColorLight,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(360),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'Join as a Business',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class AnimatedBenefitCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Duration delay;

  const AnimatedBenefitCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: BenefitCard(
              title: title,
              description: description,
              icon: icon,
              color: color,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedTextBlock extends StatelessWidget {
  final String text;
  final Duration delay;

  const AnimatedTextBlock({
    required this.text,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.black,
                height: 1.6,
              ),
            ),
          ),
        );
      },
    );
  }
}

class BenefitCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const BenefitCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Constants class (add this if not already defined)