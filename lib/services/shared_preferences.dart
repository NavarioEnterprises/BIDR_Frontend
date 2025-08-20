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
  static String sharedPreferenceBusinessPhoneNumberKey = "USEREBUSINESSPHONENUMBERKEY";

  static Future<bool> saveUserLoggedInSharedPreference(
      bool isUserLoggedIn) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setBool(
        sharedPreferenceUserLoggedInKey, isUserLoggedIn);
  }
  static Future<bool> saveUserAccessTokenSharedPreference(
      String accessToken) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceUserAccessTokenKey, accessToken);
  }
  static Future<bool> saveUserRefreshTokenSharedPreference(
      String refreshToken) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceUserRefreshTokenKey, refreshToken);
  }

  static Future<bool> saveUserRoleSharedPreference(
      String userRole) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(
        sharedPreferenceUserRoleKey, userRole);
  }

  static Future<bool> saveUserNameSharedPreference(String userName) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceUserNameKey1, userName);
  }

  static Future<bool> saveBusinessIdSharedPreference(int businessId) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(sharedPreferenceBusinessIdKey, businessId);
  }
  static Future<bool> saveBusinessUidSharedPreference(String businessUid) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceBusinessUidKey, businessUid);
  }
  static Future<bool> saveBusinessNameSharedPreference(String businessName) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceBusinessNameKey, businessName);
  }
  static Future<bool> saveBusinessEmailSharedPreference(String businessEmail) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceBusinessEmailKey, businessEmail);
  }
  static Future<bool> saveBusinessPhoneNumberSharedPreference(String businessPhone) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceBusinessPhoneNumberKey, businessPhone);
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
        sharedPreferenceUserCaloriesKey, calories);
  }

  static Future<bool> saveUserCecClientIdSharedPreference(
      int cec_client_id) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setInt(
        sharedPreferenceCecClientIdKey, cec_client_id);
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
        sharedPreferenceUserEmailKey2, userEmail);
  }

  static Future<bool> saveUserCellSharedPreference(String userCell) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    return await preferences.setString(sharedPreferenceCellKey, userCell);
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
      return encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedValue),
          iv: iv);
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
      return encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedValue),
          iv: iv);
    }
    return null;
  }

  static Future<bool> saveLastLoginDateTime(DateTime dateTime) async {
    final String dateTimeString = dateTime.toIso8601String();
    return saveEncryptedString('lastLoginDateTime', dateTimeString);
  }

  static Future<DateTime?> getLastLoginDateTime() async {
    final String? decryptedDateTimeString =
        await getDecryptedString('lastLoginDateTime');
    if (decryptedDateTimeString != null) {
      return DateTime.tryParse(decryptedDateTimeString);
    }
    return null;
  }

  static Future<bool> saveUserCredentials(
      Map<String, dynamic> credentials) async {
    final String credentialsJson = jsonEncode(credentials);
    return saveEncryptedString('userCredentials', credentialsJson);
  }

  static Future<Map<String, dynamic>?> getUserCredentials() async {
    final String? decryptedCredentialsJson =
        await getDecryptedString('userCredentials');
    if (decryptedCredentialsJson != null) {
      return jsonDecode(decryptedCredentialsJson) as Map<String, dynamic>;
    }
    return null;
  }
}
