import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_values.dart';
import '../models/alert.dart';

class NotificationApiService {
  static const String apiPath = 'api/v1/notifications';

  // Fetch all notifications for a user
  Future<List<WebNotification>> getUserNotifications(String userId) async {
    try {
      print('=== NOTIFICATION API REQUEST START ===');
      print('Fetching notifications for user: $userId');
      print('Base URL: ${GlobalVariables.notificationsServiceUrl}');
      print('Full URL: ${GlobalVariables.notificationsServiceUrl}$apiPath/user/$userId/');
      
      final url = Uri.parse(
        '${GlobalVariables.notificationsServiceUrl}$apiPath/user/$userId/',
      );
      
      print('Parsed URL: $url');
      print('Making HTTP GET request...');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Response received - Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<WebNotification> notifications = [];

        if (data is Map && data.containsKey('notifications')) {
          print('Processing ${data['notifications'].length} notifications from API');
          for (var notification in data['notifications']) {
            notifications.add(_mapToWebNotification(notification));
          }
        } else if (data is List) {
          print('Processing ${data.length} notifications from API (list format)');
          for (var notification in data) {
            notifications.add(_mapToWebNotification(notification));
          }
        } else {
          print('Unexpected response format: ${data.runtimeType}');
        }

        print('Successfully parsed ${notifications.length} notifications');
        print('=== NOTIFICATION API REQUEST END ===');
        return notifications;
      } else {
        print('HTTP error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception in getUserNotifications: $e');
      print('Exception type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      print('=== NOTIFICATION API REQUEST FAILED ===');
      return [];
    }
  }

  // Fetch unread notifications for a user
  Future<List<WebNotification>> getUnreadNotifications(String userId) async {
    try {
      final url = Uri.parse(
        '${GlobalVariables.notificationsServiceUrl}$apiPath/user/$userId/unread/',
      );
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<WebNotification> notifications = [];

        if (data is Map && data.containsKey('results')) {
          // Handle paginated response
          for (var notification in data['results']) {
            notifications.add(_mapToWebNotification(notification));
          }
        } else if (data is List) {
          // Handle array response
          for (var notification in data) {
            notifications.add(_mapToWebNotification(notification));
          }
        }

        return notifications;
      } else {
        print('Failed to fetch unread notifications: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final url = Uri.parse(
        '${GlobalVariables.notificationsServiceUrl}$apiPath/mark-read/$notificationId/',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      // First get all unread notifications
      final unreadNotifications = await getUnreadNotifications(userId);

      // Mark each notification as read
      bool allSuccess = true;
      for (var notification in unreadNotifications) {
        final success = await markAsRead(notification.id.toString());
        if (!success) {
          allSuccess = false;
        }
      }

      return allSuccess;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final url = Uri.parse(
        '${GlobalVariables.notificationsServiceUrl}$apiPath/notifications/$notificationId/',
      );
      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // Map backend notification to WebNotification model
  WebNotification _mapToWebNotification(Map<String, dynamic> data) {
    return WebNotification(
      id: data['id']?.toString() ?? '0',
      title: data['subject'] ?? '',
      body: data['message'] ?? '',
      description: data['html_content'] ?? data['message'] ?? '',
      type: _mapNotificationType(data['notification_type'] ?? ''),
      read: data['is_read'] ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  // Map backend notification types to frontend types
  String _mapNotificationType(String backendType) {
    switch (backendType) {
      case 'payment_success':
      case 'payment_failed':
      case 'payment_pending':
      case 'refund_processed':
      case 'escrow_released':
        return 'order';

      case 'review_received':
      case 'review_response':
      case 'review_flagged':
      case 'return_approved':
      case 'dispute_resolved':
      case 'resolution_offer':
        return 'accept';

      case 'return_request_received':
      case 'dispute_created':
      case 'return_shipped':
      case 'return_completed':
      case 'system_maintenance':
      case 'policy_update':
      case 'account_update':
        return 'update';

      default:
        return 'update';
    }
  }
}
