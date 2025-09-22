import 'package:bidr/pages/mobileView/landingPage/profileMobile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/Constants.dart';
import '../../../customWdget/appbar.dart';
import '../../../customWdget/customCard.dart';
import '../../../customWdget/mobileBottomNavBar.dart';
import '../../buyer/support.dart';
import '../../buyer_home.dart';
import '../breakpoints.dart';
import 'landingMobileController.dart';
import 'landingMobileViewPage.dart';

class PoliciesMobileScreen extends StatefulWidget {
  const PoliciesMobileScreen({Key? key}) : super(key: key);

  @override
  State<PoliciesMobileScreen> createState() => _PoliciesMobileScreenState();
}

class _PoliciesMobileScreenState extends State<PoliciesMobileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();

    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Breakpoints.isMobile(context);

    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading:isBackButtonDisplayed?
          IconButton(
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
          ):
          IconButton(
            onPressed:(){
              currentIndex =0;
              selectedTitle = "";
              currentControllerValueNotifier.value++;
              buyerBackMobileButtonValueNotifier.value++;

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
          title: Text(
            "Policies & Agreements",
            style: GoogleFonts.manrope(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
      body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              SizedBox(height: spacing.spacingLarge),

              // Main Content
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [

                        // Tab Selection - Mobile Only
                        Container(
                          margin: EdgeInsets.symmetric(
                            vertical: spacing.spacingLarge,
                            horizontal: spacing.paddingLarge,
                          ),
                          child: _buildMobileTabSelector(typography, spacing),
                        ),

                        // Content Area
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.symmetric(
                            horizontal: spacing.paddingLarge,
                          ),
                          constraints: BoxConstraints(maxWidth: 1200),
                          child: AnimatedSwitcher(
                            duration: Duration(milliseconds: 300),
                            child: _buildTabContent(
                              _selectedTab,
                              typography,
                              spacing,
                            ),
                          ),
                        ),

                        SizedBox(height: spacing.spacingLarge * 2),

                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
    );
  }

  Widget _buildMobileTabSelector(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          final isSelected = _selectedTab == index;
          final labels = ['Terms', 'Privacy', 'Returns', 'Sellers'];

          return GestureDetector(
            onTap: () {
              _tabController.animateTo(index);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.all(spacing.marginSmall / 2),
              padding: EdgeInsets.symmetric(
                horizontal: spacing.paddingMedium,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Constants.ctaColorLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[500],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabContent(
    int index,
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    switch (index) {
      case 0:
        return _buildTermsOfService(typography, spacing);
      case 1:
        return _buildPrivacyPolicy(typography, spacing);
      case 2:
        return _buildReturnPolicy(typography, spacing);
      case 3:
        return _buildSellerAgreement(typography, spacing);
      default:
        return Container();
    }
  }

  Widget _buildTermsOfService(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedHeader(
          'Terms of Service',
          'Last updated: January 15, 2025',
          typography,
          spacing,
        ),
        SizedBox(height: spacing.spacingLarge),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
          title: '1. Acceptance of Terms',
          content:
              'By accessing and using BIDR marketplace platform, you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
          typography: typography,
          spacing: spacing,
          delay: 0,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedUser,
          title: '2. User Registration',
          content:
              '• You must provide accurate and complete information during registration\n'
              '• You are responsible for maintaining the security of your account\n'
              '• Email verification is mandatory for platform access\n'
              '• Business sellers must complete additional verification',
          typography: typography,
          spacing: spacing,
          delay: 100,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedComputer,
          title: '3. Platform Usage',
          content:
              '• BIDR facilitates connections between buyers and sellers\n'
              '• We do not own or control products listed on the platform\n'
              '• Users must comply with all applicable laws and regulations\n'
              '• Prohibited activities include fraud, spam, and harassment',
          typography: typography,
          spacing: spacing,
          delay: 200,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedShoppingCart01,
          title: '4. Transaction Process',
          content:
              '• All transactions use our secure PIN verification system\n'
              '• Payments are held in escrow until PIN exchange\n'
              '• Both parties must complete PIN exchange for payment release\n'
              '• Escrow periods: 7 days (parts), 14 days (electronics), 21 days (custom items)',
          typography: typography,
          spacing: spacing,
          delay: 300,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedMoney01,
          title: '5. Fees and Payments',
          content:
              '• Sellers pay a commission on successful transactions\n'
              '• Payment processing fees may apply\n'
              '• All fees are clearly disclosed before transaction completion\n'
              '• Payments processed through PayFast/Stripe',
          typography: typography,
          spacing: spacing,
          delay: 400,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedJusticeScale01,
          title: '6. Dispute Resolution',
          content:
              '• Disputes should first be resolved between buyer and seller\n'
              '• BIDR provides mediation services when needed\n'
              '• Admin decisions on disputes are final\n'
              '• Evidence including chat history and photos may be reviewed',
          typography: typography,
          spacing: spacing,
          delay: 500,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedAlert02,
          title: '7. Limitation of Liability',
          content:
              'BIDR is not liable for:\n'
              '• Quality or condition of products\n'
              '• Actions of users on the platform\n'
              '• Indirect or consequential damages\n'
              '• Loss of profits or business opportunities',
          typography: typography,
          spacing: spacing,
          delay: 600,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedCancel01,
          title: '8. Termination',
          content:
              '• We may suspend or terminate accounts for violations\n'
              '• Users may close their accounts at any time\n'
              '• Outstanding transactions must be completed before closure\n'
              '• Some data may be retained for legal compliance',
          typography: typography,
          spacing: spacing,
          delay: 700,
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicy(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedHeader(
          'Privacy Policy',
          'Last updated: January 15, 2025',
          typography,
          spacing,
        ),
        SizedBox(height: spacing.spacingLarge),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedDatabase,
          title: '1. Information We Collect',
          content:
              '• Personal Information: Name, email, phone number, address\n'
              '• Business Information: Company details, tax information\n'
              '• Transaction Data: Purchase history, quotes, communications\n'
              '• Technical Data: IP address, browser type, device information',
          typography: typography,
          spacing: spacing,
          delay: 0,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedDataRecovery,
          title: '2. How We Use Your Information',
          content:
              '• To facilitate transactions between buyers and sellers\n'
              '• To verify user identity and prevent fraud\n'
              '• To send transaction-related communications\n'
              '• To improve our services and user experience\n'
              '• To comply with legal obligations',
          typography: typography,
          spacing: spacing,
          delay: 100,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedShare01,
          title: '3. Information Sharing',
          content:
              'We share information with:\n'
              '• Other users (as necessary for transactions)\n'
              '• Payment processors (PayFast/Stripe)\n'
              '• Azure services for infrastructure\n'
              '• Law enforcement (when legally required)',
          typography: typography,
          spacing: spacing,
          delay: 200,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedLock,
          title: '4. Data Security',
          content:
              '• We use industry-standard encryption\n'
              '• JWT tokens for authentication\n'
              '• Secure Azure infrastructure\n'
              '• Regular security audits and updates\n'
              '• PIN system for transaction verification',
          typography: typography,
          spacing: spacing,
          delay: 300,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedUserSettings01,
          title: '5. Your Rights',
          content:
              '• Access your personal information\n'
              '• Correct inaccurate data\n'
              '• Request data deletion (subject to legal requirements)\n'
              '• Opt-out of marketing communications\n'
              '• Data portability upon request',
          typography: typography,
          spacing: spacing,
          delay: 400,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedCookie,
          title: '6. Cookies and Tracking',
          content:
              '• We use cookies for authentication and preferences\n'
              '• Analytics to improve services\n'
              '• You can control cookie settings in your browser\n'
              '• Essential cookies required for platform functionality',
          typography: typography,
          spacing: spacing,
          delay: 500,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedClock01,
          title: '7. Data Retention',
          content:
              '• Active account data retained while account is open\n'
              '• Transaction records kept for 7 years (legal requirement)\n'
              '• Chat history retained for 1 year\n'
              '• Deleted account data removed after 30 days',
          typography: typography,
          spacing: spacing,
          delay: 600,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedMail01,
          title: '8. Contact Us',
          content:
              'For privacy concerns or requests:\n'
              'Email: privacy@bidr.co.za\n'
              'Phone: Support line available Mon-Fri 9AM-5PM\n'
              'Address: BIDR Privacy Office, South Africa',
          typography: typography,
          spacing: spacing,
          delay: 700,
        ),
      ],
    );
  }

  Widget _buildReturnPolicy(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedHeader(
          'Return Policy',
          'Last updated: January 15, 2025',
          typography,
          spacing,
        ),
        SizedBox(height: spacing.spacingLarge),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedReturnRequest,
          title: '1. Return Eligibility',
          content:
              '• Returns must be initiated within the escrow period\n'
              '• Vehicle Parts: 7 days from PIN exchange\n'
              '• Electronics: 14 days from PIN exchange\n'
              '• Custom/High-value items: 21 days from PIN exchange\n'
              '• Item must be in original condition unless defective',
          typography: typography,
          spacing: spacing,
          delay: 0,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedCheckUnread02,
          title: '2. Valid Return Reasons',
          content:
              '• Item not as described in listing\n'
              '• Defective or damaged product\n'
              '• Wrong item delivered\n'
              '• Missing parts or accessories\n'
              '• Significant quality issues',
          typography: typography,
          spacing: spacing,
          delay: 100,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedWorkflowSquare03,
          title: '3. Return Process',
          content:
              '1. Initiate return in the app within escrow period\n'
              '2. Provide detailed reason for return\n'
              '3. Upload photos documenting the issue\n'
              '4. Coordinate return shipping with seller\n'
              '5. Seller evaluates returned item\n'
              '6. Refund processed based on evaluation',
          typography: typography,
          spacing: spacing,
          delay: 200,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedDeliveryBox01,
          title: '4. Return Shipping',
          content:
              '• Buyer pays return shipping for change of mind\n'
              '• Seller pays return shipping for defective items\n'
              '• Original shipping costs non-refundable\n'
              '• Use tracked shipping for protection\n'
              '• Keep all shipping receipts',
          typography: typography,
          spacing: spacing,
          delay: 300,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedMoneyReceive01,
          title: '5. Refund Process',
          content:
              '• Refunds processed after seller confirms receipt\n'
              '• Full refund for defective or wrong items\n'
              '• Partial refunds may apply for other reasons\n'
              '• Refunds issued to original payment method\n'
              '• Processing time: 3-5 business days',
          typography: typography,
          spacing: spacing,
          delay: 400,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedCancelCircle,
          title: '6. Non-Returnable Items',
          content:
              '• Custom-made or personalized items\n'
              '• Items damaged due to misuse\n'
              '• Installed parts (unless defective)\n'
              '• Items returned after escrow period\n'
              '• Digital products or software',
          typography: typography,
          spacing: spacing,
          delay: 500,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedComplaint,
          title: '7. Dispute Resolution',
          content:
              '• Seller has 48 hours to respond to return request\n'
              '• If no agreement reached, escalate to BIDR admin\n'
              '• Admin reviews evidence from both parties\n'
              '• Admin decision is final and binding\n'
              '• False claims may result in account suspension',
          typography: typography,
          spacing: spacing,
          delay: 600,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedShield02,
          title: '8. Warranty Claims',
          content:
              '• Manufacturer warranties handled separately\n'
              '• Seller warranties as specified in listing\n'
              '• Keep all documentation for warranty claims\n'
              '• BIDR facilitates but doesn\'t guarantee warranties',
          typography: typography,
          spacing: spacing,
          delay: 700,
        ),
      ],
    );
  }

  Widget _buildSellerAgreement(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnimatedHeader(
          'Seller Agreement',
          'Last updated: January 15, 2025',
          typography,
          spacing,
        ),
        SizedBox(height: spacing.spacingLarge),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedStore01,
          title: '1. Seller Requirements',
          content:
              '• Must complete business verification\n'
              '• Provide accurate tax information\n'
              '• Maintain valid business licenses\n'
              '• Respond to buyer inquiries within 24 hours\n'
              '• Honor all accepted quotes',
          typography: typography,
          spacing: spacing,
          delay: 0,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedTag01,
          title: '2. Listing Standards',
          content:
              '• Accurate product descriptions required\n'
              '• Clear, high-quality product images\n'
              '• Honest condition assessment\n'
              '• Competitive and fair pricing\n'
              '• Update inventory regularly',
          typography: typography,
          spacing: spacing,
          delay: 100,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedPercentCircle,
          title: '3. Commission Structure',
          content:
              '• Standard commission: 8% of transaction value\n'
              '• High-volume sellers: Reduced rates available\n'
              '• Commission charged on successful transactions only\n'
              '• Monthly invoicing for fees\n'
              '• Payment due within 30 days',
          typography: typography,
          spacing: spacing,
          delay: 200,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedAgreement01,
          title: '4. Transaction Obligations',
          content:
              '• Complete PIN verification at delivery\n'
              '• Provide receipt and documentation\n'
              '• Package items securely\n'
              '• Meet agreed delivery timelines\n'
              '• Maintain professional communication',
          typography: typography,
          spacing: spacing,
          delay: 300,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedStar,
          title: '5. Quality Standards',
          content:
              '• Minimum 4-star rating to remain active\n'
              '• Response rate above 80%\n'
              '• Low dispute rate required\n'
              '• Regular performance reviews\n'
              '• Training available for improvement',
          typography: typography,
          spacing: spacing,
          delay: 400,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedAlertCircle,
          title: '6. Prohibited Conduct',
          content:
              '• No fake reviews or ratings manipulation\n'
              '• No direct contact outside platform\n'
              '• No discriminatory practices\n'
              '• No counterfeit or stolen goods\n'
              '• No circumventing platform fees',
          typography: typography,
          spacing: spacing,
          delay: 500,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedShieldUser,
          title: '7. Seller Protection',
          content:
              '• Payment guaranteed after PIN verification\n'
              '• Dispute resolution support\n'
              '• Fraud protection measures\n'
              '• Business analytics and insights\n'
              '• Marketing support for verified sellers',
          typography: typography,
          spacing: spacing,
          delay: 600,
        ),
        _buildAnimatedSection(
          icon: HugeIcons.strokeRoundedUserRemove01,
          title: '8. Account Termination',
          content:
              '• 30-day notice for voluntary termination\n'
              '• Immediate suspension for serious violations\n'
              '• Complete pending transactions before closure\n'
              '• Final fee settlement required\n'
              '• Data export available upon request',
          typography: typography,
          spacing: spacing,
          delay: 700,
        ),
      ],
    );
  }

  Widget _buildAnimatedHeader(
    String title,
    String subtitle,
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: typography.heading,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                ),
                SizedBox(height: spacing.spacingSmall),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: typography.normal,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSection({
    required IconData icon,
    required String title,
    required String content,
    required TypographyConfig typography,
    required SpacingConfig spacing,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Container(
              margin: EdgeInsets.only(bottom: spacing.spacingLarge),
              child: CustomCard(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(spacing.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(spacing.paddingSmall),
                            decoration: BoxDecoration(
                              color: Constants.ctaColorLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Constants.ctaColorLight,
                              size: typography.large,
                            ),
                          ),
                          SizedBox(width: spacing.spacingMedium),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.manrope(
                                fontSize: typography.subHeading,
                                fontWeight: FontWeight.bold,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: spacing.spacingMedium),
                      Container(
                        padding: EdgeInsets.all(spacing.paddingMedium),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          content,
                          style: GoogleFonts.manrope(
                            fontSize: typography.normal,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
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
}
