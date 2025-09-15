import 'package:bidr/services/auth_api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../constants/Constants.dart';
import '../../customWdget/customCard.dart';
import '../../customWdget/custom_input2.dart';
import '../../customWdget/custom_dialogs.dart';
import '../../pages/buyer_home.dart';
import '../login.dart';
import '../otp_screen.dart';
import '../../services/shared_preferences.dart';
import 'business_signup.dart';

class BuyerSignUpPage extends StatefulWidget {
  final String userRole;
  const BuyerSignUpPage({Key? key, required this.userRole}) : super(key: key);

  @override
  State<BuyerSignUpPage> createState() => _BuyerSignUpPageState();
}

void handleRegistrationErrors(
  BuildContext context,
  Map<String, dynamic> result,
) {
  String errorMessage = 'Registration failed. ';

  // Handle different types of errors
  if (result['errors'] != null) {
    final errors = result['errors'] as Map<String, dynamic>;
    List<String> errorMessages = [];

    // Extract specific field errors
    errors.forEach((field, messages) {
      if (messages is List) {
        for (var message in messages) {
          errorMessages.add('$field: $message');
        }
      } else {
        errorMessages.add('$field: $messages');
      }
    });

    if (errorMessages.isNotEmpty) {
      errorMessage += errorMessages.join('\n');
    }
  } else if (result['error'] != null) {
    errorMessage += result['error'].toString();
  } else if (result['statusCode'] == 500) {
    errorMessage += 'Server error. Please check your password requirements.';
  }

  // Show error message with custom dialog
  CustomDialogs.showErrorDialog(
    context,
    errorMessage,
    onRetry: () {
      // Optional retry functionality
    },
  );
}

