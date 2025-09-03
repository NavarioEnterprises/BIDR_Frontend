import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../customWdget/custom_input2.dart';
import '../../global_values.dart';
import '../buyer_home.dart';
import '../../models/contact_submission.dart';
import '../../services/contact_api_service.dart';
import '../mobileView/breakpoints.dart';
import '../mobileView/landingPage/supportMobileView.dart';

class ContactFormScreen extends StatefulWidget {
  @override
  _ContactFormScreenState createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // Focus Nodes
  final FocusNode nameFocusNode = FocusNode();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode mobileFocusNode = FocusNode();
  final FocusNode companyFocusNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();

  // API Service and form state
  final ContactApiService _contactApiService = ContactApiService();
  String _selectedSubject = ContactSubjectChoices.general;
  bool _isSubmitting = false;

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    companyController.dispose();
    messageController.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    mobileFocusNode.dispose();
    companyFocusNode.dispose();
    messageFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    // Basic validation
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submission = ContactSubmission(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: mobileController.text.trim().isEmpty ? null : mobileController.text.trim(),
        company: companyController.text.trim().isEmpty ? null : companyController.text.trim(),
        subject: _selectedSubject,
        message: messageController.text.trim(),
      );

      final result = await _contactApiService.submitContactForm(submission);

      if (result['success']) {
        // Show success dialog
        _showSuccessDialog();
        
        // Clear form on success
        nameController.clear();
        emailController.clear();
        mobileController.clear();
        companyController.clear();
        messageController.clear();
        setState(() {
          _selectedSubject = ContactSubjectChoices.general;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to submit contact form'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: BuyerDashboardHeader(
                    headerName: 'Buyer Dashboard',
                    totalAlert: GlobalVariables.alertList.length,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: 1400),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Side - Illustration
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              duration: Duration(milliseconds: 400),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: 0.8 + (0.2 * value),
                                  child: Opacity(
                                    opacity: value,
                                    child: Padding(
                                      padding: Breakpoints.isTablet(context)
                                          ? EdgeInsets.only(
                                              bottom: ResponsiveSpacing.getSpacing(context).marginLarge,
                                              left: ResponsiveSpacing.getSpacing(context).paddingLarge,
                                              right: ResponsiveSpacing.getSpacing(context).paddingLarge,
                                            )
                                          : const EdgeInsets.only(bottom: 40,left: 24,right: 24),
                                      child: Image.asset(
                                        "lib/assets/images/contact.png",
                                        fit: BoxFit.contain,
                                        width: MediaQuery.of(context).size.width,
                                        height: 450,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Right Side - Contact Form
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: Breakpoints.isTablet(context)
                                ? EdgeInsets.all(ResponsiveSpacing.getSpacing(context).paddingLarge)
                                : EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Title
                                TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 400),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(20 * (1 - value), 0),
                                        child: Text(
                                          'Contact Us',
                                          style: GoogleFonts.manrope(
                                            fontSize: Breakpoints.isTablet(context)
                                                ? ResponsiveTypography.getTypography(context).heading
                                                : 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 8),
                                TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 1000),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Text(
                                        'We\'d love to hear from you. Send us a message!',
                                        style: GoogleFonts.manrope(
                                          fontSize: Breakpoints.isTablet(context)
                                              ? ResponsiveTypography.getTypography(context).normal
                                              : 16,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(height: 40),

                                // Name Field
                                _buildAnimatedTextField(
                                  label: 'Full Name *',
                                  hintText: 'Enter your full name',
                                  controller: nameController,
                                  focusNode: nameFocusNode,
                                  textInputAction: TextInputAction.next,
                                  delay: 100,
                                  onSubmitted: (value) {
                                    FocusScope.of(context).requestFocus(emailFocusNode);
                                  },
                                ),
                                SizedBox(height: 20),

                                // Email Field
                                _buildAnimatedTextField(
                                  label: 'Email Address *',
                                  hintText: 'Enter your email address',
                                  controller: emailController,
                                  focusNode: emailFocusNode,
                                  textInputAction: TextInputAction.next,
                                  delay: 200,
                                  onSubmitted: (value) {
                                    FocusScope.of(context).requestFocus(mobileFocusNode);
                                  },
                                ),
                                SizedBox(height: 20),

                                // Mobile Number Field
                                _buildAnimatedTextField(
                                  label: 'Phone Number',
                                  hintText: 'Enter your phone number (optional)',
                                  controller: mobileController,
                                  focusNode: mobileFocusNode,
                                  textInputAction: TextInputAction.next,
                                  delay: 300,
                                  onSubmitted: (value) {
                                    FocusScope.of(context).requestFocus(companyFocusNode);
                                  },
                                ),
                                SizedBox(height: 20),

                                // Company Field
                                _buildAnimatedTextField(
                                  label: 'Company',
                                  hintText: 'Enter your company name (optional)',
                                  controller: companyController,
                                  focusNode: companyFocusNode,
                                  textInputAction: TextInputAction.next,
                                  delay: 400,
                                  onSubmitted: (value) {
                                    // Move focus to message field since subject is now a dropdown
                                    FocusScope.of(context).requestFocus(messageFocusNode);
                                  },
                                ),
                                SizedBox(height: 20),

                                // Subject Dropdown
                                _buildAnimatedSubjectDropdown(
                                  delay: 500,
                                ),
                                SizedBox(height: 20),

                                // Message Field
                                _buildAnimatedMessageField(
                                  label: 'Message *',
                                  hintText: 'Enter your message',
                                  controller: messageController,
                                  focusNode: messageFocusNode,
                                  delay: 600,
                                ),
                                SizedBox(height: 40),

                                // Submit Button
                                TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 1200),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
                                        child: _buildSubmitButton(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Animated Footer
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 1),
                      end: Offset.zero,
                    ).animate(_slideController),
                    child: Center(
                        child: FooterSection(logo: "lib/assets/images/bidr_logo2.png")
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAnimatedMessageField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Container(
              height: 120, // Bigger height for message field
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),


              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: null, // Allow unlimited lines
                expands: true, // Expand to fill container height
                textAlignVertical: TextAlignVertical.top, // Start text at top
                style: GoogleFonts.manrope(
                  fontSize: Breakpoints.isTablet(context) 
                      ? ResponsiveTypography.getTypography(context).normal 
                      : 14,
                  color: Colors.black87,
                ),

                decoration: InputDecoration(
                  hintText: hintText.replaceAll('*', ''),
                  hintStyle: GoogleFonts.manrope(
                    fontSize: Breakpoints.isTablet(context) 
                        ? ResponsiveTypography.getTypography(context).normal 
                        : 14,
                    color: Colors.grey[500],
                  ),
                  labelText: label.replaceAll('*', ''),
                  labelStyle: TextStyle(
                    color: Constants.ftaColorLight,
                    fontSize: Breakpoints.isTablet(context) 
                        ? ResponsiveTypography.getTypography(context).normal 
                        : 14,
                  ),
                  floatingLabelStyle: TextStyle(
                    color: Constants.ftaColorLight,
                    fontSize: Breakpoints.isTablet(context) 
                        ? ResponsiveTypography.getTypography(context).normal 
                        : 14,

                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Constants.ftaColorLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Color(0xFFF5A623), width: 2),
                  ),
                  contentPadding: Breakpoints.isTablet(context) 
                      ? EdgeInsets.all(ResponsiveSpacing.getSpacing(context).paddingMedium) 
                      : EdgeInsets.all(16), // More padding for bigger field
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedTextField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputAction textInputAction,
    required int delay,
    int maxLines = 1,
    Function(String)? onSubmitted,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width*0.35,
              child: CustomInputTransparent4(
                hintText: hintText.replaceAll('*', ''),
                labelText: hintText,
                controller: controller,
                focusNode: focusNode,
                textInputAction: focusNode != null
                    ? TextInputAction.next
                    : TextInputAction.done,
                isPasswordField: false,
                onChanged: (value) {},
                onSubmitted:onSubmitted??(value){},
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSubjectDropdown({required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child:Container(
              width: double.infinity,
              height: 48,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Subject",
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'YuGothic',
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Constants.ftaColorLight),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Constants.ctaColorLight),
                    borderRadius: BorderRadius.circular(36),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    menuMaxHeight: 200,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                      value: _selectedSubject,
                    hint: Text(
                      "Subject".replaceAll('*', ''),
                      style: GoogleFonts.manrope(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
                    items:ContactSubjectChoices.choices.entries.map((entry) {
                return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
                );
                }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSubject = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSubmitting ? Colors.grey : Color(0xFFF5A623),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Submitting...',
                    style: GoogleFonts.manrope(
                      fontSize: Breakpoints.isTablet(context) 
                          ? ResponsiveTypography.getTypography(context).normal 
                          : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                'Submit',
                style: GoogleFonts.manrope(
                  fontSize: Breakpoints.isTablet(context) 
                      ? ResponsiveTypography.getTypography(context).normal 
                      : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }


  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: const Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(top: 20),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFFF5A623).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFFF5A623),
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: Text(
                    'Thank You!',
                    style: GoogleFonts.manrope(
                      fontSize: Breakpoints.isTablet(context) 
                          ? ResponsiveTypography.getTypography(context).subHeading 
                          : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10, left: 20, right: 20),
                  child: Text(
                    'Your message has been sent successfully.',
                    style: GoogleFonts.manrope(
                      fontSize: Breakpoints.isTablet(context) 
                          ? ResponsiveTypography.getTypography(context).normal 
                          : 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 5, left: 20, right: 20, bottom: 20),
                  child: Text(
                    'We\'ll get back to you soon!',
                    style: GoogleFonts.manrope(
                      fontSize: Breakpoints.isTablet(context) 
                          ? ResponsiveTypography.getTypography(context).normal 
                          : 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(bottom: 20, left: 20, right: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF5A623),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: GoogleFonts.manrope(
                          fontSize: Breakpoints.isTablet(context) 
                              ? ResponsiveTypography.getTypography(context).normal 
                              : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
