
import 'dart:math';
import 'package:bidr/models/vihecle_spares.dart';

class VehicleType {
  final String id;
  final String name;
  final String category; // e.g., 'passenger_car', 'truck'
  final String? description;
  final bool isActive;

  VehicleType({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.isActive,
  });

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'description': description,
    'is_active': isActive,
  };
}

class ProductCategory {
  final String id;
  final String name;
  final String categoryType; // e.g., 'tyres', 'vehicle_parts'
  final String? description;
  final bool isActive;

  ProductCategory({
    required this.id,
    required this.name,
    required this.categoryType,
    this.description,
    required this.isActive,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      categoryType: json['category_type'],
      description: json['description'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category_type': categoryType,
    'description': description,
    'is_active': isActive,
  };
}

class TyreRimsBrand {
  final String id;
  final String name;
  final String? countryOfOrigin;
  final bool isActive;

  TyreRimsBrand({
    required this.id,
    required this.name,
    this.countryOfOrigin,
    required this.isActive,
  });

  factory TyreRimsBrand.fromJson(Map<String, dynamic> json) {
    return TyreRimsBrand(
      id: json['id'],
      name: json['name'],
      countryOfOrigin: json['country_of_origin'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country_of_origin': countryOfOrigin,
    'is_active': isActive,
  };
}

class RequestImage {
  final String id;
  final String requestId;
  final String image;
  final String? caption;
  final bool isPrimary;
  final int order;

  RequestImage({
    required this.id,
    required this.requestId,
    required this.image,
    this.caption,
    required this.isPrimary,
    required this.order,
  });

  factory RequestImage.fromJson(Map<String, dynamic> json) {
    return RequestImage(
      id: json['id'],
      requestId: json['request'],
      image: json['image'],
      caption: json['caption'],
      isPrimary: json['is_primary'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request': requestId,
    'image': image,
    'caption': caption,
    'is_primary': isPrimary,
    'order': order,
  };
}

class TyreRimsRequest {
  final String id;
  final String requestNumber;
  final String buyerId;
  final String title;
  final String description;
  final String categoryId;
  final String vehicleTypeId;
  final String status; // e.g., 'draft', 'active'
  final String priority; // e.g., 'low', 'medium'
  final DateTime? expiresAt;
  final DateTime? responseDeadline;
  final LocationPoint? preferredLocation;
  final int maxDistanceKm;
  final double? budgetMin;
  final double? budgetMax;
  final int viewsCount;
  final int quotesReceived;

  TyreRimsRequest({
    required this.id,
    required this.requestNumber,
    required this.buyerId,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.vehicleTypeId,
    required this.status,
    required this.priority,
    this.expiresAt,
    this.responseDeadline,
    this.preferredLocation,
    required this.maxDistanceKm,
    this.budgetMin,
    this.budgetMax,
    required this.viewsCount,
    required this.quotesReceived,
  });

  factory TyreRimsRequest.fromJson(Map<String, dynamic> json) {
    return TyreRimsRequest(
      id: json['id'] ?? '',
      requestNumber: json['request_number'] ?? '',
      buyerId: json['buyer'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category'] ?? '',
      vehicleTypeId: json['vehicle_type'] ?? '',
      status: json['status'] ?? 'draft',
      priority: json['priority'] ?? 'medium',
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      responseDeadline: json['response_deadline'] != null ? DateTime.parse(json['response_deadline']) : null,
      preferredLocation: json['preferred_location'] != null
          ? LocationPoint.fromJson(json['preferred_location'])
          : null,
      maxDistanceKm: json['max_distance_km'] ?? 50,
      budgetMin: (json['budget_min'] != null) ? double.tryParse(json['budget_min'].toString()) : null,
      budgetMax: (json['budget_max'] != null) ? double.tryParse(json['budget_max'].toString()) : null,
      viewsCount: json['views_count'] ?? 0,
      quotesReceived: json['quotes_received'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request_number': requestNumber,
    'buyer': buyerId,
    'title': title,
    'description': description,
    'category': categoryId,
    'vehicle_type': vehicleTypeId,
    'status': status,
    'priority': priority,
    'expires_at': expiresAt?.toIso8601String(),
    'response_deadline': responseDeadline?.toIso8601String(),
    'preferred_location': preferredLocation?.toJson(),
    'max_distance_km': maxDistanceKm,
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'views_count': viewsCount,
    'quotes_received': quotesReceived,
  };
}

class TyreSpecification {
  final String id;
  final String requestId;
  final int width;
  final int aspectRatio;
  final int diameter;
  final String loadIndex;
  final String speedRating;
  final String construction; // e.g., 'radial'
  final bool runFlat;
  final bool tubeless;

  TyreSpecification({
    required this.id,
    required this.requestId,
    required this.width,
    required this.aspectRatio,
    required this.diameter,
    required this.loadIndex,
    required this.speedRating,
    required this.construction,
    required this.runFlat,
    required this.tubeless,
  });

  factory TyreSpecification.fromJson(Map<String, dynamic> json) => TyreSpecification(
    id: json['id'] ?? '',
    requestId: json['request'] ?? '',
    width: json['width'] ?? 0,
    aspectRatio: json['aspect_ratio'] ?? 0,
    diameter: json['diameter'] ?? 0,
    loadIndex: json['load_index'] ?? '',
    speedRating: json['speed_rating'] ?? '',
    construction: json['construction'] ?? '',
    runFlat: json['run_flat'] ?? false,
    tubeless: json['tubeless'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'request': requestId,
    'width': width,
    'aspect_ratio': aspectRatio,
    'diameter': diameter,
    'load_index': loadIndex,
    'speed_rating': speedRating,
    'construction': construction,
    'run_flat': runFlat,
    'tubeless': tubeless,
  };
}

class TyreRimsQuote {
  final String id;
  final String quoteNumber;
  final String requestId;
  final String sellerId;
  final double totalAmount;
  final String currency;
  final bool deliveryAvailable;
  final double? deliveryCost;
  final bool installationAvailable;
  final double? installationCost;
  final int? estimatedDeliveryDays;
  final DateTime validUntil;
  final String status;
  final String? notes;
  final String? termsAndConditions;
  final int? warrantyPeriodMonths;
  final String? warrantyDetails;

  TyreRimsQuote({
    required this.id,
    required this.quoteNumber,
    required this.requestId,
    required this.sellerId,
    required this.totalAmount,
    required this.currency,
    required this.deliveryAvailable,
    this.deliveryCost,
    required this.installationAvailable,
    this.installationCost,
    this.estimatedDeliveryDays,
    required this.validUntil,
    required this.status,
    this.notes,
    this.termsAndConditions,
    this.warrantyPeriodMonths,
    this.warrantyDetails,
  });

  factory TyreRimsQuote.fromJson(Map<String, dynamic> json) => TyreRimsQuote(
    id: json['id'] ?? '',
    quoteNumber: json['quote_number'] ?? '',
    requestId: json['request'] ?? '',
    sellerId: json['seller'] ?? '',
    totalAmount: (json['total_amount'] ?? 0).toDouble(),
    currency: json['currency'] ?? '',
    deliveryAvailable: json['delivery_available'] ?? false,
    deliveryCost: (json['delivery_cost'] ?? 0).toDouble(),
    installationAvailable: json['installation_available'] ?? false,
    installationCost: (json['installation_cost'] ?? 0).toDouble(),
    estimatedDeliveryDays: json['estimated_delivery_days'],
    validUntil: DateTime.parse(json['valid_until'] ?? DateTime.now().toIso8601String()),
    status: json['status'] ?? '',
    notes: json['notes'],
    termsAndConditions: json['terms_and_conditions'],
    warrantyPeriodMonths: json['warranty_period_months'],
    warrantyDetails: json['warranty_details'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'quote_number': quoteNumber,
    'request': requestId,
    'seller': sellerId,
    'total_amount': totalAmount,
    'currency': currency,
    'delivery_available': deliveryAvailable,
    'delivery_cost': deliveryCost,
    'installation_available': installationAvailable,
    'installation_cost': installationCost,
    'estimated_delivery_days': estimatedDeliveryDays,
    'valid_until': validUntil.toIso8601String(),
    'status': status,
    'notes': notes,
    'terms_and_conditions': termsAndConditions,
    'warranty_period_months': warrantyPeriodMonths,
    'warranty_details': warrantyDetails,
  };
}
