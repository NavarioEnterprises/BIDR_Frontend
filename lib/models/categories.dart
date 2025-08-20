
class ProductRequest {
  final String type;
  final String brand;
  final String model;
  final int quantity;
  final double minPrice;
  final double maxPrice;
  final String features;
  final String comments;
  final String timeframe;
  final String installation;
  final String condition;
  final String purpose;

  ProductRequest({
    required this.type,
    required this.brand,
    required this.model,
    required this.quantity,
    required this.minPrice,
    required this.maxPrice,
    required this.features,
    required this.comments,
    required this.timeframe,
    required this.installation,
    required this.condition,
    required this.purpose,
  });

  factory ProductRequest.fromJson(Map<String, dynamic> json) {
    return ProductRequest(
      type: json['type'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity'].toString()) ?? 0,
      minPrice: json['min_price'] is double
          ? json['min_price']
          : double.tryParse(json['min_price'].toString()) ?? 0.0,
      maxPrice: json['max_price'] is double
          ? json['max_price']
          : double.tryParse(json['max_price'].toString()) ?? 0.0,
      features: json['features'] ?? '',
      comments: json['comments'] ?? '',
      timeframe: json['timeframe'] ?? '',
      installation: json['installation'] ?? '',
      condition: json['condition'] ?? '',
      purpose: json['purpose'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'brand': brand,
      'model': model,
      'quantity': quantity,
      'min_price': minPrice,
      'max_price': maxPrice,
      'features': features,
      'comments': comments,
      'timeframe': timeframe,
      'installation': installation,
      'condition': condition,
      'purpose': purpose,
    };
  }
}

class TireProductQuoteForm {
  final String tyreWidth;
  final String description;
  final String preferredBrand;
  final String pcd;
  final String sidewallProfile;
  final String wheelRimDiameter;
  final String tyresRims;
  final String quantity;
  final String timeframe;
  final String vehicleType;
  final String tyreConstruction;
  final String fitmentRequired;
  final String balancingRequired;
  final String tyreRotation;

  TireProductQuoteForm({
    required this.tyreWidth,
    required this.description,
    required this.preferredBrand,
    required this.pcd,
    required this.sidewallProfile,
    required this.wheelRimDiameter,
    required this.tyresRims,
    required this.quantity,
    required this.timeframe,
    required this.vehicleType,
    required this.tyreConstruction,
    required this.fitmentRequired,
    required this.balancingRequired,
    required this.tyreRotation,
  });

  factory TireProductQuoteForm.fromJson(Map<String, dynamic> json) {
    return TireProductQuoteForm(
      tyreWidth: json['tyre_width'] ?? '',
      description: json['description'] ?? '',
      preferredBrand: json['preferred_brand'] ?? '',
      pcd: json['pcd'] ?? '',
      sidewallProfile: json['sidewall_profile'] ?? '',
      wheelRimDiameter: json['wheel_rim_diameter'] ?? '',
      tyresRims: json['tyres_rims'] ?? '',
      quantity: json['quantity'] ?? '',
      timeframe: json['timeframe'] ?? '',
      vehicleType: json['vehicle_type'] ?? '',
      tyreConstruction: json['tyre_construction'] ?? '',
      fitmentRequired: json['fitment_required'] ?? '',
      balancingRequired: json['balancing_required'] ?? '',
      tyreRotation: json['tyre_rotation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tyre_width': tyreWidth,
      'description': description,
      'preferred_brand': preferredBrand,
      'pcd': pcd,
      'sidewall_profile': sidewallProfile,
      'wheel_rim_diameter': wheelRimDiameter,
      'tyres_rims': tyresRims,
      'quantity': quantity,
      'timeframe': timeframe,
      'vehicle_type': vehicleType,
      'tyre_construction': tyreConstruction,
      'fitment_required': fitmentRequired,
      'balancing_required': balancingRequired,
      'tyre_rotation': tyreRotation,
    };
  }
}

class VehicleDetailsQuoteForm {
  final String vin;
  final String partName;
  final String location;
  final String description;
  final String partNumber;
  final String mileage;
  final String? manufacturer;
  final String? makeModel;
  final String? type;
  final String? newUsedPart;
  final String? year;
  final String? quantity;
  final String? timeframe;
  final String? transmissionType;
  final String? fuelType;
  final String? bodyType;
  final double maxDistance;

  VehicleDetailsQuoteForm({
    required this.vin,
    required this.partName,
    required this.location,
    required this.description,
    required this.partNumber,
    required this.mileage,
    this.manufacturer,
    this.makeModel,
    this.type,
    this.newUsedPart,
    this.year,
    this.quantity,
    this.timeframe,
    this.transmissionType,
    this.fuelType,
    this.bodyType,
    required this.maxDistance,
  });

  factory VehicleDetailsQuoteForm.fromJson(Map<String, dynamic> json) {
    return VehicleDetailsQuoteForm(
      vin: json['vin'] ?? '',
      partName: json['part_name'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      partNumber: json['part_number'] ?? '',
      mileage: json['mileage'] ?? '',
      manufacturer: json['manufacturer'],
      makeModel: json['make_model'],
      type: json['type'],
      newUsedPart: json['new_used_part'],
      year: json['year'],
      quantity: json['quantity'],
      timeframe: json['timeframe'],
      transmissionType: json['transmission_type'],
      fuelType: json['fuel_type'],
      bodyType: json['body_type'],
      maxDistance: (json['max_distance'] is double)
          ? json['max_distance']
          : double.tryParse(json['max_distance'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vin': vin,
      'part_name': partName,
      'location': location,
      'description': description,
      'part_number': partNumber,
      'mileage': mileage,
      'manufacturer': manufacturer,
      'make_model': makeModel,
      'type': type,
      'new_used_part': newUsedPart,
      'year': year,
      'quantity': quantity,
      'timeframe': timeframe,
      'transmission_type': transmissionType,
      'fuel_type': fuelType,
      'body_type': bodyType,
      'max_distance': maxDistance,
    };
  }
}



