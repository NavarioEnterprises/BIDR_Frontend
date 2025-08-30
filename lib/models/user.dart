import 'dart:convert';

class User {
  final int id;
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String? profilePicture;
  final bool emailVerified;
  final bool phoneVerified;
  final String profileStatus;
  final bool isActive;
  final bool isVerified;
  final String? primaryAddress;
  final double profileCompletionPercentage;
  final DateTime createdAt;

  User({
    required this.id,
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    this.profilePicture,
    required this.emailVerified,
    required this.phoneVerified,
    required this.profileStatus,
    required this.isActive,
    required this.isVerified,
    this.primaryAddress,
    required this.profileCompletionPercentage,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      uid: json['uid'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'],
      phoneNumber: json['phone_number'] ?? '',
      role: json['role'],
      profilePicture: json['profile_picture'],
      emailVerified: json['email_verified'] ?? false,
      phoneVerified: json['phone_verified'] ?? false,
      profileStatus: json['profile_status'] ?? 'incomplete',
      isActive: json['is_active'] ?? true,
      isVerified: json['is_verified'] ?? false,
      primaryAddress: json['primary_address'],
      profileCompletionPercentage: (json['profile_completion_percentage'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'role': role,
      'profile_picture': profilePicture,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'profile_status': profileStatus,
      'is_active': isActive,
      'is_verified': isVerified,
      'primary_address': primaryAddress,
      'profile_completion_percentage': profileCompletionPercentage,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class LoginResponse {
  final String message;
  final String accessToken;
  final String refreshToken;
  final User user;

  LoginResponse({
    required this.message,
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'],
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  static LoginResponse fromJsonString(String jsonString) {
    return LoginResponse.fromJson(jsonDecode(jsonString));
  }
}