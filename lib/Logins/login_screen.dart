// lib/Logins/login_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving user data
import 'dart:convert'; // For jsonEncode

import '../Services/auth_services.dart'; // Your AuthService
import '../Screens/main_screen.dart';    // Your MainScreen after login
import 'signup_screen.dart';           // Your SignupScreen

class LoginScreen extends StatefulWidget {
  static const routeName = '/login-screen';

  // Constructor with super.key
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = false;
  }

  // This is the userInput widget from your provided design
  Widget userInput({
    required TextEditingController controller,
    required String hintTitle,
    required TextInputType keyboardType,
    required IconData prefixIcon,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white70, // Style from your provided code
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autocorrect: false,
        enableSuggestions: !isPassword,
        obscureText: isPassword && !_isPasswordVisible,
        autofocus: false,
        keyboardType: keyboardType,
        style: TextStyle( // Style from your provided code
          fontSize: 16,
          color: Colors.grey[800],
        ),
        decoration: InputDecoration( // Style from your provided code
          prefixIcon: Icon(prefixIcon, color: Colors.indigo.shade800),
          suffixIcon: suffixIcon,
          hintText: hintTitle,
          hintStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey[500],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.indigo.shade800, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
        ),
      );
    }
  }

  Future<void> _performLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showMessage("Email and password cannot be empty.", isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Save user data to SharedPreferences
      if (response.containsKey('user') && response['user'] is Map) {
        final Map<String, dynamic> apiUserData = response['user'] as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();

        Map<String, dynamic> userToSave = {
          'name': apiUserData['name'],     // Ensure 'name' is the key from your API
          'email': apiUserData['email'],   // Ensure 'email' is the key from your API
        };
        await prefs.setString('user', jsonEncode(userToSave));
        print('User data saved to SharedPreferences: ${jsonEncode(userToSave)}');
      } else {
        print('User data not found or in unexpected format in login response.');
      }

      if (mounted) {
        _showMessage("Login Successful!", isError: false);
        // Navigate to MainScreen
        Navigator.of(context).pushReplacementNamed(MainScreen.routeName);
      }

    } catch (e) {
      if (mounted) {
        _showMessage('Login failed: ${e.toString().replaceFirst("Exception: ", "")}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar in this design
      body: Container(
        // Background image as per your provided design
        decoration: const BoxDecoration(
          image: DecorationImage(
            alignment: Alignment.topCenter,
            fit: BoxFit.fill,
            image: AssetImage('assets/log2.jpg'), // Ensure this asset is in assets/images/
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // Content aligned to bottom
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
              width: double.infinity,
              decoration: const BoxDecoration(
                  color: Colors.white, // White card at the bottom
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, -5),
                    )
                  ]
              ),
              child: SingleChildScrollView( // Makes the form scrollable if keyboard appears
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome Back!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Text color for white background
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Login to your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600], // Text color for white background
                      ),
                    ),
                    const SizedBox(height: 35),
                    userInput(
                      controller: emailController,
                      hintTitle: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    userInput(
                      controller: passwordController,
                      hintTitle: 'Password',
                      keyboardType: TextInputType.visiblePassword,
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey[600],
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement forgot password functionality
                          _showMessage('Forgot password pressed (Not implemented yet)', isError: false);
                        },
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade800, // Button color from your design
                          foregroundColor: Colors.white, // Text color for button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        onPressed: _isLoading ? null : _performLogin,
                        child: _isLoading
                            ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                        )
                            : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            // color: Colors.white, // Already set by foregroundColor
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, SignupScreen.routeName),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800, // Link color from your design
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Added some bottom padding inside the card
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}