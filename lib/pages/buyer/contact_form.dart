import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../customWdget/custom_input2.dart';
import '../buyer_home.dart';

class ContactFormScreen extends StatefulWidget {
  @override
  _ContactFormScreenState createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // Focus Nodes
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode mobileFocusNode = FocusNode();
  final FocusNode subjectFocusNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();

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
    emailController.dispose();
    mobileController.dispose();
    subjectController.dispose();
    messageController.dispose();
    emailFocusNode.dispose();
    mobileFocusNode.dispose();
    subjectFocusNode.dispose();
    messageFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void handleSubmit() {
    // Handle form submission
    print('Email: ${emailController.text}');
    print('Mobile: ${mobileController.text}');
    print('Subject: ${subjectController.text}');
    print('Message: ${messageController.text}');

    // You can add your submission logic here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Message sent successfully!'),
        backgroundColor: Color(0xFFF5A623),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        //height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 24),
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
                                  padding: const EdgeInsets.only(bottom: 40,left: 24,right: 24),
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
                        padding: EdgeInsets.all(24),
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
                                        fontSize: 32,
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
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 40),

                            // Email Field
                            _buildAnimatedTextField(
                              label: 'Email',
                              hintText: 'Enter Email',
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
                              label: 'Mobile Number',
                              hintText: 'Enter Mobile Number',
                              controller: mobileController,
                              focusNode: mobileFocusNode,
                              textInputAction: TextInputAction.next,
                              delay: 400,
                              onSubmitted: (value) {
                                FocusScope.of(context).requestFocus(subjectFocusNode);
                              },
                            ),
                            SizedBox(height: 20),

                            // Subject Field
                            _buildAnimatedTextField(
                              label: 'Subject',
                              hintText: 'Enter Subject',
                              controller: subjectController,
                              focusNode: subjectFocusNode,
                              textInputAction: TextInputAction.next,
                              delay: 600,
                              onSubmitted: (value) {
                                FocusScope.of(context).requestFocus(messageFocusNode);
                              },
                            ),
                            SizedBox(height: 20),

                            // Message Field
                            _buildAnimatedMessageField(
                              label: 'Message',
                              hintText: 'Enter Message',
                              controller: messageController,
                              focusNode: messageFocusNode,
                              delay: 800,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
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
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Constants.ftaColorLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Color(0xFFF5A623), width: 2),
                      ),
                      contentPadding: EdgeInsets.all(16), // More padding for bigger field
                      fillColor: Colors.white,
                      filled: true,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomInputTransparent4(
                  hintText: hintText,
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: textInputAction,
                  maxLines: maxLines,
                  onChanged: (value) {},
                  onSubmitted: onSubmitted ?? (value) {},
                  isPasswordField: false,
                ),
              ],
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
        onPressed: handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFF5A623),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Submit',
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 300,
      height: 300,
      child: CustomPaint(
        painter: ContactIllustrationPainter(),
      ),
    );
  }
}


// Custom Painter for the Contact Illustration
class ContactIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw woman figure (simplified)
    // Head
    paint.color = Color(0xFFFFDBB5);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.25), 30, paint);

    // Hair
    paint.color = Colors.black87;
    final hairPath = Path();
    hairPath.addOval(Rect.fromCenter(
      center: Offset(size.width * 0.35, size.height * 0.2),
      width: 80,
      height: 60,
    ));
    canvas.drawPath(hairPath, paint);

    // Body (orange sweater)
    paint.color = Color(0xFFF5A623);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.35, size.height * 0.45),
          width: 80,
          height: 100,
        ),
        Radius.circular(20),
      ),
      paint,
    );

    // Phone
    paint.color = Color(0xFF4A4A4A);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.55, size.height * 0.4),
          width: 40,
          height: 60,
        ),
        Radius.circular(8),
      ),
      paint,
    );

    // Phone details (simplified)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width * 0.55, size.height * 0.35), 8, paint);

    // Speech bubble
    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.6, size.height * 0.15),
          width: 80,
          height: 40,
        ),
        Radius.circular(20),
      ),
      paint,
    );

    // Speech bubble tail
    final bubbleTail = Path();
    bubbleTail.moveTo(size.width * 0.55, size.height * 0.2);
    bubbleTail.lineTo(size.width * 0.45, size.height * 0.28);
    bubbleTail.lineTo(size.width * 0.6, size.height * 0.25);
    bubbleTail.close();
    canvas.drawPath(bubbleTail, paint);

    // Add some decorative lines in speech bubble
    paint.color = Colors.grey[300]!;
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.13),
      Offset(size.width * 0.65, size.height * 0.13),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.17),
      Offset(size.width * 0.65, size.height * 0.17),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}