// Flutter Web Configuration for api.bidr.co.za
// Update your API base URL in your Flutter app

class ApiConfig {
  // OLD - Remove this
  // static const String baseUrl = 'https://bidr-auth-api.westus.azurecontainer.io';
  
  // NEW - Use your custom domain
  static const String baseUrl = 'https://api.bidr.co.za';
  
  // API Endpoints
  static const String register = '$baseUrl/register/';
  static const String login = '$baseUrl/login/';
  static const String profile = '$baseUrl/profile/';
  static const String passwordReset = '$baseUrl/password/reset/';
  static const String health = '$baseUrl/health/';
}

// Example usage in your Flutter app
class AuthService {
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required String password,
    required String confirmPassword,
    required String deliveryMethod,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'role': role,
        'password': password,
        'confirm_password': confirmPassword,
        'delivery_method': deliveryMethod,
      }),
    );
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
}
