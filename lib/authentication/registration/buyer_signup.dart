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

          CustomDialogs.showSuccessDialog(
            context,
            message,
            onDismiss: () {
              // Optional: Add any action after success dialog dismissal
            },
          );

          // Navigate to OTP verification
          if (message.contains("Please verify your email") ||
              result['email'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BidrOTPVerificationScreen(
                  email: result['email'] ?? _emailController.text,
                ),
              ),
            );
          }
        } else {
          // Handle errors
          handleRegistrationErrors(context, result);
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

  // Improved password validation based on server requirements
  bool _validateForm() {
    if (_emailController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _mobileController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      CustomDialogs.showWarningDialog(
        context,
        'Please fill in all fields',
        onConfirm: () {
          // Focus on the first empty field
          if (_fullNameController.text.isEmpty) {
            _fullNameFocusNode.requestFocus();
          } else if (_mobileController.text.isEmpty) {
            _mobileFocusNode.requestFocus();
          } else if (_emailController.text.isEmpty) {
            _emailFocusNode.requestFocus();
          } else if (_passwordController.text.isEmpty) {
            _passwordFocusNode.requestFocus();
          } else if (_confirmPasswordController.text.isEmpty) {
            _confirmPasswordFocusNode.requestFocus();
          }
        },
        confirmText: 'OK',
        cancelText: 'Cancel',
      );
      return false;
    }

    // Validate email format
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text)) {
      CustomDialogs.showWarningDialog(
        context,
        'Please enter a valid email address',
        onConfirm: () {
          _emailFocusNode.requestFocus();
        },
        confirmText: 'OK',
        cancelText: 'Cancel',
      );
      return false;
    }

    // Validate password requirements (based on server logs)
    final password = _passwordController.text;
    if (password.length < 8) {
      CustomDialogs.showWarningDialog(
        context,
        'Password must be at least 8 characters long',
        onConfirm: () {
          _passwordFocusNode.requestFocus();
        },
        confirmText: 'OK',
        cancelText: 'Cancel',
      );
      return false;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      CustomDialogs.showWarningDialog(
        context,
        'Password must contain at least one uppercase letter',
        onConfirm: () {
          _passwordFocusNode.requestFocus();
        },
        confirmText: 'OK',
        cancelText: 'Cancel',
      );
      return false;
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      CustomDialogs.showWarningDialog(
        context,
        'Password must contain at least one special character (!@#%^&*(),.?":{}|<>)',
        onConfirm: () {
          _passwordFocusNode.requestFocus();
        },
        confirmText: 'OK',
        cancelText: 'Cancel',
      );
      return false;
    }

    // Validate password confirmation
    if (_passwordController.text != _confirmPasswordController.text) {
      CustomDialogs.showWarningDialog(
        context,
        'Passwords do not match',
        onConfirm: () {
          _confirmPasswordFocusNode.requestFocus();
        },
        confirmText: 'OK',
        cancelText: 'Cancel',
      );
      return false;
    }

    return true;
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
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.go('/register');
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            foregroundColor: Constants.ftaColorLight,
                          ),
                          icon: Icon(CupertinoIcons.back),
                          label: Text(
                            'Back',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

                          // Subtitle
                          Center(
                            child: Text(
                              'Create your account to get started in just a few steps',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                color: Colors.black45,

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Full Name input
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Full Name',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,

                                      fontWeight: FontWeight.w300,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomInputTransparent4(
                                  hintText: 'Enter Full Name',
                                  controller: _fullNameController,
                                  focusNode: _fullNameFocusNode,
                                  textInputAction: TextInputAction.next,
                                  isPasswordField: false,
                                  onChanged: (value) {},
                                  onSubmitted: (value) {
                                    _mobileFocusNode.requestFocus();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Mobile Number input
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Mobile Number',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,

                                      fontWeight: FontWeight.w300,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomInputTransparent4(
                                  hintText: 'Enter Mobile Number',
                                  controller: _mobileController,
                                  focusNode: _mobileFocusNode,
                                  textInputAction: TextInputAction.next,
                                  isPasswordField: false,
                                  integersOnly: true,
                                  onChanged: (value) {},
                                  onSubmitted: (value) {
                                    _emailFocusNode.requestFocus();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email input
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Email',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,

                                      fontWeight: FontWeight.w300,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomInputTransparent4(
                                  hintText: 'Enter Email',
                                  controller: _emailController,
                                  focusNode: _emailFocusNode,
                                  textInputAction: TextInputAction.next,
                                  isPasswordField: false,
                                  onChanged: (value) {},
                                  onSubmitted: (value) {
                                    _passwordFocusNode.requestFocus();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Password input
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Password',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,

                                      fontWeight: FontWeight.w300,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomInputTransparent4(
                                  hintText: 'Enter Password',
                                  controller: _passwordController,
                                  focusNode: _passwordFocusNode,
                                  textInputAction: TextInputAction.next,
                                  isPasswordField: true,
                                  onChanged: (value) {},
                                  onSubmitted: (value) {
                                    _confirmPasswordFocusNode.requestFocus();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Confirm Password input
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    'Confirm Password',
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,

                                      fontWeight: FontWeight.w300,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CustomInputTransparent4(
                                  hintText: 'Enter Confirm Password',
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocusNode,
                                  textInputAction: TextInputAction.done,
                                  isPasswordField: true,
                                  onChanged: (value) {},
                                  onSubmitted: (value) {
                                    _handleSignUp();
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Sign up button
                          SizedBox(
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
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already Have an Account? ',
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
