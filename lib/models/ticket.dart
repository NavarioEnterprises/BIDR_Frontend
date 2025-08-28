

class Ticket {
  final int id;
  final String ticketId;
  final Map<String, dynamic>? user;
  final String authUserUid;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final Map<String, dynamic>? assignee;
  final String createdAt;
  final String updatedAt;
  final String? resolvedAt;
  final List<TicketMessage>? messages;

  Ticket({
    required this.id,
    required this.ticketId,
    this.user,
    required this.authUserUid,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.assignee,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.messages,
  });

  // Backward compatibility getters
  String get title => subject;
  String get date => createdAt;

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      ticketId: json['ticket_id'],
      user: json['user'],
      authUserUid: json['auth_user_uid'],
      subject: json['subject'],
      description: json['description'],
      status: json['status'],
      priority: json['priority'],
      assignee: json['assignee'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      resolvedAt: json['resolved_at'],
      messages: json['messages'] != null
          ? List<TicketMessage>.from(json['messages'].map((x) => TicketMessage.fromJson(x)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'user': user,
      'auth_user_uid': authUserUid,
      'subject': subject,
      'description': description,
      'status': status,
      'priority': priority,
      'assignee': assignee,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'resolved_at': resolvedAt,
      'messages': messages?.map((x) => x.toJson()).toList(),
    };
  }
}

class TicketMessage {
  final int id;
  final Map<String, dynamic>? sender;
  final String message;
  final bool isFromStaff;
  final String createdAt;

  TicketMessage({
    required this.id,
    this.sender,
    required this.message,
    required this.isFromStaff,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'],
      sender: json['sender'],
      message: json['message'],
      isFromStaff: json['is_from_staff'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'is_from_staff': isFromStaff,
      'created_at': createdAt,
    };
  }
}
