import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_values.dart';
import '../models/moderation_models.dart';

/// Service for sending chat-related notifications including moderation warnings and alerts
class ChatNotificationService {
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Send a moderation warning notification
  static Future<ModerationWarning?> sendModerationWarning({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/warnings/'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'title': title,
          'message': message,
          'type': type,
          'data': data,
        }),
      );

      if (response.statusCode == 201) {
        return ModerationWarning.fromJson(json.decode(response.body));
      } else {
        print('Error sending moderation warning: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error sending moderation warning: $e');
      return null;
    }
  }

  /// Send content filtered notification
  static Future<ModerationWarning?> sendContentFilteredNotification({
    required String userId,
    required List<String> violationTypes,
    required String filteredContent,
    String? conversationId,
    String? messageId,
  }) async {
    final title = "Message Content Filtered";
    final message = "Your message contained inappropriate content and was filtered. "
        "Violations detected: ${violationTypes.join(', ')}. "
        "Please ensure your messages follow our community guidelines.";
    
    final data = {
      'violation_types': violationTypes,
      'filtered_content': filteredContent,
      'conversation_id': conversationId,
      'message_id': messageId,
      'action_required': false,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'content_filtered',
      data: data,
    );
  }

  /// Send first strike notification
  static Future<ModerationWarning?> sendFirstStrikeNotification({
    required String userId,
    required String reason,
    required String strikeId,
    String? conversationId,
    String? messageId,
  }) async {
    final title = "⚠️ First Strike - Warning Issued";
    final message = "You have received your first strike for: $reason. "
        "This is a warning to ensure you follow our community guidelines. "
        "Two more violations may result in account suspension.";
    
    final data = {
      'strike_id': strikeId,
      'reason': reason,
      'strike_count': 1,
      'conversation_id': conversationId,
      'message_id': messageId,
      'action_required': false,
      'can_appeal': true,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'first_strike',
      data: data,
    );
  }

  /// Send second strike notification
  static Future<ModerationWarning?> sendSecondStrikeNotification({
    required String userId,
    required String reason,
    required String strikeId,
    String? conversationId,
    String? messageId,
  }) async {
    final title = "🚨 Second Strike - Final Warning";
    final message = "You have received your second strike for: $reason. "
        "This is your final warning. One more violation will result in "
        "account suspension and loss of chat privileges.";
    
    final data = {
      'strike_id': strikeId,
      'reason': reason,
      'strike_count': 2,
      'conversation_id': conversationId,
      'message_id': messageId,
      'action_required': true,
      'can_appeal': true,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'second_strike',
      data: data,
    );
  }

  /// Send final warning notification (third strike)
  static Future<ModerationWarning?> sendFinalWarningNotification({
    required String userId,
    required String reason,
    required String strikeId,
    String? conversationId,
    String? messageId,
  }) async {
    final title = "🔴 Final Warning - Account at Risk";
    final message = "You have received your third strike for: $reason. "
        "Your account is now at maximum risk. Any further violations "
        "will result in immediate suspension.";
    
    final data = {
      'strike_id': strikeId,
      'reason': reason,
      'strike_count': 3,
      'conversation_id': conversationId,
      'message_id': messageId,
      'action_required': true,
      'can_appeal': true,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'final_warning',
      data: data,
    );
  }

  /// Send account suspended notification
  static Future<ModerationWarning?> sendAccountSuspendedNotification({
    required String userId,
    required String reason,
    required int durationHours,
    required DateTime suspensionEndDate,
    String? relatedStrikeId,
  }) async {
    final title = "🚫 Account Suspended";
    final endDateStr = _formatSuspensionEndDate(suspensionEndDate);
    final message = "Your account has been suspended for $durationHours hours "
        "due to: $reason. Suspension will be lifted on $endDateStr. "
        "You cannot send messages until then.";
    
    final data = {
      'reason': reason,
      'duration_hours': durationHours,
      'suspension_end_date': suspensionEndDate.toIso8601String(),
      'related_strike_id': relatedStrikeId,
      'action_required': false,
      'can_appeal': true,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'suspended',
      data: data,
    );
  }

  /// Send suspension lifted notification
  static Future<ModerationWarning?> sendSuspensionLiftedNotification({
    required String userId,
    required String reason,
  }) async {
    final title = "✅ Account Suspension Lifted";
    final message = "Good news! Your account suspension has been lifted. "
        "Reason: $reason. You can now send messages again. "
        "Please ensure you follow our community guidelines.";
    
    final data = {
      'reason': reason,
      'lifted_at': DateTime.now().toIso8601String(),
      'action_required': false,
      'can_appeal': false,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'suspension_lifted',
      data: data,
    );
  }

  /// Send dispute status update notification
  static Future<ModerationWarning?> sendDisputeStatusNotification({
    required String userId,
    required String disputeId,
    required String status,
    required String disputeType,
    String? resolution,
  }) async {
    String title;
    String message;
    
    switch (status) {
      case 'under_review':
        title = "📋 Dispute Under Review";
        message = "Your $disputeType is now under review. "
            "We'll notify you once a decision has been made.";
        break;
      case 'resolved':
        title = "✅ Dispute Resolved - Appeal Approved";
        message = "Great news! Your $disputeType has been approved. "
            "${resolution ?? 'The moderation action has been reversed.'} "
            "Thank you for bringing this to our attention.";
        break;
      case 'rejected':
        title = "❌ Dispute Rejected - Appeal Denied";
        message = "After review, your $disputeType has been denied. "
            "Reason: ${resolution ?? 'The original moderation action stands.'} "
            "The original moderation action remains in effect.";
        break;
      default:
        title = "📄 Dispute Status Update";
        message = "Your dispute status has been updated to: $status";
    }
    
    final data = {
      'dispute_id': disputeId,
      'dispute_type': disputeType,
      'status': status,
      'resolution': resolution,
      'action_required': false,
      'can_appeal': false,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'dispute_update',
      data: data,
    );
  }

  /// Send message blocked notification
  static Future<ModerationWarning?> sendMessageBlockedNotification({
    required String userId,
    required String reason,
    required List<String> violationTypes,
    String? conversationId,
  }) async {
    final title = "🚫 Message Blocked";
    final message = "Your message was blocked and not sent due to: $reason. "
        "Violations: ${violationTypes.join(', ')}. "
        "Please revise your message to comply with our guidelines.";
    
    final data = {
      'reason': reason,
      'violation_types': violationTypes,
      'conversation_id': conversationId,
      'action_required': true,
      'can_appeal': false,
    };

    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: 'message_blocked',
      data: data,
    );
  }

  /// Get user's moderation warnings
  static Future<List<ModerationWarning>?> getUserWarnings(
    String userId, {
    bool unreadOnly = false,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (unreadOnly) params['unread_only'] = 'true';
      if (type != null) params['type'] = type;

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/warnings/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? responseData;
        return data.map((json) => ModerationWarning.fromJson(json)).toList();
      } else {
        print('Error getting user warnings: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user warnings: $e');
      return null;
    }
  }

  /// Mark warning as read
  static Future<bool> markWarningAsRead(String warningId) async {
    try {
      final response = await http.patch(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/warnings/$warningId/'),
        headers: headers,
        body: json.encode({'is_read': true}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking warning as read: $e');
      return false;
    }
  }

  /// Mark multiple warnings as read
  static Future<bool> markWarningsAsRead(List<String> warningIds) async {
    try {
      final response = await http.patch(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/warnings/bulk-read/'),
        headers: headers,
        body: json.encode({'warning_ids': warningIds}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking warnings as read: $e');
      return false;
    }
  }

  /// Get unread warnings count
  static Future<int?> getUnreadWarningsCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/warnings/unread-count/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        print('Error getting unread warnings count: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting unread warnings count: $e');
      return null;
    }
  }

  /// Send custom notification
  static Future<ModerationWarning?> sendCustomNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    return await sendModerationWarning(
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
    );
  }

  /// Send bulk notifications to multiple users
  static Future<bool> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/warnings/bulk/'),
        headers: headers,
        body: json.encode({
          'user_ids': userIds,
          'title': title,
          'message': message,
          'type': type,
          'data': data,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error sending bulk notifications: $e');
      return false;
    }
  }

  /// Delete a warning (admin only)
  static Future<bool> deleteWarning(String warningId) async {
    try {
      final response = await http.delete(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/warnings/$warningId/'),
        headers: headers,
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Error deleting warning: $e');
      return false;
    }
  }

  /// Get warning by ID
  static Future<ModerationWarning?> getWarning(String warningId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/warnings/$warningId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return ModerationWarning.fromJson(json.decode(response.body));
      } else {
        print('Error getting warning: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting warning: $e');
      return null;
    }
  }

  /// Helper method to format suspension end date
  static String _formatSuspensionEndDate(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.inDays > 0) {
      return "${_formatDateTime(endDate)} (${difference.inDays} days from now)";
    } else if (difference.inHours > 0) {
      return "${_formatDateTime(endDate)} (${difference.inHours} hours from now)";
    } else if (difference.inMinutes > 0) {
      return "${_formatDateTime(endDate)} (${difference.inMinutes} minutes from now)";
    } else {
      return _formatDateTime(endDate);
    }
  }

  /// Helper method to format date time
  static String _formatDateTime(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} "
           "${dateTime.hour.toString().padLeft(2, '0')}:"
           "${dateTime.minute.toString().padLeft(2, '0')}";
  }

  /// Send real-time notification via WebSocket/Push (if implemented)
  static Future<bool> sendRealTimeNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/notifications/realtime/'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'title': title,
          'message': message,
          'type': type,
          'data': data,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending real-time notification: $e');
      return false;
    }
  }

  /// Send email notification (if email service is configured)
  static Future<bool> sendEmailNotification({
    required String userId,
    required String subject,
    required String message,
    String? template,
    Map<String, dynamic>? templateData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/notifications/email/'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'subject': subject,
          'message': message,
          'template': template,
          'template_data': templateData,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending email notification: $e');
      return false;
    }
  }

  /// Get notification preferences for user
  static Future<Map<String, dynamic>?> getNotificationPreferences(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/notification-preferences/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting notification preferences: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting notification preferences: $e');
      return null;
    }
  }

  /// Update notification preferences for user
  static Future<bool> updateNotificationPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/notification-preferences/'),
        headers: headers,
        body: json.encode(preferences),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating notification preferences: $e');
      return false;
    }
  }
}
