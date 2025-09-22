import 'package:bidr/constants/Constants.dart';
import 'package:bidr/services/auth_api_service.dart';
import 'package:bidr/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../customWdget/custom_input2.dart';
import '../breakpoints.dart';

class AccountManagementMobile extends StatefulWidget {
  const AccountManagementMobile({super.key});

  @override
  State<AccountManagementMobile> createState() =>
      _AccountManagementMobileState();
}

class _AccountManagementMobileState extends State<AccountManagementMobile>
    with SingleTickerProviderStateMixin {
  // Tab controller for navigation
  late TabController _tabController;

  // Form controllers for Edit Profile
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Form controllers for Change Password
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Form controllers for Get Quotes
  final TextEditingController _quoteEmailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _projectDetailsController =
      TextEditingController();

  // Form controllers for Message Board
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  // Focus nodes
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _currentPasswordFocusNode = FocusNode();
  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Loading states
  bool _isProfileLoading = false;
  bool _isPasswordLoading = false;

  // Auth service
  final AuthApiService _authService = AuthApiService();

  // Tab items configuration
  final List<TabItem> _tabItems = [
    TabItem(
      title: 'Edit Profile',
      icon: HugeIcons.strokeRoundedUser,
      isDestructive: false,
    ),
    TabItem(
      title: 'Change Password',
      icon: HugeIcons.strokeRoundedLockPassword,
      isDestructive: false,
    ),
    TabItem(
      title: 'Get Quotes',
      icon: HugeIcons.strokeRoundedInvoice03,
      isDestructive: false,
    ),
    TabItem(
      title: 'Message Board',
      icon: HugeIcons.strokeRoundedMessage01,
      isDestructive: false,
    ),
    TabItem(
      title: 'Delete Account',
      icon: HugeIcons.strokeRoundedDelete02,
      isDestructive: true,
    ),
    TabItem(
      title: 'Sign Out',
      icon: HugeIcons.strokeRoundedLogout01,
      isDestructive: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(
      length: _tabItems.length,
      vsync: this,
      initialIndex: 0,
    );

    // Load user data
    _loadUserData();
  }

  void _loadUserData() async {
    // Load actual user data from SharedPreferences
    final firstName = await Sharedprefs.getUserNameSharedPreference() ?? '';
    final email = await Sharedprefs.getUserEmailSharedPreference() ?? '';
    final phone = await Sharedprefs.getUserCellSharedPreference() ?? '';

    // Split full name into first and last name
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
  void dispose() {
    _tabController.dispose();

    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _quoteEmailController.dispose();
    _companyController.dispose();
    _projectDetailsController.dispose();
    _messageController.dispose();
    _subjectController.dispose();

    // Dispose focus nodes
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force mobile layout only
    final typography = ResponsiveTypography.mobileSmall;
    final spacing = ResponsiveSpacing.mobileSmall;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Tab Bar
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(spacing.paddingMedium),
                    child: Row(
                      children: [
                        ResponsiveText(
                          text: 'Account Management',
                          type: TextType.medium,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: Constants.ctaColorLight,
                      indicatorWeight: 3,
                      indicatorPadding: EdgeInsets.symmetric(
                        horizontal: spacing.spacingSmall,
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: spacing.spacingSmall,
                      ),
                      tabs: _tabItems
                          .map(
                            (item) => Tab(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(item.icon, size: 16),
                                  SizedBox(width: spacing.spacingSmall),
                                  Text(
                                    item.title,
                                    style: GoogleFonts.manrope(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditProfileContent(typography, spacing),
                _buildChangePasswordContent(typography, spacing),
                _buildGetQuotesContent(typography, spacing),
                _buildMessageBoardContent(typography, spacing),
                _buildDeleteAccountContent(typography, spacing),
                _buildSignOutContent(typography, spacing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileContent(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your personal information',
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
              onPressed: _isProfileLoading ? null : _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(360),
                ),
                elevation: 0,
              ),
              child: _isProfileLoading
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
    );
  }

  Widget _buildChangePasswordContent(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your account password',
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          _buildMobileInputField(
            'Current Password',
            'Enter current password',
            _currentPasswordController,
            _currentPasswordFocusNode,
            TextInputAction.next,
            typography,
            spacing,
            isPassword: true,
            onSubmitted: (value) => _newPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 24),

          _buildMobileInputField(
            'New Password',
            'Enter new password',
            _newPasswordController,
            _newPasswordFocusNode,
            TextInputAction.next,
            typography,
            spacing,
            isPassword: true,
            onSubmitted: (value) => _confirmPasswordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 24),

          _buildMobileInputField(
            'Confirm New Password',
            'Confirm your new password',
            _confirmPasswordController,
            _confirmPasswordFocusNode,
            TextInputAction.done,
            typography,
            spacing,
            isPassword: true,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPasswordLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(360),
                ),
                elevation: 0,
              ),
              child: _isPasswordLoading
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
    );
  }

  Widget _buildGetQuotesContent(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get Quotes',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Request quotes for your projects',
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          _buildMobileInputField(
            'Email',
            'Enter your email',
            _quoteEmailController,
            FocusNode(),
            TextInputAction.next,
            typography,
            spacing,
          ),
          const SizedBox(height: 24),

          _buildMobileInputField(
            'Company Name*',
            'Enter company name',
            _companyController,
            FocusNode(),
            TextInputAction.next,
            typography,
            spacing,
          ),
          const SizedBox(height: 24),

          _buildMobileInputField(
            'Project Details',
            'Describe your project requirements',
            _projectDetailsController,
            FocusNode(),
            TextInputAction.done,
            typography,
            spacing,
            maxLines: 5,
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
    );
  }

  Widget _buildMessageBoardContent(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Message Board',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send us a message or feedback',
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          _buildMobileInputField(
            'Subject',
            'Enter message subject',
            _subjectController,
            FocusNode(),
            TextInputAction.next,
            typography,
            spacing,
          ),
          const SizedBox(height: 24),

          _buildMobileInputField(
            'Message',
            'Type your message here',
            _messageController,
            FocusNode(),
            TextInputAction.done,
            typography,
            spacing,
            maxLines: 6,
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sendMessage,
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
                'Send Message',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountContent(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delete Account',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your account and all data',
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          Container(
            padding: EdgeInsets.all(spacing.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedAlert02,
                      color: Colors.red[600],
                      size: 20,
                    ),
                    SizedBox(width: spacing.spacingSmall),
                    Expanded(
                      child: Text(
                        'Warning: This action cannot be undone',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Deleting your account will permanently remove all your data, including your profile, requests, and transaction history.',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _deleteAccount,
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
                'Delete Account',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutContent(
    TypographyConfig typography,
    SpacingConfig spacing,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(spacing.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign Out',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign out from your account',
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          Container(
            padding: EdgeInsets.all(spacing.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
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
                      size: 20,
                    ),
                    SizedBox(width: spacing.spacingSmall),
                    Expanded(
                      child: Text(
                        'Are you sure you want to sign out?',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _tabController.animateTo(0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Constants.ftaColorLight,
                    padding: EdgeInsets.symmetric(
                      vertical: spacing.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: ResponsiveText(
                    text: 'Cancel',
                    type: TextType.medium,
                    fontWeight: FontWeight.w500,
                    color: Constants.ftaColorLight,
                  ),
                ),
              ),
              SizedBox(width: spacing.spacingMedium),
              Expanded(
                child: ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: spacing.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: ResponsiveText(
                    text: 'Sign Out',
                    type: TextType.medium,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
    bool isPassword = false,
    int maxLines = 1,
    final void Function(String)? onSubmitted,
  }) {
    return SizedBox(
      width: double.infinity,
      child: CustomInputTransparent4(
        hintText: hintText.replaceAll('*', ''),
        labelText: hintText,
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        isPasswordField: isPassword,
        onChanged: (value) {},
        onSubmitted: onSubmitted ?? (value) {},
        maxLines: maxLines,
      ),
    );
  }

  // Form validation functions
  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return '$fieldName cannot contain numbers';
    }
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return '$fieldName cannot contain special characters';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleanedPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanedPhone.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  bool _validateProfileForm() {
    final firstNameError = _validateName(
      _firstNameController.text,
      'First name',
    );
    final lastNameError = _validateName(_lastNameController.text, 'Last name');
    final phoneError = _validatePhoneNumber(_mobileController.text);

    if (firstNameError != null) {
      _showErrorMessage(firstNameError);
      return false;
    }
    if (lastNameError != null) {
      _showErrorMessage(lastNameError);
      return false;
    }
    if (phoneError != null) {
      _showErrorMessage(phoneError);
      return false;
    }
    return true;
  }

  bool _validatePasswordForm() {
    if (_currentPasswordController.text.isEmpty) {
      _showErrorMessage('Current password is required');
      return false;
    }
    if (_newPasswordController.text.isEmpty) {
      _showErrorMessage('New password is required');
      return false;
    }
    if (_newPasswordController.text.length < 8) {
      _showErrorMessage('Password must be at least 8 characters');
      return false;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorMessage('New password and confirmation do not match');
      return false;
    }
    return true;
  }

  // Action methods
  void _saveProfileChanges() async {
    if (!_validateProfileForm()) {
      return;
    }

    setState(() {
      _isProfileLoading = true;
    });

    try {
      final accessToken =
          await Sharedprefs.getUserAccessTokenSharedPreference();
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorMessage('Please log in again to update your profile');
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

        _showSuccessMessage('Profile updated successfully');
      } else {
        _showErrorMessage('Failed to update profile');
      }
    } catch (e) {
      _showErrorMessage('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  void _changePassword() async {
    if (!_validatePasswordForm()) {
      return;
    }

    _showSuccessMessage('Password reset link will be sent to your email');
    _requestPasswordReset();
  }

  void _requestPasswordReset() async {
    setState(() {
      _isPasswordLoading = true;
    });

    try {
      final email = await Sharedprefs.getUserEmailSharedPreference();
      if (email == null || email.isEmpty) {
        _showErrorMessage('Unable to retrieve your email address');
        return;
      }

      final response = await _authService.requestPasswordReset(
        context,
        email: email,
      );

      if (response != null && response['success'] != false) {
        _showSuccessMessage('Password reset link sent to your email');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showErrorMessage('Failed to send reset link');
      }
    } catch (e) {
      _showErrorMessage('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isPasswordLoading = false;
      });
    }
  }

  void _requestQuote() {
    if (_quoteEmailController.text.isEmpty || _companyController.text.isEmpty) {
      _showErrorMessage('Please fill in all required fields');
      return;
    }

    _showSuccessMessage('Quote request submitted successfully');
    _quoteEmailController.clear();
    _companyController.clear();
    _projectDetailsController.clear();
  }

  void _sendMessage() {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      _showErrorMessage('Please provide both subject and message');
      return;
    }

    _showSuccessMessage('Message sent successfully');
    _subjectController.clear();
    _messageController.clear();
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
    setState(() {
      _isPasswordLoading = true;
    });

    try {
      final accessToken =
          await Sharedprefs.getUserAccessTokenSharedPreference();
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorMessage('Please log in again to delete your account');
        return;
      }

      final response = await _authService.deleteAccount(
        accessToken: accessToken,
      );

      if (response != null && response['success'] == true) {
        await _clearAllUserData();
        _showSuccessMessage('Account deleted successfully');
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            context.go('/');
          }
        });
      } else {
        _showErrorMessage('Failed to delete account');
      }
    } catch (e) {
      _showErrorMessage('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isPasswordLoading = false;
      });
    }
  }

  void _signOut() async {
    setState(() {
      _isPasswordLoading = true;
    });

    try {
      final accessToken =
          await Sharedprefs.getUserAccessTokenSharedPreference();
      final refreshToken =
          await Sharedprefs.getUserRefreshTokenSharedPreference();

      if (accessToken != null && refreshToken != null) {
        await _authService.signOut(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      await _clearAllUserData();
      _showSuccessMessage('Signed out successfully');
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          context.go('/getstarted');
        }
      });
    } catch (e) {
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

  // Helper methods for showing messages
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// Tab item model
class TabItem {
  final String title;
  final IconData icon;
  final bool isDestructive;

  TabItem({
    required this.title,
    required this.icon,
    required this.isDestructive,
  });
}
