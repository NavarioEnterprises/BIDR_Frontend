import 'package:bidr/constants/Constants.dart';
import 'package:bidr/pages/buyer_home.dart';
import 'package:bidr/authentication/auth_api_service.dart';
import 'package:bidr/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage>
    with TickerProviderStateMixin {

  // Selected menu item
  String selectedMenuItem = 'Edit Profile';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Form controllers for Edit Profile
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Form controllers for Change Password
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Form controllers for Get Quotes
  final TextEditingController _quoteEmailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _projectDetailsController = TextEditingController();

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
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName can only contain letters and spaces';
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
    if (!RegExp(r'^[+]?[0-9]{10,15}$').hasMatch(cleanedPhone)) {
      return 'Please enter a valid phone number';
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

  String? _validatePassword(String? value, {bool isNew = false}) {
    if (value == null || value.isEmpty) {
      return isNew ? 'New password is required' : 'Current password is required';
    }
    if (isNew) {
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
        return 'Password must contain uppercase, lowercase, and numbers';
      }
    }
    return null;
  }

  bool _validateProfileForm() {
    final firstNameError = _validateName(_firstNameController.text, 'First name');
    final lastNameError = _validateName(_lastNameController.text, 'Last name');
    final phoneError = _validatePhoneNumber(_mobileController.text);

    if (firstNameError != null) {
      _showErrorDialog('Validation Error', firstNameError);
      return false;
    }
    if (lastNameError != null) {
      _showErrorDialog('Validation Error', lastNameError);
      return false;
    }
    if (phoneError != null) {
      _showErrorDialog('Validation Error', phoneError);
      return false;
    }
    return true;
  }

  bool _validatePasswordForm() {
    final currentError = _validatePassword(_currentPasswordController.text);
    final newError = _validatePassword(_newPasswordController.text, isNew: true);

    if (currentError != null) {
      _showErrorDialog('Validation Error', currentError);
      return false;
    }
    if (newError != null) {
      _showErrorDialog('Validation Error', newError);
      return false;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Validation Error', 'New password and confirmation do not match');
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    // Start initial animation
    _fadeController.forward();
    _slideController.forward();

    // Initialize form data (you can load from user data)
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
      _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      _mobileController.text = phone;
      _emailController.text = email;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();

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

  void _onMenuItemSelected(String menuItem) {
    if (selectedMenuItem != menuItem) {
      setState(() {
        selectedMenuItem = menuItem;
      });

      // Restart animations for content change
      _fadeController.reset();
      _slideController.reset();
      _fadeController.forward();
      _slideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
           // constraints: BoxConstraints(maxWidth: 1400),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sidebar
                Container(
                  width: 250,
                  height: 430,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildMenuItem('Edit Profile', HugeIcons.strokeRoundedUser),
                      _buildMenuItem('Change Password', HugeIcons.strokeRoundedLockPassword),
                      _buildMenuItem('Get Quotes', HugeIcons.strokeRoundedInvoice03),
                      _buildMenuItem('Message Board', HugeIcons.strokeRoundedMessage01),
                      const Spacer(),
                      _buildMenuItem('Delete Account', HugeIcons.strokeRoundedDelete02, isDestructive: true),
                      _buildMenuItem('Sign Out', HugeIcons.strokeRoundedLogout01, isDestructive: true),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Right Content Area
                Expanded(
                  child:  Container(
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
                        child: _buildContentForSelectedMenuItem(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, {bool isDestructive = false}) {
    final bool isSelected = selectedMenuItem == title;
    final Color textColor = isDestructive ? Colors.red[300]! :
    isSelected ? Colors.white : Colors.grey[400]!;
    final Color backgroundColor = isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor, size: 20),
        title: Text(
          title,
          style: GoogleFonts.manrope(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        onTap: () => _onMenuItemSelected(title),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildContentForSelectedMenuItem() {
    switch (selectedMenuItem) {
      case 'Edit Profile':
        return _buildEditProfileContent();
      case 'Change Password':
        return _buildChangePasswordContent();
      case 'Get Quotes':
        return _buildGetQuotesContent();
      case 'Message Board':
        return _buildMessageBoardContent();
      case 'Delete Account':
        return _buildDeleteAccountContent();
      case 'Sign Out':
        return _buildSignOutContent();
      default:
        return _buildEditProfileContent();
    }
  }

  Widget _buildEditProfileContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your personal information',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Column(
            children: [
              _buildCustomInputField(
                'First Name',
                'Enter First Name',
                _firstNameController,
                _firstNameFocusNode,
                TextInputAction.next,
                onSubmitted: () => _lastNameFocusNode.requestFocus(),
              ),
              const SizedBox(height: 24),
              _buildCustomInputField(
                'Last Name',
                'Enter Last Name',
                _lastNameController,
                _lastNameFocusNode,
                TextInputAction.next,
                onSubmitted: () => _mobileFocusNode.requestFocus(),
              ),
              const SizedBox(height: 24),
              _buildCustomInputField(
                'Mobile Number',
                'Enter Mobile Number',
                _mobileController,
                _mobileFocusNode,
                TextInputAction.next,
                onSubmitted: () => _emailFocusNode.requestFocus(),
              ),
              const SizedBox(height: 24),
              _buildCustomInputField(
                'Email',
                'Enter Email',
                _emailController,
                _emailFocusNode,
                TextInputAction.done,
              ),
            ],
          ),
          const SizedBox(height: 32),
      
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProfileLoading ? null : _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE29547),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildChangePasswordContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change Password',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your account password',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
      
          Column(
            children: [
              _buildCustomInputField(
                'Current Password',
                'Enter current password',
                _currentPasswordController,
                _currentPasswordFocusNode,
                TextInputAction.next,
                isPassword: true,
                onSubmitted: () => _newPasswordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 24),
              _buildCustomInputField(
                'New Password',
                'Enter new password',
                _newPasswordController,
                _newPasswordFocusNode,
                TextInputAction.next,
                isPassword: true,
                onSubmitted: () => _confirmPasswordFocusNode.requestFocus(),
              ),
              const SizedBox(height: 24),
              _buildCustomInputField(
                'Confirm New Password',
                'Confirm your new password',
                _confirmPasswordController,
                _confirmPasswordFocusNode,
                TextInputAction.done,
                isPassword: true,
              ),
            ],
          ),
      
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPasswordLoading ? null : _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE29547),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildGetQuotesContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get Quotes',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Request quotes for your projects',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
      
          Column(
            children: [
              _buildCustomInputField(
                'Email',
                'Enter your email',
                _quoteEmailController,
                FocusNode(),
                TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _buildCustomInputField(
                'Company Name',
                'Enter company name',
                _companyController,
                FocusNode(),
                TextInputAction.next,
              ),
              const SizedBox(height: 24),
              _buildCustomInputField(
                'Project Details',
                'Describe your project requirements',
                _projectDetailsController,
                FocusNode(),
                TextInputAction.done,
                maxLines: 5,
              ),
            ],
          ),
      
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _requestQuote,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE29547),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildMessageBoardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message Board',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Send us a message or feedback',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 24),

        Column(
          children: [
            _buildCustomInputField(
              'Subject',
              'Enter message subject',
              _subjectController,
              FocusNode(),
              TextInputAction.next,
            ),
            const SizedBox(height: 24),
            _buildCustomInputField(
              'Message',
              'Type your message here',
              _messageController,
              FocusNode(),
              TextInputAction.done,
              maxLines: 6,
            ),
          ],
        ),

        const SizedBox(height: 24),
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
    );
  }

  Widget _buildDeleteAccountContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delete Account',
          style: GoogleFonts.manrope(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Permanently delete your account and all data',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(HugeIcons.strokeRoundedAlert02, color: Colors.red[600], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Warning: This action cannot be undone',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Deleting your account will permanently remove all your data, including your profile, pantries, and transaction history. This action cannot be reversed.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _deleteAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    );
  }

  Widget _buildSignOutContent() {
    return Column(
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
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: Colors.grey[600],
          ),
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
                  Icon(HugeIcons.strokeRoundedInformationCircle, color: Colors.orange[600], size: 24),
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
                onPressed: () => _onMenuItemSelected('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Cancel',
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
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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
              borderRadius: BorderRadius.circular(label == "Message" || label == "Project Details" ?12:360),
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

  // Beautiful Success Dialog Builder
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
                                child: Icon(
                                  icon,
                                  color: color,
                                  size: 40,
                                ),
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
                                child:                                 Text(
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
                                child:                                 Text(
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
                                          HugeIcons.strokeRoundedInformationCircle,
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
                                        onPressed: () => Navigator.of(context).pop(),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.grey[600],
                                          side: BorderSide(color: Colors.grey[300]!),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
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
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
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

  // Action methods with beautiful success dialogs
  void _saveProfileChanges() async {
    // Validate form
    if (!_validateProfileForm()) {
      return;
    }

    setState(() {
      _isProfileLoading = true;
    });

    try {
      // Get access token
      final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorDialog('Authentication Error', 'Please log in again to update your profile.');
        return;
      }

      // Call API to update profile
      final response = await _authService.updateProfile(
        accessToken: accessToken,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _mobileController.text.trim(),
      );

      if (response != null && response['success'] != false) {
        // Update shared preferences with new data
        await Sharedprefs.saveUserNameSharedPreference(
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        );
        await Sharedprefs.saveUserCellSharedPreference(_mobileController.text.trim());

        // Update global constants
        Constants.myDisplayname = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        Constants.myUsername = Constants.myDisplayname;
        Constants.myCell = _mobileController.text.trim();

        _showSuccessDialog(
          title: 'Profile Updated!',
          message: 'Your profile information has been successfully updated.',
          icon: Icons.person_outline,
          color: const Color(0xFF38A169),
          additionalInfo: 'Changes will take effect immediately across the platform.',
        );
      } else {
        final errorMessage = response?['error']?.toString() ?? 'Failed to update profile';
        _showErrorDialog('Update Failed', errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isProfileLoading = false;
      });
    }
  }

  void _changePassword() async {
    // Show information dialog about password reset process
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Change Password',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'For security reasons, we\'ll send a password reset link to your email address. Please check your email and follow the instructions to set a new password.',
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPasswordReset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4299E1),
              ),
              child: Text(
                'Send Reset Link',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _requestPasswordReset() async {
    setState(() {
      _isPasswordLoading = true;
    });

    try {
      final email = await Sharedprefs.getUserEmailSharedPreference();
      if (email == null || email.isEmpty) {
        _showErrorDialog('Error', 'Unable to retrieve your email address.');
        return;
      }

      final response = await _authService.requestPasswordReset(email: email);

      if (response != null && response['success'] != false) {
        _showSuccessDialog(
          title: 'Reset Link Sent!',
          message: 'A password reset link has been sent to your email.',
          icon: Icons.email_outlined,
          color: const Color(0xFF4299E1),
          additionalInfo: 'Please check your email and follow the instructions to set a new password.',
          onContinue: () {
            // Clear password fields
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          },
        );
      } else {
        final errorMessage = response?['error']?.toString() ?? 'Failed to send reset link';
        _showErrorDialog('Reset Failed', errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isPasswordLoading = false;
      });
    }
  }

  void _requestQuote() {
    // Validate required fields
    if (_quoteEmailController.text.isEmpty || _companyController.text.isEmpty) {
      _showErrorDialog('Missing Information', 'Please fill in all required fields to request a quote.');
      return;
    }

    // Implement request quote logic here

    _showSuccessDialog(
      title: 'Quote Requested!',
      message: 'Your quote request has been submitted successfully.',
      icon: Icons.request_quote_outlined,
      color: const Color(0xFFE29547),
      additionalInfo: 'Our team will review your request and get back to you within 24 hours.',
      onContinue: () {
        // Clear form fields
        _quoteEmailController.clear();
        _companyController.clear();
        _projectDetailsController.clear();
      },
    );
  }

  void _sendMessage() {
    // Validate required fields
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      _showErrorDialog('Missing Information', 'Please provide both a subject and message before sending.');
      return;
    }

    // Implement send message logic here

    _showSuccessDialog(
      title: 'Message Sent!',
      message: 'Your message has been sent to our support team.',
      icon: Icons.message_outlined,
      color: const Color(0xFF9F7AEA),
      additionalInfo: 'You should receive a response within 2-3 business days.',
      onContinue: () {
        // Clear form fields
        _subjectController.clear();
        _messageController.clear();
      },
    );
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
                Text('• Your profile and personal information', style: GoogleFonts.manrope(fontSize: 14)),
                Text('• All your product requests and quotes', style: GoogleFonts.manrope(fontSize: 14)),
                Text('• Transaction history and reviews', style: GoogleFonts.manrope(fontSize: 14)),
                Text('• Chat messages and communications', style: GoogleFonts.manrope(fontSize: 14)),
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
      final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
      if (accessToken == null || accessToken.isEmpty) {
        _showErrorDialog('Authentication Error', 'Please log in again to delete your account.');
        return;
      }

      final response = await _authService.deleteAccount(accessToken: accessToken);

      if (response != null && response['success'] == true) {
        // Clear all shared preferences
        await _clearAllUserData();
        
        // Show success dialog and navigate to login
        _showSuccessDialog(
          title: 'Account Deleted',
          message: 'Your account has been permanently deleted.',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          additionalInfo: 'Thank you for using BIDR. You will be redirected to the login screen.',
          onContinue: () {
            // Navigate to login screen
            context.go('/');
          },
        );
      } else {
        final errorMessage = response?['error']?.toString() ?? 'Failed to delete account';
        _showErrorDialog('Deletion Failed', errorMessage);
      }
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isPasswordLoading = false;
      });
    }
  }

  void _signOut() async {
    setState(() {
      _isPasswordLoading = true; // Reuse this loading state
    });

    try {
      final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
      final refreshToken = await Sharedprefs.getUserRefreshTokenSharedPreference();

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
        title: 'Signed Out',
        message: 'You have been successfully signed out.',
        icon: Icons.logout,
        color: const Color(0xFF38A169),
        additionalInfo: 'Thank you for using BIDR. You will be redirected to the login screen.',
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
}