import 'dart:convert';

import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../authentication/successFailDialog.dart';
import '../models/user.dart';
import '../services/shared_preferences.dart';

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
        if (kDebugMode) {
          print('Role selected successfully: $jsonResponse');
        }
        return jsonResponse['role'];
      } else {
        if (kDebugMode) {
          print('Failed to select role: ${response.statusCode}');
          print(response.reasonPhrase);
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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

    if (kDebugMode) {
      print('Making request to: $url');
      print('Headers: $headers');
      print('Body: $body');
    }

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response Headers: ${response.headers}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success case
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('User registered successfully: $jsonResponse');
        }
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

          // For registration errors, preserve the backend response structure
          // while adding statusCode for compatibility
          jsonResponse['statusCode'] = response.statusCode;
          return jsonResponse;
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
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('OTP verified: $jsonResponse');
        }
        return {'success': true, 'data': jsonResponse};
      } else {
        if (kDebugMode) {
          print('OTP verification failed: ${response.statusCode}');
          print(response.reasonPhrase);
        }
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
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('OTP resent successfully: $jsonResponse');
        }
        return {'success': true, 'data': jsonResponse};
      } else {
        if (kDebugMode) {
          print('OTP resend failed: ${response.statusCode}');
          print(response.reasonPhrase);
        }
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
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('Login successful: $jsonResponse');
        }

        // Debug the response structure
        if (kDebugMode) {
          print(
            'Response contains success: ${jsonResponse.containsKey('success')}',
          );
          print('Success value: ${jsonResponse['success']}');
          print(
            'Response contains access_token: ${jsonResponse.containsKey('access_token')}',
          );
          print('Access token value: ${jsonResponse['access_token']}');
        }

        // Store tokens and user data locally
        // Check for success using either 'success: true' or 'message: Login successful'
        bool isLoginSuccessful =
            (jsonResponse['success'] == true) ||
            (jsonResponse['message'] == 'Login successful');

        if (isLoginSuccessful) {
          if (kDebugMode) {
            print('Entering token storage logic...');
          }
          // Save access token
          final accessToken = jsonResponse['access_token'];
          if (kDebugMode) {
            print('Access token to save: $accessToken');
          }
          if (accessToken != null) {
            final result =
                await Sharedprefs.saveUserAccessTokenSharedPreference(
                  accessToken,
                );
            if (kDebugMode) {
              print('Access token saved successfully: $result');
            }
          } else {
            if (kDebugMode) {
              print('Access token is null, not saving');
            }
          }

          // Save refresh token
          final refreshToken = jsonResponse['refresh_token'];
          if (refreshToken != null) {
            await Sharedprefs.saveUserRefreshTokenSharedPreference(
              refreshToken,
            );
          }

          // Save user data
          final userData = jsonResponse['user'];
          if (userData != null) {
            // Save user ID and UID
            await Sharedprefs.saveUserIdSharedPreference(userData['id'] ?? -1);
            await Sharedprefs.saveUserUidSharedPreference(
              userData['uid'] ?? '',
            );

            // Save user email
            await Sharedprefs.saveUserEmailSharedPreference(
              userData['email'] ?? '',
            );

            // Save user name (use full_name or combine first_name and last_name)
            String displayName = userData['full_name'] ?? '';
            if (displayName.isEmpty) {
              final firstName = userData['first_name'] ?? '';
              final lastName = userData['last_name'] ?? '';
              displayName = '$firstName $lastName'.trim();
            }
            if (displayName.isEmpty) {
              displayName = userData['email'] ?? '';
            }
            await Sharedprefs.saveUserNameSharedPreference(displayName);

            // Save phone number
            await Sharedprefs.saveUserCellSharedPreference(
              userData['phone_number'] ?? '',
            );

            // Save role
            await Sharedprefs.saveUserRoleSharedPreference(
              userData['role'] ?? '',
            );

            // Set logged in flag
            await Sharedprefs.saveUserLoggedInSharedPreference(true);

            // Update Constants
            Constants.myUid = userData['uid'] ?? '';
            Constants.userId = userData['id'] ?? -1;
            Constants.myEmail = userData['email'] ?? '';
            Constants.myDisplayname = displayName;
            Constants.myUsername = displayName;
            Constants.myCell = userData['phone_number'] ?? '';
            Constants.myCategoryRole = userData['role'] ?? '';

            // Create and store User object
            Constants.currentUser = User.fromJson(userData);
          }
        }

        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Login failed: ${response.statusCode}');
          print(response.reasonPhrase);
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('User profile: $jsonResponse');
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch profile: ${response.statusCode}');
          print(response.reasonPhrase);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('Logged out successfully');
        }
      } else {
        if (kDebugMode) {
          print('Logout failed: ${response.statusCode}');
          print(response.reasonPhrase);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('Seller registered: $jsonResponse');
        }
      } else {
        if (kDebugMode) {
          print('Register seller failed: ${response.statusCode}');
          print(response.reasonPhrase);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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

    if (kDebugMode) {
      print('Making business registration request to: $url');
      print('Headers: $headers');
      print('Body: $body');
    }

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (kDebugMode) {
        print('Business Registration Response Status: ${response.statusCode}');
        print('Business Registration Response Headers: ${response.headers}');
        print('Business Registration Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success case
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('Business registration submitted successfully: $jsonResponse');
        }
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
      if (kDebugMode) {
        print('Error occurred in business registration: $e');
      }
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
        if (kDebugMode) {
          print('Document uploaded: $jsonResponse');
        }
      } else {
        if (kDebugMode) {
          print('Document upload failed: ${response.statusCode}');
          print(response.reasonPhrase);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('Bank info submitted: $jsonResponse');
        }
      } else {
        if (kDebugMode) {
          print('Bank info submission failed: ${response.statusCode}');
          print(response.reasonPhrase);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('Profile updated successfully: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Profile update failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> requestPasswordReset(
    BuildContext context, {
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
      var jsonResponse1 = jsonDecode(responseBody);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (kDebugMode) {
          print('Password reset requested successfully: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Password reset request failed: ${response.statusCode}');
          print('Response:kkk ${jsonResponse1['errors']['email'][0]}');
        }
        SmartDialogService.showErrorDialog(
          context: context,
          title: 'Password reset requested failed',
          message: "${jsonResponse1['errors']['email'][0]}",
          buttonText: 'Retry',
          onPressed: () {},
        );
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> resetPassword({
    required String uid,
    required String token,
    required String password,
  }) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}password-reset/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';

    final bodyData = {
      'uid': uid,
      'token': token,
      'password': password,
      'confirm_password': password,
    };

    request.body = jsonEncode(bodyData);

    if (kDebugMode) {
      print('=== Reset Password API Call ===');
      print('URL: $url');
      print('Headers: ${request.headers}');
      print('Body: ${jsonEncode(bodyData)}');
    }

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        print('Response Status Code: ${response.statusCode}');
        print('Response Body: $responseBody');
      }

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (kDebugMode) {
          print('Password reset successful: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Password reset failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        try {
          var errorResponse = jsonDecode(responseBody);
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': errorResponse['error'] ?? 'Password reset failed',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': responseBody,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred in resetPassword: $e');
      }
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Get access token for authentication
    final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
    if (accessToken == null || accessToken.isEmpty) {
      return {'success': false, 'error': 'No access token available'};
    }

    var url = Uri.parse('${GlobalVariables.authServiceUrl}change-password/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.body = jsonEncode({
      'current_password': currentPassword,
      'new_password': newPassword,
    });

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (kDebugMode) {
          print('Password changed successfully: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Password change failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        try {
          var errorResponse = jsonDecode(responseBody);
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error':
                errorResponse['error'] ??
                errorResponse['message'] ??
                'Password change failed',
          };
        } catch (e) {
          return {
            'success': false,
            'statusCode': response.statusCode,
            'error': responseBody,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
        if (kDebugMode) {
          print('Account deleted successfully');
        }
        return {'success': true, 'message': 'Account deleted successfully'};
      } else {
        if (kDebugMode) {
          print('Account deletion failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
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
      if (kDebugMode) {
        print('Error during sign out: $e');
      }
      return {'success': false, 'error': 'Sign out error: $e'};
    }
  }

  /// Get seller profile by auth_user_uid
  Future<Map<String, dynamic>> getSellerProfile({
    required String authUserUid,
  }) async {
    try {
      final url =
          '${GlobalVariables.authServiceUrl}api/seller/profiles/by-auth-user-uid/$authUserUid/';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (kDebugMode) {
        print('Get seller profile response status: ${response.statusCode}');
        print('Get seller profile response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Get seller profile error: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update seller profile
  Future<Map<String, dynamic>> updateSellerProfile({
    required String profileId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final url =
          '${GlobalVariables.authServiceUrl}api/seller/profiles/$profileId/';

      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profileData),
      );

      if (kDebugMode) {
        print('Update seller profile response status: ${response.statusCode}');
        print('Update seller profile response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update seller profile error: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update seller basic info (company details)
  Future<Map<String, dynamic>> updateSellerBasicInfo({
    required String authUserUid,
    required Map<String, dynamic> sellerData,
  }) async {
    try {
      final url =
          '${GlobalVariables.authServiceUrl}api/seller/profiles/update-by-auth-user-uid/$authUserUid/';

      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(sellerData),
      );

      if (kDebugMode) {
        print(
          'Update seller basic info response status: ${response.statusCode}',
        );
        print('Update seller basic info response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'error': errorData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update seller basic info error: $e');
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getUserProfile({required String uid}) async {
    // Get access token for authentication
    final accessToken = await Sharedprefs.getUserAccessTokenSharedPreference();
    if (accessToken == null || accessToken.isEmpty) {
      return {'success': false, 'error': 'No access token available'};
    }

    var url = Uri.parse(
      '${GlobalVariables.authServiceUrl}profile/comprehensive/',
    );
    var request = http.Request('GET', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (kDebugMode) {
          print('User profile retrieved successfully: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Get user profile failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> sendSupportMessage({
    required String accessToken,
    required String subject,
    required String message,
  }) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}contact-support/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.body = jsonEncode({'subject': subject, 'message': message});

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (kDebugMode) {
          print('Support message sent successfully: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Send support message failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> requestQuote({
    required String accessToken,
    required String email,
    required String company,
    String? projectDetails,
  }) async {
    var url = Uri.parse('${GlobalVariables.authServiceUrl}request-quote/');
    var request = http.Request('POST', url);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.body = jsonEncode({
      'email': email,
      'company': company,
      'project_details': projectDetails,
    });

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (kDebugMode) {
          print('Quote request sent successfully: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Quote request failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  Future<Map<String, dynamic>?> getSellerEarningHistory({
    required String accessToken,
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
  }) async {
    // Build query parameters
    Map<String, String> queryParams = {'page': page.toString()};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (status != null) queryParams['status'] = status;

    var uri = Uri.parse(
      '${GlobalVariables.transactionsServiceUrl}api/v1/payment-transactions/seller-earnings/',
    ).replace(queryParameters: queryParams);

    var request = http.Request('GET', uri);
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $accessToken';

    try {
      http.StreamedResponse response = await request.send();
      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseBody);
        if (kDebugMode) {
          print('Seller earning history retrieved successfully');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('Get seller earning history failed: ${response.statusCode}');
          print('Response: $responseBody');
        }
        return {
          'success': false,
          'statusCode': response.statusCode,
          'error': responseBody,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error occurred: $e');
      }
      return {'success': false, 'error': 'Network or parsing error: $e'};
    }
  }

  // Check if user exists and their authentication status
  Future<Map<String, dynamic>?> checkUserStatus(String email) async {
    final url = Uri.parse(
      '${GlobalVariables.authServiceUrl}check-user-status/',
    );
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (kDebugMode) {
          print('User status check: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('User status check failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking user status: $e');
      }
      return null;
    }
  }

  // Update user role to include both buyer and seller
  Future<Map<String, dynamic>?> updateUserRole({
    required String email,
    required String newRole,
  }) async {
    final url = Uri.parse('${GlobalVariables.authServiceUrl}update-user-role/');
    final headers = {'Content-Type': 'application/json'};

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'email': email, 'role': newRole}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (kDebugMode) {
          print('User role updated: $jsonResponse');
        }
        return jsonResponse;
      } else {
        if (kDebugMode) {
          print('User role update failed: ${response.statusCode}');
        }
        final errorResponse = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorResponse['error'] ?? 'Failed to update user role',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user role: $e');
      }
      return {'success': false, 'error': 'Network error occurred'};
    }
  }
}
