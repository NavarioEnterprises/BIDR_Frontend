
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../constants/Constants.dart';
import '../customWdget/customCard.dart';
import '../customWdget/custom_input2.dart';
import 'login.dart';
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
          child: CustomCard(
            color: Colors.white,
            elevation: 5,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height*0.8,
              constraints: BoxConstraints(maxWidth: 880,maxHeight: 660),
              padding: EdgeInsets.only(left: 16,right: 16, bottom: 16, top:16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.75)
              ),
              child:Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed:() =>setState(() {
                                        Navigator.pop(context);
                                      }),
                                      style: IconButton.styleFrom(backgroundColor: Constants.ftaColorLight,foregroundColor: Constants.ctaColorLight,elevation: 5,shadowColor: Colors.black54),
                                      icon:  Icon(
                                        CupertinoIcons.back,
                                        color: Colors.white,
                                      ),
                                    ),Spacer(),
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

                                _buildInputField(
                                  'Email',
                                  'Enter Email',
                                  _emailController,
                                  _emailFocusNode,
                                ),

                                const SizedBox(height: 24),

                                _buildGetOTPButton(),
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
        ),
      )
    );
  }
  Widget _buildInputField(
      String label,
      String hint,
      TextEditingController controller,
      FocusNode focusNode, {
        bool integersOnly = false,
        int? maxLines,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black,
                fontFamily: 'YuGothic'
            ),
          ),
        ),
        const SizedBox(height: 8),
        CustomInputTransparent4(
          hintText: hint,
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          isPasswordField: false,
          integersOnly: integersOnly,
          maxLines: maxLines,
          onChanged: (value) {},
          onSubmitted: (value) {
            _handleGetOTP();
          },
        ),
      ],
    );
  }

  Widget _buildBidrLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          child: Image.asset(
            "lib/assets/images/bidr_logo.png",
            fit: BoxFit.contain,
            width: 90,
            height: 90,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontFamily: 'YuGothic',
            ),
            children: [
              TextSpan(
                text: 'BI',
                style: TextStyle(color: Color(0xFF1A365D)),
              ),
              TextSpan(
                text: 'D',
                style: TextStyle(color: Color(0xFFFFA500)),
              ),
              TextSpan(
                text: 'R',
                style: TextStyle(color: Color(0xFF1A365D)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: TweenAnimationBuilder(
            duration: const Duration(seconds: 6),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (0.5 - (value - 0.5).abs()) * 2),
                child: Transform.rotate(
                  angle: value * 6.28,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Constants.ctaColorLight.withOpacity(0.1),
                          const Color(0xFF4299E1).withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: TweenAnimationBuilder(
            duration: const Duration(seconds: 6),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (0.5 - ((value + 0.5) % 1 - 0.5).abs()) * 2),
                child: Transform.rotate(
                  angle: (value + 0.5) * 6.28,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4299E1).withOpacity(0.1),
                          Constants.ctaColorLight.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
      _showSnackBar('Please enter your email address');
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar('Please enter a valid email address');
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
              BidrOTPVerificationScreen(email: _emailController.text),
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

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

  Widget _buildPasswordField(
      String label,
      String hint,
      TextEditingController controller,
      FocusNode focusNode,
      bool obscureText,
      VoidCallback toggleVisibility,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black,
                fontFamily: 'YuGothic'
            ),
          ),
        ),
        const SizedBox(height: 8),
        CustomInputTransparent4(
          hintText: hint,
          controller: controller,
          focusNode: focusNode,
          textInputAction: TextInputAction.next,
          isPasswordField:obscureText ,
          integersOnly: false,
          maxLines: 2,
          suffix: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF718096),
              ),
              onPressed: toggleVisibility,
            ),
          ),
          onChanged: (value) {
          },
          onSubmitted: (value) {

          },
        ),
      ],
    );
  }

  Widget _buildBidrLogo() {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          child: Image.asset(
            "lib/assets/images/bidr_logo.png",
            fit: BoxFit.contain,
            width: 90,
            height: 90,
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              fontFamily: 'YuGothic',
            ),
            children: [
              TextSpan(
                text: 'BI',
                style: TextStyle(color: Color(0xFF1A365D)),
              ),
              TextSpan(
                text: 'D',
                style: TextStyle(color: Color(0xFFFFA500)),
              ),
              TextSpan(
                text: 'R',
                style: TextStyle(color: Color(0xFF1A365D)),
              ),
            ],
          ),
        ),
      ],
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
      _showSnackBar('Password must contain uppercase, lowercase, number and special character');
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
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LoginPage()));
                  //Navigator.of(context).popUntil((route) => route.isFirst); // Go back to login
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

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'YuGothic'),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
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
            height: MediaQuery.of(context).size.height*0.8,
            constraints: BoxConstraints(maxWidth: 880,maxHeight: 670),
            padding: EdgeInsets.only(left: 16,right: 16, bottom: 16, top:16),
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
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed:() =>setState(() {
                                            Navigator.pop(context);
                                          }),
                                          style: IconButton.styleFrom(backgroundColor: Constants.ftaColorLight,foregroundColor: Constants.ctaColorLight,elevation: 5,shadowColor: Colors.black54),
                                          icon:  Icon(
                                            CupertinoIcons.back,
                                            color: Colors.white,
                                          ),
                                        ),Spacer(),
                                        _buildBidrLogo(),
                                        Spacer(),
                                        SizedBox(width: 40,height: 40,)
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    const Text(
                                      'Reset Password',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A365D),
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

                                    _buildPasswordField(
                                      'Password',
                                      'Enter Password',
                                      _passwordController,
                                      _passwordFocusNode,
                                      _obscurePassword,
                                          () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    _buildPasswordField(
                                      'Confirm Password',
                                      'Enter Confirm Password',
                                      _confirmPasswordController,
                                      _confirmPasswordFocusNode,
                                      _obscureConfirmPassword,
                                          () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),

                                    const SizedBox(height: 8),

                                    // Password requirements
                                    Container(
                                      padding: const EdgeInsets.all(8),
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

                                    _buildResetButton(),
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
