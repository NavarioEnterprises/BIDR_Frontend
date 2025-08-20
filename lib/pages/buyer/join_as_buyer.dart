
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

import '../../constants/Constants.dart';
import '../../customWdget/appbar.dart';
import '../buyer_home.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerLandingPage extends StatefulWidget {
  @override
  _BuyerLandingPageState createState() => _BuyerLandingPageState();
}

class _BuyerLandingPageState extends State<BuyerLandingPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _heroAnimationController;
  late AnimationController _benefitsAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _buttonAnimationController;

  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _benefitsFadeAnimation;
  late Animation<Offset> _benefitsSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonScaleAnimation;

  bool _heroVisible = false;
  bool _benefitsVisible = false;
  bool _contentVisible = false;
  bool _buttonVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Initialize animation controllers
    _heroAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
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
    _buttonAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut),
    );
    _heroSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut));

    _benefitsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _benefitsAnimationController, curve: Curves.easeOut),
    );
    _benefitsSlideAnimation = Tween<Offset>(
      begin: Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _benefitsAnimationController, curve: Curves.easeOut));

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentAnimationController, curve: Curves.easeOut),
    );
    _contentSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentAnimationController, curve: Curves.easeOut));

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeOut),
    );
    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.elasticOut),
    );

    _scrollController.addListener(_onScroll);

    // Start hero animation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _heroAnimationController.forward();
      _benefitsAnimationController.forward();
      setState(() {
        _heroVisible = true;
        _benefitsVisible = true;
      });
    });
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;

    // Trigger content animation
    if (scrollOffset > 400 && !_contentVisible) {
      _contentAnimationController.forward();
      setState(() {
        _contentVisible = true;
      });
    }

    // Trigger button animation
    if (scrollOffset > 800 && !_buttonVisible) {
      _buttonAnimationController.forward();
      setState(() {
        _buttonVisible = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAnimationController.dispose();
    _benefitsAnimationController.dispose();
    _contentAnimationController.dispose();
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
            height: 50,
            width: MediaQuery.of(context).size.width,
            color: Constants.ctaColorLight,
            padding: EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 8),
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
                  ' > Why Join as a Buyer?',
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

                  SlideTransition(
                    position: _heroSlideAnimation,
                    child: FadeTransition(
                      opacity: _heroFadeAnimation,
                      child: _buildHeroSection(),
                    ),
                  ),

                  // Animated Content Section
                  SlideTransition(
                    position: _contentSlideAnimation,
                    child: FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: _buildContentSection(),
                    ),
                  ),

                  // Animated Join Button
                  ScaleTransition(
                    scale: _buttonScaleAnimation,
                    child: FadeTransition(
                      opacity: _buttonFadeAnimation,
                      child: _buildJoinButton(context),
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

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: Container(
        width: double.infinity,
        height: 400,
        constraints: BoxConstraints(maxWidth: 1400),
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            // Left side - Animated Illustration
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
                        "lib/assets/images/buyer.png",
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(width: 60),

            // Right side - Animated Benefits
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
                        title: 'Save Time & Effort',
                        description: 'No Need To Search Manually - Simply Submit A Request And Let Sellers Come To You.',
                        icon: Icons.access_time,
                        delay: Duration(milliseconds: 0),
                      ),
                      SizedBox(height: 24),
                      AnimatedBenefitCard(
                        title: 'Transparent & Secure',
                        description: 'View Seller Ratings, Reviews, And Business Details Before Making A Purchase.',
                        icon: Icons.security,
                        delay: Duration(milliseconds: 200),
                      ),
                      SizedBox(height: 24),
                      AnimatedBenefitCard(
                        title: 'Chat Before You Buy',
                        description: 'Discuss Details, Negotiate, And Make Informed Decisions Before Accepting A Quote.',
                        icon: Icons.chat_bubble_outline,
                        delay: Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 24),
                      AnimatedBenefitCard(
                        title: 'Fast & Efficient',
                        description: 'Receive Quick Responses From Sellers Who Meet Your Requirements.',
                        icon: Icons.flash_on,
                        delay: Duration(milliseconds: 600),
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

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 1400),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContentParagraph(
              text: "The Majority Of South Africa's Are Finding It Harder And Harder To Make Ends Meet. These Days, It's A Necessity To Search The \"Specials\" Pamphlets From Various Shops To Pick The Best Deals To Save A Buck.",
              delay: Duration(milliseconds: 0),
            ),
            SizedBox(height: 20),
            AnimatedContentParagraph(
              text: "We Understand The Frustration In The Amount Of Time It Takes To Call Multiple Stores To Negotiate The Best Price, Or Browse The Internet Looking For Deals. Some Sellers Are Prepared To Meet Buyers Halfway And Offer A Small Discount On Their Price. Our Solution Provides An Automated Platform To Facilitate The Negotiation Process Without Any Of The Hassles.",
              delay: Duration(milliseconds: 200),
            ),
            SizedBox(height: 20),
            AnimatedContentParagraph(
              text: "Buyers Simply Provide Information About The Product That They Require And Select The Area For Our System To Search. We Then Notify All Sellers In The Search Area Of The Request. The Sellers Will Review Your Requirements And Decide If They Want To Bid Or Not. You Will Have The Opportunity Of Communicating With All The Potential Sellers At The Same Time So That You Don't Have To Keep Providing The Same Information Repeatedly. Our System Will Update The Interested Sellers Of The Best Price On Offer And Allow Them To Counter Bid If They Opt To Do So. They May Also Offer Similar Competing Products For Your Consideration.",
              delay: Duration(milliseconds: 400),
            ),
            SizedBox(height: 20),
            AnimatedContentParagraph(
              text: "Once The Negotiation Process Is Concluded, You Can Then Decide To Accept Any Of The Offers - Which May Be The Cheapest Price Or A Similar Product With More Compelling Specifications. If None Of The Offers Are Acceptable, You Are Not Obliged To Accept Any Of The Bids.",
              delay: Duration(milliseconds: 600),
            ),
            SizedBox(height: 20),
            AnimatedContentParagraph(
              text: "We Have Implemented Several Hold Points To Allow The Deal To Be Cancelled With A Full Refund. Buyers Will Only Be Billed If They Receive Goods That Are As Per Their Specifications And Are In Good Condition.",
              delay: Duration(milliseconds: 800),
            ),
            SizedBox(height: 20),
            AnimatedContentParagraph(
              text: "Our Platform Is Free To Use For Buyers. A Small Transaction Percentage Is Levied To The Seller For Use Of The System So There Is No Hidden Costs To The Buyer. The Price Quoted By The Seller Is The Full And Total Price That You Will Be Charged.",
              delay: Duration(milliseconds: 1000),
            ),
            SizedBox(height: 20),
            AnimatedContentParagraph(
              text: "Our Service Is Provided On A Fair Use Basis. By Using Our System We Aim To Save You Time And Effort In Trying To Get The Best Price For Items That You Need. It Is Important To Note That We Are Not Influencing Selling Prices. We Have Merely Automated The Process Of You Negotiating With The Sellers Yourself. The System Allows Them To Offer A Discount That They Would Have Offered You Anyway Should You Have Negotiated With Them Directly.",
              delay: Duration(milliseconds: 1200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.5,
      margin: EdgeInsets.symmetric(horizontal: 40),
      height: 45,
      child: ElevatedButton(
        onPressed: () {
          // Handle join as buyer action
          print('Join as a Buyer clicked');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.ctaColorLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(360),
          ),
          elevation: 0,
        ),
        child: Text(
          'Join as a Buyer',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// Animated Benefit Card Component
class AnimatedBenefitCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Duration delay;

  const AnimatedBenefitCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
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
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Constants.ftaColorLight,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                          height: 1.4,
                        ),
                      ),
                    ],
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

// Animated Content Paragraph Component
class AnimatedContentParagraph extends StatelessWidget {
  final String text;
  final Duration delay;

  const AnimatedContentParagraph({
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
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.black,
                height: 1.6,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      },
    );
  }
}


