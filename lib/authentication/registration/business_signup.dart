import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:typed_data';
import 'package:path/path.dart' as path;

import '../../constants/Constants.dart';
import '../../customWdget/customCard.dart';
import '../../customWdget/custom_input2.dart';
import '../../customWdget/custom_dialogs.dart';
import '../../services/auth_api_service.dart';
import '../otp_screen.dart';
import 'complete_business_registration.dart';
import '../../pages/seller/seller_home_dashboard.dart';
import 'business_signup_mobile.dart';
import '../../services/shared_preferences.dart';

class BusinessSignUpPage extends StatefulWidget {
  const BusinessSignUpPage({super.key});

  @override
  State<BusinessSignUpPage> createState() => _BusinessSignUpPageState();
}

class _BusinessSignUpPageState extends State<BusinessSignUpPage> {
  int currentStep = 0;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  PageController pageController = PageController();
  bool isApproval = false;
  // Step 0 - User Information Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes for user information
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _userEmailFocusNode = FocusNode();
  final FocusNode _userPhoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // Step 1 - Company Details Controllers
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _tradingNameController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();
  final TextEditingController _yearEstablishedController =
      TextEditingController();

  // Step 2 - Company Address Controllers
  final TextEditingController _postalAddressController =
      TextEditingController();
  final TextEditingController _physicalAddressController =
      TextEditingController();
  final TextEditingController _contactPersonNameController =
      TextEditingController();
  final TextEditingController _contactPersonTelephoneController =
      TextEditingController();
  final TextEditingController _contactPersonEmailController =
      TextEditingController();
  final TextEditingController _platformWorkflowEmailController =
      TextEditingController();

  // Step 3 - Bank Account Controllers
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _accountHolderController =
      TextEditingController();

  // Selected bank and branch code
  String? _selectedBank;
  String? _selectedBranchCode;

  // South African Banks with branch codes
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

  // Step 4 - Product Categories 'Oil & Fluids'
  List<String> selectedCategories = [];
  final List<String> availableCategories = [
    'Engines Parts',
    'Batteries',
    'Transmission Parts',
    'Body Parts',
    'Suspension Parts',
  ];

  // Step 5 - Display on Platform
  final TextEditingController _tradingDisplayNameController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Focus Nodes
  final Map<String, FocusNode> focusNodes = {};

  List<PlatformFile> _uploadedDocuments = [];
  String? _selectedLocationText;
  bool _isLoading = false;

  // Location picker variables
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  final String _googleMapsApiKey =
      "YOUR_GOOGLE_MAPS_API_KEY"; // Replace with actual API key
  final TextEditingController _locationController = TextEditingController();
  bool _isRegisteredNameSelected = false;

  // Scroll controller for scrollbar
  final ScrollController _scrollController = ScrollController();

  final List<StepInfo> steps = [
    StepInfo(
      title: 'User Information',
      subtitle: 'Enter Your Personal Details',
      isCompleted: false,
    ),
    StepInfo(
      title: 'OTP Verification',
      subtitle: 'Verify Your Email Address',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Details',
      subtitle: 'Setup Your Company Details',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Address',
      subtitle: 'Setup Your Company Address',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Bank Account',
      subtitle: 'Setup Your Bank Account',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Product Categories',
      subtitle: 'Select Your Product Categories',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Display On Platform',
      subtitle: 'Enter Name of Trading Name',
      isCompleted: false,
    ),
  ];
  Timer? _addressValidationTimer;

