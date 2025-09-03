import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/Constants.dart';
import '../../../customWdget/appbar.dart';
import '../../../customWdget/customCard.dart';
import '../../../customWdget/custom_input2.dart';
import '../../../models/faq.dart';
import '../../../services/faq_api_service.dart';
import '../../buyer/support.dart';
import '../../buyer_home.dart';
import '../breakpoints.dart';

class FAQMobileScreen extends StatefulWidget {
  const FAQMobileScreen({super.key});

  @override
  State<FAQMobileScreen> createState() => _FAQMobileScreenState();
}

class _FAQMobileScreenState extends State<FAQMobileScreen> with TickerProviderStateMixin {
  final FAQApiService _faqApiService = FAQApiService();
  List<FAQ> _faqItems = [];
  List<FAQCategory> _categories = [];
  String _selectedCategory = "All";
  bool _isLoading = true;
  bool _isLoadingCategories = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<bool> _expandedStates = [];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
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
          _expandedStates = List.filled(faqs.length, false);
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
          _expandedStates = List.filled(faqs.length, false);
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
          _expandedStates = List.filled(faqs.length, false);
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
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(ResponsiveSpacing.getSpacing(context).spacingMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
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
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: BuyerDashboardHeader(
                    headerName: '',
                    totalAlert: 0,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacing.spacingLarge),
          
          // Main Content
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Section with Title
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.paddingLarge,
                        horizontal: spacing.paddingLarge,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Constants.ctaColorLight.withOpacity(0.1),
                            Constants.ctaColorLight.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Icon(
                                  HugeIcons.strokeRoundedHelpSquare,
                                  size: 48,
                                  color: Constants.ctaColorLight,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: spacing.spacingMedium),
                          Text(
                            'Frequently Asked Questions',
                            style: GoogleFonts.manrope(
                              fontSize: typography.heading,
                              fontWeight: FontWeight.bold,
                              color: Constants.ftaColorLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing.spacingSmall),
                          Text(
                            'Find quick answers to common questions',
                            style: GoogleFonts.manrope(
                              fontSize: typography.normal,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Search Section
                    Container(
                      margin: EdgeInsets.all(spacing.spacingLarge),
                      child: _buildSearchSection(typography, spacing),
                    ),
                    
                    // Category Filter
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: spacing.spacingLarge),
                      child: _buildCategoryFilter(typography, spacing),
                    ),
                    
                    SizedBox(height: spacing.spacingLarge),
                    
                    // FAQ Content
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: spacing.spacingLarge),
                      child: _buildFAQContent(typography, spacing),
                    ),
                    
                    // Contact Support Section
                    Container(
                      margin: EdgeInsets.all(spacing.spacingLarge),
                      child: _buildContactSupportSection(typography, spacing),
                    ),
                    
                    SizedBox(height: spacing.spacingLarge * 2),
                    
