
class VehicleMake {
  final String id;
  final String name;
  final String? countryOfOrigin;
  final bool isActive;

  VehicleMake({
    required this.id,
    required this.name,
    this.countryOfOrigin,
    this.isActive = true,
  });

  factory VehicleMake.fromJson(Map<String, dynamic> json) => VehicleMake(
    id: json['id'],
    name: json['name'],
    countryOfOrigin: json['country_of_origin'],
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country_of_origin': countryOfOrigin,
    'is_active': isActive,
  };
}

class VehicleModel {
  final String id;
  final VehicleMake make;
  final String name;
  final int? yearFrom;
  final int? yearTo;
  final bool isActive;

  VehicleModel({
    required this.id,
    required this.make,
    required this.name,
    this.yearFrom,
    this.yearTo,
    this.isActive = true,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
    id: json['id'],
    make: VehicleMake.fromJson(json['make']),
    name: json['name'],
    yearFrom: json['year_from'],
    yearTo: json['year_to'],
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'make': make.toJson(),
    'name': name,
    'year_from': yearFrom,
    'year_to': yearTo,
    'is_active': isActive,
  };
}

class SparePartCategory {
  final String id;
  final String name;
  final String categoryType;
  final SparePartCategory? parentCategory;
  final String? description;
  final bool isActive;

  SparePartCategory({
    required this.id,
    required this.name,
    required this.categoryType,
    this.parentCategory,
    this.description,
    this.isActive = true,
  });

  factory SparePartCategory.fromJson(Map<String, dynamic> json) => SparePartCategory(
    id: json['id'],
    name: json['name'],
    categoryType: json['category_type'],
    parentCategory: json['parent_category'] != null
        ? SparePartCategory.fromJson(json['parent_category'])
        : null,
    description: json['description'],
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category_type': categoryType,
    'parent_category': parentCategory?.toJson(),
    'description': description,
    'is_active': isActive,
  };
}

class SparePartBrand {
  final String id;
  final String name;
  final String? countryOfOrigin;
  final bool isOem;
  final bool isActive;

  SparePartBrand({
    required this.id,
    required this.name,
    this.countryOfOrigin,
    this.isOem = false,
    this.isActive = true,
  });

  factory SparePartBrand.fromJson(Map<String, dynamic> json) => SparePartBrand(
    id: json['id'],
    name: json['name'],
    countryOfOrigin: json['country_of_origin'],
    isOem: json['is_oem'] ?? false,
    isActive: json['is_active'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country_of_origin': countryOfOrigin,
    'is_oem': isOem,
    'is_active': isActive,
  };
}

class VehicleSpareRequest {
  final String id;
  final String requestNumber;
  final String title;
  final String description;
  final SparePartCategory category;
  final VehicleMake vehicleMake;
  final VehicleModel vehicleModel;
  final int vehicleYear;
  final String? vinNumber;
  final String? transmissionType;
  final String? fuelType;
  final String? bodyType;
  final int? mileage;
  final String partName;
  final String? partNumber;
  final List<SparePartBrand> preferredBrands;
  final String partCondition;
  final int quantity;
  final String status;
  final String priority;
  final LocationPoint? buyerLocation;
  final int maxDistanceKm;
  final bool deliveryRequired;
  final bool installationRequired;
  final DateTime? neededByDate;
  final DateTime? expiresAt;
  final int enquiryTimeHours;
  final double? budgetMin;
  final double? budgetMax;
  final int viewsCount;
  final int quotesReceived;

  VehicleSpareRequest({
    required this.id,
    required this.requestNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    this.vinNumber,
    this.transmissionType,
    this.fuelType,
    this.bodyType,
    this.mileage,
    required this.partName,
    this.partNumber,
    this.preferredBrands = const [],
    required this.partCondition,
    required this.quantity,
    required this.status,
    required this.priority,
    this.buyerLocation,
    this.maxDistanceKm = 50,
    this.deliveryRequired = false,
    this.installationRequired = false,
    this.neededByDate,
    this.expiresAt,
    this.enquiryTimeHours = 24,
    this.budgetMin,
    this.budgetMax,
    this.viewsCount = 0,
    this.quotesReceived = 0,
  });

