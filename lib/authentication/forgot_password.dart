
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'dart:async';

import '../constants/Constants.dart';
import '../customWdget/customCard.dart';
import '../customWdget/custom_input2.dart';
import '../pages/success_and_fail_dailog.dart';
import 'otp_screen.dart';


// Main Password Reset Flow Widget
class BidrPasswordResetFlow extends StatelessWidget {
  const BidrPasswordResetFlow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BIDR Password Reset',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'YuGothic',
        primarySwatch: Colors.blue,
      ),
      home: const BidrPasswordResetScreen(),
    );
  }
}

// Screen 1: Forgot Password
class BidrPasswordResetScreen extends StatefulWidget {
  const BidrPasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<BidrPasswordResetScreen> createState() => _BidrPasswordResetScreenState();
}

class _BidrPasswordResetScreenState extends State<BidrPasswordResetScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              constraints: BoxConstraints(maxWidth: 2000,),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(

                  color: Colors.black.withOpacity(0.75)
              ),
              child:Container(
                decoration: BoxDecoration(
                  color: Colors.white,

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Stack(
                          fit: StackFit.loose,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),topLeft: Radius.circular(0)),
                              child: Image.asset(
                                  "lib/assets/images/sample.jpg",
                                  fit: BoxFit.cover,
                                  height: MediaQuery.of(context).size.height
                              ),
                            ),
                          ],
                        )
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(0),topRight: Radius.circular(0)),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.only(left: 40,right: 40, bottom: 24, top:24),
                            child:  Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        context.go('/login');
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
                                    _buildBidrLogo(),
                                    Spacer(),
                                    SizedBox(width: 40,height: 40,)
                                  ],
                                ),
                                const SizedBox(height: 24),

                                const Text(
                                  'Forgot Password',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'YuGothic',
                                  ),
                                ),

                                const SizedBox(height: 8),

                                const Text(
                                  'Enter your registered email address to begin the reset process and then click the Get OTP button',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    height: 1.5,
                                    fontFamily: 'YuGothic',
                                  ),
                                ),

                                const SizedBox(height: 24),

                                Container(
                                  constraints: BoxConstraints(maxWidth: 500),
                                  width: (MediaQuery.of(context).size.width > 800)
                                      ? MediaQuery.of(context).size.width * 0.5
                                      : MediaQuery.of(context).size.width * 0.85,
                                  child: _buildCustomTextField(
                                    'Email',
                                    _emailController,
                                    _emailFocusNode,
                                    null,
                                    isPasswordField: false,


                                  ),
                                ),

                                const SizedBox(height: 24),

                                Container(
                                    constraints: BoxConstraints(maxWidth: 500),
                                    width: (MediaQuery.of(context).size.width > 800)
                                        ? MediaQuery.of(context).size.width * 0.5
                                        : MediaQuery.of(context).size.width * 0.85,
                                    child: _buildGetOTPButton()),
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
          ),
        )
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
    return Container(
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


  Widget _buildGetOTPButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleGetOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor:Constants.ctaColorLight,
            foregroundColor: Constants.ftaColorLight,
            elevation: _isLoading ? 2 : 8,
            shadowColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(360),
            ),
          ).copyWith(
            elevation: MaterialStateProperty.resolveWith<double>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) return 2;
                if (states.contains(MaterialState.hovered)) return 12;
                return 8;
              },
            ),
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
            'Get OTP',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontFamily: 'YuGothic',
            ),
          ),
        ),
      ),
    );
  }

  void _handleGetOTP() async {
    if (_emailController.text.isEmpty) {
      DialogHelper.showFailureDialog(
        context,
        title: 'Missing Information',
        message: 'Please enter your email address',
        primaryButtonText: 'OK',
        secondaryButtonText: 'Cancel',
      );
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      DialogHelper.showFailureDialog(
        context,
        title: 'Invalid Email',
        message: 'Please enter a valid email address',
        primaryButtonText: 'OK',
        secondaryButtonText: 'Cancel',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              BidrOTPVerificationScreen(email: _emailController.text,phone:_phoneController.text),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

}

// Screen 2: OTP Verification

// Screen 3: Reset Password
class BidrResetPasswordScreen extends StatefulWidget {
  final String email;

  const BidrResetPasswordScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<BidrResetPasswordScreen> createState() => _BidrResetPasswordScreenState();
}

class _BidrResetPasswordScreenState extends State<BidrResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
    return Container(
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
        height: 45,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.ctaColorLight,
            foregroundColor: Colors.white,
            elevation: _isLoading ? 2 : 8,
            shadowColor: Constants.ctaColorLight.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(360),
            ),
          ).copyWith(
            elevation: MaterialStateProperty.resolveWith<double>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) return 2;
                if (states.contains(MaterialState.hovered)) return 12;
                return 8;
              },
            ),
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
              fontSize: 14,
              fontWeight: FontWeight.w300,
              fontFamily: 'YuGothic',
            ),
          ),
        ),
      ),
    );
  }

  void _handleResetPassword() async {
    if (_passwordController.text.isEmpty) {
      DialogHelper.showFailureDialog(
        context,
        title: 'Missing Information',
        message: 'Please enter your new password',
        primaryButtonText: 'OK',
        secondaryButtonText: 'Cancel',
      );
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      DialogHelper.showFailureDialog(
        context,
        title: 'Missing Information',
        message: 'Please confirm your password',
        primaryButtonText: 'OK',
        secondaryButtonText: 'Cancel',
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      DialogHelper.showFailureDialog(
        context,
        title: 'Password Mismatch',
        message: 'Passwords do not match',
        primaryButtonText: 'OK',
        secondaryButtonText: 'Cancel',
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      DialogHelper.showFailureDialog(
        context,
        title: 'Weak Password',
        message: 'Password must be at least 8 characters long',
        primaryButtonText: 'OK',
        secondaryButtonText: 'Cancel',
      );
      return;
    }

    // Additional password strength validation
    if (!_isPasswordStrong(_passwordController.text)) {
      DialogHelper.showFailureDialog(
        context,
        title: 'Weak Password',
        message: 'Password must contain uppercase, lowercase, number and special character',
        primaryButtonText: 'OK',
        secondaryButtonText: 'Cancel',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog();
    }
  }

  bool _isPasswordStrong(String password) {
    // Check for at least one uppercase letter, one lowercase letter, one digit, and one special character
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

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
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Success!',
                style: TextStyle(
                  fontFamily: 'YuGothic',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A365D),
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
                  context.go('/login');

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
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: CustomCard(
          color: Colors.white,
          elevation: 5,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            constraints: BoxConstraints(maxWidth: 2000,),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.75)
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Expanded(
                  child: Container(
                    width: MediaQuery.of(context).size.width,


                    decoration: BoxDecoration(

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(

                      children: [
                        Expanded(
                            flex: 2,
                            child: Stack(
                              fit: StackFit.loose,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0),topLeft: Radius.circular(0)),
                                  child: Image.asset(
                                      "lib/assets/images/sample.jpg",
                                      fit: BoxFit.cover,
                                      height: MediaQuery.of(context).size.height
                                  ),
                                ),
                              ],
                            )
                        ),
                        Expanded(
                          flex: 4,
                          child: Container(
                            height: MediaQuery.of(context).size.height,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(0),topRight: Radius.circular(0)),
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.only(left: 40,right: 40, bottom: 24, top:24),
                                child:  Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            context.go('/login');
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
                                        ),Spacer(),
                                        _buildBidrLogo(),
                                        Spacer(),
                                        SizedBox(width: 40,height: 40,)
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    Text(
                                      'Reset Password',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Constants.ftaColorLight,
                                        fontFamily: 'YuGothic',
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    const Text(
                                      'Securely create a new password to restore access to your account.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF718096),
                                        fontSize: 15,
                                        height: 1.5,
                                        fontFamily: 'YuGothic',
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    Container(
                                      constraints: BoxConstraints(maxWidth: 500),
                                      width: (MediaQuery.of(context).size.width > 800)
                                          ? MediaQuery.of(context).size.width * 0.5
                                          : MediaQuery.of(context).size.width * 0.85,
                                      child: _buildCustomTextField(
                                          'Enter Password',
                                          _passwordController,
                                          _passwordFocusNode,
                                          null,
                                          isPasswordField: true
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    Container(
                                      constraints: BoxConstraints(maxWidth: 500),
                                      width: (MediaQuery.of(context).size.width > 800)
                                          ? MediaQuery.of(context).size.width * 0.5
                                          : MediaQuery.of(context).size.width * 0.85,
                                      child: _buildCustomTextField(
                                          'Enter Confirm Password',
                                          _confirmPasswordController,
                                          _confirmPasswordFocusNode,
                                          null,
                                          isPasswordField: true
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Password requirements
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      constraints: BoxConstraints(maxWidth: 500),
                                      width: (MediaQuery.of(context).size.width > 800)
                                          ? MediaQuery.of(context).size.width * 0.5
                                          : MediaQuery.of(context).size.width * 0.85,
                                      decoration: BoxDecoration(
                                        color:  Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Constants.ftaColorLight,
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
                                              fontWeight: FontWeight.w400,
                                              color: Constants.ftaColorLight,
                                              fontFamily: 'YuGothic',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '•At least 8 characters long\n• Contains uppercase and lowercase letters\n• Contains numbers and special characters',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Constants.ftaColorLight,
                                              fontWeight: FontWeight.w300,
                                              fontFamily: 'YuGothic',
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    Container(
                                        constraints: BoxConstraints(maxWidth: 500),
                                        width: (MediaQuery.of(context).size.width > 800)
                                            ? MediaQuery.of(context).size.width * 0.5
                                            : MediaQuery.of(context).size.width * 0.85,
                                        child: _buildResetButton()),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
