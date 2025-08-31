import 'dart:convert';
import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:http/http.dart' as http;
import '../models/rewards/rewards_models.dart';

class RewardsService {
  // Get complete dashboard data
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
