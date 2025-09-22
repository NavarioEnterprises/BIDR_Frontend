import 'package:bidr/constants/Constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

import 'package:share_plus/share_plus.dart';

import '../../../models/rewards/rewards_models.dart';
import '../../../services/rewards_service.dart';
import '../breakpoints.dart';


class ShareWidgetMobile extends StatefulWidget {
  @override
  _ShareWidgetMobileState createState() => _ShareWidgetMobileState();
}

class _ShareWidgetMobileState extends State<ShareWidgetMobile> {
  final RewardsService _rewardsService = RewardsService();
  ReferralCode? _referralCode;
  bool isCodeCopied = false;
  bool isLoading = false;
  String? _errorMessage;

  final String userUuid = Constants.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = await _rewardsService.getMyReferralCode(userUuid);
      setState(() {
        _referralCode = code;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load referral code. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _generateNewReferralCode() async {
    setState(() {
      isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = await _rewardsService.getMyReferralCode(userUuid);
      if (kDebugMode) {
        print("Generated new referral code: ${code.code}");
      }
      setState(() {
        _referralCode = code;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate new code. Please try again.';
        isLoading = false;
      });
    }
  }

  void _copyToClipboard() async {
    if (_referralCode == null) return;
    await Clipboard.setData(ClipboardData(text: _referralCode!.code));
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
      if (_referralCode == null) return;

      // Create the referral link and message
      String referralUrl = _referralCode!.referralUrl;

      String shareMessage =
      '''
🎉 Join me on this amazing app and earn rewards!

Use my referral code: ${_referralCode!.code}

Download the app: $referralUrl

Let's grow together and enjoy exclusive benefits! 💰
''';

      // Share the content
      final result = await Share.shareWithResult(
        shareMessage,
        subject: 'Join me and earn rewards with ${_referralCode!.code}',
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading:IconButton(
          onPressed:(){
            Navigator.pop(context);
            setState(() {

            });
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
        title: Text(
          "Refer A Friend",
          style: GoogleFonts.manrope(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Image
            Container(
              height: 250,
              width: double.infinity,
              child: Image.asset(
                'lib/assets/images/share.png',
                fit: BoxFit.contain,
              ),
            ),

           /* if (_selectedTopTab == 1) ...[
              Container(
                color: Constants.ftaColorLight,
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusTab("On Going", 0),
                      _buildStatusTab("Purchased", 1),
                      _buildStatusTab("Returns/Refunds", 2),
                      _buildStatusTab("Cancelled", 3),
                    ],
                  ),
                ),
              ),
            ],*/

            SizedBox(height: 16),

            // Title and Description
            Text(
              'Earn ${_referralCode?.referrerRewardAmount ?? 50} points for each friend you refer!',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Constants.ftaColorLight,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 8),

            Text(
              'Your friends will earn ${_referralCode?.refereeRewardAmount ?? 25} points when they join!',
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16),

            // Referral Code Container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(360),
                color: Colors.orange.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Constants.ftaColorLight,
                        ),
                      ),
                    )
                        : Text(
                      _referralCode?.code ?? 'Loading...',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Constants.ftaColorLight,
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
                        borderRadius: BorderRadius.circular(360),
                      ),
                      child: Icon(
                        isCodeCopied ? Icons.check : Icons.copy,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

           Spacer(),

            // Share Link Button
            SizedBox(
              width: MediaQuery.of(context).size.width ,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Generate New Code Button (Optional)
            TextButton(
              onPressed: _generateNewReferralCode,
              child: Text(
                'Generate New Code',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}