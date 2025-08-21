import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/Constants.dart';
import '../customWdget/customCard.dart';
import 'forgot_password.dart';
import 'login.dart';

class BidrOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String? testOtp;

  const BidrOTPVerificationScreen({Key? key, required this.email, this.testOtp})
    : super(key: key);

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
  int _timeLeft = 180;

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
      final url = Uri.parse('${Constants.bidrBaseUrl}api/otp/verify/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('OTP Verification Status: ${response.statusCode}');
      print('OTP Verification Response: ${response.body}');

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
  Future<bool> _resendOtpApi(String email) async {
    try {
      final url = Uri.parse('${Constants.bidrBaseUrl}resend-otp/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Resend OTP Status: ${response.statusCode}');
      print('Resend OTP Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('OTP resent successfully: $jsonResponse');
        return true;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('Resend OTP failed: $errorResponse');

        String errorMessage = 'Failed to resend OTP';
        if (errorResponse['error'] != null) {
          errorMessage = errorResponse['error'];
        }

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

        // Navigate to login page after successful verification
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
  }

  void _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    bool isResent = await _resendOtpApi(widget.email);

    if (mounted) {
      setState(() {
        _isResending = false;
      });

      if (isResent) {
        setState(() {
          _timeLeft = 180;
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
    return Scaffold(
      body: Center(
        child: CustomCard(
          color: Colors.white,
          elevation: 2,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: BoxConstraints(maxWidth: 880, maxHeight: 660),
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black.withOpacity(0.75),
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
                              Positioned(
                                left: 32,
                                top: 32,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Constants.ctaColorLight,
                                    foregroundColor: Constants.ftaColorLight,
                                  ),
                                  icon: Icon(
                                    CupertinoIcons.back,
                                    color: Constants.ftaColorLight,
                                  ),
                                  label: Text(
                                    'BACK',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'YuGothic',
                                      fontWeight: FontWeight.bold,
                                      color: Constants.ftaColorLight,
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
                                          onPressed: () =>
                                              Navigator.pop(context),
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
                                        color: Color(0xFF1A365D),
                                        fontFamily: 'YuGothic',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Enter the six digit code that we sent to\n${widget.email} to verify your account',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF718096),
                                        fontSize: 15,
                                        height: 1.5,
                                        fontFamily: 'YuGothic',
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    _buildOTPInput(),
                                    const SizedBox(height: 32),
                                    _buildTimer(),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                (_timeLeft == 0 &&
                                                    !_isResending)
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
                                                          ? const Color(
                                                              0xFF4299E1,
                                                            )
                                                          : const Color(
                                                              0xFF718096,
                                                            ),
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        // Changed to 6 digits
        return MouseRegion(
          cursor: SystemMouseCursors.text,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(360),
              border: Border.all(
                color: _otpFocusNodes[index].hasFocus
                    ? Constants.ctaColorLight
                    : Constants.ftaColorLight,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.ftaColorLight,
                fontFamily: 'YuGothic',
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
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
        width: double.infinity,
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
}


class SellerOTPVerificationScreen extends StatefulWidget {
  final String email;
  final String? testOtp;

  const SellerOTPVerificationScreen({Key? key, required this.email, this.testOtp})
      : super(key: key);

  @override
  State<SellerOTPVerificationScreen> createState() =>
      _SellerOTPVerificationScreenState();
}

class _SellerOTPVerificationScreenState extends State<SellerOTPVerificationScreen>
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
  int _timeLeft = 180;

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
      final url = Uri.parse('${Constants.bidrBaseUrl}api/otp/verify/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('OTP Verification Status: ${response.statusCode}');
      print('OTP Verification Response: ${response.body}');

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
  Future<bool> _resendOtpApi(String email) async {
    try {
      final url = Uri.parse('${Constants.bidrBaseUrl}resend-otp/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Resend OTP Status: ${response.statusCode}');
      print('Resend OTP Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        print('OTP resent successfully: $jsonResponse');
        return true;
      } else {
        final errorResponse = jsonDecode(response.body);
        print('Resend OTP failed: $errorResponse');

        String errorMessage = 'Failed to resend OTP';
        if (errorResponse['error'] != null) {
          errorMessage = errorResponse['error'];
        }

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

        // Navigate to login page after successful verification
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
  }

  void _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    bool isResent = await _resendOtpApi(widget.email);

    if (mounted) {
      setState(() {
        _isResending = false;
      });

      if (isResent) {
        setState(() {
          _timeLeft = 180;
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
      children:[
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
                  bottom: 24,
                  top: 24,
                ),
                child: Column(
                  children: [

                     Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Constants.ftaColorLight,
                        fontFamily: 'YuGothic',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the six digit code that we sent to\n${widget.email} to verify your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 15,
                        height: 1.5,
                        fontFamily: 'YuGothic',
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildOTPInput(),
                    const SizedBox(height: 32),
                    _buildTimer(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
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
                            (_timeLeft == 0 &&
                                !_isResending)
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
                                    ? const Color(
                                  0xFF4299E1,
                                )
                                    : const Color(
                                  0xFF718096,
                                ),
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w600,
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(360),
              border: Border.all(
                color: _otpFocusNodes[index].hasFocus
                    ? Constants.ctaColorLight
                    : Constants.ftaColorLight,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.ftaColorLight,
                fontFamily: 'YuGothic',
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
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
        width: double.infinity,
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