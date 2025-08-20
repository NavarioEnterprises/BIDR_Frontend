import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/Constants.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: "What is BIDR?",
      answer: "BIDR is a next-generation marketplace platform that revolutionizes buyer-seller connections through competitive bidding mechanisms. We support vehicle spare parts, tyres & rims, and consumer electronics marketplaces.",
      category: "General",
    ),
    FAQItem(
      question: "How does the PIN verification system work?",
      answer: "When a transaction is initiated, both buyer and seller receive unique 6-digit PINs. During physical product exchange, both parties exchange PINs to verify the transaction. This dual PIN verification ensures secure transactions and releases payment from escrow.",
      category: "Security",
    ),
    FAQItem(
      question: "What categories of products can I buy/sell on BIDR?",
      answer: "BIDR supports three main categories:\n• Vehicle Spare Parts - New and used auto parts\n• Tyres & Rims - All specifications and brands\n• Consumer Electronics - Wide range of electronic products",
      category: "Products",
    ),
    FAQItem(
      question: "How long is my payment held in escrow?",
      answer: "Payment hold periods vary by category:\n• Vehicle Parts: 7 days from PIN exchange\n• Electronics: 14 days from PIN exchange\n• Custom/High-value items: 21 days from PIN exchange",
      category: "Payments",
    ),
    FAQItem(
      question: "How do I create a product request as a buyer?",
      answer: "1. Navigate to 'Create Request'\n2. Select your product category\n3. Fill in product specifications\n4. Set your budget and timeline\n5. Specify location and travel distance\n6. Submit request for sellers to quote",
      category: "Buying",
    ),
    FAQItem(
      question: "How do sellers submit quotes?",
      answer: "Sellers can:\n1. Browse active product requests\n2. Filter by category and location\n3. Review buyer requirements\n4. Submit competitive quotes with pricing, delivery terms, and warranty information\n5. Engage with buyers through the chat system",
      category: "Selling",
    ),
    FAQItem(
      question: "What happens if I'm not satisfied with my purchase?",
      answer: "You can initiate a return within the escrow period. You'll need to:\n1. Document the issue with photos\n2. Specify the return reason\n3. Coordinate return shipping with the seller\n4. The seller evaluates the return and decides on the refund",
      category: "Returns",
    ),
    FAQItem(
      question: "Is communication between buyers and sellers secure?",
      answer: "Yes! All communication happens through our integrated chat platform. Chat history is maintained for dispute resolution, and personal contact information is protected until you choose to share it.",
      category: "Security",
    ),
    FAQItem(
      question: "What payment methods are accepted?",
      answer: "BIDR supports secure payment processing through PayFast and Stripe. All payments are held in escrow until successful transaction completion, protecting both buyers and sellers.",
      category: "Payments",
    ),
    FAQItem(
      question: "How do I verify my business as a seller?",
      answer: "During profile completion, sellers must:\n1. Provide business registration details\n2. Submit tax information\n3. Complete business verification process\n4. Upload required documentation\nVerified sellers get a verification badge visible to buyers.",
      category: "Selling",
    ),
  ];

  String _selectedCategory = "All";
  final List<String> _categories = ["All", "General", "Security", "Products", "Buying", "Selling", "Returns", "Payments"];

  List<FAQItem> get _filteredFAQItems {
    if (_selectedCategory == "All") {
      return _faqItems;
    }
    return _faqItems.where((item) => item.category == _selectedCategory).toList();
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
          'Frequently Asked Questions',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Category Filter
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 64,top: 16),
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(maxWidth: 1600),
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: GoogleFonts.manrope(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      selectedColor: Constants.ctaColorLight,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey[200],
                    ),
                  );
                },
              ),
            ),
          ),
          // FAQ Items
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 64, right: 64),
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(maxWidth: 1600),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredFAQItems.length,
                itemBuilder: (context, index) {
                  final faq = _filteredFAQItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      backgroundColor: Colors.white,
                      collapsedBackgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      title: Text(
                        faq.question,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          faq.category,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Constants.ctaColorLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      children: [
                        Text(
                          faq.answer,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Can't find what you're looking for?",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to contact support
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Contact Support',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;
  final String category;

  FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}