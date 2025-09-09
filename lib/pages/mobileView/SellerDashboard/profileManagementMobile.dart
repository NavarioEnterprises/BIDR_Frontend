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

// Mixin for SnackBar functionality
mixin SnackBarMixin<T extends StatefulWidget> on State<T> {
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Main Profile Management Mobile Widget
class ProfileManagementMobile extends StatefulWidget {
  const ProfileManagementMobile({Key? key}) : super(key: key);

  @override
  State<ProfileManagementMobile> createState() => _ProfileManagementMobileState();
}

class _ProfileManagementMobileState extends State<ProfileManagementMobile> with SnackBarMixin {
  final AuthApiService _authService = AuthApiService();

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Constants.ftaColorLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(spacing.paddingMedium),
                child: Row(
                  children: [
                    IconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft01,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    SizedBox(width: spacing.spacingSmall),
                    ResponsiveText(
                      text: 'Profile',
                      type: TextType.medium,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Menu List
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(spacing.paddingMedium),
              children: [
                _buildProfileMenuItem(
                  'Edit Profile',
                  HugeIcons.strokeRoundedUser,
                      () => _navigateToEditProfile(),
                  typography,
                  spacing,
                ),
                _buildProfileMenuItem(
                  'Edit Seller Profile',
                  HugeIcons.strokeRoundedProfile,
                      () => _navigateToEditSellerProfile(),
                  typography,
                  spacing,
                ),
                _buildProfileMenuItem(
                  'Order',
                  HugeIcons.strokeRoundedShoppingBag03,
                      () => _navigateToOrder(),
                  typography,
                  spacing,
                ),
                _buildProfileMenuItem(
                  'Change Password',
                  HugeIcons.strokeRoundedLockPassword,
                      () => _navigateToChangePassword(),
                  typography,
                  spacing,
                ),
                _buildProfileMenuItem(
                  'Get Quote',
                  HugeIcons.strokeRoundedInvoice03,
                      () => _navigateToGetQuote(),
                  typography,
                  spacing,
                ),
                _buildProfileMenuItem(
                  'Logout',
                  HugeIcons.strokeRoundedLogout01,
                      () => _signOut(),
                  typography,
                  spacing,
                  isDestructive: true,
                ),
                _buildProfileMenuItem(
                  'Delete Account',
                  HugeIcons.strokeRoundedDelete02,
                      () => _deleteAccount(),
                  typography,
                  spacing,
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
      String title,
      IconData icon,
      VoidCallback onTap,
      TypographyConfig typography,
      SpacingConfig spacing, {
        bool isDestructive = false,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing.marginSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.paddingMedium,
              vertical: spacing.paddingLarge,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isDestructive ? Colors.red : Constants.ftaColorLight,
                ),
                SizedBox(width: spacing.spacingMedium),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: typography.medium,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(),
      ),
    );
  }

  void _navigateToEditSellerProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSellerProfilePage(),
      ),
    );
  }

  void _navigateToOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPage(),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordPage(),
      ),
    );
  }

  void _navigateToGetQuote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GetQuotePage(),
      ),
    );
  }

  void _signOut() async {
    try {
      final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
      final refreshToken = await Sharedprefs.getUserRefreshTokenSharedPreference();

      if (accessToken != null && refreshToken != null) {
        await _authService.signOut(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      await _clearAllUserData();

      if (mounted) {
        context.go('/getstarted');
      }
    } catch (e) {
      await _clearAllUserData();
      if (mounted) {
        context.go('/getstarted');
      }
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
        content: Text(
          'Are you absolutely sure you want to delete your account? This action cannot be undone.',
          style: GoogleFonts.manrope(fontSize: 14),
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
    try {
      final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
      if (accessToken == null || accessToken.isEmpty) {
        showErrorSnackBar('Please log in again to delete your account');
        return;
      }

      final response = await _authService.deleteAccount(accessToken: accessToken);

      if (response != null && response['success'] == true) {
        await _clearAllUserData();
        showSuccessSnackBar('Account deleted successfully');
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            context.go('/');
          }
        });
      } else {
        showErrorSnackBar('Failed to delete account');
      }
    } catch (e) {
      showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  Future<void> _clearAllUserData() async {
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
}

// Edit Profile Page
class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with SnackBarMixin {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  bool _isLoading = false;
  final AuthApiService _authService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final firstName = await Sharedprefs.getUserNameSharedPreference() ?? '';
    final email = await Sharedprefs.getUserEmailSharedPreference() ?? '';
    final phone = await Sharedprefs.getUserCellSharedPreference() ?? '';

    final nameParts = firstName.split(' ');

    setState(() {
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : '';
      _mobileController.text = phone;
      _emailController.text = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Edit Profile', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Update your personal details',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  _buildMobileInputField(
                    'First Name',
                    'Enter First Name',
                    _firstNameController,
                    _firstNameFocusNode,
                    TextInputAction.next,
                    typography,
                    spacing,
                    onSubmitted: (value) => _lastNameFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 24),

                  _buildMobileInputField(
                    'Last Name',
                    'Enter Last Name',
                    _lastNameController,
                    _lastNameFocusNode,
                    TextInputAction.next,
                    typography,
                    spacing,
                    onSubmitted: (value) => _mobileFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 24),

                  _buildMobileInputField(
                    'Mobile Number',
                    'Enter Mobile Number',
                    _mobileController,
                    _mobileFocusNode,
                    TextInputAction.next,
                    typography,
                    spacing,
                    onSubmitted: (value) => _emailFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 24),

                  _buildMobileInputField(
                    'Email',
                    'Enter Email',
                    _emailController,
                    _emailFocusNode,
                    TextInputAction.done,
                    typography,
                    spacing,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'Save Changes',
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
        ],
      ),
    );
  }

  Widget _buildMobileInputField(
      String label,
      String hintText,
      TextEditingController controller,
      FocusNode focusNode,
      TextInputAction textInputAction,
      TypographyConfig typography,
      SpacingConfig spacing, {
        final void Function(String)? onSubmitted,
      }) {
    return SizedBox(
      width: double.infinity,
      child: CustomInputTransparent4(
        hintText: hintText,
        labelText: hintText,
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        isPasswordField: false,
        onChanged: (value) {},
        onSubmitted: onSubmitted ?? (value) {},
      ),
    );
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
      if (accessToken == null || accessToken.isEmpty) {
        showErrorSnackBar('Please log in again to update your profile');
        return;
      }

      final response = await _authService.updateProfile(
        accessToken: accessToken,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _mobileController.text.trim(),
      );

      if (response != null && response['success'] != false) {
        await Sharedprefs.saveUserNameSharedPreference(
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        );
        await Sharedprefs.saveUserCellSharedPreference(
          _mobileController.text.trim(),
        );

        Constants.myDisplayname =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        Constants.myUsername = Constants.myDisplayname;
        Constants.myCell = _mobileController.text.trim();

        showSuccessSnackBar('Profile updated successfully');
      } else {
        showErrorSnackBar('Failed to update profile');
      }
    } catch (e) {
      showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }
}

// Edit Seller Profile Page
class EditSellerProfilePage extends StatefulWidget {
  @override
  _EditSellerProfilePageState createState() => _EditSellerProfilePageState();
}

class _EditSellerProfilePageState extends State<EditSellerProfilePage> with SnackBarMixin {
  final AuthApiService _authService = AuthApiService();
  
  // Controllers for Personal Details
  final TextEditingController personalFullNameController = TextEditingController();
  final TextEditingController personalMobileController = TextEditingController();
  final TextEditingController personalEmailController = TextEditingController();

  // Controllers for Company Details
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController tradingNameController = TextEditingController();
  final TextEditingController registrationNumberController = TextEditingController();
  final TextEditingController vatNumberController = TextEditingController();
  final TextEditingController vatNumber2Controller = TextEditingController();
  final TextEditingController websiteUrlController = TextEditingController();

  // Controllers for Company Address
  final TextEditingController postalAddressController = TextEditingController();
  final TextEditingController physicalAddressController = TextEditingController();
  final TextEditingController gpsLocationController = TextEditingController();
  final TextEditingController googleMapsLinkController = TextEditingController();
  final TextEditingController contactPersonNameController = TextEditingController();
  final TextEditingController contactPersonPhoneController = TextEditingController();
  final TextEditingController contactPersonEmailController = TextEditingController();
  final TextEditingController workflowEmailController = TextEditingController();

  // Controllers for Company Account
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController bankAccountNumberController = TextEditingController();
  final TextEditingController bankBranchCodeController = TextEditingController();

  // Controllers for Displayed On Platform
  final TextEditingController displayTradingNameController = TextEditingController();

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
  
  final List<SellerProfileSection> _sections = [
    SellerProfileSection('Personal Details', HugeIcons.strokeRoundedUser),
    SellerProfileSection('Company Details', HugeIcons.strokeRoundedBuilding02),
    SellerProfileSection('Company Address', HugeIcons.strokeRoundedLocation01),
    SellerProfileSection('Company Account', HugeIcons.strokeRoundedCreditCard),
    SellerProfileSection('Product Categories', HugeIcons.strokeRoundedPackage),
    SellerProfileSection('Displayed On Platform', HugeIcons.strokeRoundedEye),
  ];
  
  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Edit Seller Profile', typography, spacing),
          Expanded(
            child: isLoadingProfile && sellerProfileData == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Constants.ctaColorLight),
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
                  )
                : profileError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
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
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSellerProfile,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(spacing.paddingMedium),
                        itemCount: _sections.length,
                        itemBuilder: (context, index) {
                          final section = _sections[index];
                          return _buildSectionItem(section, typography, spacing);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem(
      SellerProfileSection section,
      TypographyConfig typography,
      SpacingConfig spacing,
      ) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing.marginSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSection(section.title),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(spacing.paddingLarge),
            decoration: BoxDecoration(
              color: Constants.ctaColorLight.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Constants.ctaColorLight.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    section.icon,
                    size: 20,
                    color: Constants.ctaColorLight,
                  ),
                ),
                SizedBox(width: spacing.spacingMedium),
                Expanded(
                  child: Text(
                    section.title.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: typography.normal,
                      fontWeight: FontWeight.w600,
                      color: Constants.ctaColorLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: 16,
                  color: Constants.ctaColorLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSection(String sectionTitle) {
    Widget page;
    switch (sectionTitle) {
      case 'Personal Details':
        page = PersonalDetailsPage(
          personalFullNameController: personalFullNameController,
          personalMobileController: personalMobileController,
          personalEmailController: personalEmailController,
          onSave: _savePersonalDetails,
        );
        break;
      case 'Company Details':
        page = CompanyDetailsPage(
          companyNameController: companyNameController,
          tradingNameController: tradingNameController,
          registrationNumberController: registrationNumberController,
          vatNumberController: vatNumberController,
          vatNumber2Controller: vatNumber2Controller,
          websiteUrlController: websiteUrlController,
          onSave: _saveCompanyDetails,
        );
        break;
      case 'Company Address':
        page = CompanyAddressPage(
          postalAddressController: postalAddressController,
          physicalAddressController: physicalAddressController,
          gpsLocationController: gpsLocationController,
          googleMapsLinkController: googleMapsLinkController,
          contactPersonNameController: contactPersonNameController,
          contactPersonPhoneController: contactPersonPhoneController,
          contactPersonEmailController: contactPersonEmailController,
          workflowEmailController: workflowEmailController,
          onSave: _saveCompanyAddress,
        );
        break;
      case 'Company Account':
        page = CompanyAccountPage(
          bankNameController: bankNameController,
          bankAccountNumberController: bankAccountNumberController,
          bankBranchCodeController: bankBranchCodeController,
          onSave: _saveCompanyAccount,
        );
        break;
      case 'Product Categories':
        page = ProductCategoriesPage(
          categories: categories,
          onSave: _saveCompanyCategories,
        );
        break;
      case 'Displayed On Platform':
        page = DisplayedOnPlatformPage(
          displayTradingNameController: displayTradingNameController,
          registeredName: registeredName,
          onRegisteredNameChanged: (value) => setState(() => registeredName = value),
          onSave: _saveDisplayedOnPlatform,
        );
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
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
    gpsLocationController.text = '';
    googleMapsLinkController.text = '';

    // Contact Information  
    contactPersonNameController.text = data['contact_person_name'] ?? '';
    contactPersonPhoneController.text = data['contact_person_telephone'] ?? '';
    contactPersonEmailController.text = data['contact_person_email'] ?? '';
    workflowEmailController.text = data['platform_workflow_email'] ?? '';

    // Banking Information
    bankNameController.text = '';
    bankAccountNumberController.text = '';
    bankBranchCodeController.text = '';

    // Display preferences
    displayTradingNameController.text = data['trading_name'] ?? '';
    registeredName = false;

    // Categories
    final productSubcategory = data['product_subcategory'];
    if (productSubcategory != null) {
      categories.forEach((key, value) {
        categories[key] = false;
      });
      categories.forEach((key, value) {
        categories[key] = _mapBackendCategoryToFrontend(productSubcategory, key);
      });
    }
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
    final bankingData = {
      'bank_name': bankNameController.text,
      'account_number': bankAccountNumberController.text,
      'branch_code': bankBranchCodeController.text,
    };

    showSuccessSnackBar('Company Account information saved locally');
    
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
        showSuccessSnackBar('$section updated successfully');
        await _loadSellerProfile();
      } else {
        showErrorSnackBar('Failed to update $section: ${response['error']}');
      }
    } catch (e) {
      showErrorSnackBar('Error updating $section: $e');
    } finally {
      setState(() => isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
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
    displayTradingNameController.dispose();
    super.dispose();
  }
}

class SellerProfileSection {
  final String title;
  final IconData icon;

  SellerProfileSection(this.title, this.icon);
}

// Personal Details Page
class PersonalDetailsPage extends StatefulWidget {
  final TextEditingController personalFullNameController;
  final TextEditingController personalMobileController;
  final TextEditingController personalEmailController;
  final Future<void> Function() onSave;

  const PersonalDetailsPage({
    Key? key,
    required this.personalFullNameController,
    required this.personalMobileController,
    required this.personalEmailController,
    required this.onSave,
  }) : super(key: key);

  @override
  _PersonalDetailsPageState createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> with SnackBarMixin {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Personal Details', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    text: 'Personal Information',
                    type: TextType.subHeading,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  _buildInputField(
                    'Full Name',
                    'Enter Full Name',
                    widget.personalFullNameController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Mobile Number',
                    'Enter Mobile Number',
                    widget.personalMobileController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Email',
                    'Enter Email',
                    widget.personalEmailController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  _buildSaveButton(typography, spacing, _savePersonalDetails),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePersonalDetails() async {
    setState(() => _isLoading = true);

    try {
      await widget.onSave();
      showSuccessSnackBar('Personal details saved successfully');
    } catch (e) {
      showErrorSnackBar('Failed to save personal details');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Order Page (Coming Soon)
class OrderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildComingSoonPage(
      context,
      'Order History',
      'Track and manage your orders',
      HugeIcons.strokeRoundedShoppingBag03,
    );
  }
}

// Change Password Page
class ChangePasswordPage extends StatefulWidget {
  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> with SnackBarMixin {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  final AuthApiService _authService = AuthApiService();

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Change Password', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Password',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your current password and new password',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  CustomInputTransparent4(
                    hintText: 'Enter current password',
                    labelText: 'Current Password',
                    controller: _currentPasswordController,
                    focusNode: FocusNode(),
                    textInputAction: TextInputAction.next,
                    isPasswordField: true,
                    onChanged: (value) {},
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(height: 24),

                  CustomInputTransparent4(
                    hintText: 'Enter new password',
                    labelText: 'New Password',
                    controller: _newPasswordController,
                    focusNode: FocusNode(),
                    textInputAction: TextInputAction.next,
                    isPasswordField: true,
                    onChanged: (value) {},
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(height: 24),

                  CustomInputTransparent4(
                    hintText: 'Confirm new password',
                    labelText: 'Confirm New Password',
                    controller: _confirmPasswordController,
                    focusNode: FocusNode(),
                    textInputAction: TextInputAction.done,
                    isPasswordField: true,
                    onChanged: (value) {},
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'Change Password',
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
        ],
      ),
    );
  }

  void _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      showErrorSnackBar('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = await Sharedprefs.getUserEmailSharedPreference();
      if (email == null || email.isEmpty) {
        showErrorSnackBar('Unable to retrieve email address');
        return;
      }

      final response = await _authService.requestPasswordReset(email: email);

      if (response != null && response['success'] != false) {
        showSuccessSnackBar('Password reset link sent to your email');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        showErrorSnackBar('Failed to send reset link');
      }
    } catch (e) {
      showErrorSnackBar('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// Get Quote Page
class GetQuotePage extends StatefulWidget {
  @override
  _GetQuotePageState createState() => _GetQuotePageState();
}

class _GetQuotePageState extends State<GetQuotePage> with SnackBarMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _projectDetailsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Get Quote', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Quote',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about your project requirements',
                    style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),

                  CustomInputTransparent4(
                    hintText: 'Enter your email',
                    labelText: 'Email',
                    controller: _emailController,
                    focusNode: FocusNode(),
                    textInputAction: TextInputAction.next,
                    isPasswordField: false,
                    onChanged: (value) {},
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(height: 24),

                  CustomInputTransparent4(
                    hintText: 'Enter company name',
                    labelText: 'Company Name',
                    controller: _companyController,
                    focusNode: FocusNode(),
                    textInputAction: TextInputAction.next,
                    isPasswordField: false,
                    onChanged: (value) {},
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(height: 24),

                  CustomInputTransparent4(
                    hintText: 'Describe your project requirements',
                    labelText: 'Project Details',
                    controller: _projectDetailsController,
                    focusNode: FocusNode(),
                    textInputAction: TextInputAction.done,
                    isPasswordField: false,
                    maxLines: 5,
                    onChanged: (value) {},
                    onSubmitted: (value) {},
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _requestQuote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Request Quote',
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
        ],
      ),
    );
  }

  void _requestQuote() {
    if (_emailController.text.isEmpty || _companyController.text.isEmpty) {
      showErrorSnackBar('Please fill in all required fields');
      return;
    }

    showSuccessSnackBar('Quote request submitted successfully');

    _emailController.clear();
    _companyController.clear();
    _projectDetailsController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _companyController.dispose();
    _projectDetailsController.dispose();
    super.dispose();
  }
}

// Additional seller profile pages follow the same pattern...
// (The rest of the seller profile pages would be implemented similarly)

// Common UI Components
Widget _buildHeader(BuildContext context, String title, TypographyConfig typography, SpacingConfig spacing) {
  return Container(
    decoration: BoxDecoration(
      color: Constants.ftaColorLight,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.all(spacing.paddingMedium),
        child: Row(
          children: [
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: Colors.white,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(width: spacing.spacingSmall),
            ResponsiveText(
              text: title,
              type: TextType.medium,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInputField(
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

Widget _buildSaveButton(TypographyConfig typography, SpacingConfig spacing, VoidCallback onPressed) {
  return Builder(
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.ctaColorLight,
              padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: ResponsiveText(
              text: 'Save Changes',
              type: TextType.medium,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
  );
}

// Placeholder pages for remaining seller profile sections
class CompanyDetailsPage extends StatefulWidget {
  final TextEditingController companyNameController;
  final TextEditingController tradingNameController;
  final TextEditingController registrationNumberController;
  final TextEditingController vatNumberController;
  final TextEditingController vatNumber2Controller;
  final TextEditingController websiteUrlController;
  final Future<void> Function() onSave;

  const CompanyDetailsPage({
    Key? key,
    required this.companyNameController,
    required this.tradingNameController,
    required this.registrationNumberController,
    required this.vatNumberController,
    required this.vatNumber2Controller,
    required this.websiteUrlController,
    required this.onSave,
  }) : super(key: key);

  @override
  _CompanyDetailsPageState createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> with SnackBarMixin {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Company Details', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    text: 'Company Information',
                    type: TextType.subHeading,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  _buildInputField(
                    'Registered Company Name (CIPC)*',
                    'Enter Registered Company Name',
                    widget.companyNameController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Trading Name',
                    'Enter Company Trading Name',
                    widget.tradingNameController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Registration Number',
                    'Enter Registration Number',
                    widget.registrationNumberController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'VAT Number',
                    'Enter VAT Number',
                    widget.vatNumberController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Website URL',
                    'Enter Website URL',
                    widget.websiteUrlController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCompanyDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : ResponsiveText(
                              text: 'Save Changes',
                              type: TextType.medium,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCompanyDetails() async {
    setState(() => _isLoading = true);

    try {
      await widget.onSave();
      showSuccessSnackBar('Company details saved successfully');
    } catch (e) {
      showErrorSnackBar('Failed to save company details');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class CompanyAddressPage extends StatefulWidget {
  final TextEditingController postalAddressController;
  final TextEditingController physicalAddressController;
  final TextEditingController gpsLocationController;
  final TextEditingController googleMapsLinkController;
  final TextEditingController contactPersonNameController;
  final TextEditingController contactPersonPhoneController;
  final TextEditingController contactPersonEmailController;
  final TextEditingController workflowEmailController;
  final Future<void> Function() onSave;

  const CompanyAddressPage({
    Key? key,
    required this.postalAddressController,
    required this.physicalAddressController,
    required this.gpsLocationController,
    required this.googleMapsLinkController,
    required this.contactPersonNameController,
    required this.contactPersonPhoneController,
    required this.contactPersonEmailController,
    required this.workflowEmailController,
    required this.onSave,
  }) : super(key: key);

  @override
  _CompanyAddressPageState createState() => _CompanyAddressPageState();
}

class _CompanyAddressPageState extends State<CompanyAddressPage> with SnackBarMixin {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Company Address', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    text: 'Address & Contact Information',
                    type: TextType.subHeading,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  _buildInputField(
                    'Postal Address',
                    'Enter Postal Address',
                    widget.postalAddressController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Physical Address',
                    'Enter Physical Address',
                    widget.physicalAddressController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'GPS Location',
                    'Enter GPS Location',
                    widget.gpsLocationController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Google Maps Link',
                    'Enter Google Maps Link',
                    widget.googleMapsLinkController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  ResponsiveText(
                    text: 'Contact Person Details',
                    type: TextType.medium,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Contact Person Name',
                    'Enter Contact Person Name',
                    widget.contactPersonNameController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Contact Person Telephone',
                    'Enter Contact Person Telephone',
                    widget.contactPersonPhoneController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Contact Person Email Address',
                    'Enter Contact Person Email Address',
                    widget.contactPersonEmailController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Platform Workflow Email Address',
                    'Enter Platform Workflow Email Address',
                    widget.workflowEmailController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCompanyAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : ResponsiveText(
                              text: 'Save Changes',
                              type: TextType.medium,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCompanyAddress() async {
    setState(() => _isLoading = true);

    try {
      await widget.onSave();
      showSuccessSnackBar('Company address saved successfully');
    } catch (e) {
      showErrorSnackBar('Failed to save company address');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class CompanyAccountPage extends StatefulWidget {
  final TextEditingController bankNameController;
  final TextEditingController bankAccountNumberController;
  final TextEditingController bankBranchCodeController;
  final Future<void> Function() onSave;

  const CompanyAccountPage({
    Key? key,
    required this.bankNameController,
    required this.bankAccountNumberController,
    required this.bankBranchCodeController,
    required this.onSave,
  }) : super(key: key);

  @override
  _CompanyAccountPageState createState() => _CompanyAccountPageState();
}

class _CompanyAccountPageState extends State<CompanyAccountPage> with SnackBarMixin {
  bool _isLoading = false;
  String? _selectedAccountType;

  final List<String> _accountTypes = [
    'Current Account',
    'Savings Account',
    'Business Account',
    'Investment Account',
  ];

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Company Account', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    text: 'Banking Information',
                    type: TextType.subHeading,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  // Account Type Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: spacing.paddingSmall),
                        child: ResponsiveText(
                          text: 'Bank Account Type',
                          type: TextType.normal,
                          color: Constants.ftaColorLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ResponsiveGap(type: SpacingType.small),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedAccountType,
                          decoration: InputDecoration(
                            hintText: 'Select Account Type',
                            hintStyle: GoogleFonts.manrope(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items: _accountTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedAccountType = value;
                            });
                          },
                          icon: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                    ],
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Bank Name',
                    'Enter Bank Name',
                    widget.bankNameController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Bank Account Number',
                    'Enter Bank Account Number',
                    widget.bankAccountNumberController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  _buildInputField(
                    'Bank Branch Code',
                    'Enter Bank Branch Code',
                    widget.bankBranchCodeController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  // Information Note
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          HugeIcons.strokeRoundedInformationCircle,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Banking information is stored securely and used for payment processing. This information is currently saved locally and will be integrated with payment systems in future updates.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCompanyAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : ResponsiveText(
                              text: 'Save Changes',
                              type: TextType.medium,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCompanyAccount() async {
    setState(() => _isLoading = true);

    try {
      await widget.onSave();
      showSuccessSnackBar('Company account information saved successfully');
    } catch (e) {
      showErrorSnackBar('Failed to save company account information');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class ProductCategoriesPage extends StatefulWidget {
  final Map<String, bool> categories;
  final Future<void> Function() onSave;

  const ProductCategoriesPage({
    Key? key,
    required this.categories,
    required this.onSave,
  }) : super(key: key);

  @override
  _ProductCategoriesPageState createState() => _ProductCategoriesPageState();
}

class _ProductCategoriesPageState extends State<ProductCategoriesPage> with SnackBarMixin {
  bool _isLoading = false;
  late Map<String, bool> _localCategories;

  @override
  void initState() {
    super.initState();
    _localCategories = Map.from(widget.categories);
  }

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Product Categories', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    text: 'Select Product Categories',
                    type: TextType.subHeading,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose the product categories that best describe your business',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  // Category checkboxes
                  ..._localCategories.entries.map((entry) => _buildCategoryCheckbox(
                    entry.key,
                    entry.value,
                    spacing,
                  )).toList(),

                  ResponsiveGap(type: SpacingType.large),

                  // Information Note
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          HugeIcons.strokeRoundedInformationCircle,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Select the categories that best match your product offerings. This helps customers find your products more easily.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProductCategories,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : ResponsiveText(
                              text: 'Save Changes',
                              type: TextType.medium,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCheckbox(String category, bool value, SpacingConfig spacing) {
    return Container(
      margin: EdgeInsets.only(bottom: spacing.marginSmall),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Constants.ftaColorLight.withOpacity(0.2)),
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
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          value: value,
          onChanged: (bool? newValue) {
            setState(() {
              _localCategories[category] = newValue ?? false;
            });
          },
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.paddingMedium,
            vertical: spacing.paddingSmall,
          ),
        ),
      ),
    );
  }

  Future<void> _saveProductCategories() async {
    setState(() => _isLoading = true);

    try {
      // Update the original categories map
      widget.categories.clear();
      widget.categories.addAll(_localCategories);
      
      await widget.onSave();
      showSuccessSnackBar('Product categories saved successfully');
    } catch (e) {
      showErrorSnackBar('Failed to save product categories');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class DisplayedOnPlatformPage extends StatefulWidget {
  final TextEditingController displayTradingNameController;
  final bool registeredName;
  final Function(bool) onRegisteredNameChanged;
  final Future<void> Function() onSave;

  const DisplayedOnPlatformPage({
    Key? key,
    required this.displayTradingNameController,
    required this.registeredName,
    required this.onRegisteredNameChanged,
    required this.onSave,
  }) : super(key: key);

  @override
  _DisplayedOnPlatformPageState createState() => _DisplayedOnPlatformPageState();
}

class _DisplayedOnPlatformPageState extends State<DisplayedOnPlatformPage> with SnackBarMixin {
  bool _isLoading = false;
  late bool _localRegisteredName;

  @override
  void initState() {
    super.initState();
    _localRegisteredName = widget.registeredName;
  }

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context, 'Displayed On Platform', typography, spacing),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(spacing.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    text: 'Display Preferences',
                    type: TextType.subHeading,
                    fontWeight: FontWeight.w600,
                    color: Constants.ftaColorLight,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Configure how your business name appears to customers on the platform',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  // Registered Name Checkbox
                  _buildCheckboxField(
                    'Use Registered Name',
                    _localRegisteredName,
                    (bool? value) {
                      setState(() {
                        _localRegisteredName = value ?? false;
                      });
                    },
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.medium),

                  // Trading Name Input
                  _buildInputField(
                    'Trading Name',
                    'Enter Trading Name',
                    widget.displayTradingNameController,
                    typography,
                    spacing,
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  // Preview Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Constants.ctaColorLight.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              HugeIcons.strokeRoundedEye,
                              color: Constants.ctaColorLight,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Preview',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Constants.ctaColorLight,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your business will be displayed as:',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                HugeIcons.strokeRoundedBuilding02,
                                color: Constants.ctaColorLight,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _localRegisteredName 
                                    ? 'Registered Company Name' 
                                    : (widget.displayTradingNameController.text.isEmpty 
                                        ? 'Trading Name' 
                                        : widget.displayTradingNameController.text),
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  // Information Note
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          HugeIcons.strokeRoundedInformationCircle,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This setting determines which name customers will see when they view your business profile and products on the platform.',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveGap(type: SpacingType.large),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveDisplayPreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: spacing.paddingMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : ResponsiveText(
                              text: 'Save Changes',
                              type: TextType.medium,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxField(
    String label,
    bool value,
    Function(bool?) onChanged,
    SpacingConfig spacing,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Constants.ftaColorLight.withOpacity(0.2)),
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
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            'Display your registered company name instead of trading name',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          value: value,
          onChanged: onChanged,
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: EdgeInsets.symmetric(
            horizontal: spacing.paddingMedium,
            vertical: spacing.paddingSmall,
          ),
        ),
      ),
    );
  }

  Future<void> _saveDisplayPreferences() async {
    setState(() => _isLoading = true);

    try {
      // Update the callback with the local value
      widget.onRegisteredNameChanged(_localRegisteredName);
      
      await widget.onSave();
      showSuccessSnackBar('Display preferences saved successfully');
    } catch (e) {
      showErrorSnackBar('Failed to save display preferences');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class AuthorizationForCompanyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildComingSoonPage(
      context,
      'Authorization For Company',
      'Company authorization and verification',
      HugeIcons.strokeRoundedShield01,
    );
  }
}

// Helper method to build Coming Soon pages
Widget _buildComingSoonPage(BuildContext context, String title, String subtitle, IconData icon) {
  final typography = ResponsiveTypography.mobileSmall;
  final spacing = ResponsiveSpacing.mobileSmall;

  return Scaffold(
    backgroundColor: Colors.white,
    body: Column(
      children: [
        _buildHeader(context, title, typography, spacing),
        Expanded(
          child: Container(
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
          ),
        ),
      ],
    ),
  );
}