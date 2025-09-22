import 'package:bidr/constants/Constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Custom Dialog Types
enum DialogType { success, error, warning, info }

// Smart Dialog Service
class SmartDialogService {
  static void showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Continue',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => SmartDialog(
        type: DialogType.success,
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }

  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Try Again',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => SmartDialog(
        type: DialogType.error,
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }

  static void showWarningDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Understood',
    VoidCallback? onPressed,
    bool barrierDismissible = true,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => SmartDialog(
        type: DialogType.warning,
        title: title,
        message: message,
        buttonText: buttonText,
      ),
    );
  }
}

// Main Smart Dialog Widget
class SmartDialog extends StatefulWidget {
  final DialogType type;
  final String title;
  final String message;
  final String buttonText;
  final bool showSecondaryButton;
  final String? secondaryButtonText;

  const SmartDialog({
    Key? key,
    required this.type,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.showSecondaryButton = false,
    this.secondaryButtonText,
  }) : super(key: key);

  @override
  State<SmartDialog> createState() => _SmartDialogState();
}

class _SmartDialogState extends State<SmartDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  DialogConfig get _config {
    switch (widget.type) {
      case DialogType.success:
        return DialogConfig(
          color: Constants.ftaColorLight,
          icon: Icons.check_circle,
          backgroundColor: Constants.ftaColorLight,
        );
      case DialogType.error:
        return DialogConfig(
          color: const Color(0xFFEF4444),
          icon: Icons.error,
          backgroundColor: const Color(0xFFFEF2F2),
        );
      case DialogType.warning:
        return DialogConfig(
          color: const Color(0xFFF59E0B),
          icon: Icons.warning,
          backgroundColor: const Color(0xFFFFFBEB),
        );
      case DialogType.info:
        return DialogConfig(
          color: const Color(0xFF3B82F6),
          icon: Icons.info,
          backgroundColor: const Color(0xFFEFF6FF),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _buildDialogContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContent() {
    final config = _config;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and colored background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(config.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: widget.type == DialogType.success
                        ? Colors.white
                        : Constants.ftaColorLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  widget.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Buttons
                Row(
                  children: [
                    if (widget.showSecondaryButton) ...[
                      Expanded(child: _buildSecondaryButton()),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: _buildPrimaryButton(config)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(DialogConfig config) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).pop();
        context.go('/login');
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: config.color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(360)),
        elevation: 4,
      ),
      child: Text(
        widget.buttonText,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton(
      onPressed: () {
        Navigator.of(context).pop();
        setState(() {});
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(360)),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Text(
        widget.secondaryButtonText ?? 'Cancel',
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// Dialog Configuration Class
class DialogConfig {
  final Color color;
  final IconData icon;
  final Color backgroundColor;

  DialogConfig({
    required this.color,
    required this.icon,
    required this.backgroundColor,
  });
}
