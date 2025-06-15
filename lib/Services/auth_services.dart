// lib/Services/auth_services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // TODO: Ensure this URL is correct for your Laravel API backend
  // For Android Emulator connecting to localhost: 'http://10.0.2.2:8000/api'
  // For physical device on same Wi-Fi: 'http://YOUR_COMPUTER_IP:8000/api'
  final String _apiBaseUrl = 'http://192.168.18.7:8000/api';

  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token'; // Key for storing the token

  // --- Token Management ---
  Future<void> _storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // --- Authentication Methods ---
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return responseBody;
    } else {
      String errorMessage = responseBody['message'] ?? 'Registration failed.';
      if (responseBody['errors'] != null && responseBody['errors'] is Map) {
        // Concatenate Laravel validation errors
        errorMessage = (responseBody['errors'] as Map).entries.map((entry) {
          final errors = entry.value;
          if (errors is List) {
            return '${entry.key}: ${errors.join(', ')}';
          }
          return '${entry.key}: $errors';
        }).join('; ');
      }
      throw Exception(errorMessage);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      if (responseBody['token'] != null && responseBody['token'] is String) {
        await _storeToken(responseBody['token']);
      }
      // The responseBody should contain { "token": "...", "user": { ... } }
      return responseBody;
    } else {
      String errorMessage = responseBody['message'] ?? 'Login failed.';
      if (responseBody['errors'] != null && responseBody['errors']['email'] != null && responseBody['errors']['email'] is List) {
        errorMessage = (responseBody['errors']['email'] as List).join(', ');
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    String? token = await getToken();
    if (token == null) {
      print("No token found, already logged out locally.");
      return; // No token, so user is effectively logged out locally
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        print("Successfully logged out from server.");
      } else {
        // Log server error but proceed to delete local token
        print('Server logout failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Network error or other issue, still proceed to delete local token
      print('Error during server logout API call: $e');
    } finally {
      // Always delete the local token regardless of server response
      await deleteToken();
    }
  }

  // --- User Profile Update Method ---
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String email,
    // Note: Image upload would typically be a separate method using multipart/form-data
  }) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    final response = await http.put( // Using PUT as defined in Laravel API route
      Uri.parse('$_apiBaseUrl/user/profile'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'name': name,
        'email': email,
        // If you were to add password update:
        // 'current_password': currentPassword,
        // 'new_password': newPassword,
        // 'new_password_confirmation': newPasswordConfirmation,
      }),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Expecting Laravel to return { "message": "...", "user": { ...updated user data... } }
      return responseBody;
    } else {
      String errorMessage = responseBody['message'] ?? 'Failed to update profile.';
      if (responseBody['errors'] != null && responseBody['errors'] is Map) {
        // Concatenate Laravel validation errors
        errorMessage = (responseBody['errors'] as Map).entries.map((entry) {
          final errors = entry.value;
          if (errors is List) {
            return '${entry.key}: ${errors.join(', ')}';
          }
          return '${entry.key}: $errors';
        }).join('; ');
      }
      print('Profile update failed: ${response.statusCode} ${response.body}');
      throw Exception(errorMessage);
    }
  }
}