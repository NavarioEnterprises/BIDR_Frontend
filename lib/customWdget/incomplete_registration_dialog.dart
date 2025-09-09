import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../constants/Constants.dart';
import '../services/shared_preferences.dart';

class IncompleteRegistrationDialog extends StatelessWidget {
  final Map<String, dynamic> registrationData;

  const IncompleteRegistrationDialog({
    Key? key,
    required this.registrationData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBusinessRegistration = registrationData['type'] == 'business';
    final progress = registrationData['progress'] as Map<String, dynamic>;
    final timestamp = DateTime.tryParse(progress['timestamp'] ?? '');
    
    String progressText = '';
    if (isBusinessRegistration) {
      final currentStep = progress['currentStep'] ?? 0;
      final totalSteps = 7;
      progressText = 'Step ${currentStep + 1} of $totalSteps';
    } else {
      progressText = 'Registration form partially filled';
    }

    String timeAgo = '';
    if (timestamp != null) {
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      if (difference.inMinutes < 60) {
        timeAgo = '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        timeAgo = '${difference.inHours} hours ago';
      } else {
        timeAgo = '${difference.inDays} days ago';
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Constants.ctaColorLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.assignment_outlined,
                color: Constants.ctaColorLight,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Continue Registration?',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'You have an incomplete ${isBusinessRegistration ? 'business' : 'buyer'} registration saved.',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Progress info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                children: [
                  Text(
                    progressText,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Constants.ctaColorLight,
                    ),
                  ),
                  if (timeAgo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last saved: $timeAgo',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      // Clear the saved progress
                      if (isBusinessRegistration) {
                        await FormProgressService.clearBusinessFormProgress();
                      } else {
                        await FormProgressService.clearBuyerFormProgress();
                      }
                      Navigator.of(context).pop(false);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      side: BorderSide(color: Constants.ctaColorLight),
                    ),
                    child: Text(
                      'Start Fresh',
                      style: GoogleFonts.manrope(
                        color: Constants.ctaColorLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> show(BuildContext context, Map<String, dynamic> registrationData) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => IncompleteRegistrationDialog(
        registrationData: registrationData,
      ),
    );
  }
}