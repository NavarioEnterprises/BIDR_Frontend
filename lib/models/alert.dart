

class WebNotification {
  final int id;
  final String title;
  final String body;
  final String description;
  final String type;
  final bool read;
  final DateTime createdAt;

  WebNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.description,
    required this.type,
    required this.read,
    required this.createdAt,
  });

  factory WebNotification.fromJson(Map<String, dynamic> json) {
    return WebNotification(
      id: json['id']??0,
      title: json['title']??"",
      body: json['body']??"",
      description: json['description'] ?? '',
      type: json['type']??"",
      read: json['read']??false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'description': description,
      'type': type,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
