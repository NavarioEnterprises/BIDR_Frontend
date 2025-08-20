

class Ticket {
  final String id;
  final String title;
  final String status;
  final String date;
  final String description;
  final String assignee;

  Ticket({
    required this.id,
    required this.title,
    required this.status,
    required this.date,
    required this.description,
    required this.assignee,
  });
}