import 'dart:convert';

import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class AuthApiService {
  Future<String?> selectRole(String role) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}role-selection/');
    var headers = {'Content-Type': 'application/json'};

    var request = http.Request('POST', url);
    request.body = jsonEncode({'role': role});
    request.headers.addAll(headers);

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseBody);
        print('Role selected successfully: $jsonResponse');
        return jsonResponse['role'];
      } else {
        print('Failed to select role: ${response.statusCode}');
        print(response.reasonPhrase);
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> registerUser({
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required String password,
    required String confirmPassword,
    String deliveryMethod = 'sms',
  }) async {
    final url = Uri.parse('${GlobalVariables.authServiceUrl}register/');

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'role': role,
      'password': password,
      'confirm_password': confirmPassword,
      'delivery_method': deliveryMethod,
    });
    print('Making request to: $url');
    print('Headers: $headers');
    print('Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Response Status: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success case
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        print('User registered successfully: $jsonResponse');
        if (jsonResponse["success"] == true) {
          Constants.currentUser = User.fromJson(jsonResponse["user"]);
          if (kDebugMode) {
            print('Registered user: ${Constants.currentUser?.toJson()}');
          }
        }

        return jsonResponse;
      } else {
        // Handle error cases
        try {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'statusCode': response.statusCode,
            'errors': jsonResponse,
          };
        } catch (e) {
          // If response body is not valid JSON
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': 'Server error: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Error occurred: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String email, String otp) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}verify-otp/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'email': email, 'otp': otp});

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseBody);
        print('OTP verified: $jsonResponse');
        return {'success': true, 'data': jsonResponse};
      } else {
        print('OTP verification failed: ${response.statusCode}');
        print(response.reasonPhrase);
        try {
          var errorResponse = jsonDecode(responseBody);
          return {
            'success': false,
            'error': errorResponse['error'] ?? 'OTP verification failed',
          };
        } catch (e) {
          return {'success': false, 'error': 'OTP verification failed'};
        }
      }
    } catch (e) {
      print('Error occurred: $e');
      return {'success': false, 'error': 'Network error occurred'};
    }
  }

  Future<Map<String, dynamic>?> resendOtp(
    String email,
    String cellphone, {
    String deliveryMethod = 'sms',
  }) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}resend-otp/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'email': email,
      'phone': cellphone,
      'delivery_method': deliveryMethod,
    });

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseBody);
        print('OTP resent successfully: $jsonResponse');
        return {'success': true, 'data': jsonResponse};
      } else {
        print('OTP resend failed: ${response.statusCode}');
        print(response.reasonPhrase);
        try {
          var errorResponse = jsonDecode(responseBody);
          return {
            'success': false,
            'error': errorResponse['error'] ?? 'Failed to resend OTP',
          };
        } catch (e) {
          return {'success': false, 'error': 'Failed to resend OTP'};
        }
      }
    } catch (e) {
      print('Error occurred: $e');
      return {'success': false, 'error': 'Network error occurred'};
    }
  }

  Future<Map<String, dynamic>?> login(String email, String password) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}login/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'email': email, 'password': password});

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseBody);
        print('Login successful: $jsonResponse');
        return jsonResponse;
      } else {
        print('Login failed: ${response.statusCode}');
        print(response.reasonPhrase);
        return null;
      }
    } catch (e) {
      print('Error occurred: $e');
      return null;
    }
  }

  Future<void> fetchUserProfile(String accessToken) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}profile/');
    var request = http.Request('GET', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        print('User profile: $jsonResponse');
      } else {
        print('Failed to fetch profile: ${response.statusCode}');
        print(response.reasonPhrase);
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> logout(String accessToken, String refreshToken) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}logout/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.body = jsonEncode({'refresh_token': refreshToken});

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Logged out successfully');
      } else {
        print('Logout failed: ${response.statusCode}');
        print(response.reasonPhrase);
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> registerSellerAccount({
    required String userId,
    required String companyName,
    required String companyRegNo,
  }) async {
    var url = Uri.parse(
      '${GlobalVariables.authServiceUrl}api/seller/register/',
    );
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'user': userId,
      'company_name': companyName,
      'registration_number': companyRegNo,
    });

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseBody);
        print('Seller registered: $jsonResponse');
      } else {
        print('Register seller failed: ${response.statusCode}');
        print(response.reasonPhrase);
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<Map<String, dynamic>?> submitBusinessRegistration(
    Map<String, dynamic> businessData,
  ) async {
    final url = Uri.parse(
      '${GlobalVariables.authServiceUrl}api/seller/business-registration/',
    );

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode(businessData);

    print('Making business registration request to: $url');
    print('Headers: $headers');
    print('Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Business Registration Response Status: ${response.statusCode}');
      print('Business Registration Response Headers: ${response.headers}');
      print('Business Registration Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success case
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        print('Business registration submitted successfully: $jsonResponse');
        return {
          'success': true,
          'data': jsonResponse,
          'message': 'Business registration submitted successfully',
        };
      } else {
        // Handle error cases
        try {
          final jsonResponse =
              jsonDecode(response.body) as Map<String, dynamic>;
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error':
                jsonResponse['error'] ??
                jsonResponse['message'] ??
                'Business registration failed',
            'details': jsonResponse,
          };
        } catch (e) {
          // If response body is not valid JSON
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': 'Server error: ${response.body}',
          };
        }
      }
    } catch (e) {
      print('Error occurred in business registration: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<void> uploadBusinessDocument({
    required String sellerId,
    required String filePath,
    required String documentType,
  }) async {
    var url = Uri.parse(
      '${GlobalVariables.authServiceUrl}api/seller/upload-document/',
    );
    var request = http.MultipartRequest('POST', url);
    request.fields['seller'] = sellerId;
    request.fields['document_type'] = documentType;
    request.files.add(await http.MultipartFile.fromPath('document', filePath));

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseBody);
        print('Document uploaded: $jsonResponse');
      } else {
        print('Document upload failed: ${response.statusCode}');
        print(response.reasonPhrase);
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<void> submitBankInfo({
    required String sellerId,
    required String bankName,
    required String accountNumber,
    required String accountType,
  }) async {
    var url = Uri.parse(
      '${GlobalVariables.authServiceUrl}api/seller/bank-details/',
    );
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'seller': sellerId,
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_type': accountType,
    });

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var jsonResponse = jsonDecode(responseBody);
        print('Bank info submitted: $jsonResponse');
      } else {
        print('Bank info submission failed: ${response.statusCode}');
        print(response.reasonPhrase);
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Future<Map<String, dynamic>?> updateProfile({
    required String accessToken,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}profile/');
    var request = http.Request('PATCH', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.body = jsonEncode({
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
    });

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        print('Profile updated successfully: $jsonResponse');
        return jsonResponse;
      } else {
        print('Profile update failed: ${response.statusCode}');
        print('Response: $responseBody');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      print('Error occurred: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> requestPasswordReset({
    required String email,
  }) async {
    var url = Uri.parse(
      '${GlobalVariables.authServiceUrl}password-reset-request/',
    );
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({'email': email});

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        print('Password reset requested successfully: $jsonResponse');
        return jsonResponse;
      } else {
        print('Password reset request failed: ${response.statusCode}');
        print('Response: $responseBody');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      print('Error occurred: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> deleteAccount({
    required String accessToken,
  }) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}profile/');
    var request = http.Request('DELETE', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Account deleted successfully');
        return {'success': true, 'message': 'Account deleted successfully'};
      } else {
        print('Account deletion failed: ${response.statusCode}');
        print('Response: $responseBody');
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      print('Error occurred: $e');
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> signOut({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      // Call logout API
      await logout(accessToken, refreshToken);
      return {'success': true, 'message': 'Signed out successfully'};
    } catch (e) {
      print('Error during sign out: $e');
      return {'success': false, 'error': 'Sign out error: $e'};
    }
  }
}
