import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../constants/Constants.dart';
import '../../../models/alert.dart';
import '../../../services/notification_api_service.dart';



// Full Notification Page
class NotificationMobile extends StatefulWidget {
  final List<WebNotification> notifications;

  const NotificationMobile({Key? key, required this.notifications})
      : super(key: key);

  @override
  State<NotificationMobile> createState() => _NotificationMobileState();
}

class _NotificationMobileState extends State<NotificationMobile>
    with SingleTickerProviderStateMixin {
  late List<WebNotification> notifications;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String selectedTab = 'Unread';
  bool isLoading = true;
  final NotificationApiService _notificationApiService =
  NotificationApiService();

  @override
  void initState() {
    super.initState();
    notifications = [];
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userUuid = Constants.currentUser!.uid!;
      if (userUuid.isNotEmpty) {
        final fetchedNotifications = await _notificationApiService
            .getUserNotifications(userUuid);
        if (mounted) {
          setState(() {
            notifications = fetchedNotifications;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            notifications = List.from(widget.notifications);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          notifications = List.from(widget.notifications);
          isLoading = false;
        });
      }
    }
  }

  void _markAsRead(String id) async {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final notification = notifications[index];
        notifications[index] = WebNotification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          description: notification.description,
          type: notification.type,
          read: true,
          createdAt: notification.createdAt,
        );
      }
    });

    try {
      await _notificationApiService.markAsRead(id);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _deleteNotification(String id) async {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
    });

    try {
      await _notificationApiService.deleteNotification(id);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Constants.ctaColorLight,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading notifications...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final unreadNotifications = notifications.where((n) => !n.read).toList();
    final readNotifications = notifications.where((n) => n.read).toList();

    if (notifications.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Constants.ctaColorLight,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You\'ll see your notifications here when they arrive.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.ctaColorLight,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'Go to Dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            toolbarHeight: 56,
            title: const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 22),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Constants.ctaColorLight, size: 22),
                onPressed: () async {
                  await _loadNotifications();
                },
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    for (var i = 0; i < notifications.length; i++) {
                      final n = notifications[i];
                      notifications[i] = WebNotification(
                        id: n.id,
                        title: n.title,
                        body: n.body,
                        description: n.description,
                        type: n.type,
                        read: true,
                        createdAt: n.createdAt,
                      );
                    }
                  });

                  try {
                    final userUuid = Constants.myUid;
                    if (userUuid.isNotEmpty) {
                      await _notificationApiService.markAllAsRead(userUuid);
                    }
                  } catch (e) {
                    print('Error marking all notifications as read: $e');
                  }
                },
                child: Text(
                  'Mark all read',
                  style: TextStyle(
                    color: Constants.ctaColorLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTabButton('Unread', unreadNotifications.length),
                const SizedBox(width: 12),
                _buildTabButton('Read', readNotifications.length),
              ],
            ),
          ),
          Expanded(
            child: _buildNotificationList(
              selectedTab == 'Unread'
                  ? unreadNotifications
                  : readNotifications,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<WebNotification> notificationList) {
    if (notificationList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selectedTab == 'Unread'
                    ? Icons.mark_email_read_outlined
                    : Icons.drafts_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                selectedTab == 'Unread'
                    ? 'No unread notifications'
                    : 'No read notifications',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectedTab == 'Unread'
                    ? 'All caught up! You have no new notifications.'
                    : 'Your read notifications will appear here.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: notificationList
          .map((notification) => _buildNotificationCard(notification))
          .toList(),
    );
  }

  Widget _buildTabButton(String title, int count) {
    final bool isSelected = selectedTab == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Constants.ctaColorLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Constants.ctaColorLight : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Constants.ctaColorLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Constants.ctaColorLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(WebNotification notification) {
    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 22),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                setState(() {
                  notifications.add(notification);
                });
              },
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (!notification.read) {
            _markAsRead(notification.id.toString());
          }
          _showNotificationDetails(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: notification.read
                  ? Colors.grey[200]!
                  : Constants.ctaColorLight.withOpacity(0.3),
              width: notification.read ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
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
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: Colors.grey[900],
                            ),
                          ),
                        ),
                        if (!notification.read)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Constants.ctaColorLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(WebNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Constants.ctaColorLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(notification.type),
                    color: Constants.ctaColorLight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              notification.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.ctaColorLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'accept':
        return HugeIcons.strokeRoundedTick02;
      case 'update':
        return HugeIcons.strokeRoundedTimeManagementCircle;
      case 'order':
        return HugeIcons.strokeRoundedGroupItems;
      default:
        return HugeIcons.strokeRoundedNotification01;
    }
  }
}
