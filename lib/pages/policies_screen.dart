import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/Constants.dart';

class PoliciesScreen extends StatefulWidget {
  const PoliciesScreen({Key? key}) : super(key: key);

  @override
  State<PoliciesScreen> createState() => _PoliciesScreenState();
}

class _PoliciesScreenState extends State<PoliciesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.ctaColorLight,
        foregroundColor: Constants.ftaColorLight,
        elevation: 1,
        title: Text(
          'Policies',
          style: GoogleFonts.manrope(

            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Constants.ftaColorLight,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Constants.ftaColorLight,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Terms of Service'),
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Return Policy'),
            Tab(text: 'Seller Agreement'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 50, right: 50),
        child: Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(maxWidth: 1600),
          child: TabBarView(
            controller: _tabController,
            children: [
              Expanded(child: _buildTermsOfService()),
              _buildPrivacyPolicy(),
              _buildReturnPolicy(),
              _buildSellerAgreement(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsOfService() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Terms of Service'),
          _buildLastUpdated(),
          const SizedBox(height: 20),
          _buildSection(
            '1. Acceptance of Terms',
            'By accessing and using BIDR marketplace platform, you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.',
          ),
          _buildSection(
            '2. User Registration',
            '• You must provide accurate and complete information during registration\n'
            '• You are responsible for maintaining the security of your account\n'
            '• Email verification is mandatory for platform access\n'
            '• Business sellers must complete additional verification',
          ),
          _buildSection(
            '3. Platform Usage',
            '• BIDR facilitates connections between buyers and sellers\n'
            '• We do not own or control products listed on the platform\n'
            '• Users must comply with all applicable laws and regulations\n'
            '• Prohibited activities include fraud, spam, and harassment',
          ),
          _buildSection(
            '4. Transaction Process',
            '• All transactions use our secure PIN verification system\n'
            '• Payments are held in escrow until PIN exchange\n'
            '• Both parties must complete PIN exchange for payment release\n'
            '• Escrow periods: 7 days (parts), 14 days (electronics), 21 days (custom items)',
          ),
          _buildSection(
            '5. Fees and Payments',
            '• Sellers pay a commission on successful transactions\n'
            '• Payment processing fees may apply\n'
            '• All fees are clearly disclosed before transaction completion\n'
            '• Payments processed through PayFast/Stripe',
          ),
          _buildSection(
            '6. Dispute Resolution',
            '• Disputes should first be resolved between buyer and seller\n'
            '• BIDR provides mediation services when needed\n'
            '• Admin decisions on disputes are final\n'
            '• Evidence including chat history and photos may be reviewed',
          ),
          _buildSection(
            '7. Limitation of Liability',
            'BIDR is not liable for:\n'
            '• Quality or condition of products\n'
            '• Actions of users on the platform\n'
            '• Indirect or consequential damages\n'
            '• Loss of profits or business opportunities',
          ),
          _buildSection(
            '8. Termination',
            '• We may suspend or terminate accounts for violations\n'
            '• Users may close their accounts at any time\n'
            '• Outstanding transactions must be completed before closure\n'
            '• Some data may be retained for legal compliance',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Privacy Policy'),
          _buildLastUpdated(),
          const SizedBox(height: 20),
          _buildSection(
            '1. Information We Collect',
            '• Personal Information: Name, email, phone number, address\n'
            '• Business Information: Company details, tax information\n'
            '• Transaction Data: Purchase history, quotes, communications\n'
            '• Technical Data: IP address, browser type, device information',
          ),
          _buildSection(
            '2. How We Use Your Information',
            '• To facilitate transactions between buyers and sellers\n'
            '• To verify user identity and prevent fraud\n'
            '• To send transaction-related communications\n'
            '• To improve our services and user experience\n'
            '• To comply with legal obligations',
          ),
          _buildSection(
            '3. Information Sharing',
            'We share information with:\n'
            '• Other users (as necessary for transactions)\n'
            '• Payment processors (PayFast/Stripe)\n'
            '• Azure services for infrastructure\n'
            '• Law enforcement (when legally required)',
          ),
          _buildSection(
            '4. Data Security',
            '• We use industry-standard encryption\n'
            '• JWT tokens for authentication\n'
            '• Secure Azure infrastructure\n'
            '• Regular security audits and updates\n'
            '• PIN system for transaction verification',
          ),
          _buildSection(
            '5. Your Rights',
            '• Access your personal information\n'
            '• Correct inaccurate data\n'
            '• Request data deletion (subject to legal requirements)\n'
            '• Opt-out of marketing communications\n'
            '• Data portability upon request',
          ),
          _buildSection(
            '6. Cookies and Tracking',
            '• We use cookies for authentication and preferences\n'
            '• Analytics to improve services\n'
            '• You can control cookie settings in your browser\n'
            '• Essential cookies required for platform functionality',
          ),
          _buildSection(
            '7. Data Retention',
            '• Active account data retained while account is open\n'
            '• Transaction records kept for 7 years (legal requirement)\n'
            '• Chat history retained for 1 year\n'
            '• Deleted account data removed after 30 days',
          ),
          _buildSection(
            '8. Contact Us',
            'For privacy concerns or requests:\n'
            'Email: privacy@bidr.co.za\n'
            'Phone: Support line available Mon-Fri 9AM-5PM\n'
            'Address: BIDR Privacy Office, South Africa',
          ),
        ],
      ),
    );
  }

  Widget _buildReturnPolicy() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Return Policy'),
          _buildLastUpdated(),
          const SizedBox(height: 20),
          _buildSection(
            '1. Return Eligibility',
            '• Returns must be initiated within the escrow period\n'
            '• Vehicle Parts: 7 days from PIN exchange\n'
            '• Electronics: 14 days from PIN exchange\n'
            '• Custom/High-value items: 21 days from PIN exchange\n'
            '• Item must be in original condition unless defective',
          ),
          _buildSection(
            '2. Valid Return Reasons',
            '• Item not as described in listing\n'
            '• Defective or damaged product\n'
            '• Wrong item delivered\n'
            '• Missing parts or accessories\n'
            '• Significant quality issues',
          ),
          _buildSection(
            '3. Return Process',
            '1. Initiate return in the app within escrow period\n'
            '2. Provide detailed reason for return\n'
            '3. Upload photos documenting the issue\n'
            '4. Coordinate return shipping with seller\n'
            '5. Seller evaluates returned item\n'
            '6. Refund processed based on evaluation',
          ),
          _buildSection(
            '4. Return Shipping',
            '• Buyer pays return shipping for change of mind\n'
            '• Seller pays return shipping for defective items\n'
            '• Original shipping costs non-refundable\n'
            '• Use tracked shipping for protection\n'
            '• Keep all shipping receipts',
          ),
          _buildSection(
            '5. Refund Process',
            '• Refunds processed after seller confirms receipt\n'
            '• Full refund for defective or wrong items\n'
            '• Partial refunds may apply for other reasons\n'
            '• Refunds issued to original payment method\n'
            '• Processing time: 3-5 business days',
          ),
          _buildSection(
            '6. Non-Returnable Items',
            '• Custom-made or personalized items\n'
            '• Items damaged due to misuse\n'
            '• Installed parts (unless defective)\n'
            '• Items returned after escrow period\n'
            '• Digital products or software',
          ),
          _buildSection(
            '7. Dispute Resolution',
            '• Seller has 48 hours to respond to return request\n'
            '• If no agreement reached, escalate to BIDR admin\n'
            '• Admin reviews evidence from both parties\n'
            '• Admin decision is final and binding\n'
            '• False claims may result in account suspension',
          ),
          _buildSection(
            '8. Warranty Claims',
            '• Manufacturer warranties handled separately\n'
            '• Seller warranties as specified in listing\n'
            '• Keep all documentation for warranty claims\n'
            '• BIDR facilitates but doesn\'t guarantee warranties',
          ),
        ],
      ),
    );
  }

  Widget _buildSellerAgreement() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Seller Agreement'),
          _buildLastUpdated(),
          const SizedBox(height: 20),
          _buildSection(
            '1. Seller Requirements',
            '• Must complete business verification\n'
            '• Provide accurate tax information\n'
            '• Maintain valid business licenses\n'
            '• Respond to buyer inquiries within 24 hours\n'
            '• Honor all accepted quotes',
          ),
          _buildSection(
            '2. Listing Standards',
            '• Accurate product descriptions required\n'
            '• Clear, high-quality product images\n'
            '• Honest condition assessment\n'
            '• Competitive and fair pricing\n'
            '• Update inventory regularly',
          ),
          _buildSection(
            '3. Commission Structure',
            '• Standard commission: 8% of transaction value\n'
            '• High-volume sellers: Reduced rates available\n'
            '• Commission charged on successful transactions only\n'
            '• Monthly invoicing for fees\n'
            '• Payment due within 30 days',
          ),
          _buildSection(
            '4. Transaction Obligations',
            '• Complete PIN verification at delivery\n'
            '• Provide receipt and documentation\n'
            '• Package items securely\n'
            '• Meet agreed delivery timelines\n'
            '• Maintain professional communication',
          ),
          _buildSection(
            '5. Quality Standards',
            '• Minimum 4-star rating to remain active\n'
            '• Response rate above 80%\n'
            '• Low dispute rate required\n'
            '• Regular performance reviews\n'
            '• Training available for improvement',
          ),
          _buildSection(
            '6. Prohibited Conduct',
            '• No fake reviews or ratings manipulation\n'
            '• No direct contact outside platform\n'
            '• No discriminatory practices\n'
            '• No counterfeit or stolen goods\n'
            '• No circumventing platform fees',
          ),
          _buildSection(
            '7. Seller Protection',
            '• Payment guaranteed after PIN verification\n'
            '• Dispute resolution support\n'
            '• Fraud protection measures\n'
            '• Business analytics and insights\n'
            '• Marketing support for verified sellers',
          ),
          _buildSection(
            '8. Account Termination',
            '• 30-day notice for voluntary termination\n'
            '• Immediate suspension for serious violations\n'
            '• Complete pending transactions before closure\n'
            '• Final fee settlement required\n'
            '• Data export available upon request',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Text(
      'Last updated: January 15, 2025',
      style: GoogleFonts.manrope(
        fontSize: 14,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              content,
              style: GoogleFonts.manrope(
                fontSize: 14,
                height: 1.6,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}