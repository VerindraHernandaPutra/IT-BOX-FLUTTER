// successful_screen.dart
import 'package:flutter/material.dart';
// Import AuthService if you want to implement logout
import '../Services/auth_services.dart';
import 'login_screen.dart'; // For navigating back to login after logout

class SuccessfulScreen extends StatelessWidget {
  static const routeName = '/successful-screen'; // Add this if not present
  SuccessfulScreen({super.key});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Home'), // Example Title
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName, // Or WelcomeScreen.routeName
                    (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Authentication Successful!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}