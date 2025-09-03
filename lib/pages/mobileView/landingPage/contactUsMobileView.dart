import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../customWdget/appbar.dart';
import '../../../customWdget/customCard.dart';
import '../../../customWdget/custom_input2.dart';
import '../../../models/contact_submission.dart';
import '../../../services/contact_api_service.dart';
import '../../buyer/support.dart';
import '../../buyer_home.dart';
import '../breakpoints.dart';

class ContactFormMobileScreen extends StatefulWidget {
  const ContactFormMobileScreen({super.key});

  @override
  _ContactFormMobileScreenState createState() => _ContactFormMobileScreenState();
}

class _ContactFormMobileScreenState extends State<ContactFormMobileScreen> with TickerProviderStateMixin {
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
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
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
      begin: Offset(0, 0.1),
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
      _showErrorMessage('Please fill in all required fields');
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(emailController.text.trim())) {
      _showErrorMessage('Please enter a valid email address');
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
        _showSuccessDialog();
        _clearForm();
      } else {
        _showErrorMessage(result['message'] ?? 'Failed to submit contact form');
      }
    } catch (e) {
      _showErrorMessage('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    nameController.clear();
    emailController.clear();
    mobileController.clear();
    companyController.clear();
    messageController.clear();
    setState(() {
      _selectedSubject = ContactSubjectChoices.general;
    });
  }

  void _showErrorMessage(String message) {
    final spacing = ResponsiveSpacing.getSpacing(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.manrope(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(spacing.spacingMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header
          SizedBox(height: spacing.spacingLarge),
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: BuyerDashboardHeader(
                    headerName: '',
                    totalAlert: 0,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: spacing.spacingLarge),
          
          // Main Content
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Section with Title
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.paddingLarge,
                        horizontal: spacing.paddingLarge,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Constants.ctaColorLight.withOpacity(0.1),
                            Constants.ctaColorLight.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: 0.8 + (0.2 * value),
                                child: Icon(
                                  HugeIcons.strokeRoundedMail01,
                                  size: 48,
                                  color: Constants.ctaColorLight,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: spacing.spacingMedium),
                          Text(
                            'Contact Us',
                            style: GoogleFonts.manrope(
                              fontSize: typography.heading,
                              fontWeight: FontWeight.bold,
                              color: Constants.ftaColorLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing.spacingSmall),
                          Text(
                            'We\'d love to hear from you. Send us a message!',
                            style: GoogleFonts.manrope(
                              fontSize: typography.normal,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Mobile Layout - Column with Image First, Then Form
                    Container(
                      padding: EdgeInsets.all(spacing.paddingLarge),
                      child: Column(
                        children: [
                          // Contact Image Section
                          _buildImageSection(typography, spacing),
                          
                          SizedBox(height: spacing.spacingLarge * 2),
                          
                          // Contact Form Section
                          _buildContactForm(typography, spacing),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: spacing.spacingLarge * 2),
                    
                    // Footer
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1200),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: FooterSection(logo: "lib/assets/images/bidr_logo2.png"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(TypographyConfig typography, SpacingConfig spacing) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: CustomCard(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(spacing.paddingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Constants.ctaColorLight.withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Main Contact Image
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 250,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          "lib/assets/images/contact.png",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedCustomerSupport,
                                    size: 64,
                                    color: Constants.ctaColorLight,
                                  ),
                                  SizedBox(height: spacing.spacingMedium),
                                  Text(
                                    'Contact Support',
                                    style: GoogleFonts.manrope(
                                      fontSize: typography.subHeading,
                                      fontWeight: FontWeight.bold,
                                      color: Constants.ftaColorLight,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    SizedBox(height: spacing.spacingLarge),
                    
                    // Contact Information Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactInfoCard(
                            icon: HugeIcons.strokeRoundedMail01,
                            title: 'Email',
                            subtitle: 'support@bidr.co.za',
                            color: Colors.blue[400]!,
                            typography: typography,
                            spacing: spacing,
                          ),
                        ),
                        SizedBox(width: spacing.spacingMedium),
                        Expanded(
                          child: _buildContactInfoCard(
                            icon: HugeIcons.strokeRoundedCall,
                            title: 'Phone',
                            subtitle: '+27 (0) 11 123 4567',
                            color: Colors.green[400]!,
                            typography: typography,
                            spacing: spacing,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: spacing.spacingMedium),
                    
                    _buildContactInfoCard(
                      icon: HugeIcons.strokeRoundedTime04,
                      title: 'Business Hours',
                      subtitle: 'Mon-Fri: 9AM-5PM (SAST)',
                      color: Constants.ctaColorLight,
                      typography: typography,
                      spacing: spacing,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required TypographyConfig typography,
    required SpacingConfig spacing,
    bool fullWidth = false,
  }) {
    return Container(
      padding: EdgeInsets.all(spacing.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: fullWidth
          ? Row(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.paddingSmall),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: typography.large),
                ),
                SizedBox(width: spacing.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: typography.medium,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      SizedBox(height: spacing.spacingSmall / 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          fontSize: typography.normal,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(spacing.paddingSmall),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: typography.large),
                ),
                SizedBox(height: spacing.spacingSmall),
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontSize: typography.normal,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.spacingSmall / 2),
                Text(
                  subtitle,
                  style: GoogleFonts.manrope(
                    fontSize: typography.normal,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  Widget _buildContactForm(TypographyConfig typography, SpacingConfig spacing) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: CustomCard(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(spacing.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form Title
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(spacing.paddingSmall),
                          decoration: BoxDecoration(
                            color: Constants.ctaColorLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            HugeIcons.strokeRoundedEdit01,
                            color: Constants.ctaColorLight,
                            size: typography.large,
                          ),
                        ),
                        SizedBox(width: spacing.spacingMedium),
                        Text(
                          'Send us a Message',
                          style: GoogleFonts.manrope(
                            fontSize: typography.subHeading,
                            fontWeight: FontWeight.bold,
                            color: Constants.ftaColorLight,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: spacing.spacingLarge),
                    
                    // Form Fields
                    _buildAnimatedTextField(
                      label: 'Full Name',
                      hintText: 'Enter your full name',
                      controller: nameController,
                      focusNode: nameFocusNode,
                      icon: HugeIcons.strokeRoundedUser,
                      required: true,
                      delay: 200,
                      onSubmitted: (value) {
                        FocusScope.of(context).requestFocus(emailFocusNode);
                      },
                    ),
                    
                    SizedBox(height: spacing.spacingMedium),
                    
                    _buildAnimatedTextField(
                      label: 'Email Address',
                      hintText: 'Enter your email address',
                      controller: emailController,
                      focusNode: emailFocusNode,
                      icon: HugeIcons.strokeRoundedMail01,
                      required: true,
                      delay: 300,
                      onSubmitted: (value) {
                        FocusScope.of(context).requestFocus(mobileFocusNode);
                      },
                    ),
                    
                    SizedBox(height: spacing.spacingMedium),
                    
                    _buildAnimatedTextField(
                      label: 'Phone Number',
                      hintText: 'Enter your phone number (optional)',
                      controller: mobileController,
                      focusNode: mobileFocusNode,
                      icon: HugeIcons.strokeRoundedCall,
                      required: false,
                      delay: 400,
                      onSubmitted: (value) {
                        FocusScope.of(context).requestFocus(companyFocusNode);
                      },
                    ),
                    
                    SizedBox(height: spacing.spacingMedium),
                    
                    _buildAnimatedTextField(
                      label: 'Company',
                      hintText: 'Enter your company name (optional)',
                      controller: companyController,
                      focusNode: companyFocusNode,
                      icon: HugeIcons.strokeRoundedBuilding01,
                      required: false,
                      delay: 500,
                      onSubmitted: (value) {
                        FocusScope.of(context).requestFocus(messageFocusNode);
                      },
                    ),
                    
                    SizedBox(height: spacing.spacingMedium),
                    
                    // Subject Dropdown
                    _buildAnimatedSubjectDropdown(delay: 600),
                    
                    SizedBox(height: spacing.spacingMedium),
                    
                    // Message Field
                    _buildAnimatedMessageField(
                      label: 'Message',
                      hintText: 'Enter your message',
                      controller: messageController,
                      focusNode: messageFocusNode,
                      delay: 700,
                    ),
                    
                    SizedBox(height: spacing.spacingLarge),
                    
                    // Submit Button
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1400),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: _buildSubmitButton(typography, spacing),
                          ),
                        );
                      },
                    ),
                  ],
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
    required IconData icon,
    required bool required,
    required int delay,
    Function(String)? onSubmitted,
  }) {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child:  CustomInputTransparent4(
              hintText: hintText,
              labelText: label,
              controller: controller,
              focusNode: focusNode,
              prefix: Icon(
                icon,
                color: Constants.ctaColorLight,
                size: typography.normal,
              ),
              textInputAction: TextInputAction.next,
              isPasswordField: false,
              onChanged: (value) {},
              onSubmitted: onSubmitted ?? (value) {},
            ),
          ),
        );
      },
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

  Widget _buildSubmitButton(TypographyConfig typography, SpacingConfig spacing) {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSubmitting ? Colors.grey[400] : Constants.ctaColorLight,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          disabledBackgroundColor: Colors.grey[400],
        ),
        icon: _isSubmitting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(HugeIcons.strokeRoundedSent),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Send Message',
          style: GoogleFonts.manrope(
            fontSize: typography.medium,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    final typography = ResponsiveTypography.getTypography(context);
    final spacing = ResponsiveSpacing.getSpacing(context);
    
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
            constraints: BoxConstraints(maxWidth: 350),
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
                  padding: EdgeInsets.only(top: spacing.paddingLarge * 1.5),
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
                            color: Constants.ctaColorLight.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            HugeIcons.strokeRoundedCheckmarkCircle02,
                            color: Constants.ctaColorLight,
                            size: 50,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.only(
                    top: spacing.paddingLarge,
                    left: spacing.paddingLarge,
                    right: spacing.paddingLarge,
                  ),
                  child: Text(
                    'Message Sent!',
                    style: GoogleFonts.manrope(
                      fontSize: typography.subHeading,
                      fontWeight: FontWeight.bold,
                      color: Constants.ftaColorLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.only(
                    top: spacing.paddingSmall,
                    left: spacing.paddingLarge,
                    right: spacing.paddingLarge,
                  ),
                  child: Text(
                    'Thank you for contacting us! We\'ll get back to you within 24 hours.',
                    style: GoogleFonts.manrope(
                      fontSize: typography.normal,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                Container(
                  padding: EdgeInsets.only(
                    top: spacing.paddingLarge,
                    bottom: spacing.paddingLarge,
                    left: spacing.paddingLarge,
                    right: spacing.paddingLarge,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.ctaColorLight,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: spacing.paddingSmall + 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Got it!',
                        style: GoogleFonts.manrope(
                          fontSize: typography.normal,
                          fontWeight: FontWeight.bold,
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