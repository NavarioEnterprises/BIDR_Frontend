import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_values.dart';
import '../models/request_models.dart';

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

  /// Send a message to a conversation
  static Future<Map<String, dynamic>?> sendMessage(
    String conversationId,
    String content, {
    String messageType = 'text',
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${GlobalVariables.chatServiceUrl}api/v1/chat/conversations/$conversationId/send_message/',
        ),
        headers: headers,
        body: json.encode({'content': content, 'message_type': messageType}),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print(
          'Error sending message: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
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
