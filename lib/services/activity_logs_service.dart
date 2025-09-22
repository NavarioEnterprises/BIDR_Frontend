import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_values.dart';
import '../models/moderation_models.dart';

/// Service for logging and tracking all chat and moderation activities
class ActivityLogsService {
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Log an activity
  static Future<ActivityLog?> logActivity({
    required String userId,
    required String action,
    required String details,
    String? conversationId,
    String? messageId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/activity-logs/'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'action': action,
          'details': details,
          'conversation_id': conversationId,
          'message_id': messageId,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 201) {
        return ActivityLog.fromJson(json.decode(response.body));
      } else {
        print('Error logging activity: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error logging activity: $e');
      return null;
    }
  }

  /// Log message sent activity
  static Future<void> logMessageSent({
    required String userId,
    required String conversationId,
    required String messageId,
    required String content,
    bool wasFiltered = false,
    List<String>? violations,
  }) async {
    final metadata = {
      'content_length': content.length,
      'was_filtered': wasFiltered,
      if (violations != null) 'violations': violations,
    };

    await logActivity(
      userId: userId,
      action: 'message_sent',
      details: wasFiltered ? 'Message sent with content filtering applied' : 'Message sent successfully',
      conversationId: conversationId,
      messageId: messageId,
      metadata: metadata,
    );
  }

  /// Log message filtered activity
  static Future<void> logMessageFiltered({
    required String userId,
    required String conversationId,
    required String messageId,
    required List<String> violationTypes,
    required List<String> detectedItems,
    required String severity,
    required String originalContent,
  }) async {
    final metadata = {
      'violation_types': violationTypes,
      'detected_items': detectedItems,
      'severity': severity,
      'original_length': originalContent.length,
    };

    await logActivity(
      userId: userId,
      action: 'message_filtered',
      details: 'Message content filtered for violations: ${violationTypes.join(', ')}',
      conversationId: conversationId,
      messageId: messageId,
      metadata: metadata,
    );
  }

  /// Log strike issued activity
  static Future<void> logStrikeIssued({
    required String userId,
    required String strikeId,
    required String reason,
    required String severity,
    required String conversationId,
    required String messageId,
  }) async {
    final metadata = {
      'strike_id': strikeId,
      'severity': severity,
      'reason': reason,
    };

    await logActivity(
      userId: userId,
      action: 'strike_received',
      details: 'Strike issued for: $reason (Severity: $severity)',
      conversationId: conversationId,
      messageId: messageId,
      metadata: metadata,
    );
  }

  /// Log warning issued activity
  static Future<void> logWarningIssued({
    required String userId,
    required String warningType,
    required String message,
    String? conversationId,
    String? messageId,
    Map<String, dynamic>? additionalData,
  }) async {
    final metadata = {
      'warning_type': warningType,
      'message': message,
      ...?additionalData,
    };

    await logActivity(
      userId: userId,
      action: 'warning_issued',
      details: 'Warning issued: $warningType',
      conversationId: conversationId,
      messageId: messageId,
      metadata: metadata,
    );
  }

  /// Log user suspension activity
  static Future<void> logUserSuspended({
    required String userId,
    required String reason,
    required int durationHours,
    String? relatedStrikeId,
  }) async {
    final metadata = {
      'reason': reason,
      'duration_hours': durationHours,
      'suspension_end': DateTime.now().add(Duration(hours: durationHours)).toIso8601String(),
      if (relatedStrikeId != null) 'related_strike_id': relatedStrikeId,
    };

    await logActivity(
      userId: userId,
      action: 'suspended',
      details: 'Account suspended for $durationHours hours. Reason: $reason',
      metadata: metadata,
    );
  }

  /// Log dispute created activity
  static Future<void> logDisputeCreated({
    required String userId,
    required String disputeId,
    required String disputeType,
    required String reason,
  }) async {
    final metadata = {
      'dispute_id': disputeId,
      'dispute_type': disputeType,
      'reason': reason,
    };

    await logActivity(
      userId: userId,
      action: 'dispute_created',
      details: 'Dispute created: $disputeType - $reason',
      metadata: metadata,
    );
  }

  /// Log dispute resolved activity
  static Future<void> logDisputeResolved({
    required String userId,
    required String disputeId,
    required String resolution,
    required String status,
    String? resolverId,
  }) async {
    final metadata = {
      'dispute_id': disputeId,
      'resolution': resolution,
      'status': status,
      if (resolverId != null) 'resolver_id': resolverId,
    };

    await logActivity(
      userId: userId,
      action: 'dispute_resolved',
      details: 'Dispute resolved with status: $status',
      metadata: metadata,
    );
  }

