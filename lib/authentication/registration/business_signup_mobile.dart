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

class BusinessSignUpPageMobile extends StatefulWidget {
  const BusinessSignUpPageMobile({super.key});

  @override
  State<BusinessSignUpPageMobile> createState() => _BusinessSignUpPageMobileState();
}

class _BusinessSignUpPageMobileState extends State<BusinessSignUpPageMobile> {
  int currentStep = 0;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  bool _isLoadingLocation = false;
  PageController pageController = PageController();

  // Step 0 - User Information Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();

  // Step 2 - Company Address Controllers
  final TextEditingController _postalAddressController = TextEditingController();
  final TextEditingController _physicalAddressController = TextEditingController();
  final TextEditingController _contactPersonNameController = TextEditingController();
  final TextEditingController _contactPersonTelephoneController = TextEditingController();
  final TextEditingController _contactPersonEmailController = TextEditingController();
  final TextEditingController _platformWorkflowEmailController = TextEditingController();

  // Step 3 - Bank Account Controllers
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _accountHolderController = TextEditingController();

  // Step 4 - Product Categories
  List<String> selectedCategories = [];
  final List<String> availableCategories = [
    'Engines Parts',
    'Batteries',
    'Transmission Parts',
    'Body Parts',
    'Suspension Parts',
  ];

  // Step 5 - Display on Platform
  final TextEditingController _tradingDisplayNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Step 6 - Authorization
  final TextEditingController _authPersonNameController = TextEditingController();
  final TextEditingController _authPersonEmailController = TextEditingController();
  final TextEditingController _authPersonPhoneController = TextEditingController();

  // Focus Nodes
  final Map<String, FocusNode> focusNodes = {};

  List<PlatformFile> _uploadedDocuments = [];
  String? _selectedLocationText;
  bool _isLoading = false;

  // Location picker variables
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  final String _googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY"; // Replace with actual API key
  final TextEditingController _locationController = TextEditingController();
  bool _isRegisteredNameSelected = false;
  bool isApproval = false;

  final List<StepInfo> steps = [
    StepInfo(
      title: 'User Information',
      subtitle: 'Personal Details',
      isCompleted: false,
    ),
    StepInfo(
      title: 'OTP Verification',
      subtitle: 'Verify Email',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Details',
      subtitle: 'Company Info',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Company Address',
      subtitle: 'Location Details',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Bank Account',
      subtitle: 'Banking Info',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Product Categories',
      subtitle: 'Select Products',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Display Platform',
      subtitle: 'Trading Name',
      isCompleted: false,
    ),
    StepInfo(
      title: 'Authorization',
      subtitle: 'Company Auth',
      isCompleted: false,
    ),
  ];

