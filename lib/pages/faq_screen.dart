import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/Constants.dart';
import '../customWdget/custom_input2.dart';
import '../models/faq.dart';
import '../services/faq_api_service.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final FAQApiService _faqApiService = FAQApiService();
  List<FAQ> _faqItems = [];
  List<FAQCategory> _categories = [];
  String _selectedCategory = "All";
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_fetchFAQs(), _fetchCategories()]);
  }

  Future<void> _fetchFAQs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final faqs = await _faqApiService.fetchFAQs(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (faqs != null && mounted) {
        setState(() {
          _faqItems = faqs;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Failed to load FAQs. Please try again later.');
      }
    } catch (e) {
      print('Error fetching FAQs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Network error occurred while loading FAQs.');
      }
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      final categories = await _faqApiService.fetchFAQCategories();

      if (categories != null && mounted) {
        setState(() {
          _categories = [
            FAQCategory(value: 'all', label: 'All'),
            ...categories,
          ];
          _isLoadingCategories = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _onCategoryChanged(String category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      final faqs = await _faqApiService.getFAQsByCategory(
        category.toLowerCase(),
      );

      if (faqs != null && mounted) {
        setState(() {
          _faqItems = faqs;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching FAQs by category: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });

    try {
      final faqs = await _faqApiService.searchFAQs(query);

      if (faqs != null && mounted) {
        setState(() {
          _faqItems = faqs;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error searching FAQs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  List<FAQ> get _filteredFAQItems {
    if (_selectedCategory == "All") {
      return _faqItems;
    }
    return _faqItems
        .where(
          (item) =>
              item.categoryDisplay.toLowerCase() ==
              _selectedCategory.toLowerCase(),
        )
        .toList();
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
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.only(
              left: 64,
              right: 64,
              top: 16,
              bottom: 8,
            ),
            child:CustomInputTransparent4(
              hintText: 'Search FAQs...',
              labelText: "Search",
              controller: _searchController,
              focusNode: _searchFocusNode,
              prefix: Icon(Icons.search, color: Colors.grey[600]),
              suffix: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              )
                  : null,
              textInputAction:TextInputAction.next,
              isPasswordField: false,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                if (value.isEmpty) {
                  _performSearch('');
                }
              },
              onSubmitted:(value){},
            ),
          ),
          // Category Filter
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 64, top: 8),
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(maxWidth: 1600),
              color: Colors.white,
              child: _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category.label == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              category.label,
                              style: GoogleFonts.manrope(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              _onCategoryChanged(category.label);
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
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFAQItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No FAQs found for "$_searchQuery"'
                                : _selectedCategory != "All"
                                ? 'No FAQs found in "$_selectedCategory" category'
                                : 'No FAQs available',
                            style: GoogleFonts.manrope(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching with different keywords'
                                : _selectedCategory != "All"
                                ? 'Try selecting a different category'
                                : 'Check back later for updates',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _selectedCategory != "All") ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                                _onCategoryChanged('All');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Constants.ctaColorLight,
                              ),
                              child: Text(
                                'Show All FAQs',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredFAQItems.length,
                      itemBuilder: (context, index) {
                        final faq = _filteredFAQItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              20,
                              0,
                              20,
                              16,
                            ),
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
                                faq.categoryDisplay,
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
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87),
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
