import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_values.dart';
import '../models/moderation_models.dart';

/// Service for handling disputes and appeals against moderation actions
class DisputeHandlerService {
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Create a new dispute case
  static Future<DisputeCase?> createDispute({
    required String userId,
    required String type, // 'strike_appeal', 'suspension_appeal', 'content_dispute'
    required String reason,
    required String description,
    String? relatedStrikeId,
    String? relatedActionId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'type': type,
          'reason': reason,
          'description': description,
          'related_strike_id': relatedStrikeId,
          'related_action_id': relatedActionId,
        }),
      );

      if (response.statusCode == 201) {
        return DisputeCase.fromJson(json.decode(response.body));
      } else {
        print('Error creating dispute: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating dispute: $e');
      return null;
    }
  }

  /// Create a strike appeal
  static Future<DisputeCase?> appealStrike({
    required String userId,
    required String strikeId,
    required String reason,
    required String description,
  }) async {
    return await createDispute(
      userId: userId,
      type: 'strike_appeal',
      reason: reason,
      description: description,
      relatedStrikeId: strikeId,
    );
  }

  /// Create a suspension appeal
  static Future<DisputeCase?> appealSuspension({
    required String userId,
    required String suspensionActionId,
    required String reason,
    required String description,
  }) async {
    return await createDispute(
      userId: userId,
      type: 'suspension_appeal',
      reason: reason,
      description: description,
      relatedActionId: suspensionActionId,
    );
  }

  /// Create a content dispute
  static Future<DisputeCase?> disputeContentModeration({
    required String userId,
    required String moderationActionId,
    required String reason,
    required String description,
  }) async {
    return await createDispute(
      userId: userId,
      type: 'content_dispute',
      reason: reason,
      description: description,
      relatedActionId: moderationActionId,
    );
  }

  /// Get a specific dispute case
  static Future<DisputeCase?> getDispute(String disputeId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/$disputeId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return DisputeCase.fromJson(json.decode(response.body));
      } else {
        print('Error getting dispute: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting dispute: $e');
      return null;
    }
  }

  /// Get user's dispute cases
  static Future<List<DisputeCase>?> getUserDisputes(
    String userId, {
    String? status,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/disputes/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? responseData;
        return data.map((json) => DisputeCase.fromJson(json)).toList();
      } else {
        print('Error getting user disputes: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user disputes: $e');
      return null;
    }
  }

  /// Get all disputes with filters (for admin/moderator use)
  static Future<Map<String, dynamic>?> getAllDisputes({
    String? status,
    String? type,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;
      if (userId != null) params['user_id'] = userId;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'disputes': (responseData['results'] as List? ?? responseData as List)
              .map((json) => DisputeCase.fromJson(json)).toList(),
          'total_count': responseData['count'] ?? (responseData as List).length,
          'has_next': responseData['next'] != null,
          'has_previous': responseData['previous'] != null,
        };
      } else {
        print('Error getting all disputes: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting all disputes: $e');
      return null;
    }
  }

  /// Update dispute status (for admin/moderator use)
  static Future<DisputeCase?> updateDisputeStatus({
    required String disputeId,
    required String status, // 'under_review', 'resolved', 'rejected'
    String? resolution,
    String? resolverId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/$disputeId/'),
        headers: headers,
        body: json.encode({
          'status': status,
          'resolution': resolution,
          'resolver_id': resolverId,
          if (status == 'resolved' || status == 'rejected')
            'resolved_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return DisputeCase.fromJson(json.decode(response.body));
      } else {
        print('Error updating dispute status: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating dispute status: $e');
      return null;
    }
  }

  /// Resolve a dispute (approve the appeal)
  static Future<DisputeCase?> resolveDispute({
    required String disputeId,
    required String resolution,
    String? resolverId,
  }) async {
    final dispute = await updateDisputeStatus(
      disputeId: disputeId,
      status: 'resolved',
      resolution: resolution,
      resolverId: resolverId,
    );

    if (dispute != null) {
      // If it's a strike appeal that was approved, deactivate the strike
      if (dispute.type == 'strike_appeal' && dispute.relatedStrikeId != null) {
        await _deactivateStrike(dispute.relatedStrikeId!);
      }
      
      // If it's a suspension appeal that was approved, lift the suspension
      if (dispute.type == 'suspension_appeal' && dispute.relatedActionId != null) {
        await _liftSuspension(dispute.userId);
      }
    }

    return dispute;
  }

  /// Reject a dispute
  static Future<DisputeCase?> rejectDispute({
    required String disputeId,
    required String reason,
    String? resolverId,
  }) async {
    return await updateDisputeStatus(
      disputeId: disputeId,
      status: 'rejected',
      resolution: reason,
      resolverId: resolverId,
    );
  }

  /// Add a comment/note to a dispute (for internal tracking)
  static Future<bool> addDisputeComment({
    required String disputeId,
    required String comment,
    String? authorId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/$disputeId/comments/'),
        headers: headers,
        body: json.encode({
          'comment': comment,
          'author_id': authorId,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error adding dispute comment: $e');
      return false;
    }
  }

  /// Get dispute comments
  static Future<List<Map<String, dynamic>>?> getDisputeComments(String disputeId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/$disputeId/comments/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Error getting dispute comments: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting dispute comments: $e');
      return null;
    }
  }

  /// Check if user can create a dispute for a specific strike/action
  static Future<Map<String, dynamic>?> canCreateDispute({
    required String userId,
    String? strikeId,
    String? actionId,
    required String disputeType,
  }) async {
    try {
      Map<String, String> params = {
        'user_id': userId,
        'type': disputeType,
      };
      
      if (strikeId != null) params['strike_id'] = strikeId;
      if (actionId != null) params['action_id'] = actionId;

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/can-create/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error checking dispute eligibility: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error checking dispute eligibility: $e');
      return null;
    }
  }

  /// Get dispute statistics
  static Future<Map<String, dynamic>?> getDisputeStats({
    DateTime? startDate,
    DateTime? endDate,
    String? groupBy,
  }) async {
    try {
      Map<String, String> params = {};
      
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      if (groupBy != null) params['group_by'] = groupBy;

      String url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/stats/';
      if (params.isNotEmpty) {
        final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
        url += '?$queryString';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting dispute stats: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting dispute stats: $e');
      return null;
    }
  }

  /// Search disputes
  static Future<List<DisputeCase>?> searchDisputes({
    String? query,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Map<String, String> params = {
        'limit': limit.toString(),
      };
      
      if (query != null) params['q'] = query;
      if (status != null) params['status'] = status;
      if (type != null) params['type'] = type;
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/search/?$queryString';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['results'] ?? responseData;
        return data.map((json) => DisputeCase.fromJson(json)).toList();
      } else {
        print('Error searching disputes: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error searching disputes: $e');
      return null;
    }
  }

  /// Bulk update dispute statuses (for admin use)
  static Future<bool> bulkUpdateDisputes({
    required List<String> disputeIds,
    required String status,
    String? resolution,
    String? resolverId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/bulk-update/'),
        headers: headers,
        body: json.encode({
          'dispute_ids': disputeIds,
          'status': status,
          'resolution': resolution,
          'resolver_id': resolverId,
          if (status == 'resolved' || status == 'rejected')
            'resolved_at': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error bulk updating disputes: $e');
      return false;
    }
  }

  /// Get pending disputes count
  static Future<int?> getPendingDisputesCount() async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/disputes/pending-count/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        print('Error getting pending disputes count: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting pending disputes count: $e');
      return null;
    }
  }

  /// Helper method to deactivate a strike when appeal is approved
  static Future<bool> _deactivateStrike(String strikeId) async {
    try {
      final response = await http.patch(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/strikes/$strikeId/'),
        headers: headers,
        body: json.encode({
          'is_active': false,
          'deactivated_at': DateTime.now().toIso8601String(),
          'deactivation_reason': 'Appeal approved',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deactivating strike: $e');
      return false;
    }
  }

  /// Helper method to lift a user suspension when appeal is approved
  static Future<bool> _liftSuspension(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/lift-suspension/'),
        headers: headers,
        body: json.encode({
          'reason': 'Appeal approved',
          'lifted_at': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error lifting suspension: $e');
      return false;
    }
  }

  /// Get user's dispute eligibility summary
  static Future<Map<String, dynamic>?> getUserDisputeEligibility(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/dispute-eligibility/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting dispute eligibility: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting dispute eligibility: $e');
      return null;
    }
  }
}