  Timer? _addressValidationTimer;
  AuthApiService authApiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
    _physicalAddressController.addListener(() {
      if (_selectedLocationText != null && _physicalAddressController.text.isNotEmpty) {
        setState(() {
          _selectedLocationText = null;
        });
      }
      if (_physicalAddressController.text.isEmpty && _selectedLocationText != null) {
        setState(() {
          _selectedLocationText = null;
        });
      }
      _debounceAddressValidation();
    });
  }

  void _initializeFocusNodes() {
    List<String> fieldNames = [
      'companyName', 'tradingName', 'registrationNumber', 'vatNumber', 'websiteUrl',
      'postalAddress', 'physicalAddress', 'contactPersonName', 'contactPersonTelephone',
      'contactPersonEmail', 'platformWorkflowEmail', 'bankName', 'accountNumber',
      'branchCode', 'accountHolder', 'tradingDisplayName', 'description',
      'authPersonName', 'authPersonEmail', 'authPersonPhone',
    ];

    for (String name in fieldNames) {
      focusNodes[name] = FocusNode();
    }
  }

  @override
  void dispose() {
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

  void _debounceAddressValidation() {
    _addressValidationTimer?.cancel();
    _addressValidationTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_physicalAddressController.text.isNotEmpty) {
        _validatePhysicalAddress();
      }
    });
  }

  void _validatePhysicalAddress() {
    String address = _physicalAddressController.text.trim();
    if (address.length < 10) {
      print('Address might be incomplete: $address');
      return;
    }
    print('Validating address: $address');
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Phone number validation helper
  bool _isValidPhoneNumber(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return cleanPhone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(cleanPhone);
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

  // Validation methods (same as desktop version)
  bool _validateUserInformationForm() {
    if (_firstNameController.text.trim().isEmpty) {
      _showFieldValidationError('First name is required', _firstNameFocusNode);
      return false;
    }
    if (!_isValidName(_firstNameController.text)) {
      _showFieldValidationError('First name must contain only letters and spaces', _firstNameFocusNode);
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showFieldValidationError('Last name is required', _lastNameFocusNode);
      return false;
    }
    if (!_isValidName(_lastNameController.text)) {
      _showFieldValidationError('Last name must contain only letters and spaces', _lastNameFocusNode);
      return false;
    }
    if (_userEmailController.text.trim().isEmpty) {
      _showFieldValidationError('Email is required', _userEmailFocusNode);
      return false;
    }
    if (!_isValidEmail(_userEmailController.text)) {
      _showFieldValidationError('Please enter a valid email address', _userEmailFocusNode);
      return false;
    }
    if (_userPhoneController.text.trim().isEmpty) {
      _showFieldValidationError('Phone number is required', _userPhoneFocusNode);
      return false;
    }
    if (!_isValidPhoneNumber(_userPhoneController.text)) {
      _showFieldValidationError('Phone number must be exactly 10 digits', _userPhoneFocusNode);
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showFieldValidationError('Password is required', _passwordFocusNode);
      return false;
    }
    if (_passwordController.text.length < 8) {
      _showFieldValidationError('Password must be at least 8 characters', _passwordFocusNode);
      return false;
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      _showFieldValidationError('Passwords do not match', _confirmPasswordFocusNode);
      return false;
    }
    return true;
  }

  bool _validateCompanyDetailsForm() {
    if (_companyNameController.text.trim().isEmpty) {
      _showFieldValidationError('Company name is required', focusNodes['companyName']!);
      return false;
    }
    if (_tradingNameController.text.trim().isEmpty) {
      _showFieldValidationError('Trading name is required', focusNodes['tradingName']!);
      return false;
    }
    if (_registrationNumberController.text.trim().isEmpty) {
      _showFieldValidationError('Registration number is required', focusNodes['registrationNumber']!);
      return false;
    }
    if (_vatNumberController.text.trim().isNotEmpty && 
        !_isValidNumbersOnly(_vatNumberController.text, minLength: 10)) {
      _showFieldValidationError('VAT number must be at least 10 digits', focusNodes['vatNumber']!);
      return false;
    }
    return true;
  }

  bool _validateCompanyAddressForm() {
    if (_postalAddressController.text.trim().isEmpty) {
      _showFieldValidationError('Postal address is required', focusNodes['postalAddress']!);
      return false;
    }
    if (_physicalAddressController.text.trim().isEmpty) {
      _showFieldValidationError('Physical address is required', focusNodes['physicalAddress']!);
      return false;
    }
    if (_contactPersonNameController.text.trim().isEmpty) {
      _showFieldValidationError('Contact person name is required', focusNodes['contactPersonName']!);
      return false;
    }
    if (!_isValidName(_contactPersonNameController.text)) {
      _showFieldValidationError('Contact person name must contain only letters and spaces', focusNodes['contactPersonName']!);
      return false;
    }
    if (_contactPersonTelephoneController.text.trim().isEmpty) {
      _showFieldValidationError('Contact person telephone is required', focusNodes['contactPersonTelephone']!);
      return false;
    }
    if (!_isValidPhoneNumber(_contactPersonTelephoneController.text)) {
      _showFieldValidationError('Contact telephone must be exactly 10 digits', focusNodes['contactPersonTelephone']!);
      return false;
    }
    if (_contactPersonEmailController.text.trim().isEmpty) {
      _showFieldValidationError('Contact person email is required', focusNodes['contactPersonEmail']!);
      return false;
    }
    if (!_isValidEmail(_contactPersonEmailController.text)) {
      _showFieldValidationError('Please enter a valid contact person email', focusNodes['contactPersonEmail']!);
      return false;
    }
    if (_platformWorkflowEmailController.text.trim().isEmpty) {
      _showFieldValidationError('Platform workflow email is required', focusNodes['platformWorkflowEmail']!);
      return false;
    }
    if (!_isValidEmail(_platformWorkflowEmailController.text)) {
      _showFieldValidationError('Please enter a valid platform workflow email', focusNodes['platformWorkflowEmail']!);
      return false;
    }
    return true;
  }

  bool _validateBankAccountForm() {
    if (_bankNameController.text.trim().isEmpty) {
      _showFieldValidationError('Bank name is required', focusNodes['bankName']!);
      return false;
    }
    if (_accountNumberController.text.trim().isEmpty) {
      _showFieldValidationError('Account number is required', focusNodes['accountNumber']!);
      return false;
    }
    if (!_isValidNumbersOnly(_accountNumberController.text, minLength: 8, maxLength: 12)) {
      _showFieldValidationError('Account number must be between 8-12 digits', focusNodes['accountNumber']!);
      return false;
    }
    if (_branchCodeController.text.trim().isNotEmpty &&
        !_isValidNumbersOnly(_branchCodeController.text, minLength: 6, maxLength: 6)) {
      _showFieldValidationError('Branch code must be exactly 6 digits', focusNodes['branchCode']!);
      return false;
    }
    if (_accountHolderController.text.trim().isEmpty) {
      _showFieldValidationError('Account holder name is required', focusNodes['accountHolder']!);
      return false;
    }
    if (!_isValidName(_accountHolderController.text)) {
      _showFieldValidationError('Account holder name must contain only letters and spaces', focusNodes['accountHolder']!);
      return false;
    }
    return true;
  }

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

  bool _validateDisplayOnPlatformForm() {
    if (!_isRegisteredNameSelected && _tradingNameController.text.trim().isEmpty) {
      _showFieldValidationError('Please select registered name or enter trading name', focusNodes['tradingName']!);
      return false;
    }
    return true;
  }

  bool _validateAuthorizationForm() {
    if (!isApproval) {
      CustomDialogs.showErrorDialog(
        context,
        'Please grant approval for company authorization',
        onRetry: () {},
      );
      return false;
    }
    return true;
  }

  void _showFieldValidationError(String message, FocusNode focusNode) {
    CustomDialogs.showErrorDialog(
      context,
      message,
      onRetry: () {
        focusNode.requestFocus();
      },
    );
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _validateUserInformationForm();
      case 1:
        return true; // OTP validation handled separately
      case 2:
        return _validateCompanyDetailsForm();
      case 3:
        return _validateCompanyAddressForm();
      case 4:
        return _validateBankAccountForm();
      case 5:
        return _validateProductCategoriesForm();
      case 6:
        return _validateDisplayOnPlatformForm();
      case 7:
        return _validateAuthorizationForm();
      default:
        return true;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() {
        steps[currentStep].isCompleted = true;
      });

      if (currentStep < steps.length - 1) {
        setState(() {
          if (currentStep == 0) {
            _handleSignUp();
          } else {
            currentStep++;
          }
        });

        pageController.animateToPage(
          currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _handleFinalSubmission();
      }
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });

      pageController.animateToPage(
        currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
        if (result['success'] != false &&
            result['statusCode'] != 400 &&
            result['statusCode'] != 500) {
          final message = result['message'] ?? 'User registered successfully';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          if (message.contains("Please verify your email") ||
              message.contains("Please check your SMS") ||
              result['success'] == true) {
            currentStep = 1;
            setState(() {});

            pageController.animateToPage(
              currentStep,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        } else {
          String errorMessage = 'Registration failed';

          if (result['errors'] != null) {
            final errorResponse = result['errors'] as Map<String, dynamic>;
            List<String> errorMessages = [];

            if (errorResponse['errors'] != null) {
              final errors = errorResponse['errors'] as Map<String, dynamic>;
              errors.forEach((field, messages) {
                if (messages is List && messages.isNotEmpty) {
                  errorMessages.add(messages.first.toString());
                } else if (messages is String) {
                  errorMessages.add(messages);
                }
              });
            } else {
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
            errorMessage = 'Server error. Please check your password requirements.';
          }

          CustomDialogs.showErrorDialog(
            context,
            errorMessage,
            onRetry: () => _handleSignUp(),
          );
        }
      } else {
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

  void _handleOTPSuccess() {
    steps[1].isCompleted = true;

    setState(() {
      currentStep = 2;
    });

    pageController.animateToPage(
      currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleFinalSubmission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _submitBusinessRegistration();

      setState(() {
        _isLoading = false;
      });

      if (result != null && result['success'] == true) {
        setState(() {
          isApproval = true;
        });

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

        _navigateToSellerDashboard();
      } else {
        String errorMessage = result?['error'] ?? 'Registration failed. Please try again.';
        _showSubmissionError("Network error occurred. Please check your connection and try again.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSubmissionError('Network error occurred. Please check your connection and try again.');
    }
  }

  void _showSubmissionError(String message) {
    CustomDialogs.showErrorDialog(
      context,
      message,
      onRetry: () {
        _handleFinalSubmission();
      },
    );
  }

  Future<Map<String, dynamic>?> _submitBusinessRegistration() async {
    try {
      final businessRegistrationData = {
        "auth_user_id": Constants.currentUser?.uid,
        'seller': {
          'registered_company_name': _companyNameController.text,
          'trading_name': _tradingNameController.text,
          'registration_number': _registrationNumberController.text,
          'vat_number': _vatNumberController.text,
          'website_url': _websiteUrlController.text,
          'product_category': selectedCategories.join(', '),
          'product_subcategory': selectedCategories.isNotEmpty ? selectedCategories.first : null,
        },
        'company_info': {
          'company_name': _companyNameController.text,
          'trading_name': _tradingNameController.text,
          'registration_number': _registrationNumberController.text,
          'vat_number': _vatNumberController.text,
          'website_url': _websiteUrlController.text,
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
          'bank_name': _bankNameController.text,
          'account_number': _accountNumberController.text,
          'branch_code': _branchCodeController.text,
          'account_holder': _accountHolderController.text,
        },
        'product_categories': selectedCategories,
      };

      final result = await authApiService.submitBusinessRegistration(businessRegistrationData);
      return result;
    } catch (e) {
      print('Error in _submitBusinessRegistration: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  void _navigateToSellerDashboard() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.go('/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Constants.ftaColorLight,
        elevation: 0,
        title: Text(
          'Seller Sign Up',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: currentStep > 0
            ? IconButton(
                icon: Icon(CupertinoIcons.back, color: Colors.white),
                onPressed: _previousStep,
              )
            : IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => context.go('/register'),
              ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${currentStep + 1} of ${steps.length}',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Constants.ftaColorLight,
                      ),
                    ),
                    Text(
                      steps[currentStep].title,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (currentStep + 1) / steps.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Constants.ctaColorLight),
                ),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
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
                currentStep == steps.length - 1 && isApproval
                    ? BusinessRegistrationCompleteWidget()
                    : _buildAuthorizationForm(),
              ],
            ),
          ),

          // Navigation Button
          if (currentStep != 1) // Hide for OTP step
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.ctaColorLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          currentStep == steps.length - 1
                              ? (isApproval ? 'Enter BIDR Word' : 'Submit Application')
                              : 'Next',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInformationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your personal details to get started',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          _buildCustomTextField(
            'Enter first name',
            _firstNameController,
            _firstNameFocusNode,
            _lastNameFocusNode,
            isName: true,
          ),
          const SizedBox(height: 16),

          _buildCustomTextField(
            'Enter last name',
            _lastNameController,
            _lastNameFocusNode,
            _userEmailFocusNode,
            isName: true,
          ),
          const SizedBox(height: 16),

          _buildCustomTextField(
            'Enter email address',
            _userEmailController,
            _userEmailFocusNode,
            _userPhoneFocusNode,
            isEmail: true,
          ),
          const SizedBox(height: 16),

          _buildCustomTextField(
            'Enter phone number',
            _userPhoneController,
            _userPhoneFocusNode,
            _passwordFocusNode,
            integersOnly: true,
          ),
          const SizedBox(height: 16),

          _buildCustomTextField(
            'Enter password',
            _passwordController,
            _passwordFocusNode,
            _confirmPasswordFocusNode,
            isPassword: true,
          ),
          const SizedBox(height: 16),

          _buildCustomTextField(
            'Confirm password',
            _confirmPasswordController,
            _confirmPasswordFocusNode,
            null,
            isPassword: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Details',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildInputField(
            'Registered Company Name (CIPC)',
            'Enter Registered Company Name',
            _companyNameController,
            focusNodes['companyName']!,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Trading Name',
            'Enter Company Trading Name',
            _tradingNameController,
            focusNodes['tradingName']!,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Registration Number',
            'Enter Registration Number',
            _registrationNumberController,
            focusNodes['registrationNumber']!,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'VAT Number',
            'Enter VAT Number',
            _vatNumberController,
            focusNodes['vatNumber']!,
            integersOnly: true,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Website URL',
            'Enter Company Website URL',
            _websiteUrlController,
            focusNodes['websiteUrl']!,
          ),
          const SizedBox(height: 16),
          
          _buildFileUploadField(),
        ],
      ),
    );
  }

  Widget _buildCompanyAddressForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Company Address',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildInputField(
            'Postal Address',
            'Enter Postal Address',
            _postalAddressController,
            focusNodes['postalAddress']!,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Physical Address',
            'Enter Physical Address',
            _physicalAddressController,
            focusNodes['physicalAddress']!,
          ),
          const SizedBox(height: 16),
          
          _buildLocationDropdown(),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Contact Person Name',
            'Enter Contact Person Name',
            _contactPersonNameController,
            focusNodes['contactPersonName']!,
            isName: true,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Contact Person Telephone',
            'Enter Contact Person Telephone',
            _contactPersonTelephoneController,
            focusNodes['contactPersonTelephone']!,
            integersOnly: true,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Contact Person Email Address',
            'Enter Contact Person Email Address',
            _contactPersonEmailController,
            focusNodes['contactPersonEmail']!,
            isEmail: true,
          ),
          const SizedBox(height: 16),
          
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

  Widget _buildBankAccountForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Account',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildInputField(
            'Bank Name',
            'Enter Bank Name',
            _bankNameController,
            focusNodes['bankName']!,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Account Number',
            'Enter Account Number',
            _accountNumberController,
            focusNodes['accountNumber']!,
            integersOnly: true,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Branch Code',
            'Enter Branch Code',
            _branchCodeController,
            focusNodes['branchCode']!,
            integersOnly: true,
          ),
          const SizedBox(height: 16),
          
          _buildInputField(
            'Account Holder Name',
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Categories',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the categories that best describe your products:',
            style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          ...availableCategories.map((category) {
            bool isSelected = selectedCategories.contains(category);
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Constants.ctaColorLight : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected ? Constants.ctaColorLight.withOpacity(0.1) : Colors.white,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  category,
                  style: GoogleFonts.manrope(
                    color: isSelected ? Constants.ctaColorLight : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Constants.ctaColorLight : Colors.grey,
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
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDisplayOnPlatformForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display on Platform',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildRegisteredNameWithCheckbox("Use Registered Name"),
          const SizedBox(height: 20),
          
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

  Widget _buildAuthorizationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Authorization',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildApprovalNameWithCheckbox("I grant approval for company authorization"),
        ],
      ),
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
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
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
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      isPasswordField: isPassword,
      isEditable: !isReadOnly,
      integersOnly: integersOnly,
      maxLength: integersOnly ? 10 : null,
      suffix: suffixIcon,
      onChanged: (value) {
        if (integersOnly) {
          final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (digitsOnly != value) {
            controller.value = TextEditingValue(
              text: digitsOnly,
              selection: TextSelection.collapsed(offset: digitsOnly.length),
            );
          }
        } else if (isName) {
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
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildFileUploadField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload CIPC Documents',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              color: Colors.grey[50],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _uploadedDocuments.isNotEmpty
                      ? '${_uploadedDocuments.length} document(s) uploaded'
                      : 'Tap to upload documents',
                  style: GoogleFonts.manrope(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_uploadedDocuments.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_uploadedDocuments.length, (index) {
            final file = _uploadedDocuments[index];
            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getFileName(file),
                      style: GoogleFonts.manrope(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeDocument(index),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedLocationText != null && _selectedLocationText!.isNotEmpty)
          Column(
            children: [
              _buildCustomTextField(
                'Selected Location',
                _locationController,
                FocusNode(),
                null,
                isReadOnly: true,
              ),
              const SizedBox(height: 12),
            ],
          ),
        Text(
          'Location',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Location picker logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Location picker not implemented')),
              );
            },
            icon: Icon(
              Icons.location_on_outlined,
              color: _selectedLocationText != null ? Colors.white : Colors.grey[600],
              size: 20,
            ),
            label: Text(
              _selectedLocationText != null ? 'Change Location' : 'Select Location',
              style: GoogleFonts.manrope(
                color: _selectedLocationText != null ? Colors.white : Colors.grey[600],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedLocationText != null ? const Color(0xFFF5A623) : Colors.grey[100],
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisteredNameWithCheckbox(String desName) {
    return InkWell(
      onTap: () {
        setState(() {
          _isRegisteredNameSelected = !_isRegisteredNameSelected;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: _isRegisteredNameSelected ? Constants.ctaColorLight : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: _isRegisteredNameSelected ? Constants.ctaColorLight.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              _isRegisteredNameSelected ? Icons.check_circle : Icons.circle_outlined,
              color: _isRegisteredNameSelected ? Constants.ctaColorLight : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                desName,
                style: GoogleFonts.manrope(
                  color: _isRegisteredNameSelected ? Constants.ctaColorLight : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalNameWithCheckbox(String desName) {
    return InkWell(
      onTap: () {
        setState(() {
          isApproval = !isApproval;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: isApproval ? Constants.ctaColorLight : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: isApproval ? Constants.ctaColorLight.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isApproval ? Icons.check_circle : Icons.circle_outlined,
              color: isApproval ? Constants.ctaColorLight : Colors.grey[400],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                desName,
                style: GoogleFonts.manrope(
                  color: isApproval ? Constants.ctaColorLight : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: true,
        withData: kIsWeb,
        withReadStream: !kIsWeb,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (kIsWeb ? file.bytes != null : file.path != null) {
              _uploadedDocuments.add(file);
            }
          }
        });
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

  String _getFileName(PlatformFile file) {
    if (kIsWeb) {
      return file.name;
    } else {
      return path.basename(file.path ?? file.name);
    }
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