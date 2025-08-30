import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:share_plus/share_plus.dart';

class ShareWidget extends StatefulWidget {
  @override
  _ShareWidgetState createState() => _ShareWidgetState();
}

class _ShareWidgetState extends State<ShareWidget> {
  String referralCode = '';
  bool isCodeCopied = false;

  @override
  void initState() {
    super.initState();
    _generateReferralCode();
  }

  void _generateReferralCode() {
    // Generate random 8-digit number
    Random random = Random();
    int randomNumber = random.nextInt(90000000) + 10000000; // Ensures 8 digits
    setState(() {
      referralCode = 'BIDR$randomNumber';
    });
  }

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: referralCode));
    setState(() {
      isCodeCopied = true;
    });

    // Reset the copied state after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isCodeCopied = false;
        });
      }
    });

    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referral code copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLink() async {
    try {
      // Create the referral link and message
      String appUrl = 'https://your-app-url.com'; // Replace with your actual app URL
      String referralUrl = '$appUrl/referral?code=$referralCode';

      String shareMessage = '''
🎉 Join me on this amazing app and earn rewards!

Use my referral code: $referralCode

Download the app: $referralUrl

Let's grow together and enjoy exclusive benefits! 💰
''';

      // Share the content
      final result = await Share.shareWithResult(
        shareMessage,
        subject: 'Join me and earn rewards with $referralCode',
      );

      // Handle the share result
      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully shared your referral link!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Handle any errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width*0.35,
      height: 400,
      padding: EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Image
          Container(
            height: 200,
            width: double.infinity,
            child: Image.asset(
              'lib/assets/images/share.png',
              fit: BoxFit.contain,
            ),
          ),

          SizedBox(height: 24),

          // Title and Description
          Text(
            'Earn rewards by referring friends to our business!',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Constants.ftaColorLight,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8),

          Text(
            'Share the benefits and grow together.',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24),

          // Referral Code Container
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(360),
              color: Colors.orange.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    referralCode,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:Constants.ftaColorLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCodeCopied ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCodeCopied ? Icons.check : Icons.copy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Share Link Button
          SizedBox(
            width: MediaQuery.of(context).size.width*0.3,
            child: ElevatedButton(
              onPressed: _shareLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.ctaColorLight,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(360),
                ),
                elevation: 3,
              ),
              child: Text(
                'Share Link',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Generate New Code Button (Optional)
          TextButton(
            onPressed: _generateReferralCode,
            child: Text(
              'Generate New Code',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


