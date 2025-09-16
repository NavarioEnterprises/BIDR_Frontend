import 'request_models.dart';

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
  final List<String>? productImages;
  final List<String>? images;
  final String? vinPhotoUrl;
  final Map<String, dynamic>? productSpecifications;
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
    this.productImages,
    this.images,
    this.vinPhotoUrl,
    this.productSpecifications,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility getter - maps quotes to sellerOffers
  List<QuoteItem> get sellerOffers => quotes;

  factory ProductRequestItem.fromJson(Map<String, dynamic> json) {
    return ProductRequestItem(
      requestId: json['request_id'] ?? '',
      buyerId:
          json['buyer_id'] != null && json['buyer_id'] is Map<String, dynamic>
          ? ApiUser.fromJson(json['buyer_id'])
          : null,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'],
      conditionPreference: json['condition_preference'],
      maxBudget: json['max_budget'] != null
          ? double.tryParse(json['max_budget'].toString())
          : null,
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
      productImages: (json['product_images'] as List<dynamic>?)
          ?.map((image) => image.toString())
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((image) => image.toString())
          .toList(),
      vinPhotoUrl: json['vin_photo_url'],
      productSpecifications:
          json['product_specifications'] as Map<String, dynamic>?,
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
      'product_images': productImages,
      'images': images,
      'vin_photo_url': vinPhotoUrl,
      'product_specifications': productSpecifications,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to convert urgency timeline from API format to display format
  String getUrgencyDisplay() {
    switch (urgencyTimeline) {
      case '1_WEEK':
        return '7 days';
      case '2_WEEKS':
        return '14 days';
      case '1_MONTH':
        return '1 month';
      case '24_HOURS':
        return '24 hours';
      case '12_HOURS':
        return '12 hours';
      default:
        return urgencyTimeline;
    }
  }

  // Helper method to extract mileage from product specifications
  String getMileage() {
    if (productSpecifications != null) {
      // Try to get mileage from various possible fields
      final mileage =
          productSpecifications!['mileage']?.toString() ??
          productSpecifications!['vehicle_mileage']?.toString() ??
          '0';
      return mileage;
    }
    return '0';
  }

  // Convert ProductRequestItem to AutoSparesRequest format for compatibility with detail screens
  AutoSparesRequest toAutoSparesRequest() {
    // Extract vehicle and part information from product_specifications
    final specs = productSpecifications ?? {};

    // Create VehicleDetails from available data
    final vehicleDetails = VehicleDetails(
      vin: specs['vin_number']?.toString() ?? getVinNumber(),
      manufacturer: specs['vehicle_make']?.toString() ?? '',
      makeModel: specs['vehicle_model']?.toString() ?? '',
      type: _mapVehicleType(specs['vehicle_type']?.toString()),
      condition:
          specs['condition_preference']?.toString() ??
          conditionPreference ??
          '',
      year: specs['vehicle_year']?.toString() ?? '',
    );

    // Extract location info if available
    final locationInfo = specs['location_info'] as Map<String, dynamic>?;
    final locationAddress = locationInfo?['address']?.toString() ?? 'Unknown';

    // Create PartDetails from available data
    final partDetails = PartDetails(
      partName: specs['part_name']?.toString() ?? title,
      quantity: specs['quantity'] ?? quantity ?? 1,
      location: locationAddress,
      maxDistanceKm: 50.0, // Default value as seen in debug output
      urgency: getCountdownDisplay(),
      productDescription: specs['description']?.toString() ?? description,
      imageUrls: specs['product_images']?.cast<String>() ?? productImages ?? [],
    );

    // Create MoreFields from available data
    final moreFields = MoreFields(
      partNumber: specs['part_number']?.toString() ?? '',
      transmissionType: specs['transmission_type']?.toString() ?? 'Unknown',
      mileage: specs['mileage']?.toString() ?? '0',
      fuelType: specs['fuel_type']?.toString() ?? 'Unknown',
      bodyType: specs['body_type']?.toString() ?? 'Unknown',
      preferredBrand: specs['preferred_brand']?.toString() ?? '',
      fitmentRequired: specs['fitment_required']?.toString() ?? '',
      balancingRequired: specs['balancing_required']?.toString() ?? '',
      tyreRotationRequired: specs['tyre_rotation_required']?.toString() ?? '',
    );

    // Create AutoSpares object
    final autoSpares = AutoSpares(
      vehicleDetails: vehicleDetails,
      partDetails: partDetails,
      moreFields: moreFields,
    );

    // Return AutoSparesRequest
    return AutoSparesRequest(
      id: requestId,
      status: status,
      category: category,
      createdAt: createdAt,
      autoSpares: autoSpares,
      sellerOffers: quotes,
      productImages: productImages,
      images: images,
    );
  }

  // Helper method to map vehicle type from API to display format
  String _mapVehicleType(String? vehicleType) {
    switch (vehicleType) {
      case 'PASSENGER_CAR':
        return 'Passenger Car';
      case 'SUV':
        return 'SUV';
      case 'TRUCK':
        return 'Truck';
      case 'MOTORCYCLE':
        return 'Motorcycle';
      default:
        return vehicleType ?? 'Unknown';
    }
  }

  // Helper method to map urgency from specs format
  String? _mapUrgencyFromSpecs(String? urgency) {
    switch (urgency) {
      case '1_WEEK':
        return '1 Week';
      case '1_MONTH':
        return '1 Month';
      case '24_HOURS':
        return '24 Hours';
      case '12_HOURS':
        return '12 Hours';
      default:
        return urgency;
    }
  }

  // Get the duration in hours for countdown calculation
  int getUrgencyDurationInHours() {
    switch (urgencyTimeline) {
      case '1_WEEK':
        return 7 * 24; // 7 days * 24 hours
      case '2_WEEKS':
        return 14 * 24; // 14 days * 24 hours
      case '1_MONTH':
        return 30 * 24; // 30 days * 24 hours (approximate)
      case '24_HOURS':
        return 24;
      case '12_HOURS':
        return 12;
      case '6_HOURS':
        return 6;
      default:
        return 7 * 24; // Default to 1 week
    }
  }

  // Calculate remaining time from creation date
  Duration getRemainingTime() {
    final totalDuration = Duration(hours: getUrgencyDurationInHours());
    final deadline = createdAt.add(totalDuration);
    final now = DateTime.now();

    if (deadline.isBefore(now)) {
      return Duration.zero; // Expired
    }

    return deadline.difference(now);
  }

  // Get countdown display string
  String getCountdownDisplay() {
    final remaining = getRemainingTime();

    if (remaining == Duration.zero) {
      return "Expired";
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    if (days > 0) {
      return "${days}d ${hours}h ${minutes}m";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

  // Get countdown percentage (0.0 to 1.0) for circular progress
  double getCountdownPercentage() {
    final totalDuration = Duration(hours: getUrgencyDurationInHours());
    final remaining = getRemainingTime();

    if (remaining == Duration.zero) {
      return 0.0; // Expired
    }

    return remaining.inMilliseconds / totalDuration.inMilliseconds;
  }

  // Helper methods to extract additional details from product specifications
  String getEngineSize() {
    if (productSpecifications != null) {
      return productSpecifications!['engine_size']?.toString() ?? '';
    }
    return '';
  }

  String getVinNumber() {
    if (productSpecifications != null) {
      return productSpecifications!['vin_number']?.toString() ?? '';
    }
    return '';
  }

  String getPartCategory() {
    if (productSpecifications != null) {
      return productSpecifications!['part_category']?.toString() ?? '';
    }
    return '';
  }

  String getCompatibleModels() {
    if (productSpecifications != null) {
      return productSpecifications!['compatible_models']?.toString() ?? '';
    }
    return '';
  }

  String getPreferredBrand() {
    if (productSpecifications != null) {
      return productSpecifications!['preferred_brand']?.toString() ?? '';
    }
    return '';
  }

  String getAvoidBrands() {
    if (productSpecifications != null) {
      return productSpecifications!['avoid_brands']?.toString() ?? '';
    }
    return '';
  }

  String getInstallationRequired() {
    if (productSpecifications != null) {
      final value =
          productSpecifications!['installation_required']?.toString() ?? 'NO';
      return value == 'YES' ? 'Yes' : 'No';
    }
    return 'No';
  }

  String getWarrantyRequired() {
    if (productSpecifications != null) {
      final value =
          productSpecifications!['warranty_required']?.toString() ?? 'NO';
      return value == 'YES' ? 'Yes' : 'No';
    }
    return 'No';
  }

  String getWarrantyDuration() {
    if (productSpecifications != null) {
      return productSpecifications!['warranty_duration']?.toString() ?? '';
    }
    return '';
  }

  String getEnergyEfficiencyRequired() {
    if (productSpecifications != null) {
      final value =
          productSpecifications!['energy_efficiency_required']?.toString() ??
          'NO';
      return value == 'YES' ? 'Yes' : 'No';
    }
    return 'No';
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
  final String sellerNotes;
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
    required this.sellerNotes,
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
      sellerNotes: json['seller_notes'] ?? '',
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