                    // Footer
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(TypographyConfig typography, SpacingConfig spacing) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: CustomCard(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(spacing.paddingSmall),
                child: CustomInputTransparent4(
                  hintText: 'Search FAQs...',
                  labelText: "Search",
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  prefix: Icon(
                    HugeIcons.strokeRoundedSearch01,
                    color: Constants.ctaColorLight,
                  ),
                  suffix: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            HugeIcons.strokeRoundedCancel01,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  textInputAction: TextInputAction.search,
                  isPasswordField: false,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (value.isEmpty) {
                      _performSearch('');
                    }
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _performSearch(value);
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter(TypographyConfig typography, SpacingConfig spacing) {
    if (_isLoadingCategories) {
      return Center(
        child: CircularProgressIndicator(
          color: Constants.ctaColorLight,
          strokeWidth: 2,
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: spacing.spacingSmall),
                child: Text(
                  'Categories',
                  style: GoogleFonts.manrope(
                    fontSize: typography.medium,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                  ),
                ),
              ),
              Container(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category.label == _selectedCategory;
                    
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: spacing.marginSmall),
                      child: GestureDetector(
                        onTap: () => _onCategoryChanged(category.label),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing.paddingMedium,
                            vertical: spacing.paddingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Constants.ctaColorLight
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected
                                  ? Constants.ctaColorLight
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              category.label,
                              style: GoogleFonts.manrope(
                                color: isSelected ? Colors.white : Colors.grey[700],
                                fontSize: typography.normal,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQContent(TypographyConfig typography, SpacingConfig spacing) {
    if (_isLoading) {
      return Container(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Constants.ctaColorLight,
              strokeWidth: 3,
            ),
            SizedBox(height: spacing.spacingMedium),
            Text(
              'Loading FAQs...',
              style: GoogleFonts.manrope(
                fontSize: typography.medium,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredFAQItems.isEmpty) {
      return _buildEmptyState(typography, spacing);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: spacing.spacingLarge),
          child: Text(
            '${_filteredFAQItems.length} ${_filteredFAQItems.length == 1 ? 'Question' : 'Questions'}',
            style: GoogleFonts.manrope(
              fontSize: typography.medium,
              fontWeight: FontWeight.bold,
              color: Constants.ftaColorLight,
            ),
          ),
        ),
        ...List.generate(_filteredFAQItems.length, (index) {
          final faq = _filteredFAQItems[index];
          return _buildFAQItem(faq, index, typography, spacing);
        }),
      ],
    );
  }

  Widget _buildFAQItem(FAQ faq, int index, TypographyConfig typography, SpacingConfig spacing) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Container(
              margin: EdgeInsets.only(bottom: spacing.spacingMedium),
              child: CustomCard(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.all(spacing.paddingMedium),
                    childrenPadding: EdgeInsets.fromLTRB(
                      spacing.paddingMedium,
                      0,
                      spacing.paddingMedium,
                      spacing.paddingMedium,
                    ),
                    leading: Container(
                      padding: EdgeInsets.all(spacing.paddingSmall),
                      decoration: BoxDecoration(
                        color: Constants.ctaColorLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        HugeIcons.strokeRoundedHelpCircle,
                        color: Constants.ctaColorLight,
                        size: typography.large,
                      ),
                    ),
                    title: Text(
                      faq.question,
                      style: GoogleFonts.manrope(
                        fontSize: typography.medium,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    subtitle: Padding(
                      padding: EdgeInsets.only(top: spacing.spacingSmall / 2),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: spacing.paddingSmall,
                          vertical: spacing.paddingSmall / 2,
                        ),
                        decoration: BoxDecoration(
                          color: Constants.ctaColorLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          faq.categoryDisplay,
                          style: GoogleFonts.manrope(
                            fontSize: typography.normal,
                            color: Constants.ctaColorLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(spacing.paddingMedium),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          faq.answer,
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

  Widget _buildEmptyState(TypographyConfig typography, SpacingConfig spacing) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: EdgeInsets.all(spacing.paddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: value,
                  child: Icon(
                    HugeIcons.strokeRoundedSearchList01,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: spacing.spacingMedium),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No FAQs found for "$_searchQuery"'
                      : _selectedCategory != "All"
                          ? 'No FAQs found in "$_selectedCategory" category'
                          : 'No FAQs available',
                  style: GoogleFonts.manrope(
                    fontSize: typography.subHeading,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.spacingSmall),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Try searching with different keywords'
                      : _selectedCategory != "All"
                          ? 'Try selecting a different category'
                          : 'Check back later for updates',
                  style: GoogleFonts.manrope(
                    fontSize: typography.normal,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isNotEmpty || _selectedCategory != "All") ...[
                  SizedBox(height: spacing.spacingLarge),
                  ElevatedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                      _onCategoryChanged('All');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.paddingLarge,
                        vertical: spacing.paddingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: Icon(HugeIcons.strokeRoundedRefresh),
                    label: Text(
                      'Show All FAQs',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactSupportSection(TypographyConfig typography, SpacingConfig spacing) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: CustomCard(
              elevation: 3,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(spacing.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Constants.ctaColorLight.withOpacity(0.1),
                      Constants.ctaColorLight.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedCustomerSupport,
                      size: 48,
                      color: Constants.ctaColorLight,
                    ),
                    SizedBox(height: spacing.spacingMedium),
                    Text(
                      "Can't find what you're looking for?",
                      style: GoogleFonts.manrope(
                        fontSize: typography.subHeading,
                        fontWeight: FontWeight.bold,
                        color: Constants.ftaColorLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing.spacingSmall),
                    Text(
                      "Our support team is here to help you",
                      style: GoogleFonts.manrope(
                        fontSize: typography.normal,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing.spacingLarge),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to contact support
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.ctaColorLight,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: spacing.paddingMedium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        icon: Icon(HugeIcons.strokeRoundedMail01),
                        label: Text(
                          'Contact Support',
                          style: GoogleFonts.manrope(
                            fontSize: typography.medium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}