  /// Log moderation action reversal
  static Future<void> logActionReversed({
    required String userId,
    required String actionId,
    required String actionType,
    required String reason,
    required String reversedBy,
  }) async {
    final metadata = {
      'action_id': actionId,
      'action_type': actionType,
      'reversal_reason': reason,
      'reversed_by': reversedBy,
    };

    await logActivity(
      userId: userId,
      action: 'action_reversed',
      details: 'Moderation action reversed: $actionType - $reason',
      metadata: metadata,
    );
  }

  /// Get user activity logs
  static Future<List<ActivityLog>?> getUserActivityLogs(
    String userId, {
    int limit = 50,
    int offset = 0,
    List<String>? actions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (actions != null && actions.isNotEmpty) {
        params['actions'] = actions.join(',');
      }
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/activity-logs/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? responseData;
        return data.map((json) => ActivityLog.fromJson(json)).toList();
      } else {
        print('Error getting user activity logs: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user activity logs: $e');
      return null;
    }
  }

  /// Get conversation activity logs
  static Future<List<ActivityLog>?> getConversationActivityLogs(
    String conversationId, {
    int limit = 100,
    int offset = 0,
    List<String>? actions,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (actions != null && actions.isNotEmpty) {
        params['actions'] = actions.join(',');
      }

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/conversations/$conversationId/activity-logs/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? responseData;
        return data.map((json) => ActivityLog.fromJson(json)).toList();
      } else {
        print('Error getting conversation activity logs: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting conversation activity logs: $e');
      return null;
    }
  }

  /// Get all activity logs with filters
  static Future<Map<String, dynamic>?> getActivityLogs({
    int limit = 100,
    int offset = 0,
    String? userId,
    String? conversationId,
    List<String>? actions,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (userId != null) params['user_id'] = userId;
      if (conversationId != null) params['conversation_id'] = conversationId;
      if (actions != null && actions.isNotEmpty) {
        params['actions'] = actions.join(',');
      }
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/activity-logs/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'logs': (responseData['results'] as List? ?? responseData as List)
              .map((json) => ActivityLog.fromJson(json)).toList(),
          'total_count': responseData['count'] ?? (responseData as List).length,
          'has_next': responseData['next'] != null,
          'has_previous': responseData['previous'] != null,
        };
      } else {
        print('Error getting activity logs: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting activity logs: $e');
      return null;
    }
  }

  /// Get activity statistics
  static Future<Map<String, dynamic>?> getActivityStats({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy, // 'day', 'hour', 'action'
  }) async {
    try {
      Map<String, String> params = {};
      
      if (userId != null) params['user_id'] = userId;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      if (groupBy != null) params['group_by'] = groupBy;

      String url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/activity-logs/stats/';
      if (params.isNotEmpty) {
        final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
        url += '?$queryString';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting activity stats: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting activity stats: $e');
      return null;
    }
  }

  /// Search activity logs
  static Future<List<ActivityLog>?> searchActivityLogs({
    String? query,
    List<String>? actions,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
      };
      
      if (query != null) params['q'] = query;
      if (userId != null) params['user_id'] = userId;
      if (actions != null && actions.isNotEmpty) {
        params['actions'] = actions.join(',');
      }
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/activity-logs/search/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? responseData;
        return data.map((json) => ActivityLog.fromJson(json)).toList();
      } else {
        print('Error searching activity logs: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error searching activity logs: $e');
      return null;
    }
  }

  /// Export activity logs to CSV
  static Future<String?> exportActivityLogs({
    String? userId,
    String? conversationId,
    List<String>? actions,
    DateTime? startDate,
    DateTime? endDate,
    String format = 'csv', // 'csv' or 'json'
  }) async {
    try {
      Map<String, String> params = {
        'format': format,
      };
      
      if (userId != null) params['user_id'] = userId;
      if (conversationId != null) params['conversation_id'] = conversationId;
      if (actions != null && actions.isNotEmpty) {
        params['actions'] = actions.join(',');
      }
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/activity-logs/export/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return response.body;
      } else {
        print('Error exporting activity logs: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error exporting activity logs: $e');
      return null;
    }
  }

  /// Bulk log activities (for batch operations)
  static Future<bool> bulkLogActivities(List<Map<String, dynamic>> activities) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/activity-logs/bulk/'),
        headers: headers,
        body: json.encode({'activities': activities}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error bulk logging activities: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error bulk logging activities: $e');
      return false;
    }
  }
}
