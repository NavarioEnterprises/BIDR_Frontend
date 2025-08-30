/// Models for chat moderation system including strikes, activity logs, and disputes

class UserStrike {
  final String? id;
  final String userId;
  final String reason;
  final String violationContent;
  final DateTime createdAt;
  final String conversationId;
  final String messageId;
  final bool isActive;
  final String severity; // 'low', 'medium', 'high'

  UserStrike({
    this.id,
    required this.userId,
    required this.reason,
    required this.violationContent,
    required this.createdAt,
    required this.conversationId,
    required this.messageId,
    this.isActive = true,
    this.severity = 'medium',
  });

  factory UserStrike.fromJson(Map<String, dynamic> json) {
    return UserStrike(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      reason: json['reason'] ?? '',
      violationContent: json['violation_content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      conversationId: json['conversation_id']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      severity: json['severity'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reason': reason,
      'violation_content': violationContent,
      'created_at': createdAt.toIso8601String(),
      'conversation_id': conversationId,
      'message_id': messageId,
      'is_active': isActive,
      'severity': severity,
    };
  }
}

class ModerationAction {
  final String? id;
  final String actionType; // 'warning', 'strike', 'suspension', 'content_filter'
  final String userId;
  final String reason;
  final String details;
  final DateTime createdAt;
  final String moderatorId; // system or admin user ID
  final bool isReversed;
  final String? conversationId;
  final String? messageId;

  ModerationAction({
    this.id,
    required this.actionType,
    required this.userId,
    required this.reason,
    required this.details,
    required this.createdAt,
    required this.moderatorId,
    this.isReversed = false,
    this.conversationId,
    this.messageId,
  });

  factory ModerationAction.fromJson(Map<String, dynamic> json) {
    return ModerationAction(
      id: json['id']?.toString(),
      actionType: json['action_type'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      reason: json['reason'] ?? '',
      details: json['details'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      moderatorId: json['moderator_id']?.toString() ?? '',
      isReversed: json['is_reversed'] ?? false,
      conversationId: json['conversation_id']?.toString(),
      messageId: json['message_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action_type': actionType,
      'user_id': userId,
      'reason': reason,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'moderator_id': moderatorId,
      'is_reversed': isReversed,
      'conversation_id': conversationId,
      'message_id': messageId,
    };
  }
}

class ActivityLog {
  final String? id;
  final String userId;
  final String action; // 'message_sent', 'message_filtered', 'warning_issued', 'strike_received', 'suspended'
  final String details;
  final DateTime timestamp;
  final String? conversationId;
  final String? messageId;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    this.id,
    required this.userId,
    required this.action,
    required this.details,
    required this.timestamp,
    this.conversationId,
    this.messageId,
    this.metadata,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      conversationId: json['conversation_id']?.toString(),
      messageId: json['message_id']?.toString(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'conversation_id': conversationId,
      'message_id': messageId,
      'metadata': metadata,
    };
  }
}

class DisputeCase {
  final String? id;
  final String userId;
  final String type; // 'strike_appeal', 'suspension_appeal', 'content_dispute'
  final String reason;
  final String description;
  final String status; // 'pending', 'under_review', 'resolved', 'rejected'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolverId;
  final String? resolution;
  final String? relatedStrikeId;
  final String? relatedActionId;

  DisputeCase({
    this.id,
    required this.userId,
    required this.type,
    required this.reason,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
    this.resolvedAt,
    this.resolverId,
    this.resolution,
    this.relatedStrikeId,
    this.relatedActionId,
  });

  factory DisputeCase.fromJson(Map<String, dynamic> json) {
    return DisputeCase(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      type: json['type'] ?? '',
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      resolverId: json['resolver_id']?.toString(),
      resolution: json['resolution'],
      relatedStrikeId: json['related_strike_id']?.toString(),
      relatedActionId: json['related_action_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'reason': reason,
      'description': description,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolver_id': resolverId,
      'resolution': resolution,
      'related_strike_id': relatedStrikeId,
      'related_action_id': relatedActionId,
    };
  }
}

class ModerationWarning {
  final String? id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'content_filtered', 'first_strike', 'second_strike', 'final_warning', 'suspended'
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  ModerationWarning({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory ModerationWarning.fromJson(Map<String, dynamic> json) {
    return ModerationWarning(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'data': data,
    };
  }
}

class ContentFilterResult {
  final bool isViolation;
  final String filteredContent;
  final List<String> violationTypes;
  final List<String> detectedItems;
  final String severity; // 'low', 'medium', 'high'

  ContentFilterResult({
    required this.isViolation,
    required this.filteredContent,
    required this.violationTypes,
    required this.detectedItems,
    required this.severity,
  });

  factory ContentFilterResult.clean(String content) {
    return ContentFilterResult(
      isViolation: false,
      filteredContent: content,
      violationTypes: [],
      detectedItems: [],
      severity: 'low',
    );
  }

  factory ContentFilterResult.violation({
    required String filteredContent,
    required List<String> violationTypes,
    required List<String> detectedItems,
    required String severity,
  }) {
    return ContentFilterResult(
      isViolation: true,
      filteredContent: filteredContent,
      violationTypes: violationTypes,
      detectedItems: detectedItems,
      severity: severity,
    );
  }
}

class UserModerationStatus {
  final String userId;
  final int activeStrikes;
  final int totalStrikes;
  final bool isSuspended;
  final DateTime? suspensionEndDate;
  final DateTime? lastViolation;
  final List<String> recentViolations;

  UserModerationStatus({
    required this.userId,
    required this.activeStrikes,
    required this.totalStrikes,
    required this.isSuspended,
    this.suspensionEndDate,
    this.lastViolation,
    required this.recentViolations,
  });

  factory UserModerationStatus.fromJson(Map<String, dynamic> json) {
    return UserModerationStatus(
      userId: json['user_id']?.toString() ?? '',
      activeStrikes: json['active_strikes'] ?? 0,
      totalStrikes: json['total_strikes'] ?? 0,
      isSuspended: json['is_suspended'] ?? false,
      suspensionEndDate: json['suspension_end_date'] != null 
          ? DateTime.parse(json['suspension_end_date']) 
          : null,
      lastViolation: json['last_violation'] != null 
          ? DateTime.parse(json['last_violation']) 
          : null,
      recentViolations: List<String>.from(json['recent_violations'] ?? []),
    );
  }

  bool get canSendMessages => !isSuspended;
  
  bool get needsWarning => activeStrikes > 0;
  
  String get statusMessage {
    if (isSuspended) {
      if (suspensionEndDate != null) {
        final remaining = suspensionEndDate!.difference(DateTime.now());
        if (remaining.inHours > 24) {
          return 'Suspended for ${remaining.inDays} more days';
        } else if (remaining.inHours > 0) {
          return 'Suspended for ${remaining.inHours} more hours';
        } else {
          return 'Suspension ending soon';
        }
      }
      return 'Account suspended';
    }
    
    switch (activeStrikes) {
      case 1:
        return 'First strike - Please follow chat guidelines';
      case 2:
        return 'Second strike - One more violation will result in suspension';
      case 3:
        return 'Final warning - Account will be suspended with next violation';
      default:
        return 'Good standing';
    }
  }
}
