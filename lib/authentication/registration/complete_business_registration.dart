
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../constants/Constants.dart';

class BusinessRegistrationCompleteWidget extends StatelessWidget {


  const BusinessRegistrationCompleteWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BIDR Logo with checkmark
            _buildLogoWithCheckmark(),

            const SizedBox(height: 24),

            // Title
             Text(
              'Your Business\nRegistration Is Complete',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'YuGothic',
                fontWeight: FontWeight.bold,
                color: Constants.ftaColorLight,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Currently, your account status is pending. An admin will review and activate it shortly. You will receive a notification once the admin activates your account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'YuGothic',
                color: Colors.grey[400],
                height: 1.5,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildLogoWithCheckmark() {
    return SizedBox(
      width: 105,
      height: 105,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // BIDR Logo Container
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

          // Checkmark badge
          Positioned(
            top: 4,
            right: 8,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Constants.ctaColorLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Gear-like notches around the circle
                  ...List.generate(8, (index) {
                    final angle = (index * 45) * (3.14159 / 180);
                    return Positioned(
                      top: 22 - 3 + (18 * math.cos(angle + 3.14159/2)),
                      left: 22 - 3 + (18 * math.sin(angle + 3.14159/2)),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5A623),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                  // Main checkmark icon
                  const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                      weight: 700,
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
}