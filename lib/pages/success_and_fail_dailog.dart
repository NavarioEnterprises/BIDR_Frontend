import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DialogHelper {
  // Success Dialog
  static void showSuccessDialog(
      BuildContext context, {
        required String title,
        required String message,
        String? buttonText,
        VoidCallback? onPressed,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AnimatedDialog(
          child: _SuccessDialog(
            title: title,
            message: message,
            buttonText: buttonText ?? 'Continue',
            onPressed: onPressed ?? () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }

  // Failure Dialog
  static void showFailureDialog(
      BuildContext context, {
        required String title,
        required String message,
        String? primaryButtonText,
        String? secondaryButtonText,
        VoidCallback? onPrimaryPressed,
        VoidCallback? onSecondaryPressed,
      }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _AnimatedDialog(
          child: _FailureDialog(
            title: title,
            message: message,
            primaryButtonText: primaryButtonText ?? 'Try Again',
            secondaryButtonText: secondaryButtonText ?? 'Cancel',
            onPrimaryPressed: onPrimaryPressed ?? () => Navigator.of(context).pop(),
            onSecondaryPressed: onSecondaryPressed ?? () => Navigator.of(context).pop(),
          ),
        );
      },
    );
  }
}

class _AnimatedDialog extends StatefulWidget {
  final Widget child;

  const _AnimatedDialog({required this.child});

  @override
  _AnimatedDialogState createState() => _AnimatedDialogState();
}

class _AnimatedDialogState extends State<_AnimatedDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _SuccessDialog extends StatefulWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _SuccessDialog({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  _SuccessDialogState createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _checkmarkAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _checkmarkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    Future.delayed(Duration(milliseconds: 200), () {
      _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Success Icon
            AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 0,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Transform.scale(
                      scale: _checkmarkAnimation.value,
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),

            // Title
            Text(
              widget.title,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),

            // Message
            Text(
              widget.message,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Success Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.buttonText,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureDialog extends StatefulWidget {
  final String title;
  final String message;
  final String primaryButtonText;
  final String secondaryButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onSecondaryPressed;

  const _FailureDialog({
    required this.title,
    required this.message,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onPrimaryPressed,
    required this.onSecondaryPressed,
  });

  @override
  _FailureDialogState createState() => _FailureDialogState();
}

class _FailureDialogState extends State<_FailureDialog>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    Future.delayed(Duration(milliseconds: 200), () {
      _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Error Icon
            AnimatedBuilder(
              animation: _iconController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconScaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(
                      _shakeAnimation.value > 0.5
                          ? ((_shakeAnimation.value - 0.5) * 2) *
                          10 * Math.sin(_iconController.value * 20 * Math.pi)
                          : 0,
                      0,
                    ),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 0,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),

            // Title
            Text(
              widget.title,
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),

            // Message
            Text(
              widget.message,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),

            // Buttons Row
            Row(
              children: [
                // Secondary Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: widget.onSecondaryPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.secondaryButtonText,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // Primary Button
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onPrimaryPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.primaryButtonText,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
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
}