  factory VehicleSpareRequest.fromJson(Map<String, dynamic> json) {
    return VehicleSpareRequest(
      id: json['id'],
      requestNumber: json['request_number'],
      title: json['title'],
      description: json['description'],
      category: SparePartCategory.fromJson(json['category']),
      vehicleMake: VehicleMake.fromJson(json['vehicle_make']),
      vehicleModel: VehicleModel.fromJson(json['vehicle_model']),
      vehicleYear: json['vehicle_year'],
      vinNumber: json['vin_number'],
      transmissionType: json['transmission_type'],
      fuelType: json['fuel_type'],
      bodyType: json['body_type'],
      mileage: json['mileage'],
      partName: json['part_name'],
      partNumber: json['part_number'],
      preferredBrands: (json['preferred_brands'] as List<dynamic>?)
          ?.map((e) => SparePartBrand.fromJson(e))
          .toList() ??
          [],
      partCondition: json['part_condition'],
      quantity: json['quantity'],
      status: json['status'],
      priority: json['priority'],
      buyerLocation: json['buyer_location'] != null
          ? LocationPoint.fromJson(json['buyer_location'])
          : null,
      maxDistanceKm: json['max_distance_km'] ?? 50,
      deliveryRequired: json['delivery_required'] ?? false,
      installationRequired: json['installation_required'] ?? false,
      neededByDate: json['needed_by_date'] != null
          ? DateTime.parse(json['needed_by_date'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      enquiryTimeHours: json['enquiry_time_hours'] ?? 24,
      budgetMin: json['budget_min']?.toDouble(),
      budgetMax: json['budget_max']?.toDouble(),
      viewsCount: json['views_count'] ?? 0,
      quotesReceived: json['quotes_received'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'request_number': requestNumber,
    'title': title,
    'description': description,
    'category': category.toJson(),
    'vehicle_make': vehicleMake.toJson(),
    'vehicle_model': vehicleModel.toJson(),
    'vehicle_year': vehicleYear,
    'vin_number': vinNumber,
    'transmission_type': transmissionType,
    'fuel_type': fuelType,
    'body_type': bodyType,
    'mileage': mileage,
    'part_name': partName,
    'part_number': partNumber,
    'preferred_brands': preferredBrands.map((b) => b.toJson()).toList(),
    'part_condition': partCondition,
    'quantity': quantity,
    'status': status,
    'priority': priority,
    'buyer_location': buyerLocation?.toJson(),
    'max_distance_km': maxDistanceKm,
    'delivery_required': deliveryRequired,
    'installation_required': installationRequired,
    'needed_by_date': neededByDate?.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
    'enquiry_time_hours': enquiryTimeHours,
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'views_count': viewsCount,
    'quotes_received': quotesReceived,
  };
}

class LocationPoint{
  final double latitude;
  final double longitude;

  LocationPoint({required this.latitude, required this.longitude});

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: json['latitude'],
    longitude: json['longitude'],
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

class SpareRequestImage {
  final String id;
  final String requestId;
  final String image;
  final String? caption;
  final bool isPrimary;
  final int order;

  SpareRequestImage({
    required this.id,
    required this.requestId,
    required this.image,
    this.caption,
    this.isPrimary = false,
    this.order = 0,
  });

  factory SpareRequestImage.fromJson(Map<String, dynamic> json) => SpareRequestImage(
    id: json['id'],
    requestId: json['request'],
    image: json['image'],
    caption: json['caption'],
    isPrimary: json['is_primary'] ?? false,
    order: json['order'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'request': requestId,
    'image': image,
    'caption': caption,
    'is_primary': isPrimary,
    'order': order,
  };
}

class SpareQuote {
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

  SpareQuote({
    required this.id,
    required this.quoteNumber,
    required this.requestId,
    required this.sellerId,
    required this.totalAmount,
    required this.currency,
    this.deliveryAvailable = false,
    this.deliveryCost,
    this.installationAvailable = false,
    this.installationCost,
    this.estimatedDeliveryDays,
    required this.validUntil,
    required this.status,
    this.notes,
    this.termsAndConditions,
    this.warrantyPeriodMonths,
    this.warrantyDetails,
  });

  factory SpareQuote.fromJson(Map<String, dynamic> json) => SpareQuote(
    id: json['id'],
    quoteNumber: json['quote_number'],
    requestId: json['request'],
    sellerId: json['seller'],
    totalAmount: (json['total_amount'] as num).toDouble(),
    currency: json['currency'],
    deliveryAvailable: json['delivery_available'] ?? false,
    deliveryCost: json['delivery_cost']?.toDouble(),
    installationAvailable: json['installation_available'] ?? false,
    installationCost: json['installation_cost']?.toDouble(),
    estimatedDeliveryDays: json['estimated_delivery_days'],
    validUntil: DateTime.parse(json['valid_until']),
    status: json['status'],
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

class SpareQuoteItem {
  final String id;
  final String quoteId;
  final String partName;
  final String? partNumber;
  final SparePartBrand? brand;
  final String? model;
  final String? specifications;
  final String condition;
  final String? compatibleVehicles;
  final String? oemNumber;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? availability;
  final String? stockLocation;

  SpareQuoteItem({
    required this.id,
    required this.quoteId,
    required this.partName,
    this.partNumber,
    this.brand,
    this.model,
    this.specifications,
    required this.condition,
    this.compatibleVehicles,
    this.oemNumber,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.availability,
    this.stockLocation,
  });

  factory SpareQuoteItem.fromJson(Map<String, dynamic> json) => SpareQuoteItem(
    id: json['id'],
    quoteId: json['quote'],
    partName: json['part_name'],
    partNumber: json['part_number'],
    brand: json['brand'] != null
        ? SparePartBrand.fromJson(json['brand'])
        : null,
    model: json['model'],
    specifications: json['specifications'],
    condition: json['condition'],
    compatibleVehicles: json['compatible_vehicles'],
    oemNumber: json['oem_number'],
    quantity: json['quantity'],
    unitPrice: (json['unit_price'] as num).toDouble(),
    totalPrice: (json['total_price'] as num).toDouble(),
    availability: json['availability'],
    stockLocation: json['stock_location'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'quote': quoteId,
    'part_name': partName,
    'part_number': partNumber,
    'brand': brand?.toJson(),
    'model': model,
    'specifications': specifications,
    'condition': condition,
    'compatible_vehicles': compatibleVehicles,
    'oem_number': oemNumber,
    'quantity': quantity,
    'unit_price': unitPrice,
    'total_price': totalPrice,
    'availability': availability,
    'stock_location': stockLocation,
  };
}

class Transaction {
  final String id;
  final String transactionNumber;
  final String quoteId;
  final String buyerId;
  final String sellerId;
  final double totalAmount;
  final double platformFee;
  final double sellerAmount;
  final String status;
  final String paymentStatus;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final String? buyerPin;
  final String? sellerPin;
  final DateTime? pinSharedAt;
  final DateTime? pinConfirmedAt;
  final String? deliveryAddress;
  final String? trackingNumber;
  final DateTime? deliveredAt;

  Transaction({
    required this.id,
    required this.transactionNumber,
    required this.quoteId,
    required this.buyerId,
    required this.sellerId,
    required this.totalAmount,
    this.platformFee = 0.0,
    required this.sellerAmount,
    required this.status,
    required this.paymentStatus,
    this.confirmedAt,
    this.completedAt,
    this.buyerPin,
    this.sellerPin,
    this.pinSharedAt,
    this.pinConfirmedAt,
    this.deliveryAddress,
    this.trackingNumber,
    this.deliveredAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    transactionNumber: json['transaction_number'],
    quoteId: json['quote'],
    buyerId: json['buyer'],
    sellerId: json['seller'],
    totalAmount: (json['total_amount'] as num).toDouble(),
    platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
    sellerAmount: (json['seller_amount'] as num).toDouble(),
    status: json['status'],
    paymentStatus: json['payment_status'],
    confirmedAt: json['confirmed_at'] != null
        ? DateTime.parse(json['confirmed_at'])
        : null,
    completedAt: json['completed_at'] != null
        ? DateTime.parse(json['completed_at'])
        : null,
    buyerPin: json['buyer_pin'],
    sellerPin: json['seller_pin'],
    pinSharedAt: json['pin_shared_at'] != null
        ? DateTime.parse(json['pin_shared_at'])
        : null,
    pinConfirmedAt: json['pin_confirmed_at'] != null
        ? DateTime.parse(json['pin_confirmed_at'])
        : null,
    deliveryAddress: json['delivery_address'],
    trackingNumber: json['tracking_number'],
    deliveredAt: json['delivered_at'] != null
        ? DateTime.parse(json['delivered_at'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_number': transactionNumber,
    'quote': quoteId,
    'buyer': buyerId,
    'seller': sellerId,
    'total_amount': totalAmount,
    'platform_fee': platformFee,
    'seller_amount': sellerAmount,
    'status': status,
    'payment_status': paymentStatus,
    'confirmed_at': confirmedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'buyer_pin': buyerPin,
    'seller_pin': sellerPin,
    'pin_shared_at': pinSharedAt?.toIso8601String(),
    'pin_confirmed_at': pinConfirmedAt?.toIso8601String(),
    'delivery_address': deliveryAddress,
    'tracking_number': trackingNumber,
    'delivered_at': deliveredAt?.toIso8601String(),
  };
}

class SpareRating {
  final String id;
  final String transactionId;
  final String ratingType;
  final String raterId;
  final String ratedUserId;
  final int overallRating;
  final int? communicationRating;
  final int? qualityRating;
  final int? deliveryRating;
  final int? valueRating;
  final String? reviewText;
  final bool isVerified;
  final bool isPublic;

  SpareRating({
    required this.id,
    required this.transactionId,
    required this.ratingType,
    required this.raterId,
    required this.ratedUserId,
    required this.overallRating,
    this.communicationRating,
    this.qualityRating,
    this.deliveryRating,
    this.valueRating,
    this.reviewText,
    this.isVerified = true,
    this.isPublic = true,
  });

  factory SpareRating.fromJson(Map<String, dynamic> json) => SpareRating(
    id: json['id'],
    transactionId: json['transaction'],
    ratingType: json['rating_type'],
    raterId: json['rater'],
    ratedUserId: json['rated_user'],
    overallRating: json['overall_rating'],
    communicationRating: json['communication_rating'],
    qualityRating: json['quality_rating'],
    deliveryRating: json['delivery_rating'],
    valueRating: json['value_rating'],
    reviewText: json['review_text'],
    isVerified: json['is_verified'] ?? true,
    isPublic: json['is_public'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction': transactionId,
    'rating_type': ratingType,
    'rater': raterId,
    'rated_user': ratedUserId,
    'overall_rating': overallRating,
    'communication_rating': communicationRating,
    'quality_rating': qualityRating,
    'delivery_rating': deliveryRating,
    'value_rating': valueRating,
    'review_text': reviewText,
    'is_verified': isVerified,
    'is_public': isPublic,
  };
}


class SpareDispute {
  final String id;
  final String disputeNumber;
  final String transactionId;
  final String disputeType;
  final String raisedById;
  final String description;
  final String status;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final String? resolvedById;

  SpareDispute({
    required this.id,
    required this.disputeNumber,
    required this.transactionId,
    required this.disputeType,
    required this.raisedById,
    required this.description,
    required this.status,
    this.resolutionNotes,
    this.resolvedAt,
    this.resolvedById,
  });

  factory SpareDispute.fromJson(Map<String, dynamic> json) => SpareDispute(
    id: json['id'],
    disputeNumber: json['dispute_number'],
    transactionId: json['transaction'],
    disputeType: json['dispute_type'],
    raisedById: json['raised_by'],
    description: json['description'],
    status: json['status'],
    resolutionNotes: json['resolution_notes'],
    resolvedAt: json['resolved_at'] != null
        ? DateTime.parse(json['resolved_at'])
        : null,
    resolvedById: json['resolved_by'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'dispute_number': disputeNumber,
    'transaction': transactionId,
    'dispute_type': disputeType,
    'raised_by': raisedById,
    'description': description,
    'status': status,
    'resolution_notes': resolutionNotes,
    'resolved_at': resolvedAt?.toIso8601String(),
    'resolved_by': resolvedById,
  };
}

class SpareNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? relatedRequestId;
  final String? relatedQuoteId;
  final String? relatedTransactionId;
  final String? relatedDisputeId;

  SpareNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.relatedRequestId,
    this.relatedQuoteId,
    this.relatedTransactionId,
    this.relatedDisputeId,
  });

  factory SpareNotification.fromJson(Map<String, dynamic> json) => SpareNotification(
    id: json['id'],
    userId: json['user'],
    title: json['title'],
    message: json['message'],
    type: json['type'],
    isRead: json['is_read'] ?? false,
    createdAt: DateTime.parse(json['created_at']),
    readAt: json['read_at'] != null
        ? DateTime.parse(json['read_at'])
        : null,
    relatedRequestId: json['related_request'],
    relatedQuoteId: json['related_quote'],
    relatedTransactionId: json['related_transaction'],
    relatedDisputeId: json['related_dispute'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': userId,
    'title': title,
    'message': message,
    'type': type,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
    'related_request': relatedRequestId,
    'related_quote': relatedQuoteId,
    'related_transaction': relatedTransactionId,
    'related_dispute': relatedDisputeId,
  };
}

