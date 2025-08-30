import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_values.dart';
import '../models/request_models.dart';
import '../models/moderation_models.dart';
import 'chat_moderation_service.dart';
import 'activity_logs_service.dart';
import 'chat_notifications_service.dart';
import 'dispute_handler_service.dart';
import '../constants/Constants.dart';

class ChatService {
  static Map<String, String> get headers {
    final map = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    return map;
  }

  /// Create or get a conversation for a specific request
  static Future<Map<String, dynamic>?> createOrGetConversationForRequest(
    String requestId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${GlobalVariables.chatServiceUrl}api/v1/chat/conversations/create_for_request/',
        ),
        headers: headers,
        body: json.encode({'request_id': requestId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print(
          'Error creating/getting conversation: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error creating/getting conversation: $e');
      return null;
    }
  }

  /// Get conversation by request ID
  static Future<Map<String, dynamic>?> getConversationByRequest(
    String requestId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${GlobalVariables.chatServiceUrl}api/v1/chat/conversations/by_request/?request_id=$requestId',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print(
          'Error getting conversation: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }

  /// Get messages for a conversation
  static Future<List<Map<String, dynamic>>?> getMessages(
    String conversationId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${GlobalVariables.chatServiceUrl}api/v1/chat/conversations/$conversationId/messages/',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print(
          'Error getting messages: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getting messages: $e');
      return null;
    }
  }

  /// Send a message to a conversation with moderation
  static Future<Map<String, dynamic>> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
    String? userId,
  }) async {
    try {
      // Use current user if not specified
      final currentUserId = userId ?? Constants.myDisplayname;
      
      // First, run content through moderation
      final moderationResult = await ChatModerationService.processMessage(
        content: content,
        userId: currentUserId,
        conversationId: conversationId,
      );

      // If user is suspended, block the message
      if (moderationResult['reason'] == 'user_suspended') {
        return {
          'success': false,
          'blocked': true,
          'reason': 'suspended',
          'message': moderationResult['message'],
          'status': moderationResult['status'],
        };
      }

      // If message should be blocked due to severe violations
      if (!moderationResult['allowed']) {
        // Send blocked message notification
        await ChatNotificationService.sendMessageBlockedNotification(
          userId: currentUserId,
          reason: moderationResult['violations']?.join(', ') ?? 'Content violation',
          violationTypes: List<String>.from(moderationResult['violations'] ?? []),
          conversationId: conversationId,
        );

        return {
          'success': false,
          'blocked': true,
          'reason': 'content_violation',
          'message': 'Message blocked due to content violations',
          'violations': moderationResult['violations'],
          'severity': moderationResult['severity'],
        };
      }

      // Use filtered content if available
      final messageContent = moderationResult['filtered_content'] ?? content;
      final wasFiltered = messageContent != content;

      // Send the message to the backend
      final response = await http.post(
        Uri.parse(
          '${GlobalVariables.chatServiceUrl}api/v1/chat/conversations/$conversationId/send_message/',
        ),
        headers: headers,
        body: json.encode({
          'content': messageContent,
          'message_type': messageType,
          'original_content': wasFiltered ? content : null,
          'was_filtered': wasFiltered,
          'moderation_data': wasFiltered ? moderationResult : null,
        }),
      );

      if (response.statusCode == 201) {
        final messageData = json.decode(response.body);
        final messageId = messageData['id']?.toString();

        // Log activities and send notifications if needed
        await _handlePostMessageActions(
          userId: currentUserId,
          conversationId: conversationId,
          messageId: messageId,
          originalContent: content,
          finalContent: messageContent,
          moderationResult: moderationResult,
          wasFiltered: wasFiltered,
        );

        return {
          'success': true,
          'data': messageData,
          'filtered': wasFiltered,
          'violations': moderationResult['violations'] ?? [],
          'strike_issued': moderationResult['strike_issued'] ?? false,
        };
      } else {
        print(
          'Error sending message: ${response.statusCode} - ${response.body}',
        );
        return {
          'success': false,
          'blocked': false,
          'reason': 'server_error',
          'message': 'Failed to send message',
        };
      }
    } catch (e) {
      print('Error sending message: $e');
      return {
        'success': false,
        'blocked': false,
        'reason': 'exception',
        'message': 'An error occurred while sending the message',
      };
    }
  }

  /// Handle post-message actions like logging and notifications
  static Future<void> _handlePostMessageActions({
    required String userId,
    required String conversationId,
    String? messageId,
    required String originalContent,
    required String finalContent,
    required Map<String, dynamic> moderationResult,
    required bool wasFiltered,
  }) async {
    try {
      // Log message sent activity
      if (messageId != null) {
        await ActivityLogsService.logMessageSent(
          userId: userId,
          conversationId: conversationId,
          messageId: messageId,
          content: finalContent,
          wasFiltered: wasFiltered,
          violations: List<String>.from(moderationResult['violations'] ?? []),
        );
      }

      // If content was filtered, log and notify
      if (wasFiltered && messageId != null) {
        await ActivityLogsService.logMessageFiltered(
          userId: userId,
          conversationId: conversationId,
          messageId: messageId,
          violationTypes: List<String>.from(moderationResult['violations'] ?? []),
          detectedItems: List<String>.from(moderationResult['detected_items'] ?? []),
          severity: moderationResult['severity'] ?? 'low',
          originalContent: originalContent,
        );

        // Send content filtered notification
        await ChatNotificationService.sendContentFilteredNotification(
          userId: userId,
          violationTypes: List<String>.from(moderationResult['violations'] ?? []),
          filteredContent: finalContent,
          conversationId: conversationId,
          messageId: messageId,
        );
      }

      // If a strike was issued, handle strike notifications
      if (moderationResult['strike_issued'] == true) {
        await _handleStrikeNotifications(
          userId: userId,
          strikeId: moderationResult['strike_id'],
          conversationId: conversationId,
          messageId: messageId,
          violations: List<String>.from(moderationResult['violations'] ?? []),
        );
      }
    } catch (e) {
      print('Error handling post-message actions: $e');
    }
  }

  /// Handle strike notifications based on user's current strike count
  static Future<void> _handleStrikeNotifications({
    required String userId,
    String? strikeId,
    String? conversationId,
    String? messageId,
    required List<String> violations,
  }) async {
    if (strikeId == null) return;

    try {
      // Get user's current moderation status
      final userStatus = await ChatModerationService.getUserModerationStatus(userId);
      if (userStatus == null) return;

      final strikeCount = userStatus.activeStrikes;
      final reason = violations.join(', ');

      // Send appropriate notification based on strike count
      switch (strikeCount) {
        case 1:
          await ChatNotificationService.sendFirstStrikeNotification(
            userId: userId,
            reason: reason,
            strikeId: strikeId,
            conversationId: conversationId,
            messageId: messageId,
          );
          break;
        case 2:
          await ChatNotificationService.sendSecondStrikeNotification(
            userId: userId,
            reason: reason,
            strikeId: strikeId,
            conversationId: conversationId,
            messageId: messageId,
          );
          break;
        case 3:
          await ChatNotificationService.sendFinalWarningNotification(
            userId: userId,
            reason: reason,
            strikeId: strikeId,
            conversationId: conversationId,
            messageId: messageId,
          );
          break;
        default:
          // If more than 3 strikes, user should be suspended
          if (strikeCount >= 4) {
            await _suspendUser(
              userId: userId,
              reason: 'Exceeded maximum strikes (${strikeCount})',
              relatedStrikeId: strikeId,
            );
          }
          break;
      }

      // Log the strike activity
      await ActivityLogsService.logStrikeIssued(
        userId: userId,
        strikeId: strikeId,
        reason: reason,
        severity: 'medium', // Default severity for strikes
        conversationId: conversationId ?? '',
        messageId: messageId ?? '',
      );
    } catch (e) {
      print('Error handling strike notifications: $e');
    }
  }

  /// Suspend a user after too many strikes
  static Future<void> _suspendUser({
    required String userId,
    required String reason,
    String? relatedStrikeId,
    int durationHours = 24, // Default 24-hour suspension
  }) async {
    try {
      final success = await ChatModerationService.suspendUser(
        userId: userId,
        durationHours: durationHours,
        reason: reason,
        relatedStrikeId: relatedStrikeId,
      );

      if (success) {
        final suspensionEndDate = DateTime.now().add(Duration(hours: durationHours));
        
        // Send suspension notification
        await ChatNotificationService.sendAccountSuspendedNotification(
          userId: userId,
          reason: reason,
          durationHours: durationHours,
          suspensionEndDate: suspensionEndDate,
          relatedStrikeId: relatedStrikeId,
        );

        // Log suspension activity
        await ActivityLogsService.logUserSuspended(
          userId: userId,
          reason: reason,
          durationHours: durationHours,
          relatedStrikeId: relatedStrikeId,
        );
      }
    } catch (e) {
      print('Error suspending user: $e');
    }
  }

  /// Get user's moderation status for chat interface
  static Future<UserModerationStatus?> getUserModerationStatus(String userId) async {
    return await ChatModerationService.getUserModerationStatus(userId);
  }

  /// Get user's unread moderation warnings
  static Future<List<ModerationWarning>?> getUserWarnings(String userId) async {
    return await ChatNotificationService.getUserWarnings(userId, unreadOnly: false);
  }

  /// Get user's unread warnings count
  static Future<int?> getUnreadWarningsCount(String userId) async {
    return await ChatNotificationService.getUnreadWarningsCount(userId);
  }

  /// Mark warning as read
  static Future<bool> markWarningAsRead(String warningId) async {
    return await ChatNotificationService.markWarningAsRead(warningId);
  }

  /// Check if user can send messages (not suspended)
  static Future<bool> canUserSendMessages(String userId) async {
    final status = await getUserModerationStatus(userId);
    return status?.canSendMessages ?? true;
  }

  /// Get user's active strikes
  static Future<List<UserStrike>?> getUserActiveStrikes(String userId) async {
    return await ChatModerationService.getUserStrikes(userId, activeOnly: true);
  }

  /// Test message content for violations without sending
  static Future<ContentFilterResult> testMessageContent(String content) async {
    return ChatModerationService.filterContent(content);
  }

  /// Create a dispute for a moderation action
  static Future<DisputeCase?> createDispute({
    required String userId,
    required String type,
    required String reason,
    required String description,
    String? relatedStrikeId,
    String? relatedActionId,
  }) async {
    return await DisputeHandlerService.createDispute(
      userId: userId,
      type: type,
      reason: reason,
      description: description,
      relatedStrikeId: relatedStrikeId,
      relatedActionId: relatedActionId,
    );
  }

  /// Appeal a strike
  static Future<DisputeCase?> appealStrike({
    required String userId,
    required String strikeId,
    required String reason,
    required String description,
  }) async {
    return await DisputeHandlerService.appealStrike(
      userId: userId,
      strikeId: strikeId,
      reason: reason,
      description: description,
    );
  }

  /// Get user's dispute cases
  static Future<List<DisputeCase>?> getUserDisputes(String userId) async {
    return await DisputeHandlerService.getUserDisputes(userId);
  }

  /// Get all conversations for the current user
  static Future<List<Map<String, dynamic>>?> getConversations() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${GlobalVariables.chatServiceUrl}api/v1/chat/conversations/',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Handle paginated response format
        if (responseData.containsKey('results')) {
          final List<dynamic> data = responseData['results'];
          return data.cast<Map<String, dynamic>>();
        } else {
          // Handle non-paginated response format (list)
          final List<dynamic> data = json.decode(response.body);
          return data.cast<Map<String, dynamic>>();
        }
      } else {
        print(
          'Error getting conversations: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error getting conversations: $e');
      return null;
    }
  }
}

