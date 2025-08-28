
class BlogItem {
  final int id;
  final String title;
  final String description;
  final String? content;
  final String? image;
  final String section;
  final String sectionDisplay;
  final Map<String, dynamic>? author;
  final List<String> tagsList;
  final int likes;
  final int views;
  final int commentsCount;
  final String createdAt;
  final String? publishedAt;
  final List<BlogComment>? comments;

  BlogItem({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    this.image,
    required this.section,
    required this.sectionDisplay,
    this.author,
    required this.tagsList,
    required this.likes,
    required this.views,
    required this.commentsCount,
    required this.createdAt,
    this.publishedAt,
    this.comments,
  });

  // Convenience getters for backward compatibility
  String get date => publishedAt ?? createdAt;
  String get imageUrl => image ?? '';
  String get detailContent => content ?? description;

  factory BlogItem.fromJson(Map<String, dynamic> json) {
    return BlogItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      content: json['content'],
      image: json['image'],
      section: json['section'],
      sectionDisplay: json['section_display'],
      author: json['author'],
      tagsList: List<String>.from(json['tags_list'] ?? []),
      likes: json['likes'],
      views: json['views'],
      commentsCount: json['comments_count'],
      createdAt: json['created_at'],
      publishedAt: json['published_at'],
      comments: json['comments'] != null 
          ? List<BlogComment>.from(json['comments'].map((x) => BlogComment.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'image': image,
      'section': section,
      'section_display': sectionDisplay,
      'author': author,
      'tags_list': tagsList,
      'likes': likes,
      'views': views,
      'comments_count': commentsCount,
      'created_at': createdAt,
      'published_at': publishedAt,
      'comments': comments?.map((x) => x.toJson()).toList(),
    };
  }
}
class BlogComment {
  final int id;
  final Map<String, dynamic>? user;
  final String content;
  final bool isApproved;
  final DateTime createdAt;

  BlogComment({
    required this.id,
    this.user,
    required this.content,
    required this.isApproved,
    required this.createdAt,
  });

  // Backward compatibility getters
  String get userId => user?['username'] ?? 'anonymous';
  String? get userName => user?['first_name'] ?? user?['username'];
  int get postId => 0; // Not used in new API
  DateTime? get updatedAt => null; // Not provided in new API

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    return BlogComment(
      id: json['id'],
      user: json['user'],
      content: json['content'],
      isApproved: json['is_approved'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'content': content,
      'is_approved': isApproved,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
