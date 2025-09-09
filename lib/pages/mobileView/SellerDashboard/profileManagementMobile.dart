import 'package:bidr/constants/Constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../customWdget/custom_input2.dart';
import '../../../services/auth_api_service.dart';
import '../../../services/shared_preferences.dart';
import '../breakpoints.dart';

bool _isProfileLoading = false;
bool _isPasswordLoading = false;

class ProfileManagementMobile extends StatefulWidget {
  const ProfileManagementMobile({Key? key}) : super(key: key);

  @override
  State<ProfileManagementMobile> createState() => _ProfileManagementMobileState();
}

class _ProfileManagementMobileState extends State<ProfileManagementMobile>
    with SingleTickerProviderStateMixin {
  final AuthApiService _authService = AuthApiService();
  late TabController _tabController;

  // Controllers for Edit Profile
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
  final TextEditingController bankAccountNumberController =
  TextEditingController();
  final TextEditingController bankBranchCodeController =
  TextEditingController();

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
    'Engine Parts': false,
    'Body Parts': false,
    'Suspension Parts': false,
    'Transmission Parts': false,
    'Batteries': false,
  };

  bool registeredName = false;

  // Seller profile data
  Map<String, dynamic>? sellerProfileData;
  bool isLoadingProfile = false;
  String? profileError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadSellerProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    // Banking Information - not in current response structure
    bankNameController.text = '';
    bankAccountNumberController.text = '';
    bankBranchCodeController.text = '';

    // Display preferences
    displayTradingNameController.text = data['trading_name'] ?? '';
    registeredName = false; // Default since display preference not in response

    // Categories
    final productSubcategory = data['product_subcategory'];
    if (productSubcategory != null) {
      // Reset all categories first
      categories.forEach((key, value) {
        categories[key] = false;
      });
      // Set the selected category
      categories.forEach((key, value) {
        categories[key] = _mapBackendCategoryToFrontend(productSubcategory, key);
      });
    }

    print('Fields populated successfully');
    print('Company name: ${companyNameController.text}');
    print('Trading name: ${tradingNameController.text}');
    print('Registration number: ${registrationNumberController.text}');
    print('VAT number: ${vatNumberController.text}');
  }


  bool _mapBackendCategoryToFrontend(String backendCategory, String frontendCategory) {
    final mappings = {
      'engine_parts': 'Engine Parts',
      'body_parts': 'Body Parts',
      'suspension_parts': 'Suspension Parts',
      'transmission_parts': 'Transmission Parts',
      'batteries': 'Batteries',
    };
    return mappings[backendCategory] == frontendCategory;
  }

  /// Handle save action based on current section
  void _handleSaveAction() {
    switch (_tabController.index) {
      case 0:
        _savePersonalDetails();
        break;
      case 1:
        _saveCompanyDetails();
        break;
      case 2:
        _saveCompanyAddress();
        break;
      case 3:
        _saveCompanyAccount();
        break;
      case 4:
        _saveCompanyCategories();
        break;
      case 5:
        _saveDisplayedOnPlatform();
        break;
      case 6:
        _performAccountDeletion();
        break;
      case 7:
        _signOut();
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
        .map((entry) => _mapFrontendCategoryToBackend(entry.key))
        .toList();

    final categoryData = {
      'product_category': selectedCategories.isNotEmpty ? 'Auto Parts' : null,
      'product_subcategory': selectedCategories.isNotEmpty ? selectedCategories.first : null,
    };

    await _updateSellerInfo('Company Categories', categoryData);
  }

  /// Save displayed on platform preferences
  Future<void> _saveDisplayedOnPlatform() async {
    final sellerData = {
      'trading_name': displayTradingNameController.text,
    };

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
  Future<void> _updateSellerInfo(String section, Map<String, dynamic> data) async {
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
      'Engine Parts': 'engine_parts',
      'Body Parts': 'body_parts',
      'Suspension Parts': 'suspension_parts',
      'Transmission Parts': 'transmission_parts',
      'Batteries': 'batteries',
    };
    return mappings[frontendCategory] ?? 'engine_parts';
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


  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, typography, spacing) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: _buildMobileAppBar(typography, spacing),
          body: _buildMobileTabBarView(typography, spacing),
        );
      },
    );
  }

  PreferredSizeWidget _buildMobileAppBar(TypographyConfig typography, SpacingConfig spacing) {
    return AppBar(
      backgroundColor: Constants.ftaColorLight,
      elevation: 0,
      leading: IconButton(
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowLeft01,
          color: Colors.white,
          size: ResponsiveTypography.mobileSmall.medium,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: ResponsiveText(
       text:  'Profile Management',
        type: TextType.subHeading,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: Container(
          color: Constants.ftaColorLight,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: GoogleFonts.manrope(
              fontSize: ResponsiveTypography.mobileSmall.normal,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.manrope(
              fontSize: ResponsiveTypography.mobileSmall.normal,
              fontWeight: FontWeight.w400,
            ),
            tabs: [
              Tab(text: 'Personal'),
              Tab(text: 'Company'),
              Tab(text: 'Address'),
              Tab(text: 'Account'),
              Tab(text: 'Categories'),
              Tab(text: 'Display'),
              Tab(text: 'Delete Account'),
              Tab(text: 'Sign Out'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabBarView(TypographyConfig typography, SpacingConfig spacing) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMobilePersonalDetails(typography, spacing),
        _buildMobileCompanyDetails(typography, spacing),
        _buildMobileCompanyAddress(typography, spacing),
        _buildMobileCompanyAccount(typography, spacing),
        _buildMobileCompanyCategories(typography, spacing),
        _buildMobileDisplayedOnPlatform(typography, spacing),
        _buildMobileDeleteAccount(typography, spacing),
        _buildMobileSignOut(typography, spacing),
      ],
    );
  }








  Widget _buildMobilePersonalDetails(TypographyConfig typography, SpacingConfig spacing) {
    if (isLoadingProfile && sellerProfileData == null) {
      return _buildMobileLoadingState(typography, spacing);
    }
    
    if (profileError != null) {
      return _buildMobileErrorState(typography, spacing);
    }
    
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGap(type: SpacingType.medium),
            ResponsiveText(
             text:  'Personal Details',
              type: TextType.subHeading,
              fontWeight: FontWeight.w600,
              color: Constants.ftaColorLight,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileInputField(
              'Full Name',
              'Enter Full Name',
              personalFullNameController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Mobile Number',
              'Enter Mobile Number',
              personalMobileController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Email',
              'Enter Email',
              personalEmailController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileSaveButton(typography, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCompanyDetails(TypographyConfig typography, SpacingConfig spacing) {
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGap(type: SpacingType.medium),
            ResponsiveText(
              text: 'Company Details',
              type: TextType.subHeading,
              fontWeight: FontWeight.w600,
              color: Constants.ftaColorLight,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileInputField(
              'Registered Company Name (CIPC)*',
              'Enter Registered Company Name',
              companyNameController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Trading Name',
              'Enter Company Trading Name',
              tradingNameController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Registration Number',
              'Enter Registration Number',
              registrationNumberController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'VAT Number',
              'Enter VAT Number',
              vatNumberController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Website URL',
              'Enter Website URL',
              websiteUrlController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileSaveButton(typography, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCompanyAddress(TypographyConfig typography, SpacingConfig spacing) {
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGap(type: SpacingType.medium),
            ResponsiveText(
              text: ' Company Address',
              type: TextType.subHeading,
              fontWeight: FontWeight.w600,
              color: Constants.ftaColorLight,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileInputField(
              'Postal Address',
              'Enter Postal Address',
              postalAddressController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Physical Address',
              'Enter Physical Address',
              physicalAddressController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Contact Person Name',
              'Enter Contact Person Name',
              contactPersonNameController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Contact Person Phone',
              'Enter Contact Person Phone',
              contactPersonPhoneController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Contact Person Email',
              'Enter Contact Person Email',
              contactPersonEmailController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Platform Workflow Email',
              'Enter Workflow Email',
              workflowEmailController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileSaveButton(typography, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCompanyAccount(TypographyConfig typography, SpacingConfig spacing) {
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGap(type: SpacingType.medium),
            ResponsiveText(
              text:  'Company Account',
              type: TextType.subHeading,
              fontWeight: FontWeight.w600,
              color: Constants.ftaColorLight,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileInputField(
              'Bank Name',
              'Enter Bank Name',
              bankNameController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Bank Account Number',
              'Enter Bank Account Number',
              bankAccountNumberController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Bank Branch Code',
              'Enter Bank Branch Code',
              bankBranchCodeController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileSaveButton(typography, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCompanyCategories(TypographyConfig typography, SpacingConfig spacing) {
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGap(type: SpacingType.medium),
            ResponsiveText(
              text:'Company Categories',
              type: TextType.subHeading,
              fontWeight: FontWeight.w600,
              color: Constants.ftaColorLight,
            ),
            ResponsiveGap(type: SpacingType.large),
            ...categories.entries.map(
              (entry) => _buildMobileCategoryCheckbox(
                entry.key,
                entry.value,
                typography,
                spacing,
              ),
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileSaveButton(typography, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDisplayedOnPlatform(TypographyConfig typography, SpacingConfig spacing) {
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveGap(type: SpacingType.medium),
            ResponsiveText(
              text: 'Displayed On Platform',
              type: TextType.subHeading,
              fontWeight: FontWeight.w600,
              color: Constants.ftaColorLight,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileCheckboxField(
              'Registered Name',
              registeredName,
              (value) {
                setState(() {
                  registeredName = value!;
                });
              },
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.medium),
            _buildMobileInputField(
              'Trading Name',
              'Enter Trading Name',
              displayTradingNameController,
              typography,
              spacing,
            ),
            ResponsiveGap(type: SpacingType.large),
            _buildMobileSaveButton(typography, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDeleteAccount(TypographyConfig typography, SpacingConfig spacing) {
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: Colors.red,
            size: typography.heading * 2,
          ),
          ResponsiveGap(type: SpacingType.large),
          ResponsiveText(
            text:'Delete Account',
            type: TextType.subHeading,
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
          ResponsiveGap(type: SpacingType.medium),
          ResponsiveText(
            text:'This action will permanently delete your account and all associated data.',
            type: TextType.normal,
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
          ResponsiveGap(type: SpacingType.large),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _deleteAccount(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: ResponsiveText(
                text:'Delete Account',
                type: TextType.medium,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSignOut(TypographyConfig typography, SpacingConfig spacing) {
    return ResponsiveContainer(
      paddingType: SpacingType.medium,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedLogout01,
            color: Constants.ctaColorLight,
            size: typography.heading * 2,
          ),
          ResponsiveGap(type: SpacingType.large),
          ResponsiveText(
            text: 'Sign Out',
            type: TextType.subHeading,
            color: Constants.ftaColorLight,
            fontWeight: FontWeight.w600,
          ),
          ResponsiveGap(type: SpacingType.medium),
          ResponsiveText(
            text:'You will be redirected to the login screen.',
            type: TextType.normal,
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
          ResponsiveGap(type: SpacingType.large),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: ResponsiveText(
                text:'Sign Out',
                type: TextType.medium,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }










  Widget _buildMobileInputField(
      String label,
      String hintText,
      TextEditingController controller,
      TypographyConfig typography,
      SpacingConfig spacing,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: spacing.paddingSmall),
          child: ResponsiveText(
            text: label,
            type: TextType.normal,
            color: Constants.ftaColorLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        ResponsiveGap(type: SpacingType.small),
        CustomInputTransparent4(
          hintText: hintText,
          labelText: hintText,
          controller: controller,
          focusNode: FocusNode(),
          textInputAction: TextInputAction.next,
          isPasswordField: false,
          onChanged: (value) {},
          onSubmitted: (value) {},
        ),
      ],
    );
  }

  Widget _buildMobileSaveButton(TypographyConfig typography, SpacingConfig spacing) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoadingProfile ? null : () => _handleSaveAction(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.ctaColorLight,
          padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoadingProfile
            ? SizedBox(
                height: typography.medium,
                width: typography.medium,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : ResponsiveText(
          text:'Save Changes',
                type: TextType.medium,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
      ),
    );
  }

  Widget _buildMobileCategoryCheckbox(
      String category,
      bool value,
      TypographyConfig typography,
      SpacingConfig spacing,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing.marginSmall),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Constants.ftaColorLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Constants.ctaColorLight;
              }
              return null;
            }),
          ),
        ),
        child: CheckboxListTile(
          title: ResponsiveText(
            text: category,
            type: TextType.normal,
            fontWeight: FontWeight.w400,
          ),
          value: value,
          onChanged: (bool? newValue) {
            setState(() {
              categories[category] = newValue ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      ),
    );
  }

  Widget _buildMobileCheckboxField(
      String label,
      bool value,
      Function(bool?) onChanged,
      TypographyConfig typography,
      SpacingConfig spacing,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Constants.ftaColorLight),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          checkboxTheme: CheckboxThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            fillColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Constants.ctaColorLight;
              }
              return null;
            }),
          ),
        ),
        child: CheckboxListTile(
          title: ResponsiveText(
            text:label,
            type: TextType.normal,
            fontWeight: FontWeight.w400,
          ),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.trailing,
        ),
      ),
    );
  }

  Widget _buildMobileLoadingState(TypographyConfig typography, SpacingConfig spacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Constants.ctaColorLight),
          ResponsiveGap(type: SpacingType.medium),
          ResponsiveText(
            text:'Loading profile data...',
            type: TextType.medium,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileErrorState(TypographyConfig typography, SpacingConfig spacing) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: typography.heading * 2,
            color: Colors.red,
          ),
          ResponsiveGap(type: SpacingType.medium),
          ResponsiveText(
            text:'Failed to load profile',
            type: TextType.subHeading,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
          ResponsiveGap(type: SpacingType.small),
          ResponsiveText(
            text: profileError!,
            type: TextType.normal,
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
          ResponsiveGap(type: SpacingType.medium),
          ElevatedButton(
            onPressed: _loadSellerProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.ctaColorLight,
              padding: EdgeInsets.symmetric(
                horizontal: spacing.paddingLarge,
                vertical: spacing.paddingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: ResponsiveText(
              text:  'Retry',
              type: TextType.medium,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
