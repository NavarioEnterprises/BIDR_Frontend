class FAQ {
  final int id;
  final String question;
  final String answer;
  final String category;
  final String categoryDisplay;
  final int order;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.categoryDisplay,
    required this.order,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      category: json['category'] ?? '',
      categoryDisplay: json['category_display'] ?? json['category'] ?? '',
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'category_display': categoryDisplay,
      'order': order,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class FAQCategory {
  final String value;
  final String label;

  FAQCategory({
    required this.value,
    required this.label,
  });

  factory FAQCategory.fromJson(Map<String, dynamic> json) {
    return FAQCategory(
      value: json['value'],
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}
