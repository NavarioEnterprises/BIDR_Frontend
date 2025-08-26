/// Model for Product Request API responses
class ProductRequestApiResponse {
  final int count;
  final String? next;
  final String? previous;
  final List<ProductRequestItem> results;

  ProductRequestApiResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory ProductRequestApiResponse.fromJson(Map<String, dynamic> json) {
    return ProductRequestApiResponse(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) => ProductRequestItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'results': results.map((item) => item.toJson()).toList(),
    };
  }
}

class ProductRequestItem {
  final String requestId;
  final ApiUser? buyerId;
  final String category;
  final String title;
  final String description;
  final int? quantity;
  final String? conditionPreference;
  final double? maxBudget;
  final String currency;
  final String urgencyTimeline;
  final String status;
  final int viewCount;
  final bool? isExpired;
  final bool? isUrgent;
  final String? tyresRimsSummary;
  final String? vehicleSparesSummary;
  final String? consumerElectronicsSummary;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductRequestItem({
    required this.requestId,
    this.buyerId,
    required this.category,
    required this.title,
    required this.description,
    this.quantity,
    this.conditionPreference,
    this.maxBudget,
    required this.currency,
    required this.urgencyTimeline,
    required this.status,
    required this.viewCount,
    this.isExpired,
    this.isUrgent,
    this.tyresRimsSummary,
    this.vehicleSparesSummary,
    this.consumerElectronicsSummary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductRequestItem.fromJson(Map<String, dynamic> json) {
    return ProductRequestItem(
      requestId: json['request_id'] ?? '',
      buyerId: json['buyer_id'] != null ? ApiUser.fromJson(json['buyer_id']) : null,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'],
      conditionPreference: json['condition_preference'],
      maxBudget: json['max_budget']?.toDouble(),
      currency: json['currency'] ?? 'ZAR',
      urgencyTimeline: json['urgency_timeline'] ?? '',
      status: json['status'] ?? '',
      viewCount: json['view_count'] ?? 0,
      isExpired: json['is_expired'],
      isUrgent: json['is_urgent'],
      tyresRimsSummary: json['tyres_rims_summary'],
      vehicleSparesSummary: json['vehicle_spares_summary'],
      consumerElectronicsSummary: json['consumer_electronics_summary'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'buyer_id': buyerId?.toJson(),
      'category': category,
      'title': title,
      'description': description,
      'quantity': quantity,
      'condition_preference': conditionPreference,
      'max_budget': maxBudget,
      'currency': currency,
      'urgency_timeline': urgencyTimeline,
      'status': status,
      'view_count': viewCount,
      'is_expired': isExpired,
      'is_urgent': isUrgent,
      'tyres_rims_summary': tyresRimsSummary,
      'vehicle_spares_summary': vehicleSparesSummary,
      'consumer_electronics_summary': consumerElectronicsSummary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ApiUser {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  ApiUser({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}