import 'dart:convert';

class ReferralCode {
  final String code;
  final String referralUrl;
  final int totalUses;
  final int maxUses;
  final bool isActive;
  final double referrerRewardAmount;
  final double refereeRewardAmount;

  ReferralCode({
    required this.code,
    required this.referralUrl,
    required this.totalUses,
    required this.maxUses,
    required this.isActive,
    this.referrerRewardAmount = 50.0,
    this.refereeRewardAmount = 25.0,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      code: json['code'],
      referralUrl: json['referral_url'],
      totalUses: json['total_uses'],
      maxUses: json['max_uses'] ?? 100,
      isActive: json['is_active'] ?? true,
      referrerRewardAmount: json.containsKey('referrer_reward_amount')
          ? double.parse(json['referrer_reward_amount'].toString())
          : 50.0,
      refereeRewardAmount: json.containsKey('referee_reward_amount')
          ? double.parse(json['referee_reward_amount'].toString())
          : 25.0,
    );
  }
}

class RewardTransaction {
  final String id;
  final String transactionType;
  final double pointsAmount;
  final String description;
  final DateTime createdAt;
  final String status;

  RewardTransaction({
    required this.id,
    required this.transactionType,
    required this.pointsAmount,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'],
      transactionType: json['transaction_type'],
      pointsAmount: double.parse(json['points_amount'].toString()),
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
    );
  }
}

class RewardsSummary {
  final String userUuid;
  final double currentPointsBalance;
  final double totalPointsEarned;
  final double totalPointsSpent;
  final int tierLevel;
  final String tierName;
  final int pointsToNextTier;
  final bool isActive;

  RewardsSummary({
    required this.userUuid,
    required this.currentPointsBalance,
    required this.totalPointsEarned,
    required this.totalPointsSpent,
    required this.tierLevel,
    required this.tierName,
    required this.pointsToNextTier,
    required this.isActive,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      userUuid: json['user_uuid'],
      currentPointsBalance: double.parse(
        json['current_points_balance'].toString(),
      ),
      totalPointsEarned: double.parse(json['total_points_earned'].toString()),
      totalPointsSpent: double.parse(json['total_points_spent'].toString()),
      tierLevel: json['tier_level'],
      tierName: json['tier_name'],
      pointsToNextTier: json['points_to_next_tier'],
      isActive: json['is_active'],
    );
  }
}

class RewardsCampaign {
  final String id;
  final String name;
  final String description;
  final double rewardPoints;
  final DateTime startsAt;
  final DateTime endsAt;

  RewardsCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.rewardPoints,
    required this.startsAt,
    required this.endsAt,
  });

  factory RewardsCampaign.fromJson(Map<String, dynamic> json) {
    return RewardsCampaign(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      rewardPoints: double.parse(json['reward_points'].toString()),
      startsAt: DateTime.parse(json['starts_at']),
      endsAt: DateTime.parse(json['ends_at']),
    );
  }
}

class RewardsDashboard {
  final RewardsSummary summary;
  final ReferralCode referralCode;
  final List<RewardTransaction> recentTransactions;
  final List<RewardsCampaign> activeCampaigns;

  RewardsDashboard({
    required this.summary,
    required this.referralCode,
    required this.recentTransactions,
    required this.activeCampaigns,
  });

  factory RewardsDashboard.fromJson(Map<String, dynamic> json) {
    return RewardsDashboard(
      summary: RewardsSummary.fromJson(json['summary']),
      referralCode: ReferralCode.fromJson(json['referral_code']),
      recentTransactions: (json['recent_transactions'] as List)
          .map((t) => RewardTransaction.fromJson(t))
          .toList(),
      activeCampaigns: (json['active_campaigns'] as List)
          .map((c) => RewardsCampaign.fromJson(c))
          .toList(),
    );
  }
}
