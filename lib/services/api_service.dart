import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

// Conditional imports
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static const String requestsEndpoint = '/inventory/api/v1/requests/requests/';

  /// Submit a vehicle spare parts request
  static Future<Map<String, dynamic>> submitVehicleRequest({
    String? accessToken, // Add JWT token parameter
    required String? selectedManufacturer,
    required String? selectedMakeModel,
    required String? selectedYear,
    required String? selectedType,
    required String? selectedNewUsedPart,
    required String? selectedQuantity,
    required String? selectedTimeframe,
    required String? selectedTransmissionType,
    required String? selectedFuelType,
    required String? selectedBodyType,
    required String vinNumber,
    required String partName,
    required String partNumber,
    required String location,
    required String description,
    required String mileage,
    required double maxDistance,
    required List<XFile> images,
    required List<XFile> vinImages,
    // Add location coordinates parameters
    double? locationLat,
    double? locationLng,
  }) async
  {
    try {
      final uri = Uri.parse('$baseUrl$requestsEndpoint');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add headers including authentication
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Prepare vehicle spares data matching the VehicleSpares model exactly
      Map<String, dynamic> vehicleSparesData = {
        // Vehicle Information (required fields)
        'vehicle_make': selectedManufacturer ?? 'Unknown',
        'vehicle_model': selectedMakeModel ?? 'Unknown',
        'vehicle_year': selectedYear != null
            ? int.tryParse(selectedYear!) ?? 2020
            : 2020,
        'vehicle_type': _mapVehicleType(selectedType),

        // Engine and VIN information
        'engine_size': '', // Optional field
        'vin_number': vinNumber.isNotEmpty ? vinNumber : '',

        // Part specifications (required fields)
        'part_name': partName.isNotEmpty ? partName : 'Vehicle Part',
        'part_category': 'OTHER', // Default category
        'part_number': partNumber.isNotEmpty ? partNumber : '',

        // Request details (required fields)
        'quantity': selectedQuantity != null
            ? int.tryParse(selectedQuantity!) ?? 1
            : 1,
        'condition_preference': _mapConditionPreference(selectedNewUsedPart),
        'urgency': _mapTimeframeToUrgency(selectedTimeframe),

        // Additional details (optional fields)
        'description': description.isNotEmpty ? description : '',
        'compatible_models': '',
        'preferred_brand': '',
        'avoid_brands': '',

        // Installation and warranty (optional fields with proper defaults)
        'installation_required': 'NO',
        'warranty_required': 'NO',
        'warranty_duration': '',
        'energy_efficiency_required': 'NO',

        // Budget information (optional)
        'max_budget': null,
        'currency': 'ZAR',

        // Product images and location (optional)
        'product_images': null,
        'vin_photo': '',
        'location_info': {
          'address': location.isNotEmpty ? location : '',
          'lat': locationLat,
          'lng': locationLng,
        },
      };

      // Add main form fields
      request.fields.addAll({
        'category': 'VEHICLE_SPARES',
        'title': partName.isNotEmpty ? partName : 'Vehicle Spare Request',
        'description': description,
        'buyer_location': jsonEncode({
          'address': location,
          'latitude': locationLat,
          'longitude': locationLng,
        }), // buyer_location must be JSON
        'condition_preference': _mapConditionPreference(selectedNewUsedPart),
        'quantity': selectedQuantity ?? '1',
        'urgency_timeline': _mapTimeframeToUrgency(selectedTimeframe),
        'max_travel_distance': maxDistance.round().toString(),
        'product_specifications': jsonEncode(vehicleSparesData),
        'terms_accepted': 'true',
        'contact_consent': 'true',
        'buyer_id': '2', // Use testuser ID for now
      });

      // The backend expects vehicle_spares_data as a dictionary/object, not as individual fields
      // Since this is multipart form data, we'll add it as a JSON string that the serializer can parse
      request.fields['vehicle_spares_data'] = jsonEncode(vehicleSparesData);
      
      print('Added vehicle_spares_data as JSON:');
      print(jsonEncode(vehicleSparesData));
      print('All request fields: ${request.fields}');

      // Add image files (cross-platform)
      for (int i = 0; i < images.length; i++) {
        final multipartFile = await _createMultipartFile(
          images[i],
          'images',
          'image_$i.jpg',
        );
        request.files.add(multipartFile);
      }

      // Add VIN image files (cross-platform)
      for (int i = 0; i < vinImages.length; i++) {
        final multipartFile = await _createMultipartFile(
          vinImages[i],
          'vin_images',
          'vin_image_$i.jpg',
        );
        request.files.add(multipartFile);
      }

      // Debug: Print the vehicle_spares_data being sent
      print('Sending vehicle_spares_data: ${jsonEncode(vehicleSparesData)}');
      print(
        'Location data - lat: $locationLat, lng: $locationLng, address: $location',
      );
      print('buyer_location field: ${request.fields['buyer_location']}');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': 'Request submitted successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to submit request: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('Error submitting request: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Create MultipartFile for cross-platform support
  static Future<http.MultipartFile> _createMultipartFile(
    XFile file,
    String field,
    String filename,
  ) async
  {
    if (kIsWeb) {
      // For web platform - read as bytes
      final bytes = await file.readAsBytes();
      return http.MultipartFile.fromBytes(field, bytes, filename: filename);
    } else {
      // For mobile platforms - use path
      return await http.MultipartFile.fromPath(
        field,
        file.path,
        filename: filename,
      );
    }
  }

  /// Get JWT token for authentication
  static Future<String?> getJWTToken({
    String username = 'testuser',
    String password = 'testpass123',
  }) async
  {
    try {
      final uri = Uri.parse('$baseUrl/api/token/');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access'];
      } else {
        print('Failed to get JWT token: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting JWT token: $e');
      return null;
    }
  }

  /// Map condition preference to backend format
  static String _mapConditionPreference(String? condition) {
    switch (condition?.toUpperCase()) {
      case 'NEW':
        return 'NEW';
      case 'USED':
        return 'USED';
      case 'REFURBISHED':
        return 'REFURBISHED';
      case 'REMANUFACTURED':
        return 'REMANUFACTURED';
      default:
        return 'NEW'; // Default to NEW instead of ANY
    }
  }

  /// Map timeframe selection to urgency timeline values
  static String _mapTimeframeToUrgency(String? timeframe) {
    switch (timeframe) {
      case 'ASAP':
        return 'ASAP';
      case '12 Hours':
        return '12_HOURS';
      case '24 Hours':
        return '24_HOURS'; // Use 24_HOURS as valid option
      case '2-3 Days':
        return '1_WEEK';
      case '1 Week':
        return '1_WEEK';
      case '2 Weeks':
        return '1_MONTH'; // Map to 1_MONTH since 2_WEEKS is not valid
      case 'Within a Month':
        return '1_MONTH';
      default:
        return '1_WEEK'; // Default to 1_WEEK
    }
  }

  /// Map vehicle type to backend format
  static String _mapVehicleType(String? type) {
    switch (type?.toUpperCase()) {
      case 'SEDAN':
        return 'PASSENGER_CAR';
      case 'SUV':
        return 'SUV';
      case 'HATCHBACK':
        return 'PASSENGER_CAR';
      case 'COUPE':
        return 'PASSENGER_CAR';
      case 'TRUCK':
        return 'TRUCK';
      case 'VAN':
        return 'VAN';
      default:
        return 'PASSENGER_CAR';
    }
  }

  /// Submit Electronics request
  static Future<Map<String, dynamic>> submitElectronicsRequest({
    String? accessToken,
    required String electronicsType,
    required String brandPreference,
    required String modelSeries,
    required String quantityNeeded,
    required String minPrice,
    required String maxPrice,
    required String timeframe,
    required String installationRequired,
    required String conditionPreference,
    required String purposeOfPurchase,
    required String requiredFeatures,
    required String additionalComments,
    required List<XFile> images,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$requestsEndpoint');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Prepare electronics data
      Map<String, dynamic> electronicsData = {
        'electronics_type': _mapElectronicsType(electronicsType),
        'brand_preference': brandPreference,
        'model_series': modelSeries,
        'quantity_needed': int.tryParse(quantityNeeded) ?? 1,
        'min_price': minPrice.isNotEmpty ? double.tryParse(minPrice) : null,
        'max_price': maxPrice.isNotEmpty ? double.tryParse(maxPrice) : null,
        'currency': 'ZAR',
        'urgency': _mapElectronicsTimeframe(timeframe),
        'installation_required': installationRequired == 'Yes' ? 'YES' : 'NO',
        'required_features': requiredFeatures,
        'condition_preference': _mapElectronicsCondition(conditionPreference),
        'purpose_of_purchase': _mapPurposeOfPurchase(purposeOfPurchase),
        'additional_comments': additionalComments,
        'product_images': null,
        'delivery_location': null,
        'warranty_required': 'YES',
        'warranty_duration': '1 year',
        'energy_efficiency_required': 'NO',
      };

      request.fields.addAll({
        'category': 'ELECTRONICS',
        'title': electronicsType.isNotEmpty
            ? '$electronicsType Request'
            : 'Electronics Request',
        'description': requiredFeatures,
        'buyer_location': jsonEncode({
          'address': 'Default Location',
          'lat': null,
          'lng': null,
        }),
        'condition_preference': _mapElectronicsCondition(conditionPreference),
        'quantity': quantityNeeded,
        'urgency_timeline': _mapElectronicsTimeframe(timeframe),
        'max_travel_distance': '50',
        'product_specifications': jsonEncode(electronicsData),
        'consumer_electronics_data': jsonEncode(electronicsData),
        'terms_accepted': 'true',
        'contact_consent': 'true',
        'buyer_id': '2',
      });

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final multipartFile = await _createMultipartFile(
          images[i],
          'images',
          'electronics_image_$i.jpg',
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Electronics Response status: ${response.statusCode}');
      print('Electronics Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': 'Electronics request submitted successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to submit electronics request: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('Error submitting electronics request: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Submit Tyres/Rims request
  static Future<Map<String, dynamic>> submitTyresRimsRequest({
    String? accessToken,
    required String tyreWidth,
    required String sidewallProfile,
    required String wheelRimDiameter,
    required String tyresRims,
    required String quantity,
    required String timeframe,
    required String description,
    required String vehicleType,
    required String pcd,
    required String preferredBrand,
    required String tyreConstruction,
    required String fitmentRequired,
    required String balancingRequired,
    required String tyreRotation,
    required List<XFile> images,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$requestsEndpoint');
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      if (accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      // Prepare tyres/rims data
      Map<String, dynamic> tyresRimsData = {
        'tyre_width': int.tryParse(tyreWidth) ?? 195,
        'sidewall_profile': int.tryParse(sidewallProfile) ?? 55,
        'wheel_rim_diameter': int.tryParse(wheelRimDiameter) ?? 16,
        'select_tyres_rims': tyresRims,
        'quantity': int.tryParse(quantity) ?? 1,
        'urgency': _mapTimeframeToUrgency(timeframe),
        'description_of_item': description,
        'vehicle_type': _mapTyresVehicleType(vehicleType),
        'pitch_circle_diameter': pcd,
        'preferred_brand': preferredBrand,
        'tyre_construction_type': tyreConstruction.toUpperCase(),
        'fitment_required': fitmentRequired == 'Yes' ? 'YES' : 'NO',
        'balancing_required': balancingRequired == 'Yes' ? 'YES' : 'NO',
        'tyre_rotation_required': tyreRotation == 'Yes' ? 'YES' : 'NO',
        'delivery_location': null,
        'currency': 'ZAR',
        'max_budget': null,
      };

      request.fields.addAll({
        'category': 'TYRES_RIMS',
        'title':
            '$tyreWidth/$sidewallProfile R$wheelRimDiameter $tyresRims Request',
        'description': description,
        'buyer_location': jsonEncode({
          'address': 'Default Location',
          'lat': null,
          'lng': null,
        }),
        'condition_preference': 'NEW',
        'quantity': quantity,
        'urgency_timeline': _mapTimeframeToUrgency(timeframe),
        'max_travel_distance': '50',
        'product_specifications': jsonEncode(tyresRimsData),
        'vehicle_tyres_rims_data': jsonEncode(tyresRimsData),
        'terms_accepted': 'true',
        'contact_consent': 'true',
        'buyer_id': '2',
      });

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final multipartFile = await _createMultipartFile(
          images[i],
          'images',
          'tyres_image_$i.jpg',
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Tyres/Rims Response status: ${response.statusCode}');
      print('Tyres/Rims Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': 'Tyres/Rims request submitted successfully',
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to submit tyres/rims request: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('Error submitting tyres/rims request: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Map electronics type to backend format
  static String _mapElectronicsType(String type) {
    switch (type.toLowerCase()) {
      case 'washing machine':
        return 'WASHING_MACHINE';
      case 'refrigerator':
        return 'REFRIGERATOR';
      case 'television':
        return 'TELEVISION';
      case 'microwave':
        return 'MICROWAVE';
      case 'air conditioner':
        return 'AIR_CONDITIONER';
      case 'laptop':
        return 'LAPTOP';
      case 'smartphone':
        return 'SMARTPHONE';
      case 'tablet':
        return 'TABLET';
      default:
        return 'OTHER';
    }
  }

  /// Map electronics timeframe to urgency
  static String _mapElectronicsTimeframe(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'within a week':
        return 'WITHIN_WEEK';
      case 'within 2 weeks':
        return 'WITHIN_WEEK';
      case 'within a month':
        return 'WITHIN_MONTH';
      case 'within 3 months':
        return 'WITHIN_MONTH';
      case 'no rush':
        return 'FLEXIBLE';
      default:
        return 'WITHIN_WEEK';
    }
  }

  /// Map electronics condition preference
  static String _mapElectronicsCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'new / refurbished':
        return 'REFURBISHED';
      case 'new only':
        return 'NEW';
      case 'refurbished only':
        return 'REFURBISHED';
      case 'used acceptable':
        return 'USED';
      default:
        return 'NEW';
    }
  }

  /// Map purpose of purchase
  static String _mapPurposeOfPurchase(String purpose) {
    switch (purpose.toLowerCase()) {
      case 'home use':
        return 'HOME_USE';
      case 'business use':
        return 'BUSINESS_USE';
      case 'commercial use':
        return 'COMMERCIAL_USE';
      case 'industrial use':
        return 'COMMERCIAL_USE';
      default:
        return 'HOME_USE';
    }
  }

  /// Map tyres vehicle type
  static String _mapTyresVehicleType(String type) {
    switch (type.toLowerCase()) {
      case 'passenger car':
        return 'PASSENGER_CAR';
      case 'suv':
        return 'SUV';
      case 'truck':
        return 'TRUCK';
      case 'van':
        return 'VAN';
      case 'motorcycle':
        return 'MOTORCYCLE';
      case 'bus':
        return 'BUS';
      default:
        return 'PASSENGER_CAR';
    }
  }
}
