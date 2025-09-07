import 'dart:async';
import 'dart:convert';
import 'package:bidr/pages/buyer_dashboard.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/Constants.dart';
import '../customWdget/customCard.dart';
import '../global_values.dart';
import '../pages/buyer_home.dart';
import '../services/auth_api_service.dart';
import '../services/shared_preferences.dart';
import 'forgot_password.dart';
import 'login.dart';

class BidrOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;
  final String? testOtp;

  const BidrOTPVerificationScreen({
    Key? key,
    required this.email,
    required this.phone,
    this.testOtp,
  }) : super(key: key);

  @override
  State<BidrOTPVerificationScreen> createState() =>
      _BidrOTPVerificationScreenState();
}

class _BidrOTPVerificationScreenState extends State<BidrOTPVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  ); // Changed to 6 digits
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  bool _isResending = false;
  late Timer _timer;
  int _timeLeft = 300; // 5 minutes
  String _deliveryMethod = 'sms'; // Default to SMS

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _startTimer();

    // For testing: pre-fill OTP if provided
    if (widget.testOtp != null) {
      _fillTestOtp();
    }
  }

  void _fillTestOtp() {
    final otp = widget.testOtp!;
    for (int i = 0; i < otp.length && i < _otpControllers.length; i++) {
      _otpControllers[i].text = otp[i];
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  final AuthApiService _authApiService = AuthApiService();

  // API call to verify OTP
  Future<bool> _verifyOtpApi(String email, String otp) async {
    try {
      final result = await _authApiService.verifyOtp(email, otp);

      if (result != null && result['success'] == true) {
        print('OTP verified successfully: ${result['data']}');
        return true;
      } else {
        String errorMessage = result?['error'] ?? 'OTP verification failed';
        _showSnackBar(errorMessage);
        return false;
      }
    } catch (e) {
      print('Error occurred during OTP verification: $e');
      _showSnackBar('Network error. Please try again.');
      return false;
    }
  }

  // API call to resend OTP
  Future<bool> _resendOtpApi(
    String email,
    String phone,
    String deliveryMethod,
  ) async {
    try {
      final result = await _authApiService.resendOtp(
        email,
        phone,
        deliveryMethod: deliveryMethod,
      );

      if (result != null && result['success'] == true) {
        print('OTP resent successfully: ${result['data']}');
        return true;
      } else {
        String errorMessage = result?['error'] ?? 'Failed to resend OTP';
        _showSnackBar(errorMessage);
        return false;
      }
    } catch (e) {
      print('Error occurred during OTP resend: $e');
      _showSnackBar('Network error. Please try again.');
      return false;
    }
  }

  void _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      // Changed to 6 digits
      _showSnackBar('Please enter complete OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Call API to verify OTP
    bool isVerified = await _verifyOtpApi(widget.email, otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (isVerified) {
        _showSnackBar('OTP verified successfully!', isSuccess: true);

        // Navigate after a short delay to avoid Navigator conflicts
        Future.delayed(const Duration(milliseconds: 500), () async {
          // Store login status
          await Sharedprefs.saveUserLoggedInSharedPreference(true);
          await Sharedprefs.saveCompleteLoginDataSharedPreference(
            Constants.currentUser!.toJson().toString(),
          );
          await Sharedprefs.saveUserRoleSharedPreference(
            Constants.currentUser!.role,
          );

          // Navigate based on user role
          if (mounted && Constants.currentUser != null) {
            // Update global constants from the user model
            Constants.myUid = Constants.currentUser!.uid;
            Constants.userId = Constants.currentUser!.id;
            Constants.myCell = Constants.currentUser!.phoneNumber;
            Constants.myDisplayname = Constants.currentUser!.fullName;
            Constants.myCategoryRole = Constants.currentUser!.role;
            Constants.myUsername = Constants.currentUser!.fullName;
            Constants.myEmail = Constants.currentUser!.email;
          }
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    BuyerHomePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: child,
                      );
                    },
              ),
            );
          }
        });
      }
    }
  }

  void _showDeliveryMethodDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose Delivery Method',
            style: TextStyle(
              fontFamily: 'YuGothic',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.sms, color: Constants.ctaColorLight),
                title: Text('SMS', style: TextStyle(fontFamily: 'YuGothic')),
                subtitle: Text(
                  widget.phone.isNotEmpty
                      ? widget.phone
                      : 'No phone number available',
                  style: TextStyle(fontFamily: 'YuGothic'),
                ),
                onTap: widget.phone.isNotEmpty
                    ? () {
                        Navigator.of(context).pop();
                        _resendOTPWithMethod('sms');
                      }
                    : null,
                enabled: widget.phone.isNotEmpty,
              ),
              ListTile(
                leading: Icon(Icons.email, color: Constants.ctaColorLight),
                title: Text('Email', style: TextStyle(fontFamily: 'YuGothic')),
                subtitle: Text(
                  widget.email,
                  style: TextStyle(fontFamily: 'YuGothic'),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _resendOTPWithMethod('email');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontFamily: 'YuGothic', color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resendOTPWithMethod(String method) async {
    setState(() {
      _isResending = true;
      _deliveryMethod = method;
    });

    bool isResent = await _resendOtpApi(widget.email, widget.phone, method);

    if (mounted) {
      setState(() {
        _isResending = false;
      });

      if (isResent) {
        setState(() {
          _timeLeft = 300;
        });
        _startTimer();
        _showSnackBar(
          'OTP sent via ${method.toUpperCase()} successfully!',
          isSuccess: true,
        );

        for (var controller in _otpControllers) {
          controller.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    }
  }

  void _resendOTP() async {
    _showDeliveryMethodDialog();
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 800)
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
              child: MediaQuery.of(context).size.width < 800
                  ? Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 40,
                                right: 40,
                                bottom: 24,
                                top: 24,
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => Navigator.pop(context, {'action': 'back'}),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              Constants.ftaColorLight,
                                          elevation: 5,
                                          shadowColor: Colors.black54,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                      SizedBox(width: 40, height: 40),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  const Text(
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      letterSpacing: 2,
                                      fontFamily: 'YuGothic',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Enter the six digit code that we sent to \nyour registered cellphone to verify your account.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13.5,
                                      height: 1.5,
                                      fontFamily: 'YuGothic',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // _buildDeliveryMethodToggle(),
                                  const SizedBox(height: 24),
                                  _buildOTPInput(),
                                  const SizedBox(height: 32),
                                  _buildTimer(),
                                  const SizedBox(height: 8),
                                  Text(
                                    _timeLeft > 0 ? '' : 'Code expired',
                                    style: TextStyle(
                                      color: _timeLeft > 0
                                          ? Color(0xFF718096)
                                          : Colors.red,
                                      fontSize: 12,
                                      fontFamily: 'YuGothic',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Didn't Get OTP? ",
                                        style: TextStyle(
                                          color: Color(0xFF718096),
                                          fontSize: 14,
                                          fontFamily: 'YuGothic',
                                        ),
                                      ),
                                      MouseRegion(
                                        cursor:
                                            (_timeLeft == 0 && !_isResending)
                                            ? SystemMouseCursors.click
                                            : SystemMouseCursors.basic,
                                        child: GestureDetector(
                                          onTap:
                                              (_timeLeft == 0 && !_isResending)
                                              ? _showDeliveryMethodDialog
                                              : null,
                                          child: _isResending
                                              ? SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Color(0xFF4299E1)),
                                                  ),
                                                )
                                              : Text(
                                                  'Resend OTP',
                                                  style: TextStyle(
                                                    color: _timeLeft == 0
                                                        ? Colors.black
                                                        : Colors.grey,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1.2,
                                                    fontFamily: 'YuGothic',
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
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Column(
                            children: [
                              _buildVerifyButton(),
                              const SizedBox(height: 50),
                            ],
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 40,
                          right: 40,
                          bottom: 24,
                          top: 24,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context, {'action': 'back'}),
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
                                SizedBox(width: 40, height: 40),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: 2,
                                fontFamily: 'YuGothic',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Enter the six digit code that we sent to \nyour registered cellphone to verify your account.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13.5,
                                height: 1.5,
                                fontFamily: 'YuGothic',
                              ),
                            ),
                            const SizedBox(height: 16),
                            // _buildDeliveryMethodToggle(),
                            const SizedBox(height: 24),
                            _buildOTPInput(),
                            const SizedBox(height: 32),
                            _buildTimer(),
                            const SizedBox(height: 8),
                            Text(
                              _timeLeft > 0 ? '' : 'Code expired',
                              style: TextStyle(
                                color: _timeLeft > 0
                                    ? Color(0xFF718096)
                                    : Colors.red,
                                fontSize: 12,
                                fontFamily: 'YuGothic',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Didn't Get OTP? ",
                                  style: TextStyle(
                                    color: Color(0xFF718096),
                                    fontSize: 14,
                                    fontFamily: 'YuGothic',
                                  ),
                                ),
                                MouseRegion(
                                  cursor: (_timeLeft == 0 && !_isResending)
                                      ? SystemMouseCursors.click
                                      : SystemMouseCursors.basic,
                                  child: GestureDetector(
                                    onTap: (_timeLeft == 0 && !_isResending)
                                        ? _showDeliveryMethodDialog
                                        : null,
                                    child: _isResending
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF4299E1),
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Resend OTP',
                                            style: TextStyle(
                                              color: _timeLeft == 0
                                                  ? Colors.black
                                                  : Colors.grey,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.2,
                                              fontFamily: 'YuGothic',
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            _buildVerifyButton(),
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
      ],
    );
  }

  Widget _buildOTPInput() {
    return Container(
      constraints: BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          // Changed to 6 digits
          return MouseRegion(
            cursor: SystemMouseCursors.text,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(360),
                border: Border.all(
                  color: _otpFocusNodes[index].hasFocus
                      ? Constants.ctaColorLight
                      : Colors.grey,
                  width: 1,
                ),
              ),
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.backspace) {
                      if (_otpControllers[index].text.isEmpty && index > 0) {
                        // If current field is empty and backspace is pressed, move to previous field
                        _otpControllers[index - 1].clear();
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    }
                  }
                },
                child: Center(
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                      fontFamily: 'YuGothic',
                      height: 1.2,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(0),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }

                      if (index == 5 && value.isNotEmpty) {
                        _verifyOTP();
                      }
                    },
                    onSubmitted: (value) {
                      if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }
                    },
                    onTap: () {
                      // Move cursor to end when tapping
                      _otpControllers[index].selection =
                          TextSelection.fromPosition(
                            TextPosition(
                              offset: _otpControllers[index].text.length,
                            ),
                          );
                    },
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        fontFamily: 'YuGothic',
      ),
    );
  }

  Widget _buildVerifyButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 500,
        height: 45,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _verifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.ctaColorLight,
            foregroundColor: Colors.white,
            elevation: _isLoading ? 2 : 8,
            shadowColor: Constants.ctaColorLight.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(360),
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
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'YuGothic',
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDeliveryMethodToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Send OTP via: ',
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 14,
            fontFamily: 'YuGothic',
          ),
        ),
        SizedBox(width: 12),
        ChoiceChip(
          label: Text('SMS'),
          selected: _deliveryMethod == 'sms',
          onSelected: (selected) {
            if (selected && widget.phone.isNotEmpty) {
              setState(() {
                _deliveryMethod = 'sms';
              });
            } else if (widget.phone.isEmpty) {
              _showSnackBar('Phone number not available');
            }
          },
          selectedColor: Constants.ctaColorLight,
          labelStyle: TextStyle(
            color: _deliveryMethod == 'sms' ? Colors.white : Color(0xFF718096),
            fontFamily: 'YuGothic',
          ),
        ),
        SizedBox(width: 8),
        ChoiceChip(
          label: Text('Email'),
          selected: _deliveryMethod == 'email',
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _deliveryMethod = 'email';
              });
            }
          },
          selectedColor: Constants.ctaColorLight,
          labelStyle: TextStyle(
            color: _deliveryMethod == 'email'
                ? Colors.white
                : Color(0xFF718096),
            fontFamily: 'YuGothic',
          ),
        ),
      ],
    );
  }
}

class SellerOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String phone;
  final String? testOtp;
  final VoidCallback? onSuccess;

  const SellerOTPVerificationScreen({
    Key? key,
    required this.email,
    required this.phone,
    this.testOtp,
    this.onSuccess,
  }) : super(key: key);

  @override
  State<SellerOTPVerificationScreen> createState() =>
      _SellerOTPVerificationScreenState();
}

class _SellerOTPVerificationScreenState
    extends State<SellerOTPVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  ); // Changed to 6 digits
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );
  bool _isLoading = false;
  bool _isResending = false;
  late Timer _timer;
  int _timeLeft = 300; // 5 minutes
  final AuthApiService _authApiService = AuthApiService();

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _startTimer();

    // For testing: pre-fill OTP if provided
    if (widget.testOtp != null) {
      _fillTestOtp();
    }
  }

  void _fillTestOtp() {
    final otp = widget.testOtp!;
    for (int i = 0; i < otp.length && i < _otpControllers.length; i++) {
      _otpControllers[i].text = otp[i];
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  // API call to verify OTP
  Future<bool> _verifyOtpApi(String email, String otp) async {
    try {
      var url = Uri.parse('${GlobalVariables.authServiceUrl}verify-otp/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('OTP Verification Status: ${response.statusCode}');
      print('OTP Verification Response: ${response.body} $email');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('OTP verified successfully: $jsonResponse');
        return true;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('OTP verification failed: $errorResponse');

        // Show specific error message
        String errorMessage = 'OTP verification failed';
        if (errorResponse['error'] != null) {
          errorMessage = errorResponse['error'];
        } else if (errorResponse['otp'] != null) {
          errorMessage = errorResponse['otp'][0];
        } else if (errorResponse['message'] != null) {
          errorMessage = errorResponse['message'];
        }

        _showSnackBar(errorMessage);
        return false;
      }
    } catch (e) {
      print('Error occurred during OTP verification: $e');
      _showSnackBar('Network error. Please try again.');
      return false;
    }
  }

  // API call to resend OTP
  Future<bool> _resendOtpApi(String email, String phone) async {
    try {
      final result = await _authApiService.resendOtp(email, phone);

      if (result != null && result['success'] == true) {
        print('OTP resent successfully: ${result['data']}');
        return true;
      } else {
        String errorMessage = result?['error'] ?? 'Failed to resend OTP';
        _showSnackBar(errorMessage);
        return false;
      }
    } catch (e) {
      print('Error occurred during OTP resend: $e');
      _showSnackBar('Network error. Please try again.');
      return false;
    }
  }

  void _verifyOTP() async {
    String otp = _otpControllers.map((controller) => controller.text).join();

    if (otp.length != 6) {
      // Changed to 6 digits
      _showSnackBar('Please enter complete OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Call API to verify OTP
    bool isVerified = await _verifyOtpApi(widget.email, otp);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (isVerified) {
        _showSnackBar('OTP verified successfully!', isSuccess: true);

        // Navigate after a short delay to avoid Navigator conflicts
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            // If onSuccess callback is provided, use it (for signup flow)
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              // Default behavior: navigate to login page
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LoginPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: Curves.easeInOut)),
                          ),
                          child: child,
                        );
                      },
                ),
              );
            }
          }
        });
      }
    }
  }

  void _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    bool isResent = await _resendOtpApi(widget.email, widget.phone);

    if (mounted) {
      setState(() {
        _isResending = false;
      });

      if (isResent) {
        setState(() {
          _timeLeft = 300; // Reset to 5 minutes
        });
        _startTimer();
        _showSnackBar('OTP sent successfully!', isSuccess: true);

        // Clear existing OTP inputs
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _otpFocusNodes[0].requestFocus();
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
            child: MediaQuery.of(context).size.width < 800
                ? Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 24, top: 24),
                            child: Column(
                              children: [
                                Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: 1.1,
                                    fontFamily: 'YuGothic',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Enter the six digit code that we sent to your registered cellphone verify your account.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                    height: 1.5,
                                    fontFamily: 'YuGothic',
                                  ),
                                ),
                                const SizedBox(height: 40),
                                _buildOTPInput(),
                                const SizedBox(height: 32),
                                _buildTimer(),
                                const SizedBox(height: 8),
                                /*  Text(
                                  _timeLeft > 0 ? 'Code expires in:' : 'Code expired',
                                  style: TextStyle(
                                    color: _timeLeft > 0 ? Color(0xFF718096) : Colors.red,
                                    fontSize: 12,
                                    fontFamily: 'YuGothic',
                                  ),
                                ),*/
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Didn't Get OTP? ",
                                      style: TextStyle(
                                        color: Color(0xFF718096),
                                        fontSize: 14,
                                        fontFamily: 'YuGothic',
                                      ),
                                    ),
                                    MouseRegion(
                                      cursor: (_timeLeft == 0 && !_isResending)
                                          ? SystemMouseCursors.click
                                          : SystemMouseCursors.basic,
                                      child: GestureDetector(
                                        onTap: (_timeLeft == 0 && !_isResending)
                                            ? _resendOTP
                                            : null,
                                        child: _isResending
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFF4299E1)),
                                                ),
                                              )
                                            : Text(
                                                'Resend OTP',
                                                style: TextStyle(
                                                  color: _timeLeft == 0
                                                      ? const Color(0xFF4299E1)
                                                      : const Color(0xFF718096),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'YuGothic',
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
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            _buildVerifyButton(),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24, top: 24),
                      child: Column(
                        children: [
                          Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 1.1,
                              fontFamily: 'YuGothic',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter the six digit code that we sent to your registered cellphone verify your account.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              height: 1.5,
                              fontFamily: 'YuGothic',
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildOTPInput(),
                          const SizedBox(height: 32),
                          _buildTimer(),
                          const SizedBox(height: 8),
                          /*  Text(
                            _timeLeft > 0 ? 'Code expires in:' : 'Code expired',
                            style: TextStyle(
                              color: _timeLeft > 0 ? Color(0xFF718096) : Colors.red,
                              fontSize: 12,
                              fontFamily: 'YuGothic',
                            ),
                          ),*/
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't Get OTP? ",
                                style: TextStyle(
                                  color: Color(0xFF718096),
                                  fontSize: 14,
                                  fontFamily: 'YuGothic',
                                ),
                              ),
                              MouseRegion(
                                cursor: (_timeLeft == 0 && !_isResending)
                                    ? SystemMouseCursors.click
                                    : SystemMouseCursors.basic,
                                child: GestureDetector(
                                  onTap: (_timeLeft == 0 && !_isResending)
                                      ? _resendOTP
                                      : null,
                                  child: _isResending
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF4299E1),
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Resend OTP',
                                          style: TextStyle(
                                            color: _timeLeft == 0
                                                ? const Color(0xFF4299E1)
                                                : const Color(0xFF718096),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'YuGothic',
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildVerifyButton(),
                        ],
                      ),
                    ),
                  ),
          ),
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
      ],
    );
  }

  Widget _buildOTPInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        // Changed to 6 digits
        return MouseRegion(
          cursor: SystemMouseCursors.text,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(360),
              border: Border.all(
                color: _otpFocusNodes[index].hasFocus
                    ? Constants.ctaColorLight
                    : Colors.grey,
                width: 1,
              ),
            ),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.backspace) {
                    if (_otpControllers[index].text.isEmpty && index > 0) {
                      // If current field is empty and backspace is pressed, move to previous field
                      _otpControllers[index - 1].clear();
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  }
                }
              },
              child: Center(
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Constants.ftaColorLight,
                    fontFamily: 'YuGothic',
                    height: 1.2,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(0),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }

                    if (index == 5 && value.isNotEmpty) {
                      _verifyOTP();
                    }
                  },
                  onSubmitted: (value) {
                    if (value.isEmpty && index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  },
                  onTap: () {
                    // Move cursor to end when tapping
                    _otpControllers[index]
                        .selection = TextSelection.fromPosition(
                      TextPosition(offset: _otpControllers[index].text.length),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimer() {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade400,
        fontFamily: 'YuGothic',
      ),
    );
  }

  Widget _buildVerifyButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 500,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _verifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: Constants.ftaColorLight,
            maximumSize: Size(200, 50),
            foregroundColor: Colors.white,
            elevation: _isLoading ? 2 : 8,
            shadowColor: Constants.ctaColorLight.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(360),
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
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'YuGothic',
                  ),
                ),
        ),
      ),
    );
  }
}
