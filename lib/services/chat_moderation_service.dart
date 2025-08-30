import 'dart:convert';
import 'package:http/http.dart' as http;
import '../global_values.dart';
import '../models/moderation_models.dart';

/// Service for chat content moderation, profanity filtering, and user strike management
class ChatModerationService {
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Comprehensive list of prohibited words and patterns
  static const List<String> _vulgarWords = [
    // Common profanity
    'fuck', 'shit', 'damn', 'bitch', 'asshole', 'bastard', 'crap',
    'piss', 'cock', 'dick', 'pussy', 'tits', 'boobs', 'ass',
    // Slurs and offensive terms (add more as needed)
    'idiot', 'stupid', 'moron', 'retard', 'gay', 'fag',
    // Scam-related terms
    'scam', 'fraud', 'fake', 'cheat', 'lie', 'liar', 'steal',
    // Inappropriate commercial terms
    'drugs', 'weed', 'cocaine', 'heroin', 'meth',
  ];

  static const List<String> _spamPatterns = [
    // Phone numbers
    r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
    // Email patterns
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    // URLs
    r'https?://[^\s]+',
    // WhatsApp/contact sharing
    r'whatsapp|telegram|contact\s+me',
    // Repeated characters (spam-like)
    r'(.)\1{4,}',
  ];

  /// Filter message content for violations
  static ContentFilterResult filterContent(String content) {
    final originalContent = content;
    String filteredContent = content.toLowerCase();
    
    List<String> violationTypes = [];
    List<String> detectedItems = [];
    String severity = 'low';

    // Check for vulgar/inappropriate words
    List<String> detectedProfanity = [];
    for (String word in _vulgarWords) {
      final regex = RegExp(r'\b' + word + r'\b', caseSensitive: false);
      if (regex.hasMatch(filteredContent)) {
        detectedProfanity.add(word);
        filteredContent = filteredContent.replaceAll(regex, '*' * word.length);
      }
    }

    if (detectedProfanity.isNotEmpty) {
      violationTypes.add('profanity');
      detectedItems.addAll(detectedProfanity);
      severity = 'high';
    }

    // Check for spam patterns (phone numbers, emails, URLs)
    List<String> detectedSpam = [];
    for (String pattern in _spamPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(originalContent);
      for (Match match in matches) {
        detectedSpam.add(match.group(0) ?? '');
        filteredContent = filteredContent.replaceAll(match.group(0)!, '[FILTERED]');
      }
    }

    if (detectedSpam.isNotEmpty) {
      violationTypes.add('spam');
      detectedItems.addAll(detectedSpam);
      severity = severity == 'high' ? 'high' : 'medium';
    }

    // Check for excessive numbers (potential spam)
    final numberPattern = RegExp(r'\d{8,}'); // 8 or more consecutive digits
    if (numberPattern.hasMatch(originalContent)) {
      violationTypes.add('excessive_numbers');
      detectedItems.add('long_number_sequence');
      severity = severity == 'high' ? 'high' : 'medium';
      filteredContent = filteredContent.replaceAll(numberPattern, '[NUMBER_FILTERED]');
    }

    // Check for excessive caps (shouting)
    final capsRatio = originalContent.replaceAll(RegExp(r'[^A-Z]'), '').length / originalContent.length;
    if (capsRatio > 0.7 && originalContent.length > 10) {
      violationTypes.add('excessive_caps');
      detectedItems.add('shouting');
      severity = severity == 'high' ? 'high' : 'low';
    }

    // Return result
    if (violationTypes.isEmpty) {
      return ContentFilterResult.clean(originalContent);
    } else {
      return ContentFilterResult.violation(
        filteredContent: filteredContent,
        violationTypes: violationTypes,
        detectedItems: detectedItems,
        severity: severity,
      );
    }
  }

