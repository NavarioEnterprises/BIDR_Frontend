import 'package:bidr/pages/buyer_home.dart';
import 'package:bidr/pages/buyer_dashboard.dart';
import 'package:bidr/pages/home_router.dart';
import 'package:bidr/pages/faq_screen.dart';
import 'package:bidr/pages/policies_screen.dart';
import 'package:bidr/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:fvp/fvp.dart' as fvp;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'authentication/login.dart';
import 'authentication/registration/business_signup.dart';
import 'authentication/registration/buyer_signup.dart';
import 'authentication/splashscreen.dart';
import 'constants/Constants.dart';
import 'models/user.dart';
import 'dart:convert';

Future<void> main() async {
  //fvp.registerWith();
  //WakelockPlus.enable();
  setUrlStrategy(PathUrlStrategy());

  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is logged in
  final bool isLoggedIn =
      await Sharedprefs.getUserLoggedInSharedPreference() ?? false;

  // Setup initial data if logged in
  if (isLoggedIn) {
    // Try to load complete login data first
    final String? completeLoginData =
        await Sharedprefs.getCompleteLoginDataSharedPreference();

    if (completeLoginData != null && completeLoginData.isNotEmpty) {
      try {
        // Parse the complete login data and set current user
        final loginResponse = LoginResponse.fromJsonString(completeLoginData);
        Constants.currentUser = loginResponse.user;

        // Set individual constants from the user model
        Constants.myUid = loginResponse.user.uid;
        Constants.userId = loginResponse.user.id;
        Constants.myCell = loginResponse.user.phoneNumber;
        Constants.myDisplayname = loginResponse.user.fullName;
        Constants.myCategoryRole = loginResponse.user.role;
        Constants.myUsername = loginResponse.user.fullName;
        Constants.myEmail = loginResponse.user.email;
      } catch (e) {
        print('Error parsing stored login data: $e');
        // Fallback to individual SharedPreferences
        await _loadIndividualUserData();
      }
    } else {
      // Fallback to individual SharedPreferences
      await _loadIndividualUserData();
    }

    // Load business data
    Constants.business_name =
        (await Sharedprefs.getBusinessNameSharedPreference()) ?? "";
    Constants.business_email =
        (await Sharedprefs.getBusinessEmailSharedPreference()) ?? "";
    Constants.business_phone_number =
        (await Sharedprefs.getBusinessPhoneNumberSharedPreference()) ?? "";
    Constants.business_id =
        (await Sharedprefs.getBusinessIdSharedPreference()) ?? -1;
    Constants.business_uid =
        (await Sharedprefs.getBusinessUidSharedPreference()) ?? "";
  }

  // Determine initial route based on actual authentication state
  final bool hasValidUser = Constants.currentUser != null;
  final initialRoute = hasValidUser ? '/dashboard' : '/';

  runApp(MyApp(initialRoute: initialRoute));
}

Future<void> _loadIndividualUserData() async {
  Constants.myUid = (await Sharedprefs.getUserUidSharedPreference()) ?? "";
  Constants.userId = (await Sharedprefs.getUserIdSharedPreference()) ?? -1;
  Constants.myCell = (await Sharedprefs.getUserCellSharedPreference()) ?? "";
  Constants.myDisplayname =
      (await Sharedprefs.getUserNameSharedPreference()) ?? '';
  Constants.myCategoryRole =
      (await Sharedprefs.getUserRoleSharedPreference()) ?? '';
  Constants.myUsername = Constants.myDisplayname;
  Constants.myEmail = (await Sharedprefs.getUserEmailSharedPreference()) ?? '';
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  MyApp({Key? key, required this.initialRoute}) : super(key: key);

  late final GoRouter _router = GoRouter(
    initialLocation: initialRoute,
    redirect: (BuildContext context, GoRouterState state) async {
      // Check both SharedPreferences and Constants for authentication state
      final isLoggedIn =
          await Sharedprefs.getUserLoggedInSharedPreference() ?? false;
      final hasCurrentUser = Constants.currentUser != null;
      final isAuthenticated = isLoggedIn && hasCurrentUser;

      final publicRoutes = [
        '/',
        '/login',
        '/register',
        '/register/buyer',
        '/register/seller',
        '/faq',
        '/policies',
      ];

      final protectedRoutes = [
        '/dashboard',
      ];

      // If not authenticated, redirect to login for protected routes
      if (!isAuthenticated && (protectedRoutes.contains(state.matchedLocation) || !publicRoutes.contains(state.matchedLocation))) {
        return '/login';
      }

      // Allow authenticated users to access FAQ and policies
      final infoRoutes = [
        '/faq',
        '/policies',
        '/terms',
        '/privacy',
        '/help',
        '/support',
      ];
      if (isAuthenticated &&
          publicRoutes.contains(state.matchedLocation) &&
          !infoRoutes.contains(state.matchedLocation)) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      // Landing/Login Route
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) => BuyerHomePage(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginPage(),
      ),

      // Registration Routes
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (BuildContext context, GoRouterState state) =>
            SplashScreen(), // Role selection screen
      ),
      GoRoute(
        path: '/register/buyer',
        name: 'register-buyer',
        builder: (BuildContext context, GoRouterState state) =>
            const BuyerSignUpPage(userRole: 'buyer'),
      ),
      GoRoute(
        path: '/register/seller',
        name: 'register-seller',
        builder: (BuildContext context, GoRouterState state) =>
            const BusinessSignUpPage(),
      ),

      // Dashboard Route (Role-based home)
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeRouter(),
      ),

      // Information Routes
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (BuildContext context, GoRouterState state) =>
            const FAQScreen(),
      ),
      GoRoute(
        path: '/policies',
        name: 'policies',
        builder: (BuildContext context, GoRouterState state) =>
            const PoliciesScreen(),
      ),

      // Additional Information Routes
      GoRoute(
        path: '/terms',
        name: 'terms',
        redirect: (context, state) => '/policies', // Redirect to policies tab
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        redirect: (context, state) => '/policies', // Redirect to policies tab
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        redirect: (context, state) => '/faq',
      ),
      GoRoute(
        path: '/support',
        name: 'support',
        redirect: (context, state) => '/faq',
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BIDR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
