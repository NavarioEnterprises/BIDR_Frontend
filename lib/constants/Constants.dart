import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Constants {
  static bool isLoggedIn = false;
  static bool isLoggedIn5 = false;
  static String buyerAddress = "1011 makahlane street, pimville soweto 1950";
  static int buyerAppBarValue = 0;

  static String myDisplayname = "Guest";
  static int business_id = -1;
  static String business_uid = "";
  static String business_email = "";
  static String business_name = "";
  static String business_phone_number = "";
  static String myCategoryRole = "";
  static String myEmail = "";
  static String appUserFirstName = "";
  static String appUserLastName = "";
  static String appUserContacts = "";

  static String myCell = "";

  static String myUid = "";
  static int userId = -1;
  static int businessId = -1;
  static int defaultServiceId = 1; //192.168.43.107 172.20.10.2
  static String bidrBaseUrl = "http://127.0.0.1:8001/"; //#FEEDD5 //Colors.grey[800]
  static String myUsername = "";
  static Color ctaColorLight = Colors.orange;
  static Color ftaColorLight = const Color(0xFF042C4C);
  static Color gtaColorLight =  Colors.grey.shade800;
  static Color dtaColorLight = const Color(0xFFFEEDD5);
  static DateFormat formatter = DateFormat('yyyy-MM-dd');
}
