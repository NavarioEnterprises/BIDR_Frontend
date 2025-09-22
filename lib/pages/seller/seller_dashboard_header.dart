import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bidr/constants/Constants.dart';
import 'package:bidr/models/alert.dart';
import 'package:bidr/services/notification_api_service.dart';
import 'package:badges/badges.dart' as badges;
import 'package:hugeicons/hugeicons.dart';
import '../../customWdget/dropdownMenu.dart';

class SellerDashboardHeader extends StatefulWidget {
  final String headerName;
  final SortOption? initialSort;
  final Function(SortOption?)? onSortChanged;
  final int tabActiveIndex;

  const SellerDashboardHeader({
    super.key,
    required this.headerName,
    this.initialSort,
    this.onSortChanged,
    this.tabActiveIndex = 0,
  });

  @override
  State<SellerDashboardHeader> createState() => _SellerDashboardHeaderState();
}

List<WebNotification> notifications = [];

class _SellerDashboardHeaderState extends State<SellerDashboardHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;
  bool _isOverlayShown = false;
  bool _isLoadingNotifications = false;
  int _unreadCount = 0;
  bool _isHoveringText = false;
  bool _isHoveringIcon = false;
  final NotificationApiService _notificationApiService =
      NotificationApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (!mounted) return;

    try {
      // Simple initial load without complex refresh logic
      final userUuid = Constants.currentUser?.uid ?? Constants.myUid;
      if (kDebugMode) {
        print('Initializing notifications for seller UUID: $userUuid');
      }

      if (userUuid.isNotEmpty) {
        setState(() {
          _isLoadingNotifications = true;
        });

        // Load notifications first
        final fetchedNotifications = await _notificationApiService
            .getUserNotifications(userUuid)
            .timeout(const Duration(seconds: 10));

        if (mounted) {
          setState(() {
            notifications = fetchedNotifications;
            // Calculate unread count from loaded notifications
            _unreadCount = fetchedNotifications.where((n) => !n.read).length;
            _isLoadingNotifications = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing notifications: $e');
      }
      if (mounted) {
        setState(() {
          notifications = [];
          _unreadCount = 0;
          _isLoadingNotifications = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationsFromApi() async {
    if (!mounted) return;

    try {
      // Use the user's UUID from Constants
      final userUuid = Constants.currentUser?.uid ?? Constants.myUid;
      if (kDebugMode) {
        print('Loading notifications for seller UUID: $userUuid');
      }

      if (userUuid.isNotEmpty) {
        final fetchedNotifications = await _notificationApiService
            .getUserNotifications(userUuid);

        if (mounted) {
          setState(() {
            notifications = fetchedNotifications;
          });
        }
      } else {
        if (kDebugMode) {
          print('No user UUID found');
        }
        if (mounted) {
          setState(() {
            notifications = [];
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notifications from API: $e');
      }
      // On error, just set empty notifications
      if (mounted) {
        setState(() {
          notifications = [];
        });
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    if (!mounted) return;

    try {
      final userUuid = Constants.currentUser?.uid ?? Constants.myUid;
      if (kDebugMode) {
        print('Loading unread count for seller UUID: $userUuid');
      }

      if (userUuid.isNotEmpty) {
        final unreadCount = await _notificationApiService
            .getUnreadNotificationCount(userUuid);

        if (mounted) {
          setState(() {
            _unreadCount = unreadCount;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading unread notification count: $e');
      }
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
    }
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Add timeout to prevent infinite loading
      await Future.wait([
        _loadNotificationsFromApi(),
        _loadUnreadCount(),
      ]).timeout(const Duration(seconds: 15));
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing notifications: $e');
      }
      // Set empty state on error
      if (mounted) {
        setState(() {
          notifications = [];
          _unreadCount = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      final success = await _notificationApiService.markAsRead(notificationId);
      if (success && mounted) {
        // Update local notification state immediately
        setState(() {
          final index = notifications.indexWhere((n) => n.id == notificationId);
          if (index != -1) {
            notifications[index].read = true;
          }
          // Recalculate unread count from notifications
          _unreadCount = notifications.where((n) => !n.read).length;
        });
        if (kDebugMode) {
          print('Notification marked as read: $notificationId');
        }
      } else {
        if (kDebugMode) {
          print('Failed to mark notification as read: $notificationId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error marking notification as read: $e');
      }
    }
  }

  void _showNotificationOverlay() {
    if (_isOverlayShown) {
      _removeOverlay();
      return;
    }

    // Only refresh if we have no notifications or it's been a while
    if (notifications.isEmpty && !_isLoadingNotifications) {
      _initializeNotifications();
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent barrier to catch taps outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // The actual notification overlay
          Positioned(
            top: offset.dy + buttonSize.height + 5,
            right: 68, // Match the padding of the header
            child: Material(
              color: Colors.transparent,
              child: ScaleTransition(
                scale: _scaleAnimation,
                alignment: Alignment.topRight,
                child: Container(
                  width: 310,
                  constraints: BoxConstraints(maxWidth: 310, maxHeight: 6500),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'NOTIFICATIONS',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: _removeOverlay,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildNotificationStats(),
                            const SizedBox(height: 20),
                            _buildRecentNotifications(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: _unreadCount > 0
                                      ? () async {
                                          // Mark all as read
                                          final userUuid =
                                              Constants.currentUser?.uid ??
                                              Constants.myUid;
                                          if (userUuid.isNotEmpty) {
                                            final success =
                                                await _notificationApiService
                                                    .markAllAsRead(userUuid);
                                            if (success && mounted) {
                                              setState(() {
                                                // Mark all notifications as read locally
                                                for (var notification
                                                    in notifications) {
                                                  notification.read = true;
                                                }
                                                _unreadCount = 0;
                                              });
                                            }
                                          }
                                        }
                                      : null,
                                  child: Text(
                                    'Mark All Read',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _unreadCount > 0
                                          ? Constants.ctaColorLight
                                          : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _showFilteredNotifications('all'),
                                  child: Text(
                                    'View All',
                                    style: TextStyle(
                                      color: Constants.ctaColorLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    _isOverlayShown = true;
    _animationController.forward();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _animationController.reverse().then((_) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        _isOverlayShown = false;
      });
    }
  }

  Widget _buildNotificationStats() {
    // Calculate stats from actual notifications
    final totalNotifications = notifications.length;
    final readNotifications = notifications.where((n) => n.read).length;
    final unreadNotifications = notifications.where((n) => !n.read).length;

    return Column(
      children: [
        _buildStatItem(
          'Total Notifications',
          totalNotifications.toString(),
          onTap: () => _showFilteredNotifications('all'),
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          'Read Notifications',
          readNotifications.toString(),
          onTap: () => _showFilteredNotifications('read'),
        ),
        const SizedBox(height: 8),
        _buildStatItem(
          'Unread Notifications',
          unreadNotifications.toString(),
          onTap: () => _showFilteredNotifications('unread'),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Constants.ctaColorLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilteredNotifications(String filter) {
    _removeOverlay();

    List<WebNotification> filteredNotifications;
    String title;

    switch (filter) {
      case 'all':
        filteredNotifications = notifications;
        title = 'All Notifications';
        break;
      case 'read':
        filteredNotifications = notifications.where((n) => n.read).toList();
        title = 'Read Notifications';
        break;
      case 'unread':
        filteredNotifications = notifications.where((n) => !n.read).toList();
        title = 'Unread Notifications';
        break;
      default:
        filteredNotifications = notifications;
        title = 'All Notifications';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: filteredNotifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No notifications to show',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredNotifications.length,
                          itemBuilder: (context, index) {
                            return _buildNotificationItem(
                              filteredNotifications[index],
                              isCompact: false,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSingleNotification(WebNotification notification) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade600),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Content
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: notification.read
                              ? Colors.grey.shade100
                              : Constants.ctaColorLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: notification.read
                                ? Colors.grey.shade300
                                : Constants.ctaColorLight.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          notification.read ? 'Read' : 'Unread',
                          style: TextStyle(
                            color: notification.read
                                ? Colors.grey.shade600
                                : Constants.ctaColorLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Message content
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Timestamp
                      Text(
                        _formatTimestamp(notification.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mark as read/unread button
                      if (!notification.read)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _markNotificationAsRead(notification.id);
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Constants.ctaColorLight,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Mark as Read',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildRecentNotifications() {
    if (_isLoadingNotifications) {
      return Container(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Constants.ctaColorLight,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading notifications...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Container(
        height: 80,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, color: Colors.grey[400], size: 24),
              const SizedBox(height: 4),
              Text(
                'No notifications yet',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final recentNotifications = notifications.take(4).toList();
    final groupedNotifications = <String, List<WebNotification>>{};

    for (var notification in recentNotifications) {
      final dayKey = _getDayKey(notification.createdAt);
      groupedNotifications[dayKey] ??= [];
      groupedNotifications[dayKey]!.add(notification);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupedNotifications.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...entry.value.map(
              (notification) =>
                  _buildNotificationItem(notification, isCompact: true),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _getDayKey(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference == 2) return 'Monday';
    return '${difference} days ago';
  }

  Widget _buildNotificationItem(
    WebNotification notification, {
    bool isCompact = false,
  }) {
    return InkWell(
      onTap: () {
        // Close the overlay first
        _removeOverlay();

        // Show single notification dialog
        _showSingleNotification(notification);

        // Mark as read if it's unread
        if (!notification.read) {
          _markNotificationAsRead(notification.id);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: notification.read
              ? Colors.transparent
              : Constants.ctaColorLight.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: notification.read
              ? null
              : Border.all(
                  color: Constants.ctaColorLight.withOpacity(0.2),
                  width: 1,
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Constants.ctaColorLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: Constants.ctaColorLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.read
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Constants.ctaColorLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isCompact) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'accept':
        return Icons.check_circle_outline;
      case 'update':
        return Icons.update;
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment_successful':
        return Icons.payment;
      case 'payment_received':
        return Icons.account_balance_wallet;
      case 'refund_requested':
        return Icons.refresh;
      case 'new_quote':
        return Icons.request_quote;
      case 'quote_accepted':
        return Icons.thumb_up;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showNotificationOverlay,
      child: Container(
        height: 60,
        width: MediaQuery.of(context).size.width,
        color: Constants.ftaColorLight,
        padding: EdgeInsets.only(left: 68, right: 68, top: 8, bottom: 8),
        child: Row(
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _isHoveringText = true),
              onExit: (_) => setState(() => _isHoveringText = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedDefaultTextStyle(
                duration: Duration(milliseconds: 200),
                style: TextStyle(
                  color: _isHoveringText 
                    ? Colors.white.withOpacity(0.8) 
                    : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: _isHoveringText ? TextDecoration.underline : TextDecoration.none,
                  decorationColor: Colors.white.withOpacity(0.8),
                  decorationThickness: 2,
                  shadows: _isHoveringText ? [
                    Shadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ] : [],
                ),
                child: Text(widget.headerName),
              ),
            ),
            Spacer(),
            MouseRegion(
              onEnter: (_) => setState(() => _isHoveringIcon = true),
              onExit: (_) => setState(() => _isHoveringIcon = false),
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                transform: Matrix4.identity()
                  ..scale(_isHoveringIcon ? 1.1 : 1.0),
                child: badges.Badge(
                  position: badges.BadgePosition.topEnd(top: -6, end: -6),
                  showBadge: _unreadCount > 0,
                  ignorePointer: true,
                  badgeContent: Text(
                    _unreadCount.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Constants.ftaColorLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  badgeAnimation: badges.BadgeAnimation.rotation(
                    animationDuration: const Duration(seconds: 1),
                    colorChangeAnimationDuration: const Duration(seconds: 1),
                    loopAnimation: false,
                    curve: Curves.fastOutSlowIn,
                    colorChangeAnimationCurve: Curves.easeInCubic,
                  ),
                  badgeStyle: badges.BadgeStyle(
                    shape: badges.BadgeShape.circle,
                    badgeColor: Colors.white,
                    padding: const EdgeInsets.all(5),
                    borderRadius: BorderRadius.circular(10),
                    elevation: 3,
                  ),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isHoveringIcon 
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white.withOpacity(0.2),
                      boxShadow: _isHoveringIcon ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 3,
                        )
                      ] : [],
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedNotification01,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.tabActiveIndex == 0 && widget.onSortChanged != null) ...[
              SizedBox(width: 15),
              SellerSortDropdownMenu(
                initialValue: widget.initialSort,
                onSortChanged: widget.onSortChanged!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
