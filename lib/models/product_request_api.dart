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
  final List<QuoteItem> quotes;
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
    required this.quotes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Backward compatibility getter - maps quotes to sellerOffers
  List<QuoteItem> get sellerOffers => quotes;

  factory ProductRequestItem.fromJson(Map<String, dynamic> json) {
    return ProductRequestItem(
      requestId: json['request_id'] ?? '',
      buyerId: json['buyer_id'] != null ? ApiUser.fromJson(json['buyer_id']) : null,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'],
      conditionPreference: json['condition_preference'],
      maxBudget: json['max_budget'] != null ? double.tryParse(json['max_budget'].toString()) : null,
      currency: json['currency'] ?? 'ZAR',
      urgencyTimeline: json['urgency_timeline'] ?? '',
      status: json['status'] ?? '',
      viewCount: json['view_count'] ?? 0,
      isExpired: json['is_expired'],
      isUrgent: json['is_urgent'],
      tyresRimsSummary: json['tyres_rims_summary'],
      vehicleSparesSummary: json['vehicle_spares_summary'],
      consumerElectronicsSummary: json['consumer_electronics_summary'],
      quotes: (json['quotes'] as List<dynamic>? ?? [])
          .map((quote) => QuoteItem.fromJson(quote))
          .toList(),
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
      'quotes': quotes.map((quote) => quote.toJson()).toList(),
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

class QuoteItem {
  final String quoteId;
  final ApiUser sellerId;
  final double totalAmount;
  final String currency;
  final double? deliveryCost;
  final double? installationCost;
  final int? estimatedDeliveryDays;
  final String status;
  final DateTime validUntil;
  final bool? isExpired;
  final bool? isValid;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuoteItem({
    required this.quoteId,
    required this.sellerId,
    required this.totalAmount,
    required this.currency,
    this.deliveryCost,
    this.installationCost,
    this.estimatedDeliveryDays,
    required this.status,
    required this.validUntil,
    this.isExpired,
    this.isValid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      quoteId: json['quote_id'] ?? '',
      sellerId: ApiUser.fromJson(json['seller_id']),
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'ZAR',
      deliveryCost: json['delivery_cost'] != null 
          ? double.tryParse(json['delivery_cost'].toString()) 
          : null,
      installationCost: json['installation_cost'] != null 
          ? double.tryParse(json['installation_cost'].toString()) 
          : null,
      estimatedDeliveryDays: json['estimated_delivery_days'],
      status: json['status'] ?? 'PENDING',
      validUntil: DateTime.parse(json['valid_until']),
      isExpired: json['is_expired'],
      isValid: json['is_valid'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quote_id': quoteId,
      'seller_id': sellerId.toJson(),
      'total_amount': totalAmount,
      'currency': currency,
      'delivery_cost': deliveryCost,
      'installation_cost': installationCost,
      'estimated_delivery_days': estimatedDeliveryDays,
      'status': status,
      'valid_until': validUntil.toIso8601String(),
      'is_expired': isExpired,
      'is_valid': isValid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