class ChatMessage {
  final String? id;
  final String content;
  final String senderName;
  final String senderRole;
  final DateTime timestamp;
  final String messageType;
  final bool isFromCurrentUser;

  ChatMessage({
    this.id,
    required this.content,
    required this.senderName,
    required this.senderRole,
    required this.timestamp,
    this.messageType = 'text',
    this.isFromCurrentUser = false,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json,
    String currentUserName,
  ) {
    final sender = json['sender'];
    final senderName = sender != null
        ? sender['username'] ?? 'Anonymous'
        : 'Anonymous';

    return ChatMessage(
      id: json['id']?.toString(),
      content: json['content'],
      senderName: senderName,
      senderRole:
          json['sender_role'] ??
          'User', // You might need to adjust this based on your API
      timestamp: DateTime.parse(json['created_at']),
      messageType: json['message_type'] ?? 'text',
      isFromCurrentUser: senderName == currentUserName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_name': senderName,
      'sender_role': senderRole,
      'timestamp': timestamp.toIso8601String(),
      'message_type': messageType,
      'is_from_current_user': isFromCurrentUser,
    };
  }
}

class ChatConversation {
  final String id;
  final String title;
  final String requestId;
  final String conversationType;
  final String status;
  final DateTime lastMessageAt;
  final int totalMessages;
  final int participantCount;
  final int unreadCount;

  ChatConversation({
    required this.id,
    required this.title,
    required this.requestId,
    required this.conversationType,
    required this.status,
    required this.lastMessageAt,
    required this.totalMessages,
    required this.participantCount,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'].toString(),
      title: json['title'],
      requestId: json['request_id'] ?? '',
      conversationType: json['conversation_type'],
      status: json['status'],
      lastMessageAt: DateTime.parse(
        json['last_message_at'] ?? DateTime.now().toIso8601String(),
      ),
      totalMessages: json['total_messages'] ?? 0,
      participantCount: json['participant_count'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}
