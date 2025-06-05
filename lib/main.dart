// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './Logins/login_screen.dart';
import './Logins/signup_screen.dart';
import './Logins/welcome_screen.dart';
import './Services/auth_services.dart';
import './Screens/main_screen.dart'; // <-- Import MainScreen
// import './Dashboards/dashboard_screen.dart'; // No longer direct navigation

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  Future<Widget> _getInitialScreen() async {
    String? token = await _authService.getToken();
    if (token != null) {
      // Optionally, verify the token with the backend here
      return const MainScreen(); // <-- CHANGE HERE: Navigate to MainScreen
    }
    return WelcomeScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define your app's theme. You can make it dark to match your screens.
        brightness: Brightness.dark,
        primaryColor: Color(0xFF1E2125), // A primary dark color
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF1E2125),
          secondary: Color(0xFF680d13), // Your accent color
          surface: Color(0xFF131519), // Darker background
          background: Color(0xFF131519), // Main background
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white70,
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: Color(0xFF131519), // Default scaffold background
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E2125),
          elevation: 0, // Flat AppBar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white), // For back buttons, etc.
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF680d13), // Accent color for buttons
            foregroundColor: Colors.white, // Text color for buttons
          ),
        ),
        // You can customize other theme properties as needed
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF680d13),)));
          } else if (snapshot.hasData) {
            return snapshot.data!;
          } else {
            return WelcomeScreen(); // Default fallback
          }
        },
      ),
      routes: {
        WelcomeScreen.routeName: (context) => WelcomeScreen(),
        SignupScreen.routeName: (context) => SignupScreen(),
        LoginScreen.routeName: (context) => LoginScreen(),
        MainScreen.routeName: (context) => const MainScreen(), // <-- Add route for MainScreen
        // DashboardScreen.routeName: (context) => DashboardScreen(), // Dashboard is now part of MainScreen
      },
    );
  }
}