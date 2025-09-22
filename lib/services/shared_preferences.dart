import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

class Sharedprefs {
  static String sharedPreferenceUserLoggedInKey = "ISLOGGEDIN";
  static String sharedPreferenceUserRoleKey = "USERROLEKEY";
  static String sharedPreferenceUserNameKey1 = "USERNAMEKEY1";
  static String sharedPreferenceUserCaloriesKey = "USERCALORIESKEY";
  static String sharedPreferenceUserEmailKey = "USEREMAILKEY";
  static String sharedPreferenceUserEmailKey2 = "USEREMAILKEY";
  static String sharedPreferenceUidKey = "USEREUIDKEY";
  static String sharedPreferenceIdKey = "USEREIDKEY";
  static String sharedPreferenceBarcodeKey = "USEREBARCODEKEY";
  static String sharedPreferenceCellKey = "USERECELLKEY";
  static String sharedPreferenceEmpIdKey = "USEREEMPIDKEY";
  static String sharedPreferenceCecClientIdKey = "USERCECCLIENTIDKEY"; //
  static String sharedPasswordPrefKey = "USERPASSWORDKEY";
  static String sharedPreferenceUserAccessTokenKey = "USEREACCESSTOKENKEY";
  static String sharedPreferenceUserRefreshTokenKey = "USEREREFRESHTOKENKEY";
  static String sharedPreferenceBusinessUidKey = "USEREBUSINESSUIDKEY";
  static String sharedPreferenceBusinessIdKey = "USEREBUSINESSIDKEY";
  static String sharedPreferenceBusinessEmailKey = "USEREBUSINESEMAILKEY";
  static String sharedPreferenceBusinessNameKey = "USEREBUSINESSNAMEKEY";
  static String sharedPreferenceBusinessPhoneNumberKey =
      "USEREBUSINESSPHONENUMBERKEY";
  static String sharedPreferenceCompleteLoginDataKey =
      "USERCOMPLETELOGINDATAKEY";