  /// Get user's current moderation status
  static Future<UserModerationStatus?> getUserModerationStatus(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/status/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return UserModerationStatus.fromJson(json.decode(response.body));
      } else {
        print('Error getting moderation status: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting moderation status: $e');
      return null;
    }
  }

  /// Issue a strike to a user
  static Future<UserStrike?> issueStrike({
    required String userId,
    required String reason,
    required String violationContent,
    required String conversationId,
    required String messageId,
    String severity = 'medium',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/strikes/'),
        headers: headers,
        body: json.encode({
          'user_id': userId,
          'reason': reason,
          'violation_content': violationContent,
          'conversation_id': conversationId,
          'message_id': messageId,
          'severity': severity,
        }),
      );

      if (response.statusCode == 201) {
        return UserStrike.fromJson(json.decode(response.body));
      } else {
        print('Error issuing strike: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error issuing strike: $e');
      return null;
    }
  }

  /// Process message content and handle moderation
  static Future<Map<String, dynamic>> processMessage({
    required String content,
    required String userId,
    required String conversationId,
    String? messageId,
  }) async {
    // Filter content
    final filterResult = filterContent(content);
    
    // Get user's current status
    final userStatus = await getUserModerationStatus(userId);
    
    if (userStatus?.isSuspended == true) {
      return {
        'allowed': false,
        'reason': 'user_suspended',
        'message': 'Your account is currently suspended from sending messages.',
        'status': userStatus?.statusMessage,
      };
    }

    // If content has violations
    if (filterResult.isViolation) {
      // Determine action based on severity and user history
      String action = _determineAction(filterResult.severity, userStatus?.activeStrikes ?? 0);
      
      Map<String, dynamic> result = {
        'allowed': action != 'block',
        'filtered_content': filterResult.filteredContent,
        'violations': filterResult.violationTypes,
        'detected_items': filterResult.detectedItems,
        'severity': filterResult.severity,
        'action': action,
      };

      // Issue strike for medium/high severity violations
      if (filterResult.severity == 'medium' || filterResult.severity == 'high') {
        if (messageId != null) {
          final strike = await issueStrike(
            userId: userId,
            reason: filterResult.violationTypes.join(', '),
            violationContent: content,
            conversationId: conversationId,
            messageId: messageId,
            severity: filterResult.severity,
          );
          
          if (strike != null) {
            result['strike_issued'] = true;
            result['strike_id'] = strike.id;
          }
        }
      }

      return result;
    }

    // Content is clean
    return {
      'allowed': true,
      'filtered_content': content,
      'violations': <String>[],
      'action': 'allow',
    };
  }

  /// Determine moderation action based on severity and user history
  static String _determineAction(String severity, int activeStrikes) {
    switch (severity) {
      case 'low':
        return 'warn'; // Just warn, allow message
      case 'medium':
        if (activeStrikes >= 2) return 'block';
        return 'warn_and_strike';
      case 'high':
        if (activeStrikes >= 1) return 'block';
        return 'warn_and_strike';
      default:
        return 'allow';
    }
  }

  /// Report moderation action
  static Future<ModerationAction?> reportAction({
    required String actionType,
    required String userId,
    required String reason,
    required String details,
    String moderatorId = 'system',
    String? conversationId,
    String? messageId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/actions/'),
        headers: headers,
        body: json.encode({
          'action_type': actionType,
          'user_id': userId,
          'reason': reason,
          'details': details,
          'moderator_id': moderatorId,
          'conversation_id': conversationId,
          'message_id': messageId,
        }),
      );

      if (response.statusCode == 201) {
        return ModerationAction.fromJson(json.decode(response.body));
      } else {
        print('Error reporting moderation action: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error reporting moderation action: $e');
      return null;
    }
  }

  /// Get user strikes
  static Future<List<UserStrike>?> getUserStrikes(String userId, {bool activeOnly = false}) async {
    try {
      String url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/strikes/';
      if (activeOnly) url += '?active_only=true';
      
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserStrike.fromJson(json)).toList();
      } else {
        print('Error getting user strikes: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting user strikes: $e');
      return null;
    }
  }

  /// Suspend user account
  static Future<bool> suspendUser({
    required String userId,
    required int durationHours,
    required String reason,
    String? relatedStrikeId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.chatServiceUrl}api/v1/moderation/users/$userId/suspend/'),
        headers: headers,
        body: json.encode({
          'duration_hours': durationHours,
          'reason': reason,
          'related_strike_id': relatedStrikeId,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error suspending user: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error suspending user: $e');
      return false;
    }
  }

  /// Check if message should be auto-moderated based on patterns
  static bool requiresModeration(String content) {
    final filterResult = filterContent(content);
    return filterResult.isViolation && 
           (filterResult.severity == 'medium' || filterResult.severity == 'high');
  }

  /// Get moderation statistics for admin
  static Future<Map<String, dynamic>?> getModerationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '${GlobalVariables.chatServiceUrl}api/v1/moderation/stats/';
      Map<String, String> params = {};
      
      if (startDate != null) params['start_date'] = startDate.toIso8601String();
      if (endDate != null) params['end_date'] = endDate.toIso8601String();
      
      if (params.isNotEmpty) {
        url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Error getting moderation stats: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting moderation stats: $e');
      return null;
    }
  }
}