  void _debounceAddressValidation() {
    // Cancel previous timer if it exists
    _addressValidationTimer?.cancel();

    // Set a new timer for 1.5 seconds after user stops typing
    _addressValidationTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_physicalAddressController.text.isNotEmpty) {
        _validatePhysicalAddress();
      }
    });
  }

  void _validatePhysicalAddress() {
    // Add your address validation logic here
    String address = _physicalAddressController.text.trim();

    if (address.length < 10) {
      // Address might be too short
      print('Address might be incomplete: $address');
      return;
    }

    print('Validating address: $address');
  }

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
    _physicalAddressController.addListener(() {
      if (_selectedLocationText != null &&
          _physicalAddressController.text.isNotEmpty) {
        setState(() {
          // Reset location selection when address changes
          _selectedLocationText = null;
        });
      }

      // If address is cleared completely, also clear the location
      if (_physicalAddressController.text.isEmpty &&
          _selectedLocationText != null) {
        setState(() {
          _selectedLocationText = null;
        });
      }

      // Optional: Auto-debounced address validation
      _debounceAddressValidation();
    });

    // Load saved form progress
    _loadFormProgress();
  }

  void _initializeFocusNodes() {
    List<String> fieldNames = [
      'companyName',
      'tradingName',
      'registrationNumber',
      'vatNumber',
      'websiteUrl',
      'yearEstablished',
      'postalAddress',
      'physicalAddress',
      'contactPersonName',
      'contactPersonTelephone',
      'contactPersonEmail',
      'platformWorkflowEmail',
      'bankName',
      'accountNumber',
      'branchCode',
      'accountHolder',
      'tradingDisplayName',
      'description',
      'authPersonName',
      'authPersonEmail',
      'authPersonPhone',
    ];

    for (String name in fieldNames) {
      focusNodes[name] = FocusNode();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    focusNodes.values.forEach((node) => node.dispose());
    _postalAddressController.dispose();
    _physicalAddressController.dispose();
    _contactPersonNameController.dispose();
    _contactPersonTelephoneController.dispose();
    _contactPersonEmailController.dispose();
    _platformWorkflowEmailController.dispose();
    pageController.dispose();
    super.dispose();
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone number validation helper (allows + and up to 13 digits)
  bool _isValidPhoneNumber(String phone) {
    // Allow + at the beginning and digits only, max 13 digits total
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.startsWith('+')) {
      final digits = cleanPhone.substring(1);
      return digits.length >= 10 &&
          digits.length <= 12 &&
          RegExp(r'^[0-9]+$').hasMatch(digits);
    } else {
      return cleanPhone.length == 10 &&
          RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
    }
  }

  // Name validation helper (only letters and spaces)
  bool _isValidName(String name) {
    return name.trim().length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  // Numbers only validation helper
  bool _isValidNumbersOnly(String value, {int? minLength, int? maxLength}) {
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (minLength != null && cleanValue.length < minLength) return false;
    if (maxLength != null && cleanValue.length > maxLength) return false;
    return RegExp(r'^[0-9]+$').hasMatch(cleanValue);
  }

  // URL validation helper
  bool _isValidURL(String url) {
    if (url.trim().isEmpty) return true; // Optional field

    try {
      final trimmedUrl = url.trim();

      // Add protocol if missing
      String urlToValidate = trimmedUrl;
      if (!trimmedUrl.startsWith('http://') &&
          !trimmedUrl.startsWith('https://')) {
        urlToValidate = 'https://$trimmedUrl';
      }

      final uri = Uri.parse(urlToValidate);

      // Must have a host
      if (uri.host.isEmpty) {
        return false;
      }

      // Host must contain at least one dot (domain.extension)
      if (!uri.host.contains('.')) {
        return false;
      }

      // Basic domain validation - must have at least domain.tld
      final hostParts = uri.host.split('.');
      if (hostParts.length < 2 || hostParts.any((part) => part.isEmpty)) {
        return false;
      }

      // Last part must be at least 2 characters (TLD)
      if (hostParts.last.length < 2) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // User Information Form Validation
  bool _validateUserInformationForm() {
    if (_firstNameController.text.trim().isEmpty) {
      _showFieldValidationError('First name is required', _firstNameFocusNode);
      return false;
    }
    if (!_isValidName(_firstNameController.text)) {
      _showFieldValidationError(
        'First name must contain only letters and spaces',
        _firstNameFocusNode,
      );
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showFieldValidationError('Last name is required', _lastNameFocusNode);
      return false;
    }
    if (!_isValidName(_lastNameController.text)) {
      _showFieldValidationError(
        'Last name must contain only letters and spaces',
        _lastNameFocusNode,
      );
      return false;
    }
    if (_userEmailController.text.trim().isEmpty) {
      _showFieldValidationError('Email is required', _userEmailFocusNode);
      return false;
    }
    if (!_isValidEmail(_userEmailController.text)) {
      _showFieldValidationError(
        'Please enter a valid email address',
        _userEmailFocusNode,
      );
      return false;
    }
    if (_userPhoneController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Phone number is required',
        _userPhoneFocusNode,
      );
      return false;
    }
    if (!_isValidPhoneNumber(_userPhoneController.text)) {
      _showFieldValidationError(
        'Phone number must be 10 digits or include country code with + (max 13 digits total)',
        _userPhoneFocusNode,
      );
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showFieldValidationError('Password is required', _passwordFocusNode);
      return false;
    }
    if (_passwordController.text.length < 8) {
      _showFieldValidationError(
        'Password must be at least 8 characters',
        _passwordFocusNode,
      );
      return false;
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      _showFieldValidationError(
        'Passwords do not match',
        _confirmPasswordFocusNode,
      );
      return false;
    }
    return true;
  }

  // Company Details Form Validation
  bool _validateCompanyDetailsForm() {
    if (_companyNameController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Company name is required',
        focusNodes['companyName']!,
      );
      return false;
    }
    if (_tradingNameController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Trading name is required',
        focusNodes['tradingName']!,
      );
      return false;
    }
    if (_registrationNumberController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Registration number is required',
        focusNodes['registrationNumber']!,
      );
      return false;
    }
    if (_vatNumberController.text.trim().isNotEmpty &&
        !_isValidNumbersOnly(_vatNumberController.text, minLength: 10)) {
      _showFieldValidationError(
        'VAT number must be at least 10 digits',
        focusNodes['vatNumber']!,
      );
      return false;
    }
    if (_yearEstablishedController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Year Established is required',
        focusNodes['yearEstablished']!,
      );
      return false;
    }
    final currentYear = DateTime.now().year;
    final enteredYear = int.tryParse(_yearEstablishedController.text.trim());
    if (enteredYear == null ||
        enteredYear < (currentYear - 100) ||
        enteredYear > currentYear) {
      _showFieldValidationError(
        'Please enter a valid year between ${currentYear - 100} and $currentYear',
        focusNodes['yearEstablished']!,
      );
      return false;
    }
    if (_websiteUrlController.text.trim().isNotEmpty &&
        !_isValidURL(_websiteUrlController.text)) {
      _showFieldValidationError(
        'Please enter a valid website URL (e.g., example.com or https://example.com)',
        focusNodes['websiteUrl']!,
      );
      return false;
    }
    return true;
  }

  // Company Address Form Validation
  bool _validateCompanyAddressForm() {
    if (_postalAddressController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Postal address is required',
        focusNodes['postalAddress']!,
      );
      return false;
    }
    if (_physicalAddressController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Physical address is required',
        focusNodes['physicalAddress']!,
      );
      return false;
    }
    if (_contactPersonNameController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Contact person name is required',
        focusNodes['contactPersonName']!,
      );
      return false;
    }
    if (!_isValidName(_contactPersonNameController.text)) {
      _showFieldValidationError(
        'Contact person name must contain only letters and spaces',
        focusNodes['contactPersonName']!,
      );
      return false;
    }
    if (_contactPersonTelephoneController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Contact person telephone is required',
        focusNodes['contactPersonTelephone']!,
      );
      return false;
    }
    if (!_isValidPhoneNumber(_contactPersonTelephoneController.text)) {
      _showFieldValidationError(
        'Contact telephone must be 10 digits or include country code with + (max 13 digits total)',
        focusNodes['contactPersonTelephone']!,
      );
      return false;
    }
    if (_contactPersonEmailController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Contact person email is required',
        focusNodes['contactPersonEmail']!,
      );
      return false;
    }
    if (!_isValidEmail(_contactPersonEmailController.text)) {
      _showFieldValidationError(
        'Please enter a valid contact person email',
        focusNodes['contactPersonEmail']!,
      );
      return false;
    }
    if (_platformWorkflowEmailController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Platform workflow email is required',
        focusNodes['platformWorkflowEmail']!,
      );
      return false;
    }
    if (!_isValidEmail(_platformWorkflowEmailController.text)) {
      _showFieldValidationError(
        'Please enter a valid platform workflow email',
        focusNodes['platformWorkflowEmail']!,
      );
      return false;
    }
    return true;
  }

  // Bank Account Form Validation
  bool _validateBankAccountForm() {
    if (_selectedBank == null || _selectedBank!.trim().isEmpty) {
      _showFieldValidationError(
        'Bank name is required',
        focusNodes['bankName']!,
      );
      return false;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Account number is required',
        focusNodes['accountNumber']!,
      );
      return false;
    }
    if (!_isValidNumbersOnly(
      _accountNumberController.text,
      minLength: 8,
      maxLength: 12,
    )) {
      _showFieldValidationError(
        'Account number must be between 8-12 digits',
        focusNodes['accountNumber']!,
      );
      return false;
    }
    if (_selectedBranchCode == null || _selectedBranchCode!.trim().isEmpty) {
      _showFieldValidationError(
        'Branch code is required',
        focusNodes['branchCode']!,
      );
      return false;
    }
    if (_accountHolderController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Account holder name is required',
        focusNodes['accountHolder']!,
      );
      return false;
    }
    if (!_isValidName(_accountHolderController.text)) {
      _showFieldValidationError(
        'Account holder name must contain only letters and spaces',
        focusNodes['accountHolder']!,
      );
      return false;
    }
    return true;
  }

  // Product Categories Form Validation
  bool _validateProductCategoriesForm() {
    if (selectedCategories.isEmpty) {
      CustomDialogs.showErrorDialog(
        context,
        'Please select at least one product category',
        onRetry: () {},
      );
      return false;
    }
    return true;
  }

  // Display On Platform Form Validation
  bool _validateDisplayOnPlatformForm() {
    if (!_isRegisteredNameSelected &&
        _tradingNameController.text.trim().isEmpty) {
      _showFieldValidationError(
        'Please select registered name or enter trading name',
        focusNodes['tradingName']!,
      );
      return false;
    }
    return true;
  }

  // Show field validation error with focus
  void _showFieldValidationError(String message, FocusNode focusNode) {
    CustomDialogs.showErrorDialog(
      context,
      message,
      onRetry: () {
        focusNode.requestFocus();
      },
    );
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        steps[currentStep].isCompleted = true;
      });

      // Save progress before moving to next step
      _saveFormProgress();

      if (currentStep < steps.length - 1) {
        setState(() {
          if (currentStep == 0) {
            _handleSignUp();
          } else {
            currentStep++;
          }
        });
        print("fgfg $currentStep");

        // Animate to next page with a smooth transition
        pageController.animateToPage(
          currentStep,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        // Handle final submission
        _handleFinalSubmission();
      }
    } else {
      _showValidationError();
    }
  }

  AuthApiService authApiService = AuthApiService();
  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });

      // Animate to previous page
      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleFinalSubmission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Submit business registration to Django backend
      final result = await _submitBusinessRegistration();

      setState(() {
        _isLoading = false;
      });

      if (result != null && result['success'] == true) {
        // Show success and navigate to completion
        setState(() {
          isApproval = true;
        });

        // Navigate to completion screen
        pageController.animateToPage(
          steps.length,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );

        // Show success message and navigate after a brief delay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Business registration submitted successfully! Welcome to your seller dashboard.',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to seller dashboard after success message
        _navigateToSellerDashboard();
      } else {
        // Handle submission error
        String errorMessage =
            result?['error'] ?? 'Registration failed. Please try again.';
        _showSubmissionError(
          "Network error occurred. Please check your connection and try again.",
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSubmissionError(
        'Network error occurred. Please check your connection and try again.',
      );
    }
  }

  void _showValidationError() {
    // The specific error message will be set by individual validation methods
    // This method is kept for backward compatibility
  }

  void _showSubmissionError(String message) {
    CustomDialogs.showErrorDialog(
      context,
      message,
      onRetry: () {
        // Retry submission
        _handleFinalSubmission();
      },
    );
  }

  Future<Map<String, dynamic>?> _submitBusinessRegistration() async {
    try {
      // Prepare the business registration data according to Django backend structure
      final businessRegistrationData = {
        "auth_user_id": Constants.currentUser?.uid,
        'seller': {
          'registered_company_name': _companyNameController.text,
          'trading_name': _tradingNameController.text,
          'registration_number': _registrationNumberController.text,
          'vat_number': _vatNumberController.text,
          'website_url': _websiteUrlController.text,
          'year_established': _yearEstablishedController.text,
          'product_category': selectedCategories.join(', '),
          'product_subcategory': selectedCategories.isNotEmpty
              ? selectedCategories.first
              : null,
        },
        'company_info': {
          'company_name': _companyNameController.text,
          'trading_name': _tradingNameController.text,
          'registration_number': _registrationNumberController.text,
          'vat_number': _vatNumberController.text,
          'website_url': _websiteUrlController.text,
          'year_established': _yearEstablishedController.text,
        },
        'contact_info': {
          'postal_address': _postalAddressController.text,
          'physical_address': _physicalAddressController.text,
          'contact_person_name': _contactPersonNameController.text,
          'contact_person_telephone': _contactPersonTelephoneController.text,
          'contact_person_email': _contactPersonEmailController.text,
          'platform_workflow_email': _platformWorkflowEmailController.text,
          'latitude': _currentLocation?.latitude,
          'longitude': _currentLocation?.longitude,
        },
        'banking_info': {
          'bank_name': _selectedBank ?? '',
          'account_number': _accountNumberController.text,
          'branch_code': _selectedBranchCode ?? '',
          'account_holder': _accountHolderController.text,
        },
        'product_categories': selectedCategories,
      };

      // Submit to Django backend
      final result = await authApiService.submitBusinessRegistration(
        businessRegistrationData,
      );

      // Save form data for future suggestions if submission is successful
      if (result != null && result['success'] != false) {
        await _saveFormDataForSuggestions();
        // Clear form progress on successful submission
        await FormProgressService.clearBusinessFormProgress();
      }

      return result;
    } catch (e) {
      print('Error in _submitBusinessRegistration: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _saveFormDataForSuggestions() async {
    try {
      final Map<String, String> formData = {
        'business_company_name': _companyNameController.text.trim(),
        'business_trading_name': _tradingNameController.text.trim(),
        'business_registration_number': _registrationNumberController.text
            .trim(),
        'business_website_url': _websiteUrlController.text.trim(),
        'business_year_established': _yearEstablishedController.text.trim(),
        'business_contact_person_name': _contactPersonNameController.text
            .trim(),
        'business_contact_telephone': _contactPersonTelephoneController.text
            .trim(),
        'business_contact_email': _contactPersonEmailController.text.trim(),
        'business_platform_email': _platformWorkflowEmailController.text.trim(),
        'business_account_holder': _accountHolderController.text.trim(),
      };

      // Remove empty values
      formData.removeWhere((key, value) => value.isEmpty);

      if (formData.isNotEmpty) {
        await FormDataService.saveMultipleFieldSuggestions(formData);
      }
    } catch (e) {
      print('Error saving form data for suggestions: $e');
    }
  }

  Future<void> _saveFormProgress() async {
    try {
      final Map<String, String> formData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'userEmail': _userEmailController.text.trim(),
        'userPhone': _userPhoneController.text.trim(),
        'companyName': _companyNameController.text.trim(),
        'tradingName': _tradingNameController.text.trim(),
        'registrationNumber': _registrationNumberController.text.trim(),
        'vatNumber': _vatNumberController.text.trim(),
        'websiteUrl': _websiteUrlController.text.trim(),
        'yearEstablished': _yearEstablishedController.text.trim(),
        'postalAddress': _postalAddressController.text.trim(),
        'physicalAddress': _physicalAddressController.text.trim(),
        'contactPersonName': _contactPersonNameController.text.trim(),
        'contactPersonTelephone': _contactPersonTelephoneController.text.trim(),
        'contactPersonEmail': _contactPersonEmailController.text.trim(),
        'platformWorkflowEmail': _platformWorkflowEmailController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'accountHolder': _accountHolderController.text.trim(),
      };

      await FormProgressService.saveBusinessFormProgress(
        currentStep: currentStep,
        formData: formData,
        selectedCategories: selectedCategories,
        selectedBank: _selectedBank,
        selectedBranchCode: _selectedBranchCode,
      );
    } catch (e) {
      print('Error saving form progress: $e');
    }
  }

  Future<void> _loadFormProgress() async {
    try {
      final progress = await FormProgressService.getBusinessFormProgress();
      if (progress != null) {
        setState(() {
          currentStep = progress['currentStep'] ?? 0;

          final formData = progress['formData'] as Map<String, dynamic>? ?? {};
          _firstNameController.text = formData['firstName'] ?? '';
          _lastNameController.text = formData['lastName'] ?? '';
          _userEmailController.text = formData['userEmail'] ?? '';
          _userPhoneController.text = formData['userPhone'] ?? '';
          _companyNameController.text = formData['companyName'] ?? '';
          _tradingNameController.text = formData['tradingName'] ?? '';
          _registrationNumberController.text =
              formData['registrationNumber'] ?? '';
          _vatNumberController.text = formData['vatNumber'] ?? '';
          _websiteUrlController.text = formData['websiteUrl'] ?? '';
          _yearEstablishedController.text = formData['yearEstablished'] ?? '';
          _postalAddressController.text = formData['postalAddress'] ?? '';
          _physicalAddressController.text = formData['physicalAddress'] ?? '';
          _contactPersonNameController.text =
              formData['contactPersonName'] ?? '';
          _contactPersonTelephoneController.text =
              formData['contactPersonTelephone'] ?? '';
          _contactPersonEmailController.text =
              formData['contactPersonEmail'] ?? '';
          _platformWorkflowEmailController.text =
              formData['platformWorkflowEmail'] ?? '';
          _accountNumberController.text = formData['accountNumber'] ?? '';
          _accountHolderController.text = formData['accountHolder'] ?? '';

          selectedCategories = List<String>.from(
            progress['selectedCategories'] ?? [],
          );
          _selectedBank = progress['selectedBank'];
          _selectedBranchCode = progress['selectedBranchCode'];

          // Mark completed steps
          for (int i = 0; i < currentStep; i++) {
            if (i < steps.length) {
              steps[i].isCompleted = true;
            }
          }
        });

        // Navigate to saved step
        WidgetsBinding.instance.addPostFrameCallback((_) {
          pageController.jumpToPage(currentStep);
        });
      }
    } catch (e) {
      print('Error loading form progress: $e');
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0: // User Information
        return _validateUserInformationForm();
      case 1: // OTP Verification
        return true; // OTP validation will be handled separately
      case 2: // Company Details
        return _validateCompanyDetailsForm();
      case 3: // Company Address
        return _validateCompanyAddressForm();
      case 4: // Company Bank Account
        return _validateBankAccountForm();
      case 5: // Product Categories
        return _validateProductCategoriesForm();
      case 6: // Display On Platform
        return _validateDisplayOnPlatformForm();
      default:
        return true;
    }
  }

  void _handleOTPSuccess() {
    // Mark OTP verification step as completed
    steps[1].isCompleted = true;

    // Navigate to company details form (step 2)
    setState(() {
      currentStep = 2;
    });

    // Animate to company details page
    pageController.animateToPage(
      currentStep,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToSellerDashboard() {
    // Add delay and context check to avoid Navigator conflicts
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Use GoRouter to navigate to dashboard
        context.go('/dashboard');
      }
    });
  }

  void _handleSignUp() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await authApiService.registerUser(
        email: _userEmailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phoneNumber: _userPhoneController.text,
        role: "seller",
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result != null) {
        // Check if registration was successful
        if (result['success'] != false &&
            result['statusCode'] != 400 &&
            result['statusCode'] != 500) {
          // Success case
          final message = result['message'] ?? 'User registered successfully';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          print("tyytyttyty ${message}");
          // Navigate to OTP verification
          if (message.contains("Please verify your email") ||
              message.contains("Please check your SMS") ||
              result['success'] == true) {
            print("tyytyttyty ${message}");
            currentStep = 1;
            setState(() {});

            // Animate to OTP verification page
            pageController.animateToPage(
              currentStep,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          }
        } else {
          // Handle errors - extract specific error message
          String errorMessage = 'Registration failed';

          if (result['errors'] != null) {
            final errorResponse = result['errors'] as Map<String, dynamic>;
            List<String> errorMessages = [];

            // Check if the errors field contains nested errors (from API response)
            if (errorResponse['errors'] != null) {
              final errors = errorResponse['errors'] as Map<String, dynamic>;

              // Extract all field errors
              errors.forEach((field, messages) {
                if (messages is List && messages.isNotEmpty) {
                  errorMessages.add(messages.first.toString());
                } else if (messages is String) {
                  errorMessages.add(messages);
                }
              });
            }
            // Handle direct field errors (most common case)
            else {
              errorResponse.forEach((field, messages) {
                if (messages is List && messages.isNotEmpty) {
                  errorMessages.add(messages.first.toString());
                } else if (messages is String) {
                  errorMessages.add(messages);
                }
              });
            }

            if (errorMessages.isNotEmpty) {
              errorMessage = errorMessages.join('\n');
            }
          } else if (result['error'] != null) {
            errorMessage = result['error'].toString();
          } else if (result['message'] != null) {
            errorMessage = result['message'].toString();
          } else if (result['statusCode'] == 500) {
            errorMessage =
                'Server error. Please check your password requirements.';
          }

          // Show clean error message
          CustomDialogs.showErrorDialog(
            context,
            errorMessage,
            onRetry: () => _handleSignUp(),
          );
        }
      } else {
        // Handle null response
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _getCoordinatesFromAddress([StateSetter? setDialogState]) async {
    if (_physicalAddressController.text.isEmpty) return;

    final address = _physicalAddressController.text.trim();

    // Validate address format before geocoding
    if (address.length < 5) {
      CustomDialogs.showErrorDialog(
        context,
        'Please enter a more complete address',
        onRetry: () => _getCoordinatesFromAddress(setDialogState),
      );
      return;
    }

    try {
      if (setDialogState != null) {
        setDialogState(() {
          _isLoadingLocation = true;
        });
      } else {
        setState(() {
          _isLoadingLocation = true;
        });
      }

      print('🔍 Attempting to geocode address: "$address"');

      // Try multiple geocoding approaches
      List<Location>? locations;

      // Method 1: Direct geocoding
      try {
        locations = await locationFromAddress(address);
        print('📍 Found ${locations.length} locations using direct geocoding');
      } catch (e) {
        print('❌ Direct geocoding failed: $e');

        // Method 2: Try with formatted address variations
        final addressVariations = _generateAddressVariations(address);

        for (String variation in addressVariations) {
          try {
            print('🔄 Trying variation: "$variation"');
            locations = await locationFromAddress(variation);
            if (locations.isNotEmpty) {
              print('✅ Success with variation: "$variation"');
              break;
            }
          } catch (variationError) {
            print('❌ Variation failed: $variationError');
            continue;
          }
        }
      }

      if (locations != null && locations.isNotEmpty) {
        final location = locations.first;
        final newLocation = LatLng(location.latitude, location.longitude);

        print('✅ Geocoding successful:');
        print('   Latitude: ${location.latitude}');
        print('   Longitude: ${location.longitude}');

        if (setDialogState != null) {
          setDialogState(() {
            _currentLocation = newLocation;
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _currentLocation = newLocation;
            _isLoadingLocation = false;
          });
        }

        _updateMarker();

        // Move camera to new location if map controller is available
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newLocation,
                zoom: 16, // Slightly closer zoom
              ),
            ),
          );
        }

        // Show success message
        CustomDialogs.showSuccessDialog(
          context,
          'Location found successfully!',
        );
      } else {
        print('❌ No locations found for address: "$address"');
        CustomDialogs.showErrorDialog(
          context,
          'Could not find location for "$address". Please try:\n'
          '• Adding more details (street number, city, country)\n'
          '• Checking spelling\n'
          '• Using a different format',
          onRetry: () => _getCoordinatesFromAddress(setDialogState),
        );
      }
    } on PlatformException catch (e) {
      print('❌ Platform exception during geocoding: ${e.message}');
      if (e.code == 'PERMISSION_DENIED') {
        CustomDialogs.showErrorDialog(
          context,
          'Location permission denied. Please enable location services.',
          onRetry: () => _getCoordinatesFromAddress(setDialogState),
        );
      } else if (e.code == 'NETWORK_ERROR') {
        CustomDialogs.showErrorDialog(
          context,
          'Network error. Please check your internet connection.',
          onRetry: () => _getCoordinatesFromAddress(setDialogState),
        );
      } else {
        CustomDialogs.showErrorDialog(
          context,
          'Platform error: ${e.message}',
          onRetry: () => _getCoordinatesFromAddress(setDialogState),
        );
      }
    } catch (e) {
      print('❌ Unexpected error during geocoding: $e');
      CustomDialogs.showErrorDialog(
        context,
        'Unexpected error occurred. Please try again.',
        onRetry: () => _getCoordinatesFromAddress(setDialogState),
      );
    } finally {
      if (setDialogState != null) {
        setDialogState(() {
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // Generate address variations to improve geocoding success rate
  List<String> _generateAddressVariations(String originalAddress) {
    List<String> variations = [];

    // Add country if missing (adjust based on your target region)
    if (!originalAddress.toLowerCase().contains('south africa') &&
        !originalAddress.toLowerCase().contains('sa')) {
      variations.add('$originalAddress, South Africa');
      variations.add('$originalAddress, SA');
    }

    // Add common city if it seems incomplete
    if (originalAddress.split(',').length < 2) {
      variations.add('$originalAddress, Johannesburg, South Africa');
      variations.add('$originalAddress, Cape Town, South Africa');
      variations.add('$originalAddress, Durban, South Africa');
    }

    // Try with postal code format adjustments
    final cleanAddress = originalAddress.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanAddress != originalAddress) {
      variations.add(cleanAddress);
    }

    return variations;
  }

  // Get address from coordinates (reverse geocoding)
  Future<void> _getAddressFromCoordinates(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address =
            '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}, ${placemark.country}';

        // Update the physical address controller with the new address
        _physicalAddressController.text = address;

        print('Address for coordinates: $address');
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
  }

  // Update marker on map
  void _updateMarker() {
    if (_currentLocation != null) {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _physicalAddressController.text.isNotEmpty
                ? _physicalAddressController.text
                : 'Custom location',
          ),
        ),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show mobile version for screens smaller than 800px
    if (MediaQuery.of(context).size.width < 800) {
      return const BusinessSignUpPageMobile();
    }

    return Scaffold(
      backgroundColor: Constants.gtaColorLight,
      body: Padding(
        padding: EdgeInsets.all(0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(border: null),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [

              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width,

                  child: Row(
                    children: [
                      // Left Side - Stepper
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: 350,
                          padding: EdgeInsets.only(top: 0, bottom: 0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              bottomLeft: Radius.circular(0),
                            ),
                            color: Constants.ftaColorLight,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Scrollbar(
                                  controller: _scrollController,
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 24.0,
                                    ),
                                    child: Column(
                                      children: steps.asMap().entries.map((
                                        entry,
                                      ) {
                                        int index = entry.key;
                                        return _buildStepItem(index);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Side - Form
                      Expanded(
                        flex: 5,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.all(32),
                          constraints: BoxConstraints(
                            maxWidth: 850,
                            maxHeight: 1200,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(0),
                              bottomRight: Radius.circular(0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Header
                              currentStep == steps.length - 1
                                  ? SizedBox.shrink()
                                  : SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.5,
                                      child: Row(
                                        children: [
                                          currentStep > 0
                                              ? IconButton(
                                                  onPressed: currentStep > 0
                                                      ? _previousStep
                                                      : null,
                                                  style: IconButton.styleFrom(
                                                    backgroundColor:
                                                        Constants.ftaColorLight,
                                                    foregroundColor:
                                                        Constants.ctaColorLight,
                                                    elevation: 5,
                                                    shadowColor: Colors.black54,
                                                  ),
                                                  icon: Icon(
                                                    CupertinoIcons.back,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : SizedBox.shrink(),
                                          currentStep > 0
                                              ? const SizedBox(width: 20)
                                              : SizedBox.shrink(),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Application to Register a Business',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      Constants.ftaColorLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                              currentStep == steps.length - 1
                                  ? SizedBox.shrink()
                                  : (currentStep > 0
                                        ? SizedBox.shrink()
                                        : const SizedBox(height: 16)),

                              // Form Content
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 800),
                                  transitionBuilder:
                                      (
                                        Widget child,
                                        Animation<double> animation,
                                      ) {
                                        return SlideTransition(
                                          position:
                                              Tween<Offset>(
                                                begin: const Offset(0.1, 0),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: animation,
                                                  curve: Curves.easeInOutCubic,
                                                ),
                                              ),
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        );
                                      },
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    child: Center(
                                      child: PageView(
                                        controller: pageController,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        children: [
                                          _buildUserInformationForm(),
                                          SellerOTPVerificationScreen(
                                            email: _userEmailController.text,
                                            phone: _userPhoneController.text,
                                            onSuccess: _handleOTPSuccess,
                                          ),
                                          _buildCompanyDetailsForm(),
                                          _buildCompanyAddressForm(),
                                          _buildBankAccountForm(),
                                          _buildProductCategoriesForm(),
                                          _buildDisplayOnPlatformForm(),
                                          BusinessRegistrationCompleteWidget(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Navigation Button
                              const SizedBox(height: 24),
                              currentStep == steps.length - 1
                                  ? Center(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.5,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            _handleFinalSubmission();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Constants.ctaColorLight,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            elevation: _isLoading ? 0 : 2,
                                            shadowColor: Constants.ctaColorLight
                                                .withOpacity(0.3),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 600,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    key: ValueKey('loading'),
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : Text(
                                                    'Enter BIDR World',
                                                    key: ValueKey(
                                                      'text_${currentStep}',
                                                    ),
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : currentStep ==
                                        1 // Hide Next button on OTP verification step
                                  ? const SizedBox.shrink()
                                  : Center(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 600,
                                        ),
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.4,
                                        height: 45,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _nextStep,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Constants.ctaColorLight,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            elevation: _isLoading ? 0 : 2,
                                            shadowColor: Constants.ctaColorLight
                                                .withOpacity(0.3),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 600,
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    key: ValueKey('loading'),
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  )
                                                : Text(
                                                    currentStep ==
                                                            steps.length - 1
                                                        ? 'Submit Application'
                                                        : 'Next',
                                                    key: ValueKey(
                                                      'text_${currentStep}',
                                                    ),
                                                    style: GoogleFonts.manrope(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(int index) {
    bool isActive = index == currentStep;
    bool isCompleted = steps[index].isCompleted;
    bool isLastStep = index == steps.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical line and circle container
          SizedBox(
            width: 30,
            child: Column(
              children: [
                // Circle with number or checkmark
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Constants.ctaColorLight
                        : isActive
                        ? Constants.ctaColorLight
                        : Colors.grey[300],
                    boxShadow: isActive || isCompleted
                        ? [
                            BoxShadow(
                              color: Constants.ctaColorLight.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                              key: ValueKey('check'),
                            )
                          : Text(
                              '${index + 1}',
                              key: ValueKey('number_$index'),
                              style: GoogleFonts.manrope(
                                color: isActive
                                    ? Colors.white
                                    : Constants.ftaColorLight,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),

                // Vertical line (only if not last step)
                if (!isLastStep)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 2,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: (isCompleted || index < currentStep)
                          ? Constants.ctaColorLight
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Step info
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 0, bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 600),
                    style: GoogleFonts.manrope(
                      color: isActive ? Constants.ctaColorLight : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Text(steps[index].title),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[index].subtitle,
                    style: GoogleFonts.manrope(
                      color: Colors.grey[500],
                      fontSize: 13,
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

  Widget _buildUserInformationForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: Text(
                'This page will allow you to register a business in a few easy steps. Please provide all the required information. Once the application has been received, the information will be vetted and we will inform you of the status thereof. If successful, the business will be added to our database and you will immediately be eligible to receive requests as per the selections in this application.',
                textAlign: TextAlign.justify,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personal Information',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your personal details to get started',
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildCustomTextField(
                        'Enter first name',
                        _firstNameController,
                        _firstNameFocusNode,
                        _lastNameFocusNode,
                        isName: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildCustomTextField(
                        'Enter last name',
                        _lastNameController,
                        _lastNameFocusNode,
                        _userEmailFocusNode,
                        isName: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 8),
            _buildCustomTextField(
              'Enter email address',
              _userEmailController,
              _userEmailFocusNode,
              _userPhoneFocusNode,
              isEmail: true,
            ),
            const SizedBox(height: 24),

            _buildCustomTextField(
              'Enter phone number',
              _userPhoneController,
              _userPhoneFocusNode,
              _passwordFocusNode,
              integersOnly: true,
            ),
            const SizedBox(height: 24),

            _buildCustomTextField(
              'Enter password',
              _passwordController,
              _passwordFocusNode,
              _confirmPasswordFocusNode,
              isPassword: true,
            ),
            const SizedBox(height: 24),

            _buildCustomTextField(
              'Confirm password',
              _confirmPasswordController,
              _confirmPasswordFocusNode,
              _firstNameFocusNode,
              isPassword: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPVerificationForm() {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Verification',
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We have sent a verification code to ${_userEmailController.text}',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Text(
            'Enter Verification Code',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'OTP verification will be implemented here',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              // Resend OTP logic
            },
            child: Text(
              'Resend Code',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Constants.ctaColorLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDetailsForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          _buildSuggestionField(
            'Registered Company Name (CIPC)*',
            'Enter Registered Company Name',
            _companyNameController,
            focusNodes['companyName']!,
            'business_company_name',
            isName: true,
          ),
          const SizedBox(height: 24),
          _buildSuggestionField(
            'Trading Name',
            'Enter Company Trading Name',
            _tradingNameController,
            focusNodes['tradingName']!,
            'business_trading_name',
          ),
          const SizedBox(height: 24),
          _buildSuggestionField(
            'Registration Number',
            'Enter Registration Number',
            _registrationNumberController,
            focusNodes['registrationNumber']!,
            'business_registration_number',
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'VAT Number',
            'Enter VAT Number',
            _vatNumberController,
            focusNodes['vatNumber']!,
            integersOnly: true,
          ),
          const SizedBox(height: 24),
          _buildSuggestionField(
            'Website URL',
            'Enter Company Website URL',
            _websiteUrlController,
            focusNodes['websiteUrl']!,
            'business_website_url',
          ),
          const SizedBox(height: 24),
          _buildYearAutocomplete(),
          const SizedBox(height: 24),
          _buildFileUploadField(),
        ],
      ),
    );
  }

  Widget _buildCompanyAddressForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          _buildAddressField(
            'Postal Address*',
            'Enter Postal Address',
            _postalAddressController,
            focusNodes['postalAddress']!,
            showPinIcon: true,
          ),
          const SizedBox(height: 24),
          _buildAddressField(
            'Physical Address*',
            'Enter Physical Address',
            _physicalAddressController,
            focusNodes['physicalAddress']!,
            showPinIcon: true,
          ),
          const SizedBox(height: 24),
          _buildLocationDropdown(),
          const SizedBox(height: 24),
          _buildSuggestionField(
            'Contact Person Name',
            'Enter Contact Person Name',
            _contactPersonNameController,
            focusNodes['contactPersonName']!,
            'business_contact_person_name',
            isName: true,
          ),
          const SizedBox(height: 24),
          _buildSuggestionField(
            'Contact Person Telephone',
            'Enter Contact Person Telephone',
            _contactPersonTelephoneController,
            focusNodes['contactPersonTelephone']!,
            'business_contact_telephone',
            integersOnly: true,
          ),
          const SizedBox(height: 24),
          _buildSuggestionField(
            'Contact Person Email Address',
            'Enter Contact Person Email Address',
            _contactPersonEmailController,
            focusNodes['contactPersonEmail']!,
            'business_contact_email',
            isEmail: true,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Platform Workflow Email Address',
            'Enter Platform Workflow Email Address',
            _platformWorkflowEmailController,
            focusNodes['platformWorkflowEmail']!,
            isEmail: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location*',
          style: GoogleFonts.manrope(
            color: const Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.white,
          ),
          child: InkWell(
            onTap: _showLocationPickerDialog,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color:
                        _selectedLocationText != null &&
                            _selectedLocationText!.isNotEmpty
                        ? Constants.ctaColorLight
                        : const Color(0xFF666666),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedLocationText != null &&
                              _selectedLocationText!.isNotEmpty
                          ? _selectedLocationText!
                          : 'Select Location on Map',
                      style: GoogleFonts.manrope(
                        color:
                            _selectedLocationText != null &&
                                _selectedLocationText!.isNotEmpty
                            ? const Color(0xFF333333)
                            : const Color(0xFF999999),
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.map_outlined,
                    color: const Color(0xFF666666),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLocationPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _LocationPickerDialog(
          apiKey: _googleMapsApiKey,
          initialLocation: const LatLng(-26.2041, 28.0473), // Johannesburg
          onLocationSelected: (LatLng location, String address) {
            setState(() {
              _selectedLocation = location;
              _selectedAddress = address;
              _selectedLocationText = address;
              _locationController.text = address;
            });
          },
        );
      },
    );
  }

  void _showLocationPickerDialog() {
    _showLocationPicker();
  }

  // Initialize location when dialog opens
  void _initializeLocationFromAddress() {
    if (_physicalAddressController.text.isNotEmpty) {
      _getCoordinatesFromAddress(null);
    }
  }

  // Get coordinates from physical address

  Widget _buildBankDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bank Name*',
          style: GoogleFonts.manrope(
            color: const Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedBank,
              hint: Text(
                'Select Bank',
                style: GoogleFonts.manrope(
                  color: const Color(0xFF999999),
                  fontSize: 16,
                ),
              ),
              items: _southAfricanBanks.keys.map((String bank) {
                return DropdownMenuItem<String>(
                  value: bank,
                  child: Text(
                    bank,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF333333),
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBank = newValue;
                  _selectedBranchCode = newValue != null
                      ? _southAfricanBanks[newValue]
                      : null;
                  _bankNameController.text = newValue ?? '';
                  _branchCodeController.text = _selectedBranchCode ?? '';
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branch Code*',
          style: GoogleFonts.manrope(
            color: const Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.white,
          ),
          child: Text(
            _selectedBranchCode ?? 'Select a bank first',
            style: GoogleFonts.manrope(
              color: _selectedBranchCode != null
                  ? const Color(0xFF333333)
                  : const Color(0xFF999999),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankAccountForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          // Bank Name Dropdown
          _buildBankDropdown(),
          const SizedBox(height: 24),
          // Branch Code (auto-filled, read-only)
          _buildBranchCodeField(),
          const SizedBox(height: 24),
          _buildInputField(
            'Account Number*',
            'Enter Account Number',
            _accountNumberController,
            focusNodes['accountNumber']!,
            integersOnly: true,
          ),
          const SizedBox(height: 24),
          _buildInputField(
            'Account Holder Name*',
            'Enter Account Holder Name',
            _accountHolderController,
            focusNodes['accountHolder']!,
            isName: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCategoriesForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          Text(
            'Select Product Categories',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose the categories that best describe your products:',
            style: GoogleFonts.manrope(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 24),
          Container(
            height: 350, // Fixed height for ListView
            child: ListView.builder(
              itemCount: availableCategories.length,
              itemBuilder: (context, index) {
                String category = availableCategories[index];
                bool isSelected = selectedCategories.contains(category);
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    title: Text(
                      category,
                      style: GoogleFonts.manrope(
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    trailing: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedCategories.remove(category);
                          } else {
                            selectedCategories.add(category);
                          }
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Constants.ctaColorLight
                                : Colors.grey,
                            width: 2,
                          ),
                          color: isSelected
                              ? Constants.ctaColorLight
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedCategories.remove(category);
                        } else {
                          selectedCategories.add(category);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayOnPlatformForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32),
          // Registered Name with Checkbox
          _buildRegisteredNameWithCheckbox("Registered name"),
          const SizedBox(height: 24),
          // Trading Name
          _buildInputField(
            'Trading Name',
            'Enter Trading Name',
            _tradingNameController,
            focusNodes['tradingName']!,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredNameWithCheckbox(String desName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Constants.ftaColorLight),
            borderRadius: BorderRadius.circular(360),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  desName,
                  style: GoogleFonts.manrope(color: Colors.black, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isRegisteredNameSelected = !_isRegisteredNameSelected;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isRegisteredNameSelected
                        ? Constants.ctaColorLight
                        : Colors.transparent,
                    border: Border.all(
                      color: _isRegisteredNameSelected
                          ? Constants.ctaColorLight
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(360),
                  ),
                  child: _isRegisteredNameSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller,
    FocusNode focusNode, {
    bool integersOnly = false,
    bool isName = false,
    bool isEmail = false,
    int? maxLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCustomTextField(
          hint,
          controller,
          focusNode,
          null,
          integersOnly: integersOnly,
          isName: isName,
          isEmail: isEmail,
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }

  List<String> _getRecentYears() {
    final currentYear = DateTime.now().year;
    final List<String> years = [];

    // Add years from current year back to 50 years ago
    for (int i = 0; i <= 50; i++) {
      years.add((currentYear - i).toString());
    }

    return years;
  }

  Widget _buildAddressField(
    String label,
    String hint,
    TextEditingController controller,
    FocusNode focusNode, {
    bool showPinIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: const Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
            color: Colors.white,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 4,
            minLines: 4,
            style: GoogleFonts.manrope(
              color: const Color(0xFF333333),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                color: const Color(0xFF999999),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              suffixIcon: showPinIcon
                  ? Icon(Icons.location_pin, color: const Color(0xFF666666))
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionField(
    String label,
    String hint,
    TextEditingController controller,
    FocusNode focusNode,
    String fieldKey, {
    bool integersOnly = false,
    bool isName = false,
    bool isEmail = false,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            color: const Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<String>>(
          future: FormDataService.getFieldSuggestions(fieldKey),
          builder: (context, snapshot) {
            final suggestions = snapshot.data ?? [];

            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return suggestions.take(
                    5,
                  ); // Show recent suggestions when empty
                }
                return suggestions
                    .where((String suggestion) {
                      return suggestion.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    })
                    .take(5);
              },
              fieldViewBuilder:
                  (
                    context,
                    fieldController,
                    fieldFocusNode,
                    onEditingComplete,
                  ) {
                    // Sync with our main controller
                    if (controller.text != fieldController.text) {
                      fieldController.text = controller.text;
                    }

                    // Add listener to update main controller
                    fieldController.addListener(() {
                      if (controller.text != fieldController.text) {
                        controller.text = fieldController.text;
                      }
                    });

                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: fieldController,
                        focusNode: focusNode,
                        keyboardType: integersOnly
                            ? TextInputType.number
                            : TextInputType.text,
                        obscureText: isPassword,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF333333),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          hintStyle: GoogleFonts.manrope(
                            color: const Color(0xFF999999),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          suffixIcon: suffixIcon,
                        ),
                        onEditingComplete: onEditingComplete,
                        onChanged: (value) {
                          // Save suggestion when user types
                          if (value.trim().isNotEmpty) {
                            FormDataService.saveFieldSuggestion(
                              fieldKey,
                              value.trim(),
                            );
                          }
                        },
                      ),
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                if (options.isEmpty) return Container();

                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 300,
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(option),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: index < options.length - 1
                                        ? Colors.black
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 16,
                                    color: const Color(0xFF666666),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF333333),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              onSelected: (String selection) {
                controller.text = selection;
                FormDataService.saveFieldSuggestion(fieldKey, selection);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Year Established*',
          style: GoogleFonts.manrope(
            color: const Color(0xFF333333),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _getRecentYears().where((String year) {
              return year.contains(textEditingValue.text.toLowerCase());
            });
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
                // Sync with our main controller
                if (_yearEstablishedController.text != controller.text) {
                  controller.text = _yearEstablishedController.text;
                }

                // Add listener to update main controller
                controller.addListener(() {
                  if (_yearEstablishedController.text != controller.text) {
                    _yearEstablishedController.text = controller.text;
                  }
                });

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                    color: Colors.white,
                  ),
                  child: TextFormField(
                    controller: controller,
                    focusNode: focusNodes['yearEstablished']!,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF333333),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter Year Established',
                      hintStyle: GoogleFonts.manrope(
                        color: const Color(0xFF999999),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onEditingComplete: onEditingComplete,
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 300,
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: index < options.length - 1
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            option,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF333333),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (String selection) {
            _yearEstablishedController.text = selection;
          },
        ),
      ],
    );
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: true,
        withData: kIsWeb, // Load file bytes for web
        withReadStream: !kIsWeb, // Use streams for mobile
      );

      if (result != null) {
        List<String> oversizedFiles = [];

        setState(() {
          for (var file in result.files) {
            // Check file size (10MB = 10 * 1024 * 1024 bytes)
            final fileSize = kIsWeb ? (file.bytes?.length ?? 0) : (file.size);

            if (fileSize > 10 * 1024 * 1024) {
              oversizedFiles.add('${file.name} (${_formatFileSize(fileSize)})');
              continue;
            }

            // On web: file.bytes is available
            // On mobile: file.path is available
            if (kIsWeb ? file.bytes != null : file.path != null) {
              _uploadedDocuments.add(file);
            }
          }
        });

        if (oversizedFiles.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'The following files exceed 10MB limit:\n${oversizedFiles.join('\n')}',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking files: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeDocument(int index) {
    setState(() {
      _uploadedDocuments.removeAt(index);
    });
  }

  Widget _buildFileUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload CIPC Documents',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 2),
              color: Colors.white,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_upload_outlined,
                  color: Color(0xFF999999),
                ),
                const SizedBox(width: 12),
                Text(
                  _uploadedDocuments.isNotEmpty
                      ? '${_uploadedDocuments.length} document(s) uploaded'
                      : 'Upload CIPC Documents',
                  style: GoogleFonts.manrope(
                    color: Color(0xFF999999),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_uploadedDocuments.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Uploaded Documents',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _uploadedDocuments.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final file = _uploadedDocuments[index];
                    final fileName = _getFileName(file);
                    final isImage =
                        fileName.toLowerCase().endsWith('.jpg') ||
                        fileName.toLowerCase().endsWith('.jpeg') ||
                        fileName.toLowerCase().endsWith('.png');

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          if (isImage)
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: _buildImageWidget(file),
                              ),
                            )
                          else
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Icon(
                                Icons.description,
                                color: Colors.grey[600],
                                size: 24,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getFileSize(file),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeDocument(index),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                              size: 20,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getFileName(PlatformFile file) {
    if (kIsWeb) {
      return file.name;
    } else {
      return path.basename(file.path ?? file.name);
    }
  }

  Widget _buildImageWidget(PlatformFile file) {
    if (kIsWeb) {
      // On web, use file.bytes
      if (file.bytes != null) {
        return Image.memory(file.bytes!, fit: BoxFit.cover);
      } else {
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.image, color: Colors.grey[600]),
        );
      }
    } else {
      // On mobile, use file.path
      if (file.path != null && !kIsWeb) {
        return Image.file(
          (!kIsWeb
              ? File(file.path!)
              : throw UnsupportedError('Cannot use File on web')),
          fit: BoxFit.cover,
        );
      } else {
        return Container(
          color: Colors.grey[300],
          child: Icon(Icons.image, color: Colors.grey[600]),
        );
      }
    }
  }

  String _getFileSize(PlatformFile file) {
    try {
      int? bytes;
      if (kIsWeb) {
        bytes = file.bytes?.length ?? file.size;
      } else {
        if (file.path != null) {
          bytes =
              (!kIsWeb
                      ? File(file.path!)
                      : throw UnsupportedError('Cannot use File on web'))
                  .lengthSync();
        } else {
          bytes = file.size;
        }
      }

      if (bytes == null) return 'Unknown size';

      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
    bool isPassword = false,
    bool isReadOnly = false,
    bool integersOnly = false,
    bool isName = false,
    bool isEmail = false,
  }) {
    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      textInputAction: nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
      isPasswordField: isPassword,
      isEditable: !isReadOnly,
      integersOnly: integersOnly,
      maxLength:
          integersOnly &&
              (hintText.toLowerCase().contains('phone') ||
                  hintText.toLowerCase().contains('telephone'))
          ? 13
          : (integersOnly ? 10 : null),
      suffix: suffixIcon,
      onChanged: (value) {
        // Real-time validation and formatting
        if (integersOnly) {
          // For phone number fields, allow + and digits
          if (hintText.toLowerCase().contains('phone') ||
              hintText.toLowerCase().contains('telephone')) {
            final phoneAllowed = value.replaceAll(RegExp(r'[^0-9+]'), '');
            if (phoneAllowed != value) {
              controller.value = TextEditingValue(
                text: phoneAllowed,
                selection: TextSelection.collapsed(offset: phoneAllowed.length),
              );
            }
          } else {
            // For other number fields, ensure only digits
            final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (digitsOnly != value) {
              controller.value = TextEditingValue(
                text: digitsOnly,
                selection: TextSelection.collapsed(offset: digitsOnly.length),
              );
            }
          }
        } else if (isName) {
          // For name fields, only allow letters and spaces
          final lettersOnly = value.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
          if (lettersOnly != value) {
            controller.value = TextEditingValue(
              text: lettersOnly,
              selection: TextSelection.collapsed(offset: lettersOnly.length),
            );
          }
        }
      },
      onSubmitted: (value) {
        // Validate field before moving to next
        bool isValid = true;
        String? errorMessage;

        if (isEmail && value.isNotEmpty && !_isValidEmail(value)) {
          isValid = false;
          errorMessage = 'Please enter a valid email address';
        } else if (integersOnly && value.isNotEmpty) {
          if (hintText.toLowerCase().contains('phone') ||
              hintText.toLowerCase().contains('telephone')) {
            if (!_isValidPhoneNumber(value)) {
              isValid = false;
              errorMessage =
                  'Phone number must be 10 digits or include country code with + (max 13 digits total)';
            }
          } else if (hintText.toLowerCase().contains('account number')) {
            if (!_isValidNumbersOnly(value, minLength: 8, maxLength: 12)) {
              isValid = false;
              errorMessage = 'Account number must be between 8-12 digits';
            }
          }
        } else if (isName && value.isNotEmpty && !_isValidName(value)) {
          isValid = false;
          errorMessage = 'This field must contain only letters and spaces';
        }

        if (!isValid && errorMessage != null) {
          _showFieldValidationError(errorMessage, focusNode);
          return;
        }

        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
    );
  }
}

class StepInfo {
  final String title;
  final String subtitle;
  bool isCompleted;

  StepInfo({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
  });
}

class _LocationPickerDialog extends StatefulWidget {
  final String apiKey;
  final LatLng initialLocation;
  final Function(LatLng location, String address) onLocationSelected;

  const _LocationPickerDialog({
    Key? key,
    required this.apiKey,
    required this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  late GoogleMapController _mapController;
  LatLng _currentLocation = const LatLng(-26.2041, 28.0473);
  String _currentAddress = '';
  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _physicalAddressController =
      TextEditingController();
  List<Map<String, dynamic>> _searchSuggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _updateMarker();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateMarker() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _currentLocation,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _currentAddress.isNotEmpty
                ? _currentAddress
                : 'Tap to select',
          ),
        ),
      };
    });
  }

  void _onMapTap(LatLng location) async {
    setState(() {
      _currentLocation = location;
    });

    _updateMarker();

    // Get address from coordinates using reverse geocoding
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = [
          placemark.street,
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((s) => s != null && s.isNotEmpty).join(', ');

        // Update the physical address controller with actual address
        setState(() {
          _physicalAddressController.text = _currentAddress;
        });
      } else {
        _currentAddress =
            '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        setState(() {
          _physicalAddressController.text = _currentAddress;
        });
      }
    } catch (e) {
      _currentAddress =
          '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
      setState(() {
        _physicalAddressController.text = _currentAddress;
      });
    }

    _updateMarker();
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> suggestions = [];

      for (Location location in locations) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            suggestions.add({
              'address': [
                placemark.street,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country,
              ].where((s) => s != null && s.isNotEmpty).join(', '),
              'location': LatLng(location.latitude, location.longitude),
            });
          }
        } catch (e) {
          // Skip if reverse geocoding fails
        }
      }

      setState(() {
        _searchSuggestions = suggestions
            .take(5)
            .toList(); // Limit to 5 suggestions
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchSuggestions.clear();
        _isSearching = false;
      });
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final location = suggestion['location'] as LatLng;
    final address = suggestion['address'] as String;

    setState(() {
      _currentLocation = location;
      _currentAddress = address;
      _searchController.text = address;
      _searchSuggestions.clear();
    });

    _updateMarker();

    // Move camera to selected location
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Modern Header with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Constants.ctaColorLight,
                    Constants.ctaColorLight.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Location',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Compact Search Section
            Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.manrope(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: GoogleFonts.manrope(
                          color: const Color(0xFF999999),
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Constants.ctaColorLight,
                          size: 22,
                        ),
                        suffixIcon: _isSearching
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Constants.ctaColorLight,
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                color: const Color(0xFF666666),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchSuggestions.clear();
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        // Debounce search
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (_searchController.text == value &&
                              value.isNotEmpty) {
                            _searchPlaces(value);
                          }
                        });
                      },
                    ),
                  ),
                  // Compact Search Suggestions
                  if (_searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _searchSuggestions[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _selectSuggestion(suggestion),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Constants.ctaColorLight
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        color: Constants.ctaColorLight,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        suggestion['address'],
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          color: const Color(0xFF333333),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            // Map
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: 15,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                onTap: _onMapTap,
              ),
            ),
            // Modern Footer
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentAddress.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Constants.ctaColorLight,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentAddress,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: const Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Tap on the map to select a location',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.black),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF666666),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentAddress.isNotEmpty
                              ? () {
                                  widget.onLocationSelected(
                                    _currentLocation,
                                    _currentAddress,
                                  );
                                  Navigator.pop(context);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Confirm Location',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
