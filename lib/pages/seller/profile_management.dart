

import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class ProfileManagement extends StatefulWidget {
  const ProfileManagement({Key? key}) : super(key: key);

  @override
  State<ProfileManagement> createState() => _ProfileManagementState();
}

class _ProfileManagementState extends State<ProfileManagement>
    with TickerProviderStateMixin {
  // Main sidebar selection
  String selectedTab = 'Edit Profile';

  // Seller profile sidebar selection
  String selectedSellerTab = 'Personal Details';

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

  // Controllers for Edit Profile
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

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

  // Controllers for Change Password
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Controllers for Displayed On Platform
  final TextEditingController displayTradingNameController = TextEditingController();

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

  bool grantApproval = false;
  bool registeredName = false;

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
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _sidebarFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOut,
    ));

    _sellerSidebarSlideAnimation = Tween<double>(
      begin: -250.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _sellerSidebarAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
    _sidebarAnimationController.forward();
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
    super.dispose();//
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
                  _buildMenuItem('Edit Profile',HugeIcons.strokeRoundedEditUser02),
                  _buildMenuItem('Edit Seller Profile',HugeIcons.strokeRoundedEdit02),
                  _buildMenuItem('Change Password',HugeIcons.strokeRoundedResetPassword),
                  _buildMenuItem('Get Quotes',HugeIcons.strokeRoundedQuotes),
                  _buildMenuItem('Message Board',HugeIcons.strokeRoundedMessage01),
                  _buildMenuItem('Delete Account',HugeIcons.strokeRoundedDelete01),
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
                          _buildSellerMenuItem('Personal Details',HugeIcons.strokeRoundedEditUser02),
                          _buildSellerMenuItem('Company Details',HugeIcons.strokeRoundedBuilding02),
                          _buildSellerMenuItem('Company Address',HugeIcons.strokeRoundedLocation01),
                          _buildSellerMenuItem('Company Account',HugeIcons.strokeRoundedPayment01),
                          _buildSellerMenuItem('Company Categories',HugeIcons.strokeRoundedCatalogue),
                          _buildSellerMenuItem('Displayed On Platform',HugeIcons.strokeRoundedWork),
                          _buildSellerMenuItem('Authorization For Company',HugeIcons.strokeRoundedAuthorized),
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

  Widget _buildMenuItem(String title, IconData icon, {bool isDestructive = false}) {
    final bool isSelected = selectedTab == title;
    final Color textColor = isDestructive ? Colors.red[300]! :
    isSelected ? Colors.white : Colors.grey[400]!;
    final Color backgroundColor = isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent;

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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        );
      },
    );
  }
  Widget _buildSellerMenuItem(String title, IconData icon, {bool isDestructive = false}) {
    final bool isSelected = selectedSellerTab == title;
    final Color textColor = isDestructive ? Constants.ftaColorLight.withOpacity(0.55) :
    isSelected ? Colors.white : Constants.ftaColorLight.withOpacity(0.55);
    final Color backgroundColor = isSelected ? Constants.ftaColorLight : Colors.transparent;

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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
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
      case 'Edit Profile':
        return _buildEditProfile();
      case 'Edit Seller Profile':
        return _buildSellerProfileContent();
      case 'Change Password':
        return _buildChangePassword();
      case 'Get Quotes':
        return Center(
          child: Text(
            'Get Quotes Content',
            style: GoogleFonts.manrope(fontSize: 24),
          ),
        );
      case 'Message Board':
        return Center(
          child: Text(
            'Message Board Content',
            style: GoogleFonts.manrope(fontSize: 24),
          ),
        );
      case 'Delete Account':
        return Center(
          child: Text(
            'Delete Account Content',
            style: GoogleFonts.manrope(fontSize: 24),
          ),
        );
      case 'Sign Out':
        return Center(
          child: Text(
            'Signing Out...',
            style: GoogleFonts.manrope(fontSize: 24),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildEditProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Profile',
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
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
      case 'Authorization For Company':
        return _buildAuthorizationForCompany();
      default:
        return Container();
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
            'Registered Company Name (CIPC)',
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
            'VAT Number',
            'Enter VAT Number',
            vatNumber2Controller,
            FocusNode(),
            TextInputAction.next,
            4,
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
          _buildAnimatedDropdownField('Bank Account Type', 'Enter Bank Account Type', 0),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Bank Name',
            'Enter Bank Name',
            bankNameController,
            FocusNode(),
            TextInputAction.next,
            1,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Bank Account Number',
            'Enter Bank Account Number',
            bankAccountNumberController,
            FocusNode(),
            TextInputAction.next,
            2,
          ),
          const SizedBox(height: 20),
          _buildAnimatedInputField(
            'Bank Branch Code',
            'Enter Bank Branch Code',
            bankBranchCodeController,
            FocusNode(),
            TextInputAction.done,
            3,
          ),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(4),
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
          ...categories.entries.toList().asMap().entries.map((entry) =>
              _buildAnimatedCategoryCheckbox(entry.value.key, entry.value.value, entry.key)
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
          _buildAnimatedCheckboxField('Registered Name', registeredName, (value) {
            setState(() {
              registeredName = value!;
            });
          }, 0),
          const SizedBox(height: 20),
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

  Widget _buildAuthorizationForCompany() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authorization for Company and Director Background and Police Clearance Checks',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          _buildAnimatedCheckboxField('Grant Approval', grantApproval, (value) {
            setState(() {
              grantApproval = value!;
            });
          }, 0),
          const SizedBox(height: 40),
          _buildAnimatedSaveButton(1),
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
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
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

  Widget _buildAnimatedCategoryCheckbox(String category, bool value, int index) {
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
      ),
    );
  }

  Widget _buildAnimatedCheckboxField(String label, bool value, Function(bool?) onChanged, int index) {
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

  Widget _buildCheckboxField(String label, bool value, Function(bool?) onChanged) {
    return Container(
      width: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
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
              borderRadius: BorderRadius.circular(360),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: hint,
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
              ),
              items: const [],
              onChanged: (value) {},
              icon: const Icon(Icons.arrow_drop_down),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedSaveButton(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + (index * 100)),
      curve: Curves.easeOutBack,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: Opacity(
            opacity: animation,
            child: _buildSaveButton(),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.height * 0.5,
      child: ElevatedButton(
        onPressed: () {
          // Handle save action
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8A838),
          padding: const EdgeInsets.symmetric(vertical: 16),
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
        VoidCallback? onSubmitted,
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
                  label == "Message" || label == "Project Details" ? 12 : 360),
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
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}