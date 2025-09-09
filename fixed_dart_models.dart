// Fixed Dart models for the BIDR quoting service
class Seller {
  final String name;
  final double bid;
  final DateTime bidTime;
  final double rating;
  final int maxRating;
  final String comment;
  final double radius;

  Seller({
    required this.name,
    required this.comment,
    required this.radius,
    required this.bid,
    required this.bidTime,
    required this.rating,
    required this.maxRating,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      name: json['name'] ?? "",
      comment: json['comment'] ?? "",
      radius: (json['radius'] as num?)?.toDouble() ?? 0.0,
      bid: (json['bid'] as num).toDouble(),
      bidTime: DateTime.parse(json['bid_time']),
      rating: (json['rating'] as num).toDouble(),
      maxRating: json['max_rating'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'comment': comment,
      'radius': radius,
      'bid': bid,
      'bid_time': bidTime.toIso8601String(),
      'rating': rating,
      'max_rating': maxRating,
    };
  }
}

// Auto Spares Models - These should be from quoting service only
class VehicleDetails {
  final String vin;
  final String manufacturer;
  final String makeModel;
  final String type; // e.g., SUV, Sedan
  final String condition; // e.g., New or Used
  final String year;

  VehicleDetails({
    required this.vin,
    required this.manufacturer,
    required this.makeModel,
    required this.type,
    required this.condition,
    required this.year,
  });

  factory VehicleDetails.fromJson(Map<String, dynamic> json) {
    return VehicleDetails(
      vin: json['vin'] ?? "",
      manufacturer: json['manufacturer'] ?? "",
      makeModel: json['make_model'] ?? "",
      type: json['type'] ?? "",
      condition: json['condition'] ?? "",
      year: json['year'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vin': vin,
      'manufacturer': manufacturer,
      'make_model': makeModel,
      'type': type,
      'condition': condition,
      'year': year,
    };
  }
}

class PartDetails {
  final String partName;
  final int quantity;
  final String location;
  final double maxDistanceKm;
  final String urgency; // e.g., "Immediately", "1-2 weeks"
  final String productDescription;
  final List<String> imageUrls; // URLs or file paths

  PartDetails({
    required this.partName,
    required this.quantity,
    required this.location,
    required this.maxDistanceKm,
    required this.urgency,
    required this.productDescription,
    required this.imageUrls,
  });

  factory PartDetails.fromJson(Map<String, dynamic> json) {
    return PartDetails(
      partName: json['part_name'] ?? "",
      quantity: json['quantity'] ?? 0,
      location: json['location'] ?? "",
      maxDistanceKm: (json['max_distance_km'] as num?)?.toDouble() ?? 0.0,
      urgency: json['urgency'] ?? "",
      productDescription: json['product_description'] ?? "",
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_name': partName,
      'quantity': quantity,
      'location': location,
      'max_distance_km': maxDistanceKm,
      'urgency': urgency,
      'product_description': productDescription,
      'image_urls': imageUrls,
    };
  }
}

class MoreFields {
  final String partNumber;
  final String transmissionType; // e.g., Manual or Automatic
  final String mileage;
  final String fuelType;
  final String bodyType;

  MoreFields({
    required this.partNumber,
    required this.transmissionType,
    required this.mileage,
    required this.fuelType,
    required this.bodyType,
  });

  factory MoreFields.fromJson(Map<String, dynamic> json) {
    return MoreFields(
      partNumber: json['part_number'] ?? "",
      transmissionType: json['transmission_type'] ?? "",
      mileage: json['mileage'] ?? "",
      fuelType: json['fuel_type'] ?? "",
      bodyType: json['body_type'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'part_number': partNumber,
      'transmission_type': transmissionType,
      'mileage': mileage,
      'fuel_type': fuelType,
      'body_type': bodyType,
    };
  }
}

class AutoSpares {
  final VehicleDetails vehicleDetails;
  final PartDetails partDetails;
  final MoreFields moreFields;

  AutoSpares({
    required this.vehicleDetails,
    required this.partDetails,
    required this.moreFields,
  });

  factory AutoSpares.fromJson(Map<String, dynamic> json) {
    return AutoSpares(
      vehicleDetails: VehicleDetails.fromJson(json['vehicle_details'] ?? {}),
      partDetails: PartDetails.fromJson(json['part_details'] ?? {}),
      moreFields: MoreFields.fromJson(json['more_fields'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_details': vehicleDetails.toJson(),
      'part_details': partDetails.toJson(),
      'more_fields': moreFields.toJson(),
    };
  }
}

class AutoSparesRequest {
  final int id;
  final String status;
  final String category;
  final DateTime createdAt;
  final AutoSpares autoSpares;
  final List<Seller> sellerOffers;

  AutoSparesRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.autoSpares,
    required this.sellerOffers,
    required this.category,
  });

  factory AutoSparesRequest.fromJson(Map<String, dynamic> json) {
    return AutoSparesRequest(
      id: json['id'] ?? 0,
      status: json['status'] ?? "",
      category: json['category'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
      autoSpares: AutoSpares.fromJson(json['auto_spares'] ?? {}),
      sellerOffers: (json['seller_offers'] as List<dynamic>? ?? [])
          .map((item) => Seller.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'auto_spares': autoSpares.toJson(),
      'seller_offers': sellerOffers.map((seller) => seller.toJson()).toList(),
    };
  }
}

// Consumer Electronics Models - From quoting service only
class ProductDetails {
  final String typeOfElectronics;
  final String brandPreference;
  final String? modelSeries;
  final int quantityNeeded;

  ProductDetails({
    required this.typeOfElectronics,
    required this.brandPreference,
    this.modelSeries,
    required this.quantityNeeded,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      typeOfElectronics: json['type_of_electronics'] ?? "",
      brandPreference: json['brand_preference'] ?? "",
      modelSeries: json['model_series'],
      quantityNeeded: json['quantity_needed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type_of_electronics': typeOfElectronics,
      'brand_preference': brandPreference,
      'model_series': modelSeries,
      'quantity_needed': quantityNeeded,
    };
  }
}

class BudgetTimeline {
  final double? minPrice;
  final double? maxPrice;
  final String urgency; // e.g., 'Within a week', 'Immediately'
  final bool needsInstallation;

  BudgetTimeline({
    this.minPrice,
    this.maxPrice,
    required this.urgency,
    required this.needsInstallation,
  });

  factory BudgetTimeline.fromJson(Map<String, dynamic> json) {
    return BudgetTimeline(
      minPrice: (json['min_price'] as num?)?.toDouble(),
      maxPrice: (json['max_price'] as num?)?.toDouble(),
      urgency: json['urgency'] ?? "",
      needsInstallation: json['needs_installation'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_price': minPrice,
      'max_price': maxPrice,
      'urgency': urgency,
      'needs_installation': needsInstallation,
    };
  }
}

class FeaturesAndSpecs {
  final String? requiredFeatures;
  final String conditionPreference; // e.g., 'New / Refurbished'
  final String purpose; // e.g., 'Home Use', 'Commercial'
  final List<String> documentsOrImages; // List of file paths or URLs
  final String? additionalComments;

  FeaturesAndSpecs({
    this.requiredFeatures,
    required this.conditionPreference,
    required this.purpose,
    required this.documentsOrImages,
    this.additionalComments,
  });

  factory FeaturesAndSpecs.fromJson(Map<String, dynamic> json) {
    return FeaturesAndSpecs(
      requiredFeatures: json['required_features'],
      conditionPreference: json['condition_preference'] ?? "",
      purpose: json['purpose'] ?? "",
      documentsOrImages: List<String>.from(json['documents_or_images'] ?? []),
      additionalComments: json['additional_comments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'required_features': requiredFeatures,
      'condition_preference': conditionPreference,
      'purpose': purpose,
      'documents_or_images': documentsOrImages,
      'additional_comments': additionalComments,
    };
  }
}

class ConsumerElectronics {
  final ProductDetails productDetails;
  final BudgetTimeline budgetTimeline;
  final FeaturesAndSpecs featuresAndSpecs;

  ConsumerElectronics({
    required this.productDetails,
    required this.budgetTimeline,
    required this.featuresAndSpecs,
  });

  factory ConsumerElectronics.fromJson(Map<String, dynamic> json) {
    return ConsumerElectronics(
      productDetails: ProductDetails.fromJson(json['product_details'] ?? {}),
      budgetTimeline: BudgetTimeline.fromJson(json['budget_timeline'] ?? {}),
      featuresAndSpecs: FeaturesAndSpecs.fromJson(json['features_and_specs'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_details': productDetails.toJson(),
      'budget_timeline': budgetTimeline.toJson(),
      'features_and_specs': featuresAndSpecs.toJson(),
    };
  }
}

class ConsumerElectronicsRequest {
  final int id;
  final DateTime createdAt;
  final String status;
  final String category;
  final ConsumerElectronics consumerElectronics;
  final List<Seller> sellerOffers;

  ConsumerElectronicsRequest({
    required this.id,
    required this.status,
    required this.category,
    required this.createdAt,
    required this.consumerElectronics,
    required this.sellerOffers,
  });

  factory ConsumerElectronicsRequest.fromJson(Map<String, dynamic> json) {
    return ConsumerElectronicsRequest(
      id: json['id'] ?? 0,
      status: json['status'] ?? "",
      category: json['category'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
      consumerElectronics: ConsumerElectronics.fromJson(json['consumer_electronics'] ?? {}),
      sellerOffers: (json['seller_offers'] as List<dynamic>? ?? [])
          .map((item) => Seller.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'consumer_electronics': consumerElectronics.toJson(),
      'seller_offers': sellerOffers.map((seller) => seller.toJson()).toList(),
    };
  }
}

// Vehicle Tyre and Rims Models - From quoting service only
class RimTyreProductDetails {
  final int tyreWidthMm;
  final String sidewallProfile;
  final String wheelRimDiameterInches;
  final String tyreType; // e.g., Tyres, Rims
  final int quantity;
  final String urgency; // e.g., 12 Hours, 1 Day

  RimTyreProductDetails({
    required this.tyreWidthMm,
    required this.sidewallProfile,
    required this.wheelRimDiameterInches,
    required this.tyreType,
    required this.quantity,
    required this.urgency,
  });

  factory RimTyreProductDetails.fromJson(Map<String, dynamic> json) {
    return RimTyreProductDetails(
      tyreWidthMm: json['tyre_width_mm'] ?? 0,
      sidewallProfile: json['sidewall_profile'] ?? "",
      wheelRimDiameterInches: json['wheel_rim_diameter_inches'] ?? "",
      tyreType: json['tyre_type'] ?? "",
      quantity: json['quantity'] ?? 0,
      urgency: json['urgency'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tyre_width_mm': tyreWidthMm,
      'sidewall_profile': sidewallProfile,
      'wheel_rim_diameter_inches': wheelRimDiameterInches,
      'tyre_type': tyreType,
      'quantity': quantity,
      'urgency': urgency,
    };
  }
}

class RimTyreMoreFields {
  final String description;
  final String vehicleType; // e.g., Passenger Car, SUV
  final String pitchCircleDiameter;
  final String preferredBrand;
  final String tyreConstructionType; // e.g., Radial
  final bool fitmentRequired;
  final bool balancingRequired;
  final bool tyreRotationRequired;
  final List<String> imageUrls; // file paths or URLs

  RimTyreMoreFields({
    required this.description,
    required this.vehicleType,
    required this.pitchCircleDiameter,
    required this.preferredBrand,
    required this.tyreConstructionType,
    required this.fitmentRequired,
    required this.balancingRequired,
    required this.tyreRotationRequired,
    required this.imageUrls,
  });

  factory RimTyreMoreFields.fromJson(Map<String, dynamic> json) {
    return RimTyreMoreFields(
      description: json['description'] ?? "",
      vehicleType: json['vehicle_type'] ?? "",
      pitchCircleDiameter: json['pitch_circle_diameter'] ?? "",
      preferredBrand: json['preferred_brand'] ?? "",
      tyreConstructionType: json['tyre_construction_type'] ?? "",
      fitmentRequired: json['fitment_required'] ?? false,
      balancingRequired: json['balancing_required'] ?? false,
      tyreRotationRequired: json['tyre_rotation_required'] ?? false,
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'vehicle_type': vehicleType,
      'pitch_circle_diameter': pitchCircleDiameter,
      'preferred_brand': preferredBrand,
      'tyre_construction_type': tyreConstructionType,
      'fitment_required': fitmentRequired,
      'balancing_required': balancingRequired,
      'tyre_rotation_required': tyreRotationRequired,
      'image_urls': imageUrls,
    };
  }
}

class RimTyre {
  final RimTyreProductDetails productDetails;
  final RimTyreMoreFields moreFields;

  RimTyre({
    required this.productDetails,
    required this.moreFields,
  });

  factory RimTyre.fromJson(Map<String, dynamic> json) {
    return RimTyre(
      productDetails: RimTyreProductDetails.fromJson(json['product_details'] ?? {}),
      moreFields: RimTyreMoreFields.fromJson(json['more_fields'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_details': productDetails.toJson(),
      'more_fields': moreFields.toJson(),
    };
  }
}

class RimTyreRequest {
  final int id;
  final String status;
  final String category;
  final DateTime createdAt;
  final RimTyre rimTyre;
  final List<Seller> sellerOffers;

  RimTyreRequest({
    required this.id,
    required this.status,
    required this.category,
    required this.createdAt,
    required this.rimTyre,
    required this.sellerOffers,
  });

  factory RimTyreRequest.fromJson(Map<String, dynamic> json) {
    return RimTyreRequest(
      id: json['id'] ?? 0,
      status: json['status'] ?? "",
      category: json['category'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
      rimTyre: RimTyre.fromJson(json['rim_tyre'] ?? {}),
      sellerOffers: (json['seller_offers'] as List<dynamic>? ?? [])
          .map((item) => Seller.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'rim_tyre': rimTyre.toJson(),
      'seller_offers': sellerOffers.map((seller) => seller.toJson()).toList(),
    };
  }
}

// Quoting Service Models - Core quote models that should integrate with backend
class Quote {
  final String referenceNumber;
  final String title;
  final String description;
  final String quoteType;
  final String supplierId;
  final double unitPrice;
  final int quantityQuoted;
  final double totalPrice;
  final double shippingCost;
  final double taxAmount;
  final double platformFee;
  final double finalTotal;
  final String deliveryMethod;
  final int estimatedDeliveryDays;
  final String deliveryTerms;
  final DateTime? validUntil;
  final String paymentTerms;
  final String status;
  final bool isBestPrice;
  final int? rankPosition;
  final bool viewedByRequester;
  final DateTime? requesterViewDate;
  final DateTime createdAt;

  Quote({
    required this.referenceNumber,
    required this.title,
    required this.description,
    required this.quoteType,
    required this.supplierId,
    required this.unitPrice,
    required this.quantityQuoted,
    required this.totalPrice,
    required this.shippingCost,
    required this.taxAmount,
    required this.platformFee,
    required this.finalTotal,
    required this.deliveryMethod,
    required this.estimatedDeliveryDays,
    required this.deliveryTerms,
    this.validUntil,
    required this.paymentTerms,
    required this.status,
    required this.isBestPrice,
    this.rankPosition,
    required this.viewedByRequester,
    this.requesterViewDate,
    required this.createdAt,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      referenceNumber: json['reference_number'] ?? "",
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      quoteType: json['quote_type'] ?? "",
      supplierId: json['supplier_id'] ?? "",
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantityQuoted: json['quantity_quoted'] ?? 0,
      totalPrice: (json['total_price'] as num).toDouble(),
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (json['final_total'] as num).toDouble(),
      deliveryMethod: json['delivery_method'] ?? "",
      estimatedDeliveryDays: json['estimated_delivery_days'] ?? 0,
      deliveryTerms: json['delivery_terms'] ?? "",
      validUntil: json['valid_until'] != null ? DateTime.parse(json['valid_until']) : null,
      paymentTerms: json['payment_terms'] ?? "",
      status: json['status'] ?? "",
      isBestPrice: json['is_best_price'] ?? false,
      rankPosition: json['rank_position'],
      viewedByRequester: json['viewed_by_requester'] ?? false,
      requesterViewDate: json['requester_view_date'] != null ? DateTime.parse(json['requester_view_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reference_number': referenceNumber,
      'title': title,
      'description': description,
      'quote_type': quoteType,
      'supplier_id': supplierId,
      'unit_price': unitPrice,
      'quantity_quoted': quantityQuoted,
      'total_price': totalPrice,
      'shipping_cost': shippingCost,
      'tax_amount': taxAmount,
      'platform_fee': platformFee,
      'final_total': finalTotal,
      'delivery_method': deliveryMethod,
      'estimated_delivery_days': estimatedDeliveryDays,
      'delivery_terms': deliveryTerms,
      'valid_until': validUntil?.toIso8601String(),
      'payment_terms': paymentTerms,
      'status': status,
      'is_best_price': isBestPrice,
      'rank_position': rankPosition,
      'viewed_by_requester': viewedByRequester,
      'requester_view_date': requesterViewDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Computed properties
  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  bool get isValid {
    return status == 'active' && !isExpired;
  }

  DateTime get estimatedDeliveryDate {
    return DateTime.now().add(Duration(days: estimatedDeliveryDays));
  }

  double get pricePerUnitWithExtras {
    if (quantityQuoted == 0) return 0.0;
    return finalTotal / quantityQuoted;
  }
}
