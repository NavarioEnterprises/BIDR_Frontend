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
  String _deliveryMethod = 'sms'; // Default to SMS
  String message = "";
  AuthApiService apiService = AuthApiService();

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

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _handleSignUp() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

          // Navigate to OTP verification
          if (result['success'] == true) {
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
          // Handle errors - extract specific error message
          String errorMessage = 'Registration failed';

          if (result['errors'] != null) {
            final errorResponse = result['errors'] as Map<String, dynamic>;

            // Check if the errors field contains nested errors (from API response)
            if (errorResponse['errors'] != null) {
              final errors = errorResponse['errors'] as Map<String, dynamic>;

              // Check for email error first
              if (errors['email'] != null) {
                final emailErrors = errors['email'] as List;
                if (emailErrors.isNotEmpty) {
                  errorMessage = emailErrors.first.toString();
                }
              }
              // Check for other field errors
              else {
                List<String> errorMessages = [];
                errors.forEach((field, messages) {
                  if (messages is List && messages.isNotEmpty) {
                    errorMessages.add(messages.first.toString());
                  } else if (messages is String) {
                    errorMessages.add(messages);
                  }
                });
                if (errorMessages.isNotEmpty) {
                  errorMessage = errorMessages.first;
                }
              }
            }
            // Handle direct field errors (fallback)
            else if (errorResponse['email'] != null) {
              final emailErrors = errorResponse['email'] as List;
              if (emailErrors.isNotEmpty) {
                errorMessage = emailErrors.first.toString();
              }
            }
          } else if (result['message'] != null) {
            errorMessage = result['message'].toString();
          }

          // Show clean error message directly
          CustomDialogs.showErrorDialog(
            context,
            errorMessage,
            onRetry: () => _handleSignUp(),
          );
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

  // Enhanced form validation using field-specific validation
  bool _validateForm() {
    // Validate each field using the new validation method
    final fields = [
      {'name': 'Full Name*', 'value': _fullNameController.text, 'focus': _fullNameFocusNode},
      {'name': 'Mobile Number*', 'value': _mobileController.text, 'focus': _mobileFocusNode},
      {'name': 'Email*', 'value': _emailController.text, 'focus': _emailFocusNode},
      {'name': 'Password*', 'value': _passwordController.text, 'focus': _passwordFocusNode},
      {'name': 'Confirm Password*', 'value': _confirmPasswordController.text, 'focus': _confirmPasswordFocusNode},
    ];

    for (var field in fields) {
      String? error = _validateField(field['name'] as String, field['value'] as String);
      if (error != null) {
        _showFieldError(error, field['focus'] as FocusNode);
        return false;
      }
    }

    return true;
  }

  Widget _buildCustomTextField(
    String hintText,
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode, {
    Widget? suffixIcon,
    bool? isPasswordField,
    bool? integersOnly,
    bool? isName,
  }) {
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
      maxLength: integersOnly == true ? 10 : null,
      suffix: suffixIcon,
      onChanged: (value) {
        // Real-time validation and formatting
        if (integersOnly == true) {
          // For mobile numbers, ensure only digits and limit to 10
          final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
          if (digitsOnly != value) {
            controller.value = TextEditingValue(
              text: digitsOnly,
              selection: TextSelection.collapsed(offset: digitsOnly.length),
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
      },
      onSubmitted: (value) {
        // Validate before moving to next field
        String? error = _validateField(hintText, value);
        if (error != null) {
          _showFieldError(error, focusNode);
          return;
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
      if (value.length != 10) {
        return 'Mobile number must be exactly 10 digits';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        return 'Mobile number can only contain digits';
      }
    } else if (fieldName.contains('Email')) {
      if (value.trim().isEmpty) {
        return 'Email is required';
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    } else if (fieldName.contains('Password') && !fieldName.contains('Confirm')) {
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

  void _handleSignIn() {
    print('Navigate to sign in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            border: Border.all(color: Constants.gtaColorLight, width: 20),
          ),
          child: Row(
            children: [
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
                  height: MediaQuery.of(context).size.height,
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
                                onPressed: () => Navigator.pop(context),
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
                              Center(
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
                              ),
                              Spacer(),
                              SizedBox(width: 40, height: 40),
                              SizedBox(width: 32),
                            ],
                          ),
                          const SizedBox(height: 24),
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
                          Center(
                            child: Text(
                              'Create your account to get started in just a few steps',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: Colors.black45,

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Full Name input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: _buildCustomTextField(
                              'Full Name*',
                              _fullNameController,
                              _fullNameFocusNode,
                              _mobileFocusNode,
                              isName: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mobile Number input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: _buildCustomTextField(
                              'Mobile Number*',
                              _mobileController,
                              _mobileFocusNode,
                              _emailFocusNode,
                              integersOnly: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: _buildCustomTextField(
                              'Email*',
                              _emailController,
                              _emailFocusNode,
                              _passwordFocusNode,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Password input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: _buildCustomTextField(
                              'Password*',
                              _passwordController,
                              _passwordFocusNode,
                              _confirmPasswordFocusNode,
                              isPasswordField: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Confirm Password input
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: _buildCustomTextField(
                              'Confirm Password*',
                              _confirmPasswordController,
                              _confirmPasswordFocusNode,
                              null,
                              isPasswordField: true,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Sign up button
                          Container(
                            constraints: BoxConstraints(maxWidth: 500),
                            width: MediaQuery.of(context).size.width * 0.5,
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
                            width: MediaQuery.of(context).size.width * 0.5,
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
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
