import 'package:bidr/constants/Constants.dart';

class ReviewItem {
  final String uuid;
  final int? id;
  final String customerName;
  final String description;
  final int rating;
  final String comment;
  final String createdAt;
  final String type;
  final String? title;
  final String? content;
  final String? productId;
  final String? sellerId;
  final bool? isApproved;
  final bool? isFeatured;
  final String? updatedAt;
  final int? helpfulCount;
  final int? notHelpfulCount;
  final int? totalVotes;
  final double? helpfulnessPercentage;
  final Map<String, dynamic>? currentUserVote;
  final Map<String, dynamic>? sellerResponse;
  final Map<String, dynamic>? user;
  final String? userDisplayName;

  ReviewItem({
    required this.uuid,
    this.id,
    required this.customerName,
    required this.description,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.type,
    this.title,
    this.content,
    this.productId,
    this.sellerId,
    this.isApproved,
    this.isFeatured,
    this.updatedAt,
    this.helpfulCount,
    this.notHelpfulCount,
    this.totalVotes,
    this.helpfulnessPercentage,
    this.currentUserVote,
    this.sellerResponse,
    this.user,
    this.userDisplayName,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      uuid: json['uuid']?.toString() ?? json['id']?.toString() ?? Constants.myUid,
      id: json['id'],
      customerName: json['customerName'] ?? json['user_display_name'] ?? 'Anonymous',
      description: json['description'] ?? json['content'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? json['content'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      type: json['type'] ?? 'review',
      title: json['title'],
      content: json['content'],
      productId: json['product_id']?.toString(),
      sellerId: json['seller_id']?.toString(),
      isApproved: json['is_approved'],
      isFeatured: json['is_featured'],
      updatedAt: json['updated_at'],
      helpfulCount: json['helpful_count'],
      notHelpfulCount: json['not_helpful_count'],
      totalVotes: json['total_votes'],
      helpfulnessPercentage: json['helpfulness_percentage']?.toDouble(),
      currentUserVote: json['current_user_vote'],
      sellerResponse: json['seller_response'],
      user: json['user'],
      userDisplayName: json['user_display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'id': id,
      'customerName': customerName,
      'description': description,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
      'type': type,
      'title': title,
      'content': content,
      'product_id': productId,
      'seller_id': sellerId,
      'is_approved': isApproved,
      'is_featured': isFeatured,
      'updated_at': updatedAt,
      'helpful_count': helpfulCount,
      'not_helpful_count': notHelpfulCount,
      'total_votes': totalVotes,
      'helpfulness_percentage': helpfulnessPercentage,
      'current_user_vote': currentUserVote,
      'seller_response': sellerResponse,
      'user': user,
      'user_display_name': userDisplayName,
    };
  }
  
  // Helper getters
  bool get hasSellerResponse => sellerResponse != null && sellerResponse!.isNotEmpty;
  
  String? get sellerResponseText => sellerResponse?['response_text'];
  
  String? get sellerResponseDate => sellerResponse?['created_at'];
  
  bool get userHasVoted => currentUserVote?['voted'] ?? false;
  
  bool? get userVoteIsHelpful => currentUserVote?['is_helpful'];
}