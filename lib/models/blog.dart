
class BlogItem {
  final String title;
  final String description;
  final String date;
  final String imageUrl;
  final int likes;
  final int comments;
  final String detailContent;
  final String section;

  BlogItem({
    required this.title,
    required this.description,
    required this.date,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.detailContent,
    required this.section,
  });
}
class BlogComment {
  final int id;
  final String content;
  final String userId;
  final String? userName;
  final int postId; // or productId, articleId, etc.
  final DateTime createdAt;
  final DateTime? updatedAt;

  BlogComment({
    required this.id,
    required this.content,
    required this.userId,
    this.userName,
    required this.postId,
    required this.createdAt,
    this.updatedAt,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    return BlogComment(
      id: json['id'],
      content: json['content'],
      userId: json['user_id'],
      userName: json['user_name'],
      postId: json['post_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'user_id': userId,
      'user_name': userName,
      'post_id': postId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
