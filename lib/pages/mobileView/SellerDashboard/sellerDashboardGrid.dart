
import 'package:flutter/material.dart';

class HelperWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;

  const HelperWidget({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.backgroundColor = const Color(0xFFE8A567),
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 100,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: iconColor,
                      size: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Title and subtitle
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HelperWidgetsGrid extends StatelessWidget {
  const HelperWidgetsGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Helper Widgets'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                HelperWidget(
                  icon: Icons.book_outlined,
                  title: 'My Bookkeeper',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('My Bookkeeper tapped')),
                    );
                  },
                ),
                HelperWidget(
                  icon: Icons.support_agent_outlined,
                  title: 'Support (BIDR)',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support tapped')),
                    );
                  },
                ),
                HelperWidget(
                  icon: Icons.person_add_outlined,
                  title: 'Refer a Friend/',
                  subtitle: 'Business',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Refer a Friend tapped')),
                    );
                  },
                ),
                HelperWidget(
                  icon: Icons.star_outline,
                  title: 'Review & Rating',
                  subtitle: 'Manager',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review & Rating tapped')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Example of different color variants
class HelperWidgetVariants extends StatelessWidget {
  const HelperWidgetVariants({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Widget Variants'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Original orange style
            HelperWidget(
              icon: Icons.analytics_outlined,
              title: 'Analytics',
              backgroundColor: const Color(0xFFE8A567),
            ),
            // Blue variant
            HelperWidget(
              icon: Icons.settings_outlined,
              title: 'Settings',
              backgroundColor: const Color(0xFF4A90E2),
            ),
            // Green variant
            HelperWidget(
              icon: Icons.payment_outlined,
              title: 'Payments',
              backgroundColor: const Color(0xFF7ED321),
            ),
            // Purple variant
            HelperWidget(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              backgroundColor: const Color(0xFF9013FE),
            ),
          ],
        ),
      ),
    );
  }
}
