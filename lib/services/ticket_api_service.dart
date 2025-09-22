import 'dart:convert';
import 'package:bidr/global_values.dart';
import 'package:http/http.dart' as http;
import '../models/ticket.dart';

class TicketApiService {
  /// Fetch tickets for a specific user
  Future<List<Ticket>?> fetchUserTickets(String authUserUid) async {
    final url = Uri.parse(
      '${GlobalVariables.reviewsServiceUrl}api/reviews/router/tickets/user_tickets/',
    );

    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.get(
        url.replace(queryParameters: {'auth_user_uid': authUserUid}),
        headers: headers,
      );

      print('Fetch tickets Response Status: ${response.statusCode}');
      print('Fetch tickets Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final tickets = jsonData
            .map((ticketJson) => Ticket.fromJson(ticketJson))
            .toList();
        print('Fetched ${tickets.length} tickets successfully');
        return tickets;
      } else {
        print('Failed to fetch tickets: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred while fetching tickets: $e');
      return null;
    }
  }

  /// Create a new ticket
  Future<Map<String, dynamic>?> createTicket({
    required String authUserUid,
    required String subject,
    required String description,
    String priority = 'medium',
  }) async {
    final url = Uri.parse(
      '${GlobalVariables.reviewsServiceUrl}api/reviews/router/tickets/',
    );

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'auth_user_uid': authUserUid,
      'subject': subject,
      'description': description,
      'priority': priority,
    });

    print('Creating ticket - URL: $url');
    print('Creating ticket - Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Create ticket Response Status: ${response.statusCode}');
      print('Create ticket Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        print('Ticket created successfully: $jsonResponse');
        return {'success': true, 'data': jsonResponse};
      } else {
        try {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': jsonResponse['error'] ?? 'Failed to create ticket',
            'details': jsonResponse,
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': 'Server error: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Error occurred while creating ticket: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  /// Add a message to an existing ticket
  Future<Map<String, dynamic>?> addMessageToTicket({
    required int ticketId,
    required String authUserUid,
    required String message,
  }) async {
    final url = Uri.parse(
      '${GlobalVariables.reviewsServiceUrl}api/reviews/router/tickets/$ticketId/add_message/',
    );

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'auth_user_uid': authUserUid, 'message': message});

    print('Adding message to ticket - URL: $url');
    print('Adding message to ticket - Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Add message Response Status: ${response.statusCode}');
      print('Add message Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        print('Message added successfully: $jsonResponse');
        return {'success': true, 'data': jsonResponse};
      } else {
        try {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': jsonResponse['error'] ?? 'Failed to add message',
            'details': jsonResponse,
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': 'Server error: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Error occurred while adding message: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  /// Update ticket status
  Future<Map<String, dynamic>?> updateTicketStatus({
    required int ticketId,
    required String status,
  }) async {
    final url = Uri.parse(
      '${GlobalVariables.reviewsServiceUrl}api/reviews/router/tickets/$ticketId/update_status/',
    );

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'status': status});

    print('Updating ticket status - URL: $url');
    print('Updating ticket status - Body: $body');

    try {
      final response = await http.patch(url, headers: headers, body: body);

      print('Update status Response Status: ${response.statusCode}');
      print('Update status Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        print('Ticket status updated successfully: $jsonResponse');
        return {'success': true, 'data': jsonResponse};
      } else {
        try {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': jsonResponse['error'] ?? 'Failed to update ticket status',
            'details': jsonResponse,
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': 'Server error: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Error occurred while updating ticket status: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }
}
