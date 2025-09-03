import 'dart:convert';
import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:http/http.dart' as http;
import '../models/rewards/rewards_models.dart';

class RewardsService {
  // Get complete dashboard data
  static Future<Map<String, dynamic>> submitReview({
    required String authUserUid,
    required String productId,
    required String sellerId,
    required String requestId,
    required int rating,
    required String content,
    required String customerName,
    String? title,
  }) async {
    try {
      print(
        "Url ${GlobalVariables.reviewsServiceUrl}api/reviews/router/reviews/",
      );
      print("Submitting review for product $productId by user $authUserUid");
      print(
        "Review details: rating=$rating, content=$content, customerName=$customerName, title=$title",
      );
      print({
        'auth_user_uid': authUserUid,
        'product_id': requestId,
        'seller_id': sellerId,
        'rating': rating,
        'content': content,
        'customer_name': customerName,
        'title': title ?? 'Review by $customerName',
      });
      final response = await http.post(
        Uri.parse(
          '${GlobalVariables.reviewsServiceUrl}api/reviews/router/reviews/',
        ),

        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_user_uid': authUserUid,
          'product_id': requestId,
          'seller_id': sellerId,
          'rating': rating,
          'content': content,
          'customer_name': customerName,
          'title': title ?? 'Review by $customerName',
        }),
      );
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Parsed response data: $responseData");

        // Handle the response format from our custom endpoint
        if (responseData is Map && responseData.containsKey('success')) {
          return {
            'success': responseData['success'] ?? true,
            'data': responseData['review'] ?? responseData,
            'message':
                responseData['message'] ?? 'Review submitted successfully',
          };
        }

        // Fallback for standard DRF response
        return {'success': true, 'data': responseData};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error':
              error['error'] ?? error['detail'] ?? 'Failed to submit review',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getProductReviews(
    String productId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${GlobalVariables.reviewsServiceUrl}api/reviews/by_product/?product_id=$productId',
        ),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to fetch reviews'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<RewardsDashboard> getDashboard(String userUuid) async {
    final response = await http.get(
      Uri.parse(
        '${GlobalVariables.reviewsServiceUrl}api/dashboard/?user_uuid=$userUuid',
      ),
    );

    if (response.statusCode == 200) {
      return RewardsDashboard.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load rewards dashboard: ${response.body}');
    }
  }

  // Get or create user's referral code
  Future<ReferralCode> getMyReferralCode(String userUuid) async {
    final response = await http.get(
      Uri.parse(
        '${GlobalVariables.reviewsServiceUrl}api/my-code/?user_uuid=$userUuid',
      ),
    );
    print(
      "GetMyReferralCode Response: ${response.statusCode} - ${response.body}",
    );

    if (response.statusCode == 200) {
      return ReferralCode.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get referral code: ${response.body}');
    }
  }

  // Validate a referral code
  Future<Map<String, dynamic>> validateReferralCode(String code) async {
    final response = await http.get(
      Uri.parse(
        '${GlobalVariables.reviewsServiceUrl}api//validate-code/?code=$code',
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to validate referral code: ${response.body}');
    }
  }

  // Process a referral
  Future<Map<String, dynamic>> processReferral({
    required String referralCode,
    required String userUuid,
  }) async {
    final response = await http.post(
      Uri.parse('${GlobalVariables.reviewsServiceUrl}api//process-referral/'),
      body: {'referral_code': referralCode, 'user_uuid': userUuid},
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to process referral: ${response.body}');
    }
  }

  // Get reward transactions history
  Future<List<RewardTransaction>> getTransactionHistory(String userUuid) async {
    final response = await http.get(
      Uri.parse(
        '${GlobalVariables.reviewsServiceUrl}api//my-transactions/?user_uuid=$userUuid',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['results'] != null) {
        return (data['results'] as List)
            .map((t) => RewardTransaction.fromJson(t))
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load transaction history: ${response.body}');
    }
  }

  // Get rewards summary
  Future<RewardsSummary> getRewardsSummary(String userUuid) async {
    final response = await http.get(
      Uri.parse(
        '${GlobalVariables.reviewsServiceUrl}api//my-summary/?user_uuid=$userUuid',
      ),
    );

    if (response.statusCode == 200) {
      return RewardsSummary.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load rewards summary: ${response.body}');
    }
  }

  // Get leaderboard
  Future<List<RewardsSummary>> getLeaderboard({int limit = 10}) async {
    final response = await http.get(
      Uri.parse(
        '${GlobalVariables.reviewsServiceUrl}api//leaderboard/?limit=$limit',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((s) => RewardsSummary.fromJson(s)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load leaderboard: ${response.body}');
    }
  }

  // Get active campaigns
  Future<List<RewardsCampaign>> getActiveCampaigns() async {
    final response = await http.get(
      Uri.parse('${GlobalVariables.reviewsServiceUrl}api/active-campaigns/'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data.map((c) => RewardsCampaign.fromJson(c)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load active campaigns: ${response.body}');
    }
  }
}