class _BuyerSignUpPageState extends State<BuyerSignUpPage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  String _deliveryMethod = 'email'; // Default to email
  String message = "";
  AuthApiService apiService = AuthApiService();

  // Validation error states
  Map<String, String?> _fieldErrors = {};
  Map<String, bool> _fieldTouched = {};
  
  // Track if form has been submitted at least once
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    
    // Remove all focus listeners that were showing errors on focus loss
    // We only want to show errors after the user attempts to submit
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _fullNameFocusNode.dispose();
    _mobileFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    super.dispose();
  }

  void _handleSignUp() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Proceed with registration - backend will handle existing user logic
      final result = await apiService.registerUser(
        email: _emailController.text,
        firstName: _fullNameController.text,
        lastName: '',
        phoneNumber: _mobileController.text,
        role: widget.userRole,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
        deliveryMethod: _deliveryMethod,
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

          // Save form data for future suggestions if registration successful
          if (result['success'] == true) {
            await _saveBuyerFormDataForSuggestions();
          }

          // Navigate to OTP verification
          if (result['success'] == true) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BidrOTPVerificationScreen(
                  email: result['email'] ?? _emailController.text,
                  phone: result['phone'] ?? _mobileController.text,
                ),
              ),
            );
          }
        } else {
          // Handle errors - backend now returns structured error responses
          final bool isOtpVerified = result['otp_verified'] ?? true;
          final bool canAddSeller = result['can_add_seller'] ?? false;
          final String userRole = result['user_role'] ?? '';

          if (!isOtpVerified) {
            // User exists but OTP not verified, go to OTP screen
            _navigateToOtpVerification();
            return;
          } else if (canAddSeller) {
            // Existing buyer wants to add seller account
            _showAddSellerAccountDialog();
            return;
          } else if (result['error'] != null) {
            final String errorMessage = result['error'].toString();

            // Check for specific error patterns
            if (errorMessage.toLowerCase().contains('already exists') ||
                errorMessage.toLowerCase().contains('already registered')) {
              _showEmailExistsDialog();
              return;
            }
          }

          // Handle other error cases
          if (result['errors'] != null) {
            handleRegistrationErrors(context, result);
          } else if (result['message'] != null) {
            CustomDialogs.showErrorDialog(
              context,
              result['message'].toString(),
              onRetry: () => _handleSignUp(),
            );
          } else {
            CustomDialogs.showErrorDialog(
              context,
              'Registration failed. Please try again.',
              onRetry: () => _handleSignUp(),
            );
          }
        }
      } else {
        // Handle null response
        CustomDialogs.showErrorDialog(
          context,
          'Registration failed. Please try again.',
          onRetry: () => _handleSignUp(),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      CustomDialogs.showErrorDialog(
        context,
        'An error occurred: $e',
        onRetry: () => _handleSignUp(),
      );
    }
  }

  // Enhanced form validation with visual feedback
  bool _validateForm() {
    setState(() {
      _fieldErrors.clear();
      _fieldTouched.clear();
      _hasAttemptedSubmit = true; // Mark that user has attempted to submit
    });

    // Validate each field and collect errors
    final fields = [
      {
        'key': 'fullName',
        'name': 'Full Name*',
        'value': _fullNameController.text,
        'focus': _fullNameFocusNode,
      },
      {
        'key': 'mobile',
        'name': 'Mobile Number*',
        'value': _mobileController.text,
        'focus': _mobileFocusNode,
      },
      {
        'key': 'email',
        'name': 'Email*',
        'value': _emailController.text,
        'focus': _emailFocusNode,
      },
      {
        'key': 'password',
        'name': 'Password*',
        'value': _passwordController.text,
        'focus': _passwordFocusNode,
      },
      {
        'key': 'confirmPassword',
        'name': 'Confirm Password*',
        'value': _confirmPasswordController.text,
        'focus': _confirmPasswordFocusNode,
      },
    ];

    bool hasErrors = false;
    for (var field in fields) {
      String? error = _validateField(
        field['name'] as String,
        field['value'] as String,
      );
      if (error != null) {
        _fieldErrors[field['key'] as String] = error;
        _fieldTouched[field['key'] as String] = true;
        hasErrors = true;
      }
    }

    if (hasErrors) {
      setState(() {}); // Trigger rebuild to show errors
      // Focus on first error field
      for (var field in fields) {
        if (_fieldErrors[field['key'] as String] != null) {
          (field['focus'] as FocusNode).requestFocus();
          break;
        }
      }
      return false;
    }

    return true;
  }

  void _validateFieldRealTime(
    String fieldKey,
    String fieldName,
    String value, {
    bool showErrorsImmediately = false,
  }) {
    // Only validate and show errors if form has been submitted at least once
    if (!_hasAttemptedSubmit && !showErrorsImmediately) {
      return;
    }

    String? error = _validateField(fieldName, value);
    setState(() {
      _fieldTouched[fieldKey] = true;
      
      if (error != null) {
        _fieldErrors[fieldKey] = error;
      } else {
        _fieldErrors.remove(fieldKey);
      }
    });
  }

  Future<void> _saveBuyerFormDataForSuggestions() async {
    try {
      final Map<String, String> formData = {
        'buyer_full_name': _fullNameController.text.trim(),
        'buyer_mobile_number': _mobileController.text.trim(),
        'buyer_email': _emailController.text.trim(),
      };

      // Remove empty values
      formData.removeWhere((key, value) => value.isEmpty);

      if (formData.isNotEmpty) {
        await FormDataService.saveMultipleFieldSuggestions(formData);
      }
    } catch (e) {
      print('Error saving buyer form data for suggestions: $e');
    }
  }

  Widget _buildSuggestionTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode,
    String fieldKey, {
    Widget? suffixIcon,
    bool? isPasswordField,
    bool? integersOnly,
    bool? isName,
  }) {
    // Map the fieldKey to validation key
    String validationKey = fieldKey;
    if (fieldKey == 'buyer_full_name') validationKey = 'fullName';
    if (fieldKey == 'buyer_mobile_number') validationKey = 'mobile';
    if (fieldKey == 'buyer_email') validationKey = 'email';

    return FutureBuilder<List<String>>(
      future: FormDataService.getFieldSuggestions(fieldKey),
      builder: (context, snapshot) {
        final suggestions = snapshot.data ?? [];

        if (suggestions.isEmpty || isPasswordField == true) {
          // If no suggestions or password field, use regular field
          return _buildCustomTextField(
            hintText,
            controller,
            focusNode,
            nextFocusNode,
            validationKey,
            suffixIcon: suffixIcon,
            isPasswordField: isPasswordField,
            integersOnly: integersOnly,
            isName: isName,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return suggestions.take(
                    3,
                  ); // Show recent suggestions when empty
                }
                return suggestions
                    .where((String suggestion) {
                      return suggestion.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    })
                    .take(3);
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

                    fieldController.addListener(() {
                      if (controller.text != fieldController.text) {
                        controller.text = fieldController.text;
                        // Save suggestion when user types
                        if (fieldController.text.trim().isNotEmpty) {
                          FormDataService.saveFieldSuggestion(
                            fieldKey,
                            fieldController.text.trim(),
                          );
                        }
                      }
                    });

                    return _buildCustomTextField(
                      hintText,
                      fieldController,
                      focusNode,
                      nextFocusNode,
                      validationKey,
                      suffixIcon: suffixIcon,
                      isPasswordField: isPasswordField,
                      integersOnly: integersOnly,
                      isName: isName,
                    );
                  },
              optionsViewBuilder: (context, onSelected, options) {
                if (options.isEmpty) return Container();

                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 300,
                      constraints: const BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
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
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: index < options.length - 1
                                        ? const Color(0xFFE0E0E0)
                                        : Colors.transparent,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 14,
                                    color: const Color(0xFF666666),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.manrope(
                                        color: const Color(0xFF333333),
                                        fontSize: 14,
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
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode,
    String fieldKey, {
    Widget? suffixIcon,
    bool? isPasswordField,
    bool? integersOnly,
    bool? isName,
  }) {
    // Only show errors if form has been attempted to submit
    bool shouldShowError = _hasAttemptedSubmit && 
                          _fieldTouched[fieldKey] == true && 
                          _fieldErrors[fieldKey] != null;

    return CustomInputTransparent4(
      hintText: hintText.replaceAll('*', ''),
      labelText: hintText,
      controller: controller,
      focusNode: focusNode,
      textInputAction: nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
      isPasswordField: isPasswordField ?? false,
      integersOnly: integersOnly,
      maxLength: integersOnly == true ? 15 : null,
      suffix: suffixIcon,
      hasError: shouldShowError,
      errorText: shouldShowError ? _fieldErrors[fieldKey] : null,
      onChanged: (value) {
        // Real-time validation and formatting
        if (integersOnly == true) {
          // For mobile numbers, allow + prefix and digits
          final cleanedValue = value.replaceAll(RegExp(r'[^0-9+]'), '');
          // Ensure + only appears at the beginning
          String formattedValue = cleanedValue;
          if (cleanedValue.contains('+')) {
            final plusCount = '+'.allMatches(cleanedValue).length;
            if (plusCount > 1 ||
                (plusCount == 1 && !cleanedValue.startsWith('+'))) {
              formattedValue = cleanedValue.replaceAll('+', '');
              if (value.startsWith('+')) {
                formattedValue = '+' + formattedValue;
              }
            }
          }
          if (formattedValue != value) {
            controller.value = TextEditingValue(
              text: formattedValue,
              selection: TextSelection.collapsed(offset: formattedValue.length),
            );
          }
        } else if (isName == true) {
          // For names, only allow letters and spaces
          final lettersOnly = value.replaceAll(RegExp(r'[^a-zA-Z\s]'), '');
          if (lettersOnly != value) {
            controller.value = TextEditingValue(
              text: lettersOnly,
              selection: TextSelection.collapsed(offset: lettersOnly.length),
            );
          }
        }

        // Only validate if form has been submitted at least once
        if (_hasAttemptedSubmit) {
          _validateFieldRealTime(fieldKey, hintText, controller.text);
        }
      },
      onSubmitted: (value) {
        // Don't validate on submit unless form has been attempted
        if (_hasAttemptedSubmit) {
          _validateFieldRealTime(fieldKey, hintText, value, showErrorsImmediately: true);
          
          if (_fieldErrors[fieldKey] != null) {
            return; // Don't proceed if there's an error
          }
        }

        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        } else {
          // If it's the last field, trigger signup
          _handleSignUp();
        }
      },
    );
  }

  String? _validateField(String fieldName, String value) {
    if (fieldName.contains('Full Name')) {
      if (value.trim().isEmpty) {
        return 'Full name is required';
      }
      if (value.trim().length < 2) {
        return 'Full name must be at least 2 characters';
      }
      if (RegExp(r'[0-9]').hasMatch(value)) {
        return 'Full name cannot contain numbers';
      }
    } else if (fieldName.contains('Mobile Number')) {
      if (value.trim().isEmpty) {
        return 'Mobile number is required';
      }
      // Remove + prefix for length checking
      final digitsOnly = value.replaceAll('+', '');
      if (digitsOnly.length < 10 || digitsOnly.length > 15) {
        return 'Mobile number must be between 10-15 digits';
      }
      // Allow optional + at the beginning followed by digits
      if (!RegExp(r'^\+?[0-9]+$').hasMatch(value)) {
        return 'Mobile number can only contain digits and optional + prefix';
      }
    } else if (fieldName.contains('Email')) {
      if (value.trim().isEmpty) {
        return 'Email is required';
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    } else if (fieldName.contains('Password') &&
        !fieldName.contains('Confirm')) {
      if (value.isEmpty) {
        return 'Password is required';
      }
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Password must contain at least one uppercase letter';
      }
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password must contain at least one number';
      }
      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
        return 'Password must contain at least one special character';
      }
    } else if (fieldName.contains('Confirm Password')) {
      if (value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != _passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  void _showFieldError(String error, FocusNode focusNode) {
    CustomDialogs.showWarningDialog(
      context,
      error,
      onConfirm: () {
        focusNode.requestFocus();
      },
      confirmText: 'OK',
      cancelText: 'Cancel',
    );
  }

  void _showEmailExistsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Account Already Exists',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Constants.ftaColorLight,
            ),
          ),
          content: Text(
            'An account with this email already exists. Would you like to:\n\n'
            '1. Go to OTP verification screen\n'
            '2. Resend OTP to the new phone number: ${_mobileController.text}',
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.manrope(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Resend OTP with new phone number
                setState(() {
                  _isLoading = true;
                });

                final result = await apiService.resendOtp(
                  _emailController.text,
                  _mobileController.text,
                  deliveryMethod: _deliveryMethod,
                );

                setState(() {
                  _isLoading = false;
                });

                if (result != null && result['success'] == true) {
                  if (!mounted) return;
                  CustomDialogs.showSuccessDialog(
                    context,
                    'OTP sent to ${_mobileController.text}',
                    onDismiss: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BidrOTPVerificationScreen(
                            email: _emailController.text,
                            phone: _mobileController.text,
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  if (!mounted) return;
                  CustomDialogs.showErrorDialog(
                    context,
                    result?['error'] ?? 'Failed to send OTP',
                  );
                }
              },
              child: Text(
                'Resend OTP',
                style: GoogleFonts.manrope(
                  color: Constants.ctaColorLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Go directly to OTP screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BidrOTPVerificationScreen(
                      email: _emailController.text,
                      phone: _mobileController.text,
                    ),
                  ),
                );
              },
              child: Text(
                'Go to OTP',
                style: GoogleFonts.manrope(
                  color: Constants.ctaColorLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddSellerAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Constants.ctaColorLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store_outlined,
                      size: 40,
                      color: Constants.ctaColorLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Expand Your Account',
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'You already have a buyer account. Would you like to add selling capabilities to start earning on our platform?',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Benefits
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildBenefitRow(
                          Icons.trending_up,
                          'Start selling your products',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow(
                          Icons.dashboard_outlined,
                          'Access seller dashboard',
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitRow(
                          Icons.analytics_outlined,
                          'Track your earnings',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            'Not Now',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _addSellerAccount();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                          ),
                          child: Text(
                            'Add Seller Account',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Constants.ctaColorLight),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showUserAlreadyHasRoleDialog(String role) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Account Already Exists',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Constants.ftaColorLight,
            ),
          ),
          content: Text(
            'You already have an account with $role privileges. Please use the login page to access your account.',
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.manrope(
                  color: Constants.ctaColorLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToOtpVerification() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => BidrOTPVerificationScreen(
          email: _emailController.text,
          phone: _mobileController.text,
        ),
      ),
    );
  }

  Future<void> _addSellerAccount() async {
    try {
      // Navigate directly to business registration with existing user data
      // The business registration process will handle adding the seller role
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => BusinessSignUpPage(
            isProceedingFromBuyer: true,
            existingUserData: {
              'firstName': _fullNameController.text,
              'lastName': '',
              'email': _emailController.text,
              'phone': _mobileController.text,
            },
          ),
        ),
      );
    } catch (e) {
      CustomDialogs.showErrorDialog(
        context,
        'An error occurred while navigating to seller registration',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(border: null),
          child: Row(
            children: [
              if (MediaQuery.of(context).size.width > 800)
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Image.asset(
                        "lib/assets/images/sample.jpg",
                        fit: BoxFit.cover,
                        height: MediaQuery.of(context).size.height,
                      ),
                    ],
                  ),
                ),
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 0,
                        right: 0,
                        bottom: 24,
                        top: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              SizedBox(width: 32),
                              IconButton(
                                onPressed: () {
                                  context.go('/register');
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Constants.ftaColorLight,
                                  elevation: 5,
                                  shadowColor: Colors.black54,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(
                                  CupertinoIcons.back,
                                  color: Constants.ftaColorLight,
                                ),
                              ),
                              Spacer(),
                              (MediaQuery.of(context).size.width > 800)
                                  ? Center(
                                      child: Container(
                                        width: 90,
                                        height: 90,
                                        child: Image.asset(
                                          "lib/assets/images/bidr_logo.png",
                                          fit: BoxFit.contain,
                                          width: 90,
                                          height: 90,
                                        ),
                                      ),
                                    )
                                  : Container(),
                              Spacer(),
                              SizedBox(width: 40, height: 40),
                              SizedBox(width: 32),
                            ],
                          ),

                          Center(
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.manrope(
                                fontSize: 24,

                                fontWeight: FontWeight.bold,
                                color: Constants.ftaColorLight,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),

                          // Subtitle
                          (MediaQuery.of(context).size.width > 800)
                              ? Center(
                                  child: Text(
                                    'Create your account to get started in just a few steps',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      color: Colors.black45,

                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              : Container(),
                          const SizedBox(height: 24),

                          // Full Name input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: (MediaQuery.of(context).size.width > 800)
                                ? MediaQuery.of(context).size.width * 0.5
                                : MediaQuery.of(context).size.width * 0.85,
                            child: _buildSuggestionTextField(
                              'Full Name*',
                              _fullNameController,
                              _fullNameFocusNode,
                              _mobileFocusNode,
                              'buyer_full_name',
                              isName: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mobile Number input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: (MediaQuery.of(context).size.width > 800)
                                ? MediaQuery.of(context).size.width * 0.5
                                : MediaQuery.of(context).size.width * 0.85,
                            child: _buildSuggestionTextField(
                              'Mobile Number*',
                              _mobileController,
                              _mobileFocusNode,
                              _emailFocusNode,
                              'buyer_mobile_number',
                              integersOnly: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: (MediaQuery.of(context).size.width > 800)
                                ? MediaQuery.of(context).size.width * 0.5
                                : MediaQuery.of(context).size.width * 0.85,
                            child: _buildSuggestionTextField(
                              'Email*',
                              _emailController,
                              _emailFocusNode,
                              _passwordFocusNode,
                              'buyer_email',
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Password input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: (MediaQuery.of(context).size.width > 800)
                                ? MediaQuery.of(context).size.width * 0.5
                                : MediaQuery.of(context).size.width * 0.85,
                            child: _buildCustomTextField(
                              'Password*',
                              _passwordController,
                              _passwordFocusNode,
                              _confirmPasswordFocusNode,
                              'password',
                              isPasswordField: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Confirm Password input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: (MediaQuery.of(context).size.width > 800)
                                ? MediaQuery.of(context).size.width * 0.5
                                : MediaQuery.of(context).size.width * 0.85,
                            child: _buildCustomTextField(
                              'Confirm Password*',
                              _confirmPasswordController,
                              _confirmPasswordFocusNode,
                              null,
                              'confirmPassword',
                              isPasswordField: true,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Sign up button
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: (MediaQuery.of(context).size.width > 800)
                                ? MediaQuery.of(context).size.width * 0.5
                                : MediaQuery.of(context).size.width * 0.85,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Constants.ctaColorLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Constants.ftaColorLight,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Sign Up',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,

                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Sign in link
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: (MediaQuery.of(context).size.width > 800)
                                ? MediaQuery.of(context).size.width * 0.5
                                : MediaQuery.of(context).size.width * 0.85,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Already Have an Account?',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.black,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () {
                                    /*Navigator.pushNamed(
                                                  context,
                                                  '/login',
                                                );*/
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginPage(),
                                      ),
                                    );
                                    setState(() {});
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: BorderSide.none,
                                    foregroundColor: Constants.ftaColorLight,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Sign in',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,

                                      fontWeight: FontWeight.bold,
                                      color: Constants.ftaColorLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Sign Up title
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
