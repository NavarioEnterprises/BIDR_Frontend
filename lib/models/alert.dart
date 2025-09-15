class WebNotification {
  final String id; // Changed from int to String to handle UUID
  final String title;
  final String body;
  final String description;
  final String type;
  bool read;
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
      id: json['id']?.toString() ?? '0', // Convert to string
      title: json['title'] ?? "",
      body: json['body'] ?? "",
      description: json['description'] ?? '',
      type: json['type'] ?? "",
      read: json['read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
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

  WebNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? description,
    String? type,
    bool? read,
    DateTime? createdAt,
  }) {
    return WebNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      description: description ?? this.description,
      type: type ?? this.type,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
