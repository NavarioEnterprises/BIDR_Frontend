import 'dart:convert';
import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:http/http.dart' as http;
import '../models/contact_submission.dart';

class ContactApiService {
  Future<Map<String, dynamic>> submitContactForm(
    ContactSubmission submission,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${GlobalVariables.reviewsServiceUrl}api/contact/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(submission.toJson()),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Contact form submitted successfully!',
          'data': jsonDecode(response.body),
        };
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          'success': false,
          'message': 'Failed to submit contact form',
          'errors': errorBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: Failed to submit contact form',
        'error': e.toString(),
      };
    }
  }
}