  static Future<bool> saveUserLoggedInSharedPreference(
    bool isUserLoggedIn,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
      sharedPreferenceUserLoggedInKey,
      isUserLoggedIn,
    );
  }

  static Future<bool> saveUserAccessTokenSharedPreference(
    String accessToken,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceUserAccessTokenKey,
      accessToken,
    );
  }

  static Future<bool> saveUserRefreshTokenSharedPreference(
    String refreshToken,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceUserRefreshTokenKey,
      refreshToken,
    );
  }

  static Future<bool> saveUserRoleSharedPreference(String userRole) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserRoleKey, userRole);
  }

  static Future<bool> saveUserNameSharedPreference(String userName) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserNameKey1, userName);
  }

  static Future<bool> saveBusinessIdSharedPreference(int businessId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(sharedPreferenceBusinessIdKey, businessId);
  }

  static Future<bool> saveBusinessUidSharedPreference(
    String businessUid,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceBusinessUidKey,
      businessUid,
    );
  }

  static Future<bool> saveBusinessNameSharedPreference(
    String businessName,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceBusinessNameKey,
      businessName,
    );
  }

  static Future<bool> saveBusinessEmailSharedPreference(
    String businessEmail,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceBusinessEmailKey,
      businessEmail,
    );
  }

  static Future<bool> saveBusinessPhoneNumberSharedPreference(
    String businessPhone,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceBusinessPhoneNumberKey,
      businessPhone,
    );
  }

  static Future<bool> saveUserEmpIdSharedPreference(int cec_employeeid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(sharedPreferenceEmpIdKey, cec_employeeid);
  }

  static Future<bool> saveUserPasswordPreference(String password) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPasswordPrefKey, password);
  }

  static Future<bool> saveUserTargetCaloriesPreference(double calories) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setDouble(
      sharedPreferenceUserCaloriesKey,
      calories,
    );
  }

  static Future<bool> saveUserCecClientIdSharedPreference(
    int cec_client_id,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(
      sharedPreferenceCecClientIdKey,
      cec_client_id,
    );
  }

  static Future<bool> saveUserUidSharedPreference(String uid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUidKey, uid);
  }

  static Future<bool> saveUserIdSharedPreference(int id) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(sharedPreferenceIdKey, id);
  }

  static Future<bool> saveUserBarcodeSharedPreference(String uid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceBarcodeKey, uid);
  }

  static Future<bool> saveUserEmailSharedPreference(String userEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserEmailKey, userEmail);
  }

  static Future<bool> saveUserEmailSharedPreference2(String userEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceUserEmailKey2,
      userEmail,
    );
  }

  static Future<bool> saveUserCellSharedPreference(String userCell) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceCellKey, userCell);
  }

  static Future<bool> saveCompleteLoginDataSharedPreference(
    String loginData,
  ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
      sharedPreferenceCompleteLoginDataKey,
      loginData,
    );
  }

  //Get Prefs
  static Future<int?> getBusinessIdSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceBusinessIdKey);
  }

  static Future<String?> getBusinessUidSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessUidKey);
  }

  static Future<String?> getBusinessNameSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessNameKey);
  }

  static Future<String?> getBusinessEmailSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessEmailKey);
  }

  static Future<String?> getBusinessPhoneNumberSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBusinessPhoneNumberKey);
  }

  static Future<bool?> getUserLoggedInSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getBool(sharedPreferenceUserLoggedInKey);
  }

  static Future<String?> getUserAccessTokenSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserAccessTokenKey);
  }

  static Future<String?> getUserRefreshTokenSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserRefreshTokenKey);
  }

  static Future<String?> getUserNameSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserNameKey1);
  }

  static Future<String?> getUserRoleSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserRoleKey);
  }

  static Future<int?> getEmpIdSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceEmpIdKey);
  }

  static Future<double?> getUserCaloriesSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getDouble(sharedPreferenceUserCaloriesKey);
  }

  static Future<int?> getCecClientIdSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceCecClientIdKey);
  }

  static Future<String?> getUserEmailSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserEmailKey);
  }

  static Future<String?> getUserEmailSharedPreference2() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUserEmailKey2);
  }

  static Future<String?> getUserCellSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceCellKey);
  }

  static Future<String?> getUserUidSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceUidKey);
  }

  static Future<int?> getUserIdSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getInt(sharedPreferenceIdKey);
  }

  static Future<String?> getUserBarcodeSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceBarcodeKey);
  }

  static Future<String?> getUserPasswordPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPasswordPrefKey);
  }

  static Future<String?> getCompleteLoginDataSharedPreference() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.getString(sharedPreferenceCompleteLoginDataKey);
  }
}

class EncryptedSharedPreferences {
  static final key = encrypt.Key.fromUtf8("GP3sP7n9yCC&E)H@TcQfTj4nZT4u7x!A");
  static final iv = encrypt.IV.fromLength(16);
  static final encrypter = encrypt.Encrypter(encrypt.AES(key));

  static Future<bool> saveEncryptedString(String key, String value) async {
    final encryptedValue = encrypter.encrypt(value, iv: iv).base64;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, encryptedValue);
  }

  static Future<String?> getDecryptedString(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final encryptedValue = prefs.getString(key);
    if (encryptedValue != null) {
      return encrypter.decrypt(
        encrypt.Encrypted.fromBase64(encryptedValue),
        iv: iv,
      );
    }
    return null;
  }

  static Future<bool> saveEncryptedInt(String key, int value) async {
    final encryptedValue = encrypter.encrypt(value.toString(), iv: iv).base64;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, encryptedValue);
  }

  static Future<bool> saveEncryptedDouble(String key, double value) async {
    final encryptedValue = encrypter.encrypt(value.toString(), iv: iv).base64;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(key, encryptedValue);
  }

  static Future<bool?> getDecryptedBool(String key) async {
    final decryptedValue = await _getDecryptedValue(key);
    return decryptedValue == null
        ? null
        : decryptedValue.toLowerCase() == 'true';
  }

  static Future<int?> getDecryptedInt(String key) async {
    final decryptedValue = await _getDecryptedValue(key);
    return decryptedValue == null ? null : int.tryParse(decryptedValue);
  }

  static Future<double?> getDecryptedDouble(String key) async {
    final decryptedValue = await _getDecryptedValue(key);
    return decryptedValue == null ? null : double.tryParse(decryptedValue);
  }

  static Future<String?> _getDecryptedValue(String key) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final encryptedValue = prefs.getString(key);
    if (encryptedValue != null) {
      return encrypter.decrypt(
        encrypt.Encrypted.fromBase64(encryptedValue),
        iv: iv,
      );
    }
    return null;
  }

  static Future<bool> saveLastLoginDateTime(DateTime dateTime) async {
    final String dateTimeString = dateTime.toIso8601String();
    return saveEncryptedString('lastLoginDateTime', dateTimeString);
  }

  static Future<DateTime?> getLastLoginDateTime() async {
    final String? decryptedDateTimeString = await getDecryptedString(
      'lastLoginDateTime',
    );
    if (decryptedDateTimeString != null) {
      return DateTime.tryParse(decryptedDateTimeString);
    }
    return null;
  }

  static Future<bool> saveUserCredentials(
    Map<String, dynamic> credentials,
  ) async {
    final String credentialsJson = jsonEncode(credentials);
    return saveEncryptedString('userCredentials', credentialsJson);
  }

  static Future<Map<String, dynamic>?> getUserCredentials() async {
    final String? decryptedCredentialsJson = await getDecryptedString(
      'userCredentials',
    );
    if (decryptedCredentialsJson != null) {
      return jsonDecode(decryptedCredentialsJson) as Map<String, dynamic>;
    }
    return null;
  }
}

// Form Data Suggestions Service
class FormDataService {
  static const String _formSuggestionsKey = 'FORM_SUGGESTIONS';
  
  // Save form field suggestions
  static Future<bool> saveFieldSuggestion(String fieldKey, String value) async {
    if (value.trim().isEmpty) return false;
    
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing suggestions
      final existingSuggestionsJson = prefs.getString(_formSuggestionsKey);
      Map<String, dynamic> suggestions = {};
      
      if (existingSuggestionsJson != null) {
        suggestions = jsonDecode(existingSuggestionsJson);
      }
      
      // Get or create field suggestions list
      List<String> fieldSuggestions = [];
      if (suggestions.containsKey(fieldKey)) {
        fieldSuggestions = List<String>.from(suggestions[fieldKey]);
      }
      
      // Add new suggestion if it doesn't exist (case insensitive)
      final lowercaseValue = value.trim().toLowerCase();
      if (!fieldSuggestions.any((s) => s.toLowerCase() == lowercaseValue)) {
        fieldSuggestions.add(value.trim());
        
        // Keep only the last 10 suggestions per field
        if (fieldSuggestions.length > 10) {
          fieldSuggestions = fieldSuggestions.sublist(fieldSuggestions.length - 10);
        }
        
        suggestions[fieldKey] = fieldSuggestions;
        
        // Save back to preferences
        return await prefs.setString(_formSuggestionsKey, jsonEncode(suggestions));
      }
      
      return true;
    } catch (e) {
      print('Error saving form suggestion: $e');
      return false;
    }
  }
  
  // Get suggestions for a specific field
  static Future<List<String>> getFieldSuggestions(String fieldKey) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final suggestionsJson = prefs.getString(_formSuggestionsKey);
      
      if (suggestionsJson != null) {
        final Map<String, dynamic> suggestions = jsonDecode(suggestionsJson);
        if (suggestions.containsKey(fieldKey)) {
          return List<String>.from(suggestions[fieldKey]);
        }
      }
    } catch (e) {
      print('Error getting form suggestions: $e');
    }
    
    return [];
  }
  
  // Get filtered suggestions based on current input
  static Future<List<String>> getFilteredSuggestions(String fieldKey, String currentInput) async {
    final allSuggestions = await getFieldSuggestions(fieldKey);
    
    if (currentInput.trim().isEmpty) {
      return allSuggestions;
    }
    
    final lowerInput = currentInput.toLowerCase();
    return allSuggestions
        .where((suggestion) => suggestion.toLowerCase().contains(lowerInput))
        .toList();
  }
  
  // Save multiple field data at once (useful for form submission)
  static Future<bool> saveMultipleFieldSuggestions(Map<String, String> fieldData) async {
    try {
      for (final entry in fieldData.entries) {
        await saveFieldSuggestion(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      print('Error saving multiple form suggestions: $e');
      return false;
    }
  }
  
  // Clear suggestions for a specific field
  static Future<bool> clearFieldSuggestions(String fieldKey) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final suggestionsJson = prefs.getString(_formSuggestionsKey);
      
      if (suggestionsJson != null) {
        final Map<String, dynamic> suggestions = jsonDecode(suggestionsJson);
        suggestions.remove(fieldKey);
        return await prefs.setString(_formSuggestionsKey, jsonEncode(suggestions));
      }
      
      return true;
    } catch (e) {
      print('Error clearing field suggestions: $e');
      return false;
    }
  }
  
  // Clear all form suggestions
  static Future<bool> clearAllSuggestions() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_formSuggestionsKey);
    } catch (e) {
      print('Error clearing all suggestions: $e');
      return false;
    }
  }
}

// Form Progress Persistence Service
class FormProgressService {
  static const String _businessFormProgressKey = 'BUSINESS_FORM_PROGRESS';
  static const String _buyerFormProgressKey = 'BUYER_FORM_PROGRESS';
  
  // Save business form progress
  static Future<bool> saveBusinessFormProgress({
    required int currentStep,
    required Map<String, String> formData,
    required List<String> selectedCategories,
    String? selectedBank,
    String? selectedBranchCode,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final progressData = {
        'currentStep': currentStep,
        'formData': formData,
        'selectedCategories': selectedCategories,
        'selectedBank': selectedBank,
        'selectedBranchCode': selectedBranchCode,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return await prefs.setString(_businessFormProgressKey, jsonEncode(progressData));
    } catch (e) {
      print('Error saving business form progress: $e');
      return false;
    }
  }
  
  // Get business form progress
  static Future<Map<String, dynamic>?> getBusinessFormProgress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_businessFormProgressKey);
      
      if (progressJson != null) {
        final progress = jsonDecode(progressJson) as Map<String, dynamic>;
        
        // Check if progress is recent (within 7 days)
        final timestamp = DateTime.tryParse(progress['timestamp'] ?? '');
        if (timestamp != null && 
            DateTime.now().difference(timestamp).inDays <= 7) {
          return progress;
        } else {
          // Clear old progress
          await clearBusinessFormProgress();
        }
      }
    } catch (e) {
      print('Error getting business form progress: $e');
    }
    
    return null;
  }
  
  // Save buyer form progress
  static Future<bool> saveBuyerFormProgress({
    required Map<String, String> formData,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      final progressData = {
        'formData': formData,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      return await prefs.setString(_buyerFormProgressKey, jsonEncode(progressData));
    } catch (e) {
      print('Error saving buyer form progress: $e');
      return false;
    }
  }
  
  // Get buyer form progress
  static Future<Map<String, dynamic>?> getBuyerFormProgress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_buyerFormProgressKey);
      
      if (progressJson != null) {
        final progress = jsonDecode(progressJson) as Map<String, dynamic>;
        
        // Check if progress is recent (within 7 days)
        final timestamp = DateTime.tryParse(progress['timestamp'] ?? '');
        if (timestamp != null && 
            DateTime.now().difference(timestamp).inDays <= 7) {
          return progress;
        } else {
          // Clear old progress
          await clearBuyerFormProgress();
        }
      }
    } catch (e) {
      print('Error getting buyer form progress: $e');
    }
    
    return null;
  }
  
  // Clear business form progress
  static Future<bool> clearBusinessFormProgress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_businessFormProgressKey);
    } catch (e) {
      print('Error clearing business form progress: $e');
      return false;
    }
  }
  
  // Clear buyer form progress
  static Future<bool> clearBuyerFormProgress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_buyerFormProgressKey);
    } catch (e) {
      print('Error clearing buyer form progress: $e');
      return false;
    }
  }
  
  // Check if there's any incomplete registration
  static Future<Map<String, dynamic>?> getIncompleteRegistration() async {
    final businessProgress = await getBusinessFormProgress();
    final buyerProgress = await getBuyerFormProgress();
    
    if (businessProgress != null) {
      return {
        'type': 'business',
        'progress': businessProgress,
      };
    } else if (buyerProgress != null) {
      return {
        'type': 'buyer', 
        'progress': buyerProgress,
      };
    }
    
    return null;
  }
}
