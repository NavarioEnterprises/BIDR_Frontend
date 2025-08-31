import 'dart:convert';
import 'dart:typed_data';
import 'package:bidr/constants/Constants.dart';
import 'package:bidr/global_values.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

// Conditional imports
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class ApiService {
  /// Submit a vehicle spare parts request
  static Future<Map<String, dynamic>> submitVehicleRequest({
    // String? accessToken, // Remove JWT token parameter for now
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
  }) async {
    try {
      final uri = Uri.parse(
        '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/',
      );

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add headers without authentication for now
      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      // Remove token authentication for now
      // if (accessToken != null) {
      //   request.headers['Authorization'] = 'Bearer $accessToken';
      // }

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
        'currency': 'ZAR',

        // Location information
        'location_info': {
          'address': location.isNotEmpty
              ? location
              : 'Selected Location: ${locationLat ?? 0.0}, ${locationLng ?? 0.0}',
          'lat': locationLat ?? 0.0,
          'lng': locationLng ?? 0.0,
        },
      };

      // Add main form fields
      request.fields.addAll({
        'category': 'VEHICLE_SPARES',
        'title': partName.isNotEmpty ? partName : 'Vehicle Spare Request',
        'description': description,
        'buyer_location': jsonEncode({
          'address': location.isNotEmpty
              ? location
              : 'Selected Location: ${locationLat ?? 0.0}, ${locationLng ?? 0.0}',
          'lat': locationLat ?? 0.0,
          'lng': locationLng ?? 0.0,
        }),
        'condition_preference': _mapConditionPreference(selectedNewUsedPart),
        'quantity': selectedQuantity ?? '1',
        'urgency_timeline': _mapTimeframeToUrgency(selectedTimeframe),
        'max_travel_distance': maxDistance.round().toString(),
        'product_specifications': jsonEncode(vehicleSparesData),
        'terms_accepted': 'true',
        'contact_consent': 'true',
        'buyer_id': Constants.myUid,
        'auth_user_uid': Constants.myUid,
      });

      // Add vehicle_spares_data as a JSON string
      request.fields['vehicle_spares_data'] = jsonEncode(vehicleSparesData);

      print('=== DEBUG JSON FIELDS ===');

      // Test the original data before encoding
      String testBuyerLocation = jsonEncode({
        'address': location.isNotEmpty
            ? location
            : 'Selected Location: ${locationLat ?? 0.0}, ${locationLng ?? 0.0}',
        'lat': locationLat ?? 0.0,
        'lng': locationLng ?? 0.0,
      });

      String testVehicleData = jsonEncode(vehicleSparesData);

      print('TEST buyer_location: $testBuyerLocation');
      print('TEST vehicle_spares_data: $testVehicleData');

      print('ACTUAL buyer_location raw: ${request.fields['buyer_location']}');
      print(
        'ACTUAL product_specifications raw: ${request.fields['product_specifications']}',
      );
      print(
        'ACTUAL vehicle_spares_data raw: ${request.fields['vehicle_spares_data']}',
      );

      // Validate JSON strings
      try {
        jsonDecode(request.fields['buyer_location']!);
        print('✓ buyer_location is valid JSON');
      } catch (e) {
        print('✗ buyer_location JSON error: $e');
      }

      try {
        jsonDecode(request.fields['product_specifications']!);
        print('✓ product_specifications is valid JSON');
      } catch (e) {
        print('✗ product_specifications JSON error: $e');
      }

      try {
        jsonDecode(request.fields['vehicle_spares_data']!);
        print('✓ vehicle_spares_data is valid JSON');
      } catch (e) {
        print('✗ vehicle_spares_data JSON error: $e');
      }

      print('=== END DEBUG ===');

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
  ) async {
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
        return '12_HOURS'; // Map to 12_HOURS since 24_HOURS is not valid
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
    // String? accessToken, // Remove JWT token parameter for now
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
    // Add location parameters
    double? locationLat,
    double? locationLng,
    String? locationAddress,
  }) async {
    try {
      final uri = Uri.parse(
        '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/',
      );
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      // Remove token authentication for now
      // if (accessToken != null) {
      //   request.headers['Authorization'] = 'Bearer $accessToken';
      // }

      // Prepare electronics data
      Map<String, dynamic> electronicsData = {
        'electronics_type': _mapElectronicsType(electronicsType),
        'brand_preference': brandPreference,
        'model_series': modelSeries,
        'quantity_needed': int.tryParse(quantityNeeded) ?? 1,
        'currency': 'ZAR',
        'urgency': _mapElectronicsTimeframe(timeframe),
        'installation_required': installationRequired == 'Yes' ? 'YES' : 'NO',
        'required_features': requiredFeatures,
        'condition_preference': _mapElectronicsCondition(conditionPreference),
        'purpose_of_purchase': _mapPurposeOfPurchase(purposeOfPurchase),
        'additional_comments': additionalComments,
        'warranty_required': 'YES',
        'warranty_duration': '1 year',
        'energy_efficiency_required': 'NO',
      };

      // Add optional fields only if they have values
      if (minPrice.isNotEmpty) {
        final minPriceValue = double.tryParse(minPrice);
        if (minPriceValue != null) {
          electronicsData['min_price'] = minPriceValue;
        }
      }

      if (maxPrice.isNotEmpty) {
        final maxPriceValue = double.tryParse(maxPrice);
        if (maxPriceValue != null) {
          electronicsData['max_price'] = maxPriceValue;
        }
      }

      request.fields.addAll({
        'category': 'ELECTRONICS',
        'title': electronicsType.isNotEmpty
            ? '${electronicsType} Request'
            : 'Electronics Request',
        'description': requiredFeatures,
        'buyer_location': jsonEncode({
          'address': locationAddress ?? 'Default Location',
          'lat': locationLat ?? -26.2041, // Default Johannesburg coordinates
          'lng': locationLng ?? 28.0473,
        }),
        'condition_preference': _mapElectronicsCondition(conditionPreference),
        'quantity': (int.tryParse(quantityNeeded) ?? 1).toString(),
        'urgency_timeline': _mapElectronicsTimeframe(timeframe),
        'max_travel_distance': '50',
        'product_specifications': jsonEncode(electronicsData),
        'consumer_electronics_data': jsonEncode(electronicsData),
        'terms_accepted': 'true',
        'contact_consent': 'true',
        'buyer_id': '2',
        'auth_user_uid': Constants.myUid, // Add auth user UID from Constants
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
    // String? accessToken, // Remove JWT token parameter for now
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
    // Add location parameters
    double? locationLat,
    double? locationLng,
    String? locationAddress,
  }) async {
    try {
      final uri = Uri.parse(
        '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/',
      );
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Content-Type': 'multipart/form-data',
        'Accept': 'application/json',
      });

      // Remove token authentication for now
      // if (accessToken != null) {
      //   request.headers['Authorization'] = 'Bearer $accessToken';
      // }

      // Prepare tyres/rims data (remove null values to prevent JSON parsing issues)
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
        'currency': 'ZAR',
      };

      request.fields.addAll({
        'category': 'TYRES_RIMS',
        'title':
            '$tyreWidth/$sidewallProfile R$wheelRimDiameter $tyresRims Request',
        'description': description,
        'buyer_location': jsonEncode({
          'address': locationAddress ?? 'Default Location',
          'lat': locationLat ?? -26.2041, // Default Johannesburg coordinates
          'lng': locationLng ?? 28.0473,
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
        'auth_user_uid': Constants.myUid, // Add auth user UID from Constants
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
        return '1_WEEK';
      case 'within 2 weeks':
        return '1_WEEK';
      case 'within a month':
        return '1_MONTH';
      case 'within 3 months':
        return '1_MONTH';
      case 'no rush':
        return '1_MONTH';
      case 'asap':
        return 'ASAP';
      case '12 hours':
        return '12_HOURS';
      default:
        return '1_WEEK';
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

  /// Fetch product requests by auth_user_uid
  static Future<Map<String, dynamic>> getRequestsByBuyer({
    String? authUserUid,
  }) async {
    try {
      // Use the provided authUserUid or fall back to Constants.myUid
      final uid = authUserUid ?? Constants.myUid;

      final uri = Uri.parse(
        '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/by_auth_user/?auth_user_uid=$uid',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Get requests response status: ${response.statusCode}');
      print('Get requests response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch requests: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('Error fetching requests: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getRequestsBySeller({
    String? authUserUid,
  }) async {
    try {
      // Use the provided authUserUid or fall back to Constants.myUid
      final uid = authUserUid ?? Constants.myUid;

      // Get user location from Constants

      final myLat = Constants.myLatitude;
      final myLng = Constants.myLongitude;
      if (myLat == null || myLng == null) {
        return {
          'success': false,
          'message': 'User location not available',
          'error': 'Location data is null',
        };
      }
      print(
        "Fetching requests for seller UID: $uid at location ($myLat, $myLng) ${'${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/by_seller/?auth_user_uid=$uid&lat=$myLat&lng=$myLng'}",
      );

      final uri = Uri.parse(
        '${GlobalVariables.productsServiceUrl}api/v1/product-requests/requests/by_seller/?auth_user_uid=$uid&lat=$myLat&lng=$myLng',
      );
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Get requests response status: ${response.statusCode}');
      print('Get requests response body2: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch requests: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('Error fetching requests: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Submit a quote/bid for a product request
  static Future<Map<String, dynamic>> submitQuote({
    required String requestId,
    required double totalAmount,
    required int estimatedDeliveryDays,
    String? sellerNotes,
    String? warrantyInfo,
    String? currency = 'ZAR',
  }) async {
    if (kDebugMode) {
      print('Submitting quote for request: $requestId');
    }

    try {
      final url = '${GlobalVariables.productsServiceUrl}api/v1/quotes/quotes/';

      final quoteData = {
        'request_id': requestId,
        'seller_id': Constants.currentUser!.uid,
        'total_amount': totalAmount.toString(),
        'currency': currency,
        'estimated_delivery_days': estimatedDeliveryDays,
        'terms_conditions': '',
        'status': 'PENDING',
        'valid_until': DateTime.now().add(Duration(days: 30)).toIso8601String(),
      };

      // Add optional fields if provided
      if (sellerNotes != null && sellerNotes.isNotEmpty) {
        quoteData['seller_notes'] = sellerNotes;
      }

      if (warrantyInfo != null && warrantyInfo.isNotEmpty) {
        quoteData['warranty_info'] = warrantyInfo;
      }

      if (kDebugMode) {
        print('Quote data: $quoteData');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(quoteData),
      );

      if (kDebugMode) {
        print('Submit quote response status: ${response.statusCode}');
        print('Submit quote response body: ${response.body}');
      }

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Quote submitted successfully',
          'data': responseData,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': 'Failed to submit quote',
          'error': errorData,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Submit quote error: $e');
      }
      return {
        'success': false,
        'message': 'Failed to submit quote',
        'error': e.toString(),
      };
    }
  }

  /// Get quotes submitted by the current seller
  static Future<Map<String, dynamic>> getQuotesBySeller() async {
    if (kDebugMode) {
      print('Fetching quotes by seller');
    }

    try {
      if (Constants.currentUser?.uid == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
          'error': 'No user UID found',
        };
      }

      final url =
          '${GlobalVariables.productsServiceUrl}api/v1/quotes/quotes/by_seller/?auth_user_uid=${Constants.currentUser!.uid}';

      if (kDebugMode) {
        print('Get quotes by seller URL: $url');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (kDebugMode) {
        print('Get quotes by seller response status: ${response.statusCode}');
        print('Get quotes by seller response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle paginated response
        List<dynamic> quotes = [];
        if (responseData is Map && responseData.containsKey('results')) {
          quotes = responseData['results'];
        } else if (responseData is List) {
          quotes = responseData;
        }

        return {
          'success': true,
          'message': 'Quotes fetched successfully',
          'quotes': quotes,
          'total_count': responseData is Map
              ? (responseData['count'] ?? quotes.length)
              : quotes.length,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': 'Failed to fetch quotes',
          'error': errorData,
        };
      }
    } catch (e) {
      print('Get quotes by seller error: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      };
    }
  }

  /// Update order status after successful order creation
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    print('Updating order status for order: $orderId to status: $status');

    try {
      final url =
          '${GlobalVariables.productsServiceUrl}api/v1/product-requests/orders/$orderId/update_status/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      print('Update order status response status: ${response.statusCode}');
      print('Update order status response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Order status updated successfully',
          'data': responseData,
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': 'Failed to update order status: ${response.statusCode}',
          'error': errorData,
        };
      }
    } catch (e) {
      print('Update order status error: $e');
      return {
        'success': false,
        'message': 'Failed to update order status',
        'error': e.toString(),
      };
    }
  }
}
