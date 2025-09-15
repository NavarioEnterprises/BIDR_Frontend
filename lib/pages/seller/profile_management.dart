import 'package:bidr/constants/Constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../customWdget/custom_input2.dart';
import '../../services/auth_api_service.dart';
import '../../services/shared_preferences.dart';

bool _isProfileLoading = false;
bool _isPasswordLoading = false;

class ProfileManagement extends StatefulWidget {
  const ProfileManagement({Key? key}) : super(key: key);

  @override
  State<ProfileManagement> createState() => _ProfileManagementState();
}

class _ProfileManagementState extends State<ProfileManagement>
    with TickerProviderStateMixin {
  // Main sidebar selection
  String selectedTab = 'Edit Seller Profile';

  // Seller profile sidebar selection
  String selectedSellerTab = 'Personal Details';
  final AuthApiService _authService = AuthApiService();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _sidebarAnimationController;
  late AnimationController _sellerSidebarAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sidebarFadeAnimation;
  late Animation<double> _sellerSidebarSlideAnimation;

  // Controllers (legacy - no longer used)
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  // Controllers for Personal Details
  final TextEditingController personalFullNameController =
      TextEditingController();
  final TextEditingController personalMobileController =
      TextEditingController();
  final TextEditingController personalEmailController = TextEditingController();

  // Controllers for Company Details
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController tradingNameController = TextEditingController();
  final TextEditingController registrationNumberController =
      TextEditingController();
  final TextEditingController vatNumberController = TextEditingController();
  final TextEditingController vatNumber2Controller = TextEditingController();
  final TextEditingController websiteUrlController = TextEditingController();

  // Controllers for Company Address
  final TextEditingController postalAddressController = TextEditingController();
  final TextEditingController physicalAddressController =
      TextEditingController();
  final TextEditingController gpsLocationController = TextEditingController();
  final TextEditingController googleMapsLinkController =
      TextEditingController();
  final TextEditingController contactPersonNameController =
      TextEditingController();
  final TextEditingController contactPersonPhoneController =
      TextEditingController();
  final TextEditingController contactPersonEmailController =
      TextEditingController();
  final TextEditingController workflowEmailController = TextEditingController();

  // Controllers for Company Account
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController bankBranchCodeController =
      TextEditingController();
  final TextEditingController accountTypeController = TextEditingController();
  final TextEditingController bankAccountNumberController =
      TextEditingController();
  final TextEditingController accountHolderController = TextEditingController();

  // Selected values for dropdowns
  String? _selectedBank;
  String? _selectedBranchCode;
  String? _selectedAccountType;

  // South African Banks with branch codes (same as business_signup.dart)
  static const Map<String, String> _southAfricanBanks = {
    'ABSA Bank': '632005',
    'Standard Bank': '051001',
    'First National Bank (FNB)': '250655',
    'Nedbank': '198765',
    'Capitec Bank': '470010',
    'African Bank': '430000',
    'Investec Bank': '580105',
    'Discovery Bank': '679000',
    'TymeBank': '678910',
    'Bidvest Bank': '462005',
    'Sasfin Bank': '683000',
    'Mercantile Bank': '450105',
    'Grindrod Bank': '584000',
    'Ithala Bank': '410506',
    'Bank of Athens': '410010',
    'China Construction Bank': '679001',
    'Habib Overseas Bank': '587000',
    'HBZ Bank': '570000',
    'Albaraka Bank': '800000',
    'Postbank': '460005',
  };

  final List<String> _accountTypes = [
    'Savings',
    'Current',
    'Business',
    'Cheque',
  ];

  // Controllers for Change Password
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Controllers for Displayed On Platform
  final TextEditingController displayTradingNameController =
      TextEditingController();

  // Focus nodes
  final FocusNode fullNameFocus = FocusNode();
  final FocusNode mobileNumberFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();

  // Category selections
  Map<String, bool> categories = {
    'Vehicle Spares': false,
    'Vehicle Tyres and Rims': false,
    'Consumer Electronics': false,
  };

  bool registeredName = false;

  // Seller profile data
  Map<String, dynamic>? sellerProfileData;
  bool isLoadingProfile = false;
  String? profileError;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _sellerSidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _sidebarFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sidebarAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _sellerSidebarSlideAnimation = Tween<double>(begin: -250.0, end: 0.0)
        .animate(
          CurvedAnimation(
            parent: _sellerSidebarAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _sidebarAnimationController.forward();

    // Since 'Edit Seller Profile' is the default, animate the seller sidebar on initial load
    _sellerSidebarAnimationController.forward();

    // Load seller profile data
    _loadSellerProfile();
  }

  @override
  void dispose() {
    // Dispose animation controllers
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _sidebarAnimationController.dispose();
    _sellerSidebarAnimationController.dispose();

    // Dispose all controllers
    fullNameController.dispose();
    mobileNumberController.dispose();
    emailController.dispose();
    personalFullNameController.dispose();
    personalMobileController.dispose();
    personalEmailController.dispose();
    companyNameController.dispose();
    tradingNameController.dispose();
    registrationNumberController.dispose();
    vatNumberController.dispose();
    vatNumber2Controller.dispose();
    websiteUrlController.dispose();
    postalAddressController.dispose();
    physicalAddressController.dispose();
    gpsLocationController.dispose();
    googleMapsLinkController.dispose();
    contactPersonNameController.dispose();
    contactPersonPhoneController.dispose();
    contactPersonEmailController.dispose();
    workflowEmailController.dispose();
    bankNameController.dispose();
    bankAccountNumberController.dispose();
    bankBranchCodeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    displayTradingNameController.dispose();
    fullNameFocus.dispose();
    mobileNumberFocus.dispose();
    emailFocus.dispose();
    super.dispose(); //
  }

  /// Load seller profile data from API
  Future<void> _loadSellerProfile() async {
    setState(() {
      isLoadingProfile = true;
      profileError = null;
    });

    try {
      final response = await _authService.getSellerProfile(
        authUserUid: Constants.myUid,
      );

      if (response['success']) {
        setState(() {
          sellerProfileData = response['data'];
          isLoadingProfile = false;
        });
        _populateFields();
        // Force UI update after populating fields
        setState(() {});
      } else {
        setState(() {
          profileError = response['error'].toString();
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        profileError = 'Failed to load profile: $e';
        isLoadingProfile = false;
      });
    }
  }

  /// Populate form fields with loaded data
  void _populateFields() {
    if (sellerProfileData == null) return;

    // The API returns a flat structure, not nested
    final data = sellerProfileData!;

    // Personal Details - now unencrypted from backend
    final firstName = data['first_name'] ?? '';
    final lastName = data['last_name'] ?? '';
    personalFullNameController.text = '$firstName $lastName'.trim();
    personalMobileController.text = data['phone_number'] ?? '';
    personalEmailController.text = data['email'] ?? '';

    // Company Details
    companyNameController.text = data['registered_company_name'] ?? '';
    tradingNameController.text = data['trading_name'] ?? '';
    registrationNumberController.text = data['registration_number'] ?? '';
    vatNumberController.text = data['vat_number'] ?? '';
    websiteUrlController.text = data['website_url'] ?? '';

    // Company Address
    postalAddressController.text = data['postal_address'] ?? '';
    physicalAddressController.text = data['physical_address'] ?? '';
    gpsLocationController.text = ''; // GPS coordinates not in flat structure
    googleMapsLinkController.text = ''; // Google maps link not in response

    // Contact Information
    contactPersonNameController.text = data['contact_person_name'] ?? '';
    contactPersonPhoneController.text = data['contact_person_telephone'] ?? '';
    contactPersonEmailController.text = data['contact_person_email'] ?? '';
    workflowEmailController.text = data['platform_workflow_email'] ?? '';

    // Banking Information - retrieve from banking_info in API response
    final bankingInfo = data['banking_info'] ?? {};
    bankNameController.text = bankingInfo['bank_name'] ?? '';
    bankAccountNumberController.text = bankingInfo['account_number'] ?? '';
    bankBranchCodeController.text = bankingInfo['branch_code'] ?? '';
    accountTypeController.text = bankingInfo['account_type'] ?? '';
    accountHolderController.text = bankingInfo['account_holder'] ?? '';

    // Sync dropdown state variables with loaded data
    if (bankingInfo['bank_name'] != null &&
        bankingInfo['bank_name'].toString().isNotEmpty) {
      _selectedBank = bankingInfo['bank_name'];
    }
    if (bankingInfo['branch_code'] != null &&
        bankingInfo['branch_code'].toString().isNotEmpty) {
      _selectedBranchCode = bankingInfo['branch_code'];
    }
    if (bankingInfo['account_type'] != null &&
        bankingInfo['account_type'].toString().isNotEmpty) {
      _selectedAccountType = bankingInfo['account_type'];
    }

    // Display preferences
    displayTradingNameController.text = data['trading_name'] ?? '';
    registeredName = false; // Default since display preference not in response

    // Categories - handle both product_category and product_subcategory
    final productCategory = data['product_category'];
    final productSubcategory = data['product_subcategory'];

    // Reset all categories first
    categories.forEach((key, value) {
      categories[key] = false;
    });

    // Handle main categories from product_category
    if (productCategory != null && productCategory.toString().isNotEmpty) {
      final categoryList = productCategory
          .toString()
          .split(',')
          .map((e) => e.trim())
          .toList();
      print('Processing category list: $categoryList');

      for (String category in categoryList) {
        print('Checking if category "$category" exists in categories map...');
        if (categories.containsKey(category)) {
          categories[category] = true;
          print('✓ Set "$category" to true');
        } else {
          print('✗ Category "$category" not found in categories map');
        }
      }
    }

    // Handle subcategory mapping for specific parts
    if (productSubcategory != null) {
      print('Processing subcategory: $productSubcategory');
      categories.forEach((key, value) {
        if (_mapBackendCategoryToFrontend(productSubcategory, key)) {
          categories[key] = true;
          print(
            '✓ Set subcategory "$key" to true based on "$productSubcategory"',
          );
        }
      });
    }

    print('Fields populated successfully');
    print('Company name: ${companyNameController.text}');
    print('Trading name: ${tradingNameController.text}');
    print('Registration number: ${registrationNumberController.text}');
    print('VAT number: ${vatNumberController.text}');
    print('Banking info - Bank name: ${bankNameController.text}');
    print('Banking info - Account number: ${bankAccountNumberController.text}');
    print('Banking info - Branch code: ${bankBranchCodeController.text}');
    print('Banking info - Account type: ${accountTypeController.text}');
    print('Banking info - Account holder: ${accountHolderController.text}');
    print('Product category: $productCategory');
    print('Product subcategory: $productSubcategory');
    print('Banking info from API: ${data['banking_info']}');
    print(
      'Selected categories: ${categories.entries.where((e) => e.value).map((e) => e.key).toList()}',
    );
  }

  bool _mapBackendCategoryToFrontend(
    String backendCategory,
    String frontendCategory,
  ) {
    final mappings = {
      'engine_parts': 'Engine Parts',
      'body_parts': 'Body Parts',
      'suspension_parts': 'Suspension Parts',
      'transmission_parts': 'Transmission Parts',
      'batteries': 'Batteries',
      'vehicle_spares': 'Vehicle Spares', // Map to the main category
      'tyres_rims': 'Vehicle Tyres and Rims',
      'consumer_electronics': 'Consumer Electronics',
    };
    return mappings[backendCategory] == frontendCategory;
  }

  /// Handle save action based on current section
  void _handleSaveAction() {
    switch (selectedSellerTab) {
      case 'Personal Details':
        _savePersonalDetails();
        break;
      case 'Company Details':
        _saveCompanyDetails();
        break;
      case 'Company Address':
        _saveCompanyAddress();
        break;
      case 'Company Account':
        _saveCompanyAccount();
        break;
      case 'Company Categories':
        _saveCompanyCategories();
        break;
      case 'Displayed On Platform':
        _saveDisplayedOnPlatform();
        break;
      default:
        _saveGeneralProfile();
    }
  }

  /// Save personal details
  Future<void> _savePersonalDetails() async {
    final names = personalFullNameController.text.split(' ');
    final userData = {
      'first_name': names.isNotEmpty ? names[0] : '',
      'last_name': names.length > 1 ? names.sublist(1).join(' ') : '',
      'phone_number': personalMobileController.text,
      'email': personalEmailController.text,
    };

    await _updateSellerInfo('Personal Details', userData);
  }

  /// Save company details
  Future<void> _saveCompanyDetails() async {
    final sellerData = {
      'registered_company_name': companyNameController.text,
      'trading_name': tradingNameController.text,
      'registration_number': registrationNumberController.text,
      'vat_number': vatNumberController.text,
      'website_url': websiteUrlController.text,
    };

    await _updateSellerInfo('Company Details', sellerData);
  }

  /// Save company address
  Future<void> _saveCompanyAddress() async {
    final addressAndContactData = {
      'postal_address': postalAddressController.text,
      'physical_address': physicalAddressController.text,
      'contact_person_name': contactPersonNameController.text,
      'contact_person_telephone': contactPersonPhoneController.text,
      'contact_person_email': contactPersonEmailController.text,
      'platform_workflow_email': workflowEmailController.text,
    };

    await _updateSellerInfo('Company Address', addressAndContactData);
  }

  /// Save company account (banking info)
  Future<void> _saveCompanyAccount() async {
    // For now, banking info is not fully integrated with the backend
    // Show success message and store locally
    final bankingData = {
      'bank_name': bankNameController.text,
      'account_number': bankAccountNumberController.text,
      'branch_code': bankBranchCodeController.text,
      'account_type': accountTypeController.text,
      'account_holder': accountHolderController.text,
    };

    // TODO: Integrate with proper banking info endpoint when available
    // For now, just show success message
    _showSuccessSnackBar('Company Account information saved locally');

    if (kDebugMode) {
      print('Banking info to be saved: $bankingData');
    }
  }

  /// Save company categories
  Future<void> _saveCompanyCategories() async {
    final selectedCategories = categories.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key) // Use the frontend category names
        .toList();

    final selectedBackendCategories = categories.entries
        .where((entry) => entry.value)
        .map((entry) => _mapFrontendCategoryToBackend(entry.key))
        .toList();

    final categoryData = {
      'product_category': selectedCategories.isNotEmpty
          ? selectedCategories.join(', ')
          : null,
      'product_subcategory': selectedBackendCategories.isNotEmpty
          ? selectedBackendCategories.first
          : null,
    };

    if (kDebugMode) {
      print('Saving categories - Frontend: $selectedCategories');
      print('Saving categories - Backend: $selectedBackendCategories');
      print('Category data to save: $categoryData');
    }

    await _updateSellerInfo('Company Categories', categoryData);
  }

  /// Save displayed on platform preferences
  Future<void> _saveDisplayedOnPlatform() async {
    final sellerData = {'trading_name': displayTradingNameController.text};

    final profileData = {
      'display_name_preference': registeredName ? 'registered' : 'trading',
    };

    await _updateSellerInfo('Display Preferences', sellerData);
    await _updateProfile('Display Preferences', profileData);
  }

  /// Save general profile (fallback)
  Future<void> _saveGeneralProfile() async {
    _showSuccessSnackBar('Profile saved successfully');
  }

  /// Update seller basic information
  Future<void> _updateSellerInfo(
    String section,
    Map<String, dynamic> data,
  ) async {
    try {
      setState(() => isLoadingProfile = true);

      final response = await _authService.updateSellerBasicInfo(
        authUserUid: Constants.myUid,
        sellerData: data,
      );

      if (response['success']) {
        _showSuccessSnackBar('$section updated successfully');
        await _loadSellerProfile(); // Reload to get updated data
      } else {
        _showErrorSnackBar('Failed to update $section: ${response['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating $section: $e');
    } finally {
      setState(() => isLoadingProfile = false);
    }
  }

  /// Update profile information
  Future<void> _updateProfile(String section, Map<String, dynamic> data) async {
    try {
      if (sellerProfileData?['profile']?['id'] == null) {
        _showErrorSnackBar('Profile ID not found');
        return;
      }

      setState(() => isLoadingProfile = true);

      final response = await _authService.updateSellerProfile(
        profileId: sellerProfileData!['profile']['id'],
        profileData: data,
      );

      if (response['success']) {
        _showSuccessSnackBar('$section updated successfully');
        await _loadSellerProfile(); // Reload to get updated data
      } else {
        _showErrorSnackBar('Failed to update $section: ${response['error']}');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating $section: $e');
    } finally {
      setState(() => isLoadingProfile = false);
    }
  }

  String _mapFrontendCategoryToBackend(String frontendCategory) {
    final mappings = {
      'Vehicle Spares': 'vehicle_spares',
      'Vehicle Tyres and Rims': 'tyres_rims',
      'Consumer Electronics': 'consumer_electronics',
      'Engine Parts': 'engine_parts',
      'Body Parts': 'body_parts',
      'Suspension Parts': 'suspension_parts',
      'Transmission Parts': 'transmission_parts',
      'Batteries': 'batteries',
    };
    return mappings[frontendCategory] ?? 'vehicle_spares';
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onMenuItemSelected(String menuItem) {
    if (selectedTab != menuItem) {
      setState(() {
        selectedTab = menuItem;
      });

      // Restart animations for content change
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();

      // Handle seller sidebar animation
      if (menuItem == 'Edit Seller Profile') {
        _sellerSidebarAnimationController.forward();
      } else {
        _sellerSidebarAnimationController.reverse();
      }
    }
  }

  void _onSellerMenuItemSelected(String menuItem) {
    if (selectedSellerTab != menuItem) {
      setState(() {
        selectedSellerTab = menuItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Sidebar
          FadeTransition(
            opacity: _sidebarFadeAnimation,
            child: Container(
              width: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Constants.ftaColorLight,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    'Edit Seller Profile',
                    HugeIcons.strokeRoundedEdit02,
                  ),
                  _buildMenuItem(
                    'Change Password',
                    HugeIcons.strokeRoundedResetPassword,
                  ),
                  _buildMenuItem('Get Quotes', HugeIcons.strokeRoundedQuotes),
                  _buildMenuItem(
                    'Message Board',
                    HugeIcons.strokeRoundedMessage01,
                  ),
                  _buildMenuItem(
                    'Delete Account',
                    HugeIcons.strokeRoundedDelete01,
                  ),
                  _buildMenuItem('Sign Out', HugeIcons.strokeRoundedLogout01),
                ],
              ),
            ),
          ),

          // Second Sidebar (for Edit Seller Profile)
          if (selectedTab == 'Edit Seller Profile')
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 8),
              child: AnimatedBuilder(
                animation: _sellerSidebarSlideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_sellerSidebarSlideAnimation.value, 0),
                    child: Container(
                      width: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: Constants.ctaColorLight,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildSellerMenuItem(
                            'Personal Details',
                            HugeIcons.strokeRoundedEditUser02,
                          ),
                          _buildSellerMenuItem(
                            'Company Details',
                            HugeIcons.strokeRoundedBuilding02,
                          ),
                          _buildSellerMenuItem(
                            'Company Address',
                            HugeIcons.strokeRoundedLocation01,
                          ),
                          _buildSellerMenuItem(
                            'Company Account',
                            HugeIcons.strokeRoundedPayment01,
                          ),
                          _buildSellerMenuItem(
                            'Company Categories',
                            HugeIcons.strokeRoundedCatalogue,
                          ),
                          _buildSellerMenuItem(
                            'Displayed On Platform',
                            HugeIcons.strokeRoundedWork,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Main Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    bool isDestructive = false,
  }) {
    final bool isSelected = selectedTab == title;
    final bool isSignOutSelected = title == "Sign Out";
    final bool isDeleteSelected = title == "Delete Account";
    final Color textColor = isSignOutSelected
        ? Colors.red.shade700
        : isDeleteSelected
        ? Constants.ctaColorLight
        : isSelected
        ? Colors.white
        : Colors.blueAccent.withOpacity(0.5);
    final Color backgroundColor = isSelected
        ? Colors.white.withOpacity(0.1)
        : Colors.transparent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(360),
          ),
          child: Transform.scale(
            scale: 1 + (value * 0.02),
            child: ListTile(
              leading: Icon(icon, color: textColor, size: 20),

              title: Text(
                title,
                style: GoogleFonts.manrope(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
              onTap: () => _onMenuItemSelected(title),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSellerMenuItem(
    String title,
    IconData icon, {
    bool isDestructive = false,
  }) {
    final bool isSelected = selectedSellerTab == title;
    final Color textColor = isDestructive
        ? Constants.ftaColorLight.withOpacity(0.55)
        : isSelected
        ? Colors.white
        : Constants.ftaColorLight.withOpacity(0.55);
    final Color backgroundColor = isSelected
        ? Constants.ftaColorLight
        : Colors.transparent;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),

          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(360),
          ),
          child: Transform.scale(
            scale: 1 + (value * 0.02),
            child: ListTile(
              leading: Icon(icon, color: textColor, size: 20),
              title: Text(
                title,
                style: GoogleFonts.manrope(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
              onTap: () => _onSellerMenuItemSelected(title),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSellerSidebarItem(String title) {
    bool isSelected = selectedSellerTab == title;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isSelected ? 1 : 0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return InkWell(
          onTap: () {
            setState(() {
              selectedSellerTab = title;
            });
            // Trigger content animation
            _fadeController.reset();
            _slideController.reset();
            _fadeController.forward();
            _slideController.forward();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Transform.translate(
              offset: Offset(value * 5, 0),
              child: Text(
                title,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    switch (selectedTab) {
      case 'Edit Seller Profile':
        return _buildSellerProfileContent();
      case 'Change Password':
        return _buildChangePassword();
      case 'Get Quotes':
        return _buildComingSoonWidget(
          title: 'Get Quotes',
          subtitle:
              'View and manage all quotes received from suppliers in one place',
          icon: HugeIcons.strokeRoundedQuotes,
        );
      case 'Message Board':
        return _buildComingSoonWidget(
          title: 'Message Board',
          subtitle:
              'Connect with customers and manage communications in one place',
          icon: HugeIcons.strokeRoundedMessage01,
        );
      case 'Delete Account':
        return Center(
          child: Text(
            'Delete Account Content',
            style: GoogleFonts.manrope(fontSize: 24),
          ),
        );
      case 'Sign Out':
        return _buildSignOutContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSignOutContent() {
    return Container(
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign Out',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign out from your account',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedInformationCircle,
                      color: Colors.orange[600],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Are you sure you want to sign out?',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'You will be redirected to the login screen and will need to enter your credentials to access your account again.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onMenuItemSelected('Edit Seller Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Constants.ftaColorLight,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(360),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(360),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Profile',
          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 40),
        _buildAnimatedInputField(
          'Full Name',
          'Enter Full Name',
          fullNameController,
          fullNameFocus,
          TextInputAction.next,
          0,
        ),
        const SizedBox(height: 20),
        _buildAnimatedInputField(
          'Mobile Number',
          'Enter Mobile Number',
          mobileNumberController,
          mobileNumberFocus,
          TextInputAction.next,
          1,
        ),
        const SizedBox(height: 20),
        _buildAnimatedInputField(
          'Email',
          'Enter Email',
          emailController,
          emailFocus,
          TextInputAction.done,
          2,
        ),
        const SizedBox(height: 40),
        _buildAnimatedSaveButton(3),
      ],
    );
  }

  Widget _buildSellerProfileContent() {
    // Show loading state
    if (isLoadingProfile && sellerProfileData == null) {
      return Container(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Constants.ftaColorLight,
              ),
              SizedBox(height: 16),
              Text(
                'Loading profile data...',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (profileError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Text(
              profileError!,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: _loadSellerProfile, child: Text('Retry')),
          ],
        ),
      );
    }

    // Show content
    switch (selectedSellerTab) {
      case 'Personal Details':
        return _buildPersonalDetails();
      case 'Company Details':
        return _buildCompanyDetails();
      case 'Company Address':
        return _buildCompanyAddress();
      case 'Company Account':
        return _buildCompanyAccount();
      case 'Company Categories':
        return _buildCompanyCategories();
      case 'Displayed On Platform':
        return _buildDisplayedOnPlatform();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPersonalDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Details',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          _buildAnimatedInputField(
            'Full Name',
            'Enter Full Name',
            personalFullNameController,
            FocusNode(),
            TextInputAction.next,
            0,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Mobile Number',
            'Enter Mobile Number',
            personalMobileController,
            FocusNode(),
            TextInputAction.next,
            1,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Email',
            'Enter Email',
            personalEmailController,
            FocusNode(),
            TextInputAction.done,
            2,
          ),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(3),
        ],
      ),
    );
  }

  Widget _buildCompanyDetails() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Details',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          _buildAnimatedInputField(
            'Registered Company Name (CIPC)*',
            'Enter Registered Company Name',
            companyNameController,
            FocusNode(),
            TextInputAction.next,
            0,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Trading Name',
            'Enter Company Trading Name',
            tradingNameController,
            FocusNode(),
            TextInputAction.next,
            1,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Registration Number',
            'Enter Registration Number',
            registrationNumberController,
            FocusNode(),
            TextInputAction.next,
            2,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'VAT Number',
            'Enter VAT Number',
            vatNumberController,
            FocusNode(),
            TextInputAction.next,
            3,
          ),

          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Website URL',
            'Enter Website URL',
            websiteUrlController,
            FocusNode(),
            TextInputAction.done,
            5,
          ),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(6),
        ],
      ),
    );
  }

  Widget _buildCompanyAddress() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Address',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          _buildAnimatedInputField(
            'Postal Address',
            'Enter Postal Address',
            postalAddressController,
            FocusNode(),
            TextInputAction.next,
            0,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Physical Address',
            'Enter Physical Address',
            physicalAddressController,
            FocusNode(),
            TextInputAction.next,
            1,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'GPS Location',
            'Enter GPS Location',
            gpsLocationController,
            FocusNode(),
            TextInputAction.next,
            2,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Google Maps Link',
            'Enter Google Maps Link',
            googleMapsLinkController,
            FocusNode(),
            TextInputAction.next,
            3,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Contact Person Name',
            'Enter Contact Person Name',
            contactPersonNameController,
            FocusNode(),
            TextInputAction.next,
            4,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Contact Person Telephone',
            'Enter Contact Person Telephone',
            contactPersonPhoneController,
            FocusNode(),
            TextInputAction.next,
            5,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Contact Person Email Address',
            'Enter Contact Person Email Address',
            contactPersonEmailController,
            FocusNode(),
            TextInputAction.next,
            6,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Platform Workflow Email Address',
            'Enter Contact Person Email Address',
            workflowEmailController,
            FocusNode(),
            TextInputAction.done,
            7,
          ),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(8),
        ],
      ),
    );
  }

  Widget _buildCompanyAccount() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Account',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),

          // 1. Bank Name (dropdown)
          _buildAnimatedBankDropdownField('Bank Name*', 'Select Bank', 0),
          const SizedBox(height: 20),

          // 2. Branch Code (auto-populated, read-only)
          _buildAnimatedBranchCodeField(
            'Branch Code*',
            'Select a bank first',
            1,
          ),
          const SizedBox(height: 20),

          // 3. Account Type (dropdown)
          _buildAnimatedAccountTypeDropdownField(
            'Account Type*',
            'Select Account Type',
            2,
          ),
          const SizedBox(height: 20),

          // 4. Account Number
          _buildAnimatedInputField(
            'Account Number*',
            'Enter Account Number',
            bankAccountNumberController,
            FocusNode(),
            TextInputAction.next,
            3,
          ),
          const SizedBox(height: 20),

          // 5. Account Holder Name
          _buildAnimatedInputField(
            'Account Holder Name*',
            'Enter Account Holder Name',
            accountHolderController,
            FocusNode(),
            TextInputAction.done,
            4,
          ),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(5),
        ],
      ),
    );
  }

  Widget _buildCompanyCategories() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Categories',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          ...categories.entries.toList().asMap().entries.map(
            (entry) => _buildAnimatedCategoryCheckbox(
              entry.value.key,
              entry.value.value,
              entry.key,
            ),
          ),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(categories.length),
        ],
      ),
    );
  }

  Widget _buildDisplayedOnPlatform() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Displayed On Platform',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),

          _buildAnimatedInputField(
            'Trading Name',
            'Enter Trading Name',
            displayTradingNameController,
            FocusNode(),
            TextInputAction.done,
            1,
          ),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(2),
        ],
      ),
    );
  }

  Widget _buildChangePassword() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Change Password',
          style: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 40),
        _buildAnimatedInputField(
          'New Password',
          'Enter New Password',
          newPasswordController,
          FocusNode(),
          TextInputAction.next,
          0,
          isPassword: true,
        ),
        const SizedBox(height: 20),
        _buildAnimatedInputField(
          'Confirm Password',
          'Enter Confirm Password',
          confirmPasswordController,
          FocusNode(),
          TextInputAction.done,
          1,
          isPassword: true,
        ),
        const SizedBox(height: 40),
        _buildAnimatedSaveButton(2),
      ],
    );
  }

  Widget _buildAnimatedCategoryCheckbox(
    String category,
    bool value,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset((1 - animation) * 30, 0),
          child: Opacity(
            opacity: animation,
            child: _buildCategoryCheckbox(category, value),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCheckbox(String category, bool value) {
    return Container(
      width: MediaQuery.of(context).size.height * 0.5,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Constants.ftaColorLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            shape: const CircleBorder(),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Constants.ctaColorLight;
              }
              return null;
            }),
          ),
        ),
        child: CheckboxListTile(
          title: Text(
            category,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          value: value,
          onChanged: (bool? newValue) {
            setState(() {
              categories[category] = newValue ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.trailing,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildAnimatedCheckboxField(
    String label,
    bool value,
    Function(bool?) onChanged,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset((1 - animation) * 30, 0),
          child: Opacity(
            opacity: animation,
            child: _buildCheckboxField(label, value, onChanged),
          ),
        );
      },
    );
  }

  Widget _buildCheckboxField(
    String label,
    bool value,
    Function(bool?) onChanged,
  ) {
    return Container(
      width: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Constants.ftaColorLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            shape: const CircleBorder(),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Constants.ctaColorLight;
              }
              return null;
            }),
          ),
        ),
        child: CheckboxListTile(
          title: Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.trailing,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildAnimatedDropdownField(String label, String hint, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset((1 - animation) * 30, 0),
          child: Opacity(
            opacity: animation,
            child: _buildDropdownField(label, hint),
          ),
        );
      },
    );
  }

  Widget _buildDropdownField(String label, String hint) {
    // Create a controller for the dropdown display
    final dropdownController = TextEditingController();
    final accountTypes = ['Savings', 'Current', 'Business', 'Cheque'];
    String? selectedAccountType;

    return GestureDetector(
      onTap: () => _showAccountTypeSelectionDialog(
        dropdownController,
        accountTypes,
        selectedAccountType,
      ),
      child: AbsorbPointer(
        child: CustomInputTransparent4(
          hintText: hint,
          labelText: label,
          controller: dropdownController,
          focusNode: FocusNode(),
          textInputAction: TextInputAction.next,
          isPasswordField: false,
          isEditable: false,
          onChanged: (value) {
            // Handled by dialog
          },
          onSubmitted: (value) {
            // Handled by dialog
          },
          suffix: Icon(Icons.arrow_drop_down, color: const Color(0xFF666666)),
        ),
      ),
    );
  }

  void _showAccountTypeSelectionDialog(
    TextEditingController controller,
    List<String> options,
    String? selectedValue,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: 300,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Account Type',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      String option = options[index];
                      bool isSelected = selectedValue == option;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            controller.text = option;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Constants.ctaColorLight.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: GoogleFonts.manrope(
                                    color: isSelected
                                        ? Constants.ctaColorLight
                                        : const Color(0xFF333333),
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: Constants.ctaColorLight,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // New animated dropdown methods for Company Account section
  Widget _buildAnimatedBankDropdownField(String label, String hint, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset((1 - animation) * 30, 0),
          child: Opacity(
            opacity: animation,
            child: _buildBankDropdownField(label, hint),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBranchCodeField(String label, String hint, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset((1 - animation) * 30, 0),
          child: Opacity(
            opacity: animation,
            child: _buildBranchCodeField(label, hint),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedAccountTypeDropdownField(
    String label,
    String hint,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset((1 - animation) * 30, 0),
          child: Opacity(
            opacity: animation,
            child: _buildAccountTypeDropdownField(label, hint),
          ),
        );
      },
    );
  }

  Widget _buildBankDropdownField(String label, String hint) {
    // Only update if _selectedBank is not null and different from current value
    if (_selectedBank != null && _selectedBank != bankNameController.text) {
      print(
        'Updating bank name controller from $_selectedBank to ${bankNameController.text}',
      );
      bankNameController.text = _selectedBank!;
    }

    if (kDebugMode) {
      print(
        'Bank dropdown field - _selectedBank: $_selectedBank, controller: ${bankNameController.text}',
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.35,
      child: GestureDetector(
        onTap: () => _showBankSelectionDialogProfile(),
        child: AbsorbPointer(
          child: CustomInputTransparent4(
            hintText: hint,
            labelText: label,
            controller: bankNameController,
            focusNode: FocusNode(),
            textInputAction: TextInputAction.next,
            isPasswordField: false,
            isEditable: false,
            onChanged: (value) {
              // Handled by dialog
            },
            onSubmitted: (value) {
              // Handled by dialog
            },
            suffix: Icon(Icons.arrow_drop_down, color: const Color(0xFF666666)),
          ),
        ),
      ),
    );
  }

  Widget _buildBranchCodeField(String label, String hint) {
    // Only update if _selectedBranchCode is not null and different from current value
    if (_selectedBranchCode != null &&
        _selectedBranchCode != bankBranchCodeController.text) {
      print(
        'Updating branch code controller from $_selectedBranchCode to ${bankBranchCodeController.text}',
      );
      bankBranchCodeController.text = _selectedBranchCode!;
    }

    if (kDebugMode) {
      print(
        'Branch code field - _selectedBranchCode: $_selectedBranchCode, controller: ${bankBranchCodeController.text}',
      );
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.35,
      child: CustomInputTransparent4(
        hintText: hint,
        labelText: label,
        controller: bankBranchCodeController,
        focusNode: FocusNode(),
        textInputAction: TextInputAction.next,
        isPasswordField: false,
        isEditable: false,
        onChanged: (value) {
          // Read-only field
        },
        onSubmitted: (value) {
          // Read-only field
        },
      ),
    );
  }

  Widget _buildAccountTypeDropdownField(String label, String hint) {
    // Only update if _selectedAccountType is not null and different from current value
    if (_selectedAccountType != null && _selectedAccountType != accountTypeController.text) {
      print('Updating account type controller from $_selectedAccountType to ${accountTypeController.text}');
      accountTypeController.text = _selectedAccountType!;
    }
    
    if (kDebugMode) {
      print('Account type field - _selectedAccountType: $_selectedAccountType, controller: ${accountTypeController.text}');
    }
    
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.35,
      child: GestureDetector(
        onTap: () => _showAccountTypeSelectionDialogProfile(),
        child: AbsorbPointer(
          child: CustomInputTransparent4(
            hintText: hint,
            labelText: label,
            controller: accountTypeController,
            focusNode: FocusNode(),
            textInputAction: TextInputAction.next,
            isPasswordField: false,
            isEditable: false,
            onChanged: (value) {
              // Handled by dialog
            },
            onSubmitted: (value) {
              // Handled by dialog
            },
            suffix: Icon(Icons.arrow_drop_down, color: const Color(0xFF666666)),
          ),
        ),
      ),
    );
  }

  void _showBankSelectionDialogProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: 400,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Bank',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _southAfricanBanks.keys.length,
                    itemBuilder: (context, index) {
                      String bank = _southAfricanBanks.keys.elementAt(index);
                      bool isSelected = _selectedBank == bank;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBank = bank;
                            _selectedBranchCode = _southAfricanBanks[bank];
                            bankNameController.text = bank;
                            bankBranchCodeController.text =
                                _selectedBranchCode ?? '';
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Constants.ctaColorLight.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bank,
                                  style: GoogleFonts.manrope(
                                    color: isSelected
                                        ? Constants.ctaColorLight
                                        : const Color(0xFF333333),
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: Constants.ctaColorLight,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAccountTypeSelectionDialogProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: 300,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Account Type',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _accountTypes.length,
                    itemBuilder: (context, index) {
                      String accountType = _accountTypes[index];
                      bool isSelected = _selectedAccountType == accountType;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAccountType = accountType;
                            accountTypeController.text = accountType;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Constants.ctaColorLight.withOpacity(0.1)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  accountType,
                                  style: GoogleFonts.manrope(
                                    color: isSelected
                                        ? Constants.ctaColorLight
                                        : const Color(0xFF333333),
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: Constants.ctaColorLight,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSaveButton(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.01, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation.clamp(0.0, 1.0),
          child: Opacity(
            opacity: animation.clamp(0.0, 1.0),
            child: _buildSaveButton(),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.35,
      child: ElevatedButton(
        onPressed: isLoadingProfile ? null : () => _handleSaveAction(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.ctaColorLight,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(360),
          ),
        ),
        child: Text(
          'Save Changes',
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInputField(
    String label,
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    TextInputAction textInputAction,
    int index, {
    bool isPassword = false,
    int maxLines = 1,
    final Function(String)? onSubmitted,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset((1 - animation) * 30, 0),
          child: Opacity(
            opacity: animation,
            child: _buildCustomInputField(
              label,
              hintText,
              controller,
              focusNode,
              textInputAction,
              isPassword: isPassword,
              maxLines: maxLines,
              onSubmitted: onSubmitted,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomInputField(
    String label,
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    TextInputAction textInputAction, {
    bool isPassword = false,
    int maxLines = 1,
    final Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.35,
      child: CustomInputTransparent4(
        hintText: hintText,
        labelText: hintText,
        controller: controller,
        focusNode: focusNode,
        textInputAction: focusNode != null
            ? TextInputAction.next
            : TextInputAction.done,
        isPasswordField: false,
        onChanged: (value) {},
        onSubmitted: onSubmitted ?? (value) {},
      ),
    );
  }
  /*Widget _buildCustomInputField(
    String label,
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    TextInputAction textInputAction, {
    bool isPassword = false,
    int maxLines = 1,
    VoidCallback? onSubmitted,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.height * 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(
                label == "Message" || label == "Project Details" ? 12 : 360,
              ),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: textInputAction,
              obscureText: isPassword,
              maxLines: maxLines,
              onFieldSubmitted: (_) => onSubmitted?.call(),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.manrope(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          // obscureText ? Icons.visibility : Icons.visibility_off,
                          Icons.visibility,
                          color: Colors.grey[500],
                        ),
                        onPressed: () {
                          setState(() {
                            // Toggle password visibility
                          });
                        },
                      )
                    : null,
              ),
              style: GoogleFonts.manrope(fontWeight: FontWeight.w300),
            ),
          ),
        ],
      ),
    );
  }*/

  void _signOut() async {
    setState(() {
      _isPasswordLoading = true; // Reuse this loading state
    });

    try {
      final accessToken =
          await Sharedprefs.getUserAccessTokenSharedPreference();
      final refreshToken =
          await Sharedprefs.getUserRefreshTokenSharedPreference();

      if (accessToken != null && refreshToken != null) {
        // Call API to logout

        await _authService.signOut(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      // Clear all user data regardless of API response
      await _clearAllUserData();

      // Show success message and navigate to login
      _showSuccessDialog(
        title: 'Sign Out',
        message: 'Are you sure you would like to signed out.',
        icon: Icons.logout,
        color: Constants.ctaColorLight,
        additionalInfo:
            'After this action you will be redirected to the home screen.',
        onContinue: () {
          // Navigate to login screen
          context.go('/getstarted');
        },
      );
    } catch (e) {
      // Even if API call fails, clear local data and sign out
      await _clearAllUserData();
      if (mounted) {
        context.go('/getstarted');
      }
    } finally {
      setState(() {
        _isPasswordLoading = false;
      });
    }
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(HugeIcons.strokeRoundedAlert02, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(
              'Delete Account',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you absolutely sure you want to delete your account?',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action will permanently remove:',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• Your profile and personal information',
                  style: GoogleFonts.manrope(fontSize: 14),
                ),
                Text(
                  '• All your product requests and quotes',
                  style: GoogleFonts.manrope(fontSize: 14),
                ),
                Text(
                  '• Transaction history and reviews',
                  style: GoogleFonts.manrope(fontSize: 14),
                ),
                Text(
                  '• Chat messages and communications',
                  style: GoogleFonts.manrope(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                '⚠️ This action cannot be undone!',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performAccountDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete Account',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _performAccountDeletion() async {
    setState(() {
      _isPasswordLoading = true; // Reuse this loading state
    });

    try {
      final accessToken =
          await Sharedprefs.getUserAccessTokenSharedPreference();
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorDialog(
          'Authentication Error',
          'Please log in again to delete your account.',
        );
        return;
      }

      final response = await _authService.deleteAccount(
        accessToken: accessToken,
      );

      if (response != null && response['success'] == true) {
        // Clear all shared preferences
        await _clearAllUserData();

        // Show success dialog and navigate to login
        _showSuccessDialog(
          title: 'Account Deleted',
          message: 'Your account has been permanently deleted.',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          additionalInfo:
              'Thank you for using BIDR. You will be redirected to the login screen.',
          onContinue: () {
            // Navigate to login screen
            context.go('/');
          },
        );
      } else {
        final errorMessage =
            response?['error']?.toString() ?? 'Failed to delete account';
        _showErrorDialog('Deletion Failed', errorMessage);
      }
    } catch (e) {
      _showErrorDialog(
        'Error',
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      setState(() {
        _isPasswordLoading = false;
      });
    }
  }

  Future<void> _clearAllUserData() async {
    // Clear all shared preferences
    await Sharedprefs.saveUserLoggedInSharedPreference(false);
    await Sharedprefs.saveUserAccessTokenSharedPreference('');
    await Sharedprefs.saveUserRefreshTokenSharedPreference('');
    await Sharedprefs.saveUserIdSharedPreference(-1);
    await Sharedprefs.saveUserUidSharedPreference('');
    await Sharedprefs.saveUserEmailSharedPreference('');
    await Sharedprefs.saveUserNameSharedPreference('');
    await Sharedprefs.saveUserRoleSharedPreference('');
    await Sharedprefs.saveUserCellSharedPreference('');
    await Sharedprefs.saveBusinessIdSharedPreference(-1);
    await Sharedprefs.saveBusinessUidSharedPreference('');
    await Sharedprefs.saveBusinessNameSharedPreference('');
    await Sharedprefs.saveBusinessEmailSharedPreference('');
    await Sharedprefs.saveBusinessPhoneNumberSharedPreference('');

    // Clear global constants
    Constants.myUid = '';
    Constants.userId = -1;
    Constants.myCell = '';
    Constants.myDisplayname = '';
    Constants.myCategoryRole = '';
    Constants.myUsername = '';
    Constants.myEmail = '';
    Constants.business_name = '';
    Constants.business_email = '';
    Constants.business_phone_number = '';
    Constants.business_id = -1;
    Constants.business_uid = '';
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 300),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 350,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            HugeIcons.strokeRoundedAlert02,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            color: Color(0xFF4A5568),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Got it',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String? additionalInfo,
    VoidCallback? onContinue,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder(
            duration: const Duration(milliseconds: 400),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          spreadRadius: 0,
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Success Icon
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double iconValue, child) {
                            return Transform.scale(
                              scale: iconValue,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(icon, color: color, size: 40),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Success Title
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 500),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double textValue, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - textValue)),
                              child: Opacity(
                                opacity: textValue,
                                child: Text(
                                  title,
                                  style: GoogleFonts.manrope(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3748),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Success Message
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 700),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double messageValue, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - messageValue)),
                              child: Opacity(
                                opacity: messageValue,
                                child: Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    color: Color(0xFF4A5568),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Additional Info (if provided)
                        if (additionalInfo != null) ...[
                          const SizedBox(height: 20),
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double infoValue, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - infoValue)),
                                child: Opacity(
                                  opacity: infoValue,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: color.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          HugeIcons
                                              .strokeRoundedInformationCircle,
                                          color: color,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            additionalInfo,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: color.withOpacity(0.8),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Action Buttons
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 900),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double buttonValue, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - buttonValue)),
                              child: Opacity(
                                opacity: buttonValue,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey[600],
                                          side: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Close',
                                          style: GoogleFonts.manrope(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                          onContinue?.call();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: color,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          'Continue',
                                          style: GoogleFonts.manrope(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildComingSoonWidget({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: 500),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon container
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1500),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Constants.ctaColorLight,
                            Constants.ctaColorLight.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Constants.ctaColorLight.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: icon,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 32),

              // Coming Soon badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Constants.ctaColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Constants.ctaColorLight.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'COMING SOON',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Constants.ctaColorLight,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Title
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Subtitle
              Container(
                constraints: BoxConstraints(maxWidth: 500),
                child: Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 40),

              // Progress indicator
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          HugeIcons.strokeRoundedTimer01,
                          size: 20,
                          color: Colors.amber[600],
                        ),
                        SizedBox(width: 12),
                        Text(
                          'We\'re working hard to bring this feature to you',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Progress bar
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.7, // 70% progress
                        child: Container(
                          decoration: BoxDecoration(
                            color: Constants.ctaColorLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '70% Complete',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
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
  }
}
