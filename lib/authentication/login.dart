import 'package:bidr/authentication/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/Constants.dart';
import '../customWdget/custom_input2.dart';
import '../services/shared_preferences.dart';
import '../pages/buyer_home.dart';
import '../pages/seller/seller_home_dashboard.dart';
import 'auth_api_service.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Call the API service to login
    final authService = AuthApiService();
    final response = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (response != null) {
      // Store credentials in shared preferences
      await Sharedprefs.saveUserLoggedInSharedPreference(true);
      await Sharedprefs.saveUserAccessTokenSharedPreference(
        response['access_token'],
      );
      await Sharedprefs.saveUserRefreshTokenSharedPreference(
        response['refresh_token'],
      );

      // Store user data
      final user = response['user'];
      await Sharedprefs.saveUserIdSharedPreference(user['id']);
      await Sharedprefs.saveUserUidSharedPreference(user['uid']);
      await Sharedprefs.saveUserEmailSharedPreference(user['email']);
      await Sharedprefs.saveUserNameSharedPreference(
        '${user['first_name']} ${user['last_name']}',
      );
      await Sharedprefs.saveUserRoleSharedPreference(user['role']);
      await Sharedprefs.saveUserCellSharedPreference(
        user['phone_number'] ?? '',
      );

      // Navigate based on user role
      if (mounted) {
        // Update global constants
        Constants.myUid = user['uid'];
        Constants.userId = user['id'];
        Constants.myCell = user['phone_number'] ?? '';
        Constants.myDisplayname = '${user['first_name']} ${user['last_name']}';
        Constants.myCategoryRole = user['role'];
        Constants.myUsername = Constants.myDisplayname;
        Constants.myEmail = user['email'];

        // Navigate to dashboard
        context.go('/dashboard');
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleForgotPassword() {
    // Handle forgot password
    print('Forgot password clicked');
  }

  void _handleSignUp() {
    // Navigate to sign up page
    print('Sign up clicked');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            border: Border.all(color: Constants.gtaColorLight,width: 20),

          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(0),
                    topLeft: Radius.circular(0),
                  ),
                  child: Image.asset(
                    "lib/assets/covers/Group 1171275363.png",
                    fit: BoxFit.cover,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Fixed spacing at top
                        //const SizedBox(height: 60),
                        Center(
                          child: Container(
                            width: 160,
                            height: 160,
                            child: Image.asset(
                              "lib/assets/images/bidr_logo_with_text.png",
                              fit: BoxFit.contain,
                              width: 90,
                              height: 90,
                            ),
                          ),
                        ),
                        // Welcome back title
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Welcome back! Sign In',
                            style: GoogleFonts.manrope(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Center(
                          child: Text(
                            'Sign in to existing account',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email input
                        SizedBox(
                          width:
                          MediaQuery.of(context).size.height * 0.5,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                          width:
                          MediaQuery.of(context).size.height * 0.5,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                                textInputAction: TextInputAction.done,
                                isPasswordField: true,
                                onChanged: (value) {},
                                onSubmitted: (value) {
                                  _handleLogin();
                                },
                                suffix: const Icon(
                                  Icons.visibility_off_outlined,
                                  color: Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Forgot password
                        SizedBox(
                          width:
                          MediaQuery.of(context).size.height * 0.5,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BidrPasswordResetFlow(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.manrope(
                                  color: Color(0xFF999999),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign in button
                        SizedBox(
                          width:
                          MediaQuery.of(context).size.height * 0.5,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                                : Text(
                              'Sign In',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sign up link
                        SizedBox(
                          width:
                          MediaQuery.of(context).size.height * 0.5,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                context.go('/register');
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.transparent,
                                ),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: "Don't Have an Account? ",
                                        style: TextStyle(
                                          color: Color(0xFF999999),
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Sign Up',
                                        style: TextStyle(
                                          color: Constants.ftaColorLight,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Constants.ftaColorLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Fixed spacing at bottom to match top
                        const SizedBox(height: 12),
                      ],
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

// Responsive wrapper for different screen sizes
class ResponsiveLoginPage extends StatelessWidget {
  const ResponsiveLoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile layout
          return const MobileLoginPage();
        } else {
          // Desktop/tablet layout
          return const LoginPage();
        }
      },
    );
  }
}

// Mobile optimized version
class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({Key? key}) : super(key: key);

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Call the API service to login
    final authService = AuthApiService();
    final response = await authService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (response != null) {
      // Store credentials in shared preferences
      await Sharedprefs.saveUserLoggedInSharedPreference(true);
      await Sharedprefs.saveUserAccessTokenSharedPreference(
        response['access_token'],
      );
      await Sharedprefs.saveUserRefreshTokenSharedPreference(
        response['refresh_token'],
      );

      // Store user data
      final user = response['user'];
      await Sharedprefs.saveUserIdSharedPreference(user['id']);
      await Sharedprefs.saveUserUidSharedPreference(user['uid']);
      await Sharedprefs.saveUserEmailSharedPreference(user['email']);
      await Sharedprefs.saveUserNameSharedPreference(
        '${user['first_name']} ${user['last_name']}',
      );
      await Sharedprefs.saveUserRoleSharedPreference(user['role']);
      await Sharedprefs.saveUserCellSharedPreference(
        user['phone_number'] ?? '',
      );

      // Navigate based on user role
      if (mounted) {
        // Update global constants
        Constants.myUid = user['uid'];
        Constants.userId = user['id'];
        Constants.myCell = user['phone_number'] ?? '';
        Constants.myDisplayname = '${user['first_name']} ${user['last_name']}';
        Constants.myCategoryRole = user['role'];
        Constants.myUsername = Constants.myDisplayname;
        Constants.myEmail = user['email'];

        // Navigate to dashboard
        context.go('/dashboard');
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B365D), Color(0xFF2E4A6B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Form container
                Container(
                  padding: const EdgeInsets.all(30.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Welcome back! Sign In',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to existing account',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Email input
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
                      const SizedBox(height: 20),

                      // Password input
                      CustomInputTransparent4(
                        hintText: 'Enter Password',
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        textInputAction: TextInputAction.done,
                        isPasswordField: true,
                        onChanged: (value) {},
                        onSubmitted: (value) {
                          _handleLogin();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.manrope(
                              color: Color(0xFF999999),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Constants.ctaColorLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't Have an Account? ",
                            style: GoogleFonts.manrope(
                              color: Color(0xFF999999),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'Sign Up',
                              style: GoogleFonts.manrope(
                                color: Color(0xFF333333),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
