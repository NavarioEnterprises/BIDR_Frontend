class ContactSubmission {
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final String subject;
  final String message;

  ContactSubmission({
    required this.name,
    required this.email,
    this.phone,
    this.company,
    required this.subject,
    required this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'subject': subject,
      'message': message,
    };
  }

  factory ContactSubmission.fromJson(Map<String, dynamic> json) {
    return ContactSubmission(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      company: json['company'],
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

// Subject choices matching the backend
class ContactSubjectChoices {
  static const String general = 'general';
  static const String support = 'support';
  static const String billing = 'billing';
  static const String partnership = 'partnership';
  static const String feedback = 'feedback';

  static const Map<String, String> choices = {
    general: 'General Inquiry',
    support: 'Support',
    billing: 'Billing',
    partnership: 'Partnership',
    feedback: 'Feedback',
  };

  static List<String> get values => choices.keys.toList();
  static List<String> get labels => choices.values.toList();
  
  static String getLabel(String value) => choices[value] ?? value;
}
