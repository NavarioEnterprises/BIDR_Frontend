import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/Constants.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  List<FAQItem> _faqItems = [];
  List<String> _categories = ["All"];
  String _selectedCategory = "All";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFAQs();
  }

  Future<void> _fetchFAQs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse('http://127.0.0.1:8078/api/faqs/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        
        final List<FAQItem> faqs = results.map((faqJson) {
          return FAQItem(
            question: faqJson['question'],
            answer: faqJson['answer'], 
            category: faqJson['category_display'],
          );
        }).toList();

        // Extract unique categories
        final Set<String> categorySet = {'All'};
        for (final faq in faqs) {
          categorySet.add(faq.category);
        }

        setState(() {
          _faqItems = faqs;
          _categories = categorySet.toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load FAQs');
      }
    } catch (e) {
      print('Error fetching FAQs: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load FAQs. Please try again later.'),
        ),
      );
    }
  }

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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
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