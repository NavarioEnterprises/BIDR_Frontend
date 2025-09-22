import 'dart:convert';
import 'package:bidr/global_values.dart';
import 'package:http/http.dart' as http;
import '../models/faq.dart';

class FAQApiService {
  /// Fetch all FAQs
  Future<List<FAQ>?> fetchFAQs({String? category, String? search}) async {
    try {
      final Map<String, String> queryParams = {};
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${GlobalVariables.reviewsServiceUrl}api/faqs/')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('Fetch FAQs Response Status: ${response.statusCode}');
      print('Fetch FAQs Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Handle both paginated and non-paginated responses
        final List<dynamic> results = data.containsKey('results') 
            ? data['results'] 
            : data is List 
                ? data 
                : [];
                
        final faqs = results.map((faqJson) => FAQ.fromJson(faqJson)).toList();
        print('Fetched ${faqs.length} FAQs successfully');
        return faqs;
      } else {
        print('Failed to fetch FAQs: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred while fetching FAQs: $e');
      return null;
    }
  }

  /// Fetch FAQ categories
  Future<List<FAQCategory>?> fetchFAQCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.reviewsServiceUrl}api/faqs/categories/'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Fetch FAQ Categories Response Status: ${response.statusCode}');
      print('Fetch FAQ Categories Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final categories = data.map((categoryJson) => FAQCategory.fromJson(categoryJson)).toList();
        print('Fetched ${categories.length} FAQ categories successfully');
        return categories;
      } else {
        print('Failed to fetch FAQ categories: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred while fetching FAQ categories: $e');
      return null;
    }
  }

  /// Search FAQs
  Future<List<FAQ>?> searchFAQs(String query) async {
    if (query.trim().isEmpty) {
      return fetchFAQs();
    }

    try {
      final response = await http.get(
        Uri.parse('${GlobalVariables.reviewsServiceUrl}api/faqs/')
            .replace(queryParameters: {'search': query.trim()}),
        headers: {'Content-Type': 'application/json'},
      );

      print('Search FAQs Response Status: ${response.statusCode}');
      print('Search FAQs Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Handle both paginated and non-paginated responses
        final List<dynamic> results = data.containsKey('results') 
            ? data['results'] 
            : data is List 
                ? data 
                : [];
                
        final faqs = results.map((faqJson) => FAQ.fromJson(faqJson)).toList();
        print('Found ${faqs.length} FAQs matching search query');
        return faqs;
      } else {
        print('Failed to search FAQs: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error occurred while searching FAQs: $e');
      return null;
    }
  }

  /// Get FAQs by category
  Future<List<FAQ>?> getFAQsByCategory(String category) async {
    if (category.toLowerCase() == 'all') {
      return fetchFAQs();
    }
    return fetchFAQs(category: category);
  }
}
