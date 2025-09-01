import 'package:bidr/constants/Constants.dart';

class ReviewItem {
  final String uuid;
  final String customerName;
  final String description;
  final int rating;
  final String comment;
  final String createdAt;
  final String type;

  ReviewItem({
    required this.uuid,
    required this.customerName,
    required this.description,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.type,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      uuid: json['uuid'] ?? Constants.myUid,
      customerName: json['customerName'] ?? 'Anonymous',
      description: json['description'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      type: json['type'] ?? 'review',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'customerName': customerName,
      'description': description,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt,
      'type': type,
    };
  }
}