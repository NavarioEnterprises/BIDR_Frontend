import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../constants/Constants.dart';
import '../customWdget/customCard.dart';
import '../customWdget/custom_input2.dart';
import '../services/auth_api_service.dart';
import 'login.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String uid;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.uid,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.loose,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    topLeft: Radius.circular(0),
                  ),
                  child: Image.asset(
                    "lib/assets/images/sample.jpg",
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height,
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
                    left: 40,
                    right: 40,
                    bottom: 24,
                    top: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Constants.ftaColorLight,
                              foregroundColor: Constants.ctaColorLight,
                              elevation: 5,
                              shadowColor: Colors.black54,
                            ),
                            icon: Icon(
                              CupertinoIcons.back,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          _buildBidrLogo(),
                          Spacer(),
                          SizedBox(width: 40, height: 40),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Reset Your Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A365D),
                          fontFamily: 'YuGothic',
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Create a strong, secure password to restore access to your BIDR account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 15,
                          height: 1.5,
                          fontFamily: 'YuGothic',
                        ),
                      ),

                      const SizedBox(height: 32),

                      _buildCustomTextField(
                          'Enter new password',
                          _passwordController,
                          _passwordFocusNode,
                          null,
                          isPasswordField: true

                      ),

                      const SizedBox(height: 20),

                      _buildCustomTextField(
                          'Confirm new password',
                          _confirmPasswordController,
                          _confirmPasswordFocusNode,
                          null,
                          isPasswordField: true

                      ),

                      const SizedBox(height: 8),

                      // Password requirements
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Constants.ftaColorLight.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password requirements:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Constants.ftaColorLight,
                                fontFamily: 'YuGothic',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '• At least 8 characters long\n• Contains uppercase and lowercase letters\n• Contains numbers and special characters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Constants.ftaColorLight,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'YuGothic',
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildResetButton(),
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

  Widget _buildCustomTextField(
      String hintText,
      TextEditingController controller,
      FocusNode focusNode,
      FocusNode? nextFocusNode, {
        Widget? suffixIcon,
        bool? isPasswordField,
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
      suffix: suffixIcon,
      onChanged: (value) {},
      onSubmitted: (value) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildBidrLogo() {
    return SizedBox(
      width: 90,
      height: 90,
      child: Image.asset(
        "lib/assets/images/bidr_logo.png",
        fit: BoxFit.contain,
        width: 90,
        height: 90,
      ),
    );
  }

  Widget _buildResetButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                foregroundColor: Colors.white,
                elevation: _isLoading ? 2 : 8,
                shadowColor: Constants.ctaColorLight.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                elevation: WidgetStateProperty.resolveWith<double>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.pressed)) return 2;
                  if (states.contains(WidgetState.hovered)) return 12;
                  return 8;
                }),
              ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'YuGothic',
                  ),
                ),
        ),
      ),
    );
  }

  void _handleResetPassword() async {
    print('=== Password Reset Debug ===');
    print('UID: ${widget.uid}');
    print('Token: ${widget.token}');
    print('Password length: ${_passwordController.text.length}');

    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter your new password');
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please confirm your password');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showSnackBar('Password must be at least 8 characters long');
      return;
    }

    // Additional password strength validation
    if (!_isPasswordStrong(_passwordController.text)) {
      _showSnackBar(
        'Password must contain uppercase, lowercase, number and special character',
      );
      return;
    }

    print('All validations passed, making API call...');

    setState(() {
      _isLoading = true;
    });

    try {
      // Call password reset API with uid and token
      final AuthApiService authApiService = AuthApiService();

      print('Calling resetPassword API...');
      final result = await authApiService.resetPassword(
        uid: widget.uid,
        token: widget.token,
        password: _passwordController.text,
      );

      print('API Result: $result');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result != null && result['success'] == true) {
          print('Success! Showing success dialog...');
          _showSuccessDialog();
        } else {
          String errorMessage = 'Failed to reset password';
          if (result != null && result['error'] != null) {
            errorMessage = result['error'].toString();
          }
          print('Error: $errorMessage');
          _showSnackBar(errorMessage);
        }
      }
    } catch (e) {
      print('Exception caught: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('An error occurred. Please try again. Error: $e');
      }
    }
  }

  bool _isPasswordStrong(String password) {
    // Check for at least one uppercase letter, one lowercase letter, one digit, and one special character
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'Password Reset Successful!',
                style: TextStyle(
                  fontFamily: 'YuGothic',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A365D),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Your password has been reset successfully. You can now log in with your new password.',
            style: TextStyle(
              fontFamily: 'YuGothic',
              fontSize: 16,
              color: Color(0xFF718096),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false, // Remove all previous routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontFamily: 'YuGothic',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'YuGothic')),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}


class ResetPasswordMobileScreen extends StatefulWidget {
  final String uid;
  final String token;

  const ResetPasswordMobileScreen({
    super.key,
    required this.uid,
    required this.token,
  });

  @override
  State<ResetPasswordMobileScreen> createState() => _ResetPasswordMobileScreenState();
}

class _ResetPasswordMobileScreenState extends State<ResetPasswordMobileScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Constants.ftaColorLight,
                        foregroundColor: Constants.ctaColorLight,
                        elevation: 3,
                        shadowColor: Colors.black54,
                      ),
                      icon: Icon(
                        CupertinoIcons.back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Spacer(),
                    _buildBidrLogo(),
                    Spacer(),
                    SizedBox(width: 40, height: 40),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Reset Your Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A365D),
                    fontFamily: 'YuGothic',
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Create a strong, secure password to restore access to your BIDR account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: 'YuGothic',
                  ),
                ),

                const SizedBox(height: 28),

                _buildCustomTextField(
                    'Enter new password',
                    _passwordController,
                    _passwordFocusNode,
                    null,
                    isPasswordField: true

                ),

                const SizedBox(height: 16),

                _buildCustomTextField(
                    'Confirm new password',
                    _confirmPasswordController,
                    _confirmPasswordFocusNode,
                    null,
                    isPasswordField: true

                ),

                const SizedBox(height: 12),

                // Password requirements
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Constants.ftaColorLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password requirements:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Constants.ftaColorLight,
                          fontFamily: 'YuGothic',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• At least 8 characters long\n• Contains uppercase and lowercase letters\n• Contains numbers and special characters',
                        style: TextStyle(
                          fontSize: 11,
                          color: Constants.ftaColorLight,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'YuGothic',
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _buildResetButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildCustomTextField(
      String hintText,
      TextEditingController controller,
      FocusNode focusNode,
      FocusNode? nextFocusNode, {
        Widget? suffixIcon,
        bool? isPasswordField,
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
      suffix: suffixIcon,
      onChanged: (value) {},
      onSubmitted: (value) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
    );
  }

  Widget _buildBidrLogo() {
    return SizedBox(
      width: 70,
      height: 70,
      child: Image.asset(
        "lib/assets/images/bidr_logo.png",
        fit: BoxFit.contain,
        width: 70,
        height: 70,
      ),
    );
  }

  Widget _buildResetButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style:
          ElevatedButton.styleFrom(
            backgroundColor: Constants.ctaColorLight,
            foregroundColor: Colors.white,
            elevation: _isLoading ? 2 : 6,
            shadowColor: Constants.ctaColorLight.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ).copyWith(
            elevation: WidgetStateProperty.resolveWith<double>((
                Set<WidgetState> states,
                ) {
              if (states.contains(WidgetState.pressed)) return 2;
              if (states.contains(WidgetState.hovered)) return 10;
              return 6;
            }),
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
              : const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'YuGothic',
            ),
          ),
        ),
      ),
    );
  }

  void _handleResetPassword() async {
    print('=== Password Reset Debug ===');
    print('UID: ${widget.uid}');
    print('Token: ${widget.token}');
    print('Password length: ${_passwordController.text.length}');

    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter your new password');
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please confirm your password');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 8) {
      _showSnackBar('Password must be at least 8 characters long');
      return;
    }

    // Additional password strength validation
    if (!_isPasswordStrong(_passwordController.text)) {
      _showSnackBar(
        'Password must contain uppercase, lowercase, number and special character',
      );
      return;
    }

    print('All validations passed, making API call...');

    setState(() {
      _isLoading = true;
    });

    try {
      // Call password reset API with uid and token
      final AuthApiService authApiService = AuthApiService();

      print('Calling resetPassword API...');
      final result = await authApiService.resetPassword(
        uid: widget.uid,
        token: widget.token,
        password: _passwordController.text,
      );

      print('API Result: $result');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result != null && result['success'] == true) {
          print('Success! Showing success dialog...');
          _showSuccessDialog();
        } else {
          String errorMessage = 'Failed to reset password';
          if (result != null && result['error'] != null) {
            errorMessage = result['error'].toString();
          }
          print('Error: $errorMessage');
          _showSnackBar(errorMessage);
        }
      }
    } catch (e) {
      print('Exception caught: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('An error occurred. Please try again. Error: $e');
      }
    }
  }

  bool _isPasswordStrong(String password) {
    // Check for at least one uppercase letter, one lowercase letter, one digit, and one special character
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          title: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 12),
              Text(
                'Password Reset Successful!',
                style: TextStyle(
                  fontFamily: 'YuGothic',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A365D),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Your password has been reset successfully. You can now log in with your new password.',
            style: TextStyle(
              fontFamily: 'YuGothic',
              fontSize: 14,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false, // Remove all previous routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(
                    fontFamily: 'YuGothic',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'YuGothic')),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}