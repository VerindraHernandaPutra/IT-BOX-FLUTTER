// lib/Services/auth_services.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Base URL for your Laravel API backend
  // For physical device on same Wi-Fi: 'http://YOUR_COMPUTER_IP:8000/api'
  final String _apiBaseUrl = 'http://35.219.25.96:8000/api';

  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token'; // Key for storing the token in secure storage

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

  /// Registers a new user.
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
        errorMessage = (responseBody['errors'] as Map).entries.map((entry) {
          final errors = entry.value;
          return errors is List ? '${entry.key}: ${errors.join(', ')}' : '${entry.key}: $errors';
        }).join('; ');
      }
      throw Exception(errorMessage);
    }
  }

  /// Logs in a user and stores the authentication token.
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
      return responseBody;
    } else {
      String errorMessage = responseBody['message'] ?? 'Login failed.';
      if (responseBody['errors'] != null && responseBody['errors']['email'] != null) {
        errorMessage = (responseBody['errors']['email'] as List).join(', ');
      }
      throw Exception(errorMessage);
    }
  }

  /// Logs out the user from the server and deletes the local token.
  Future<void> logout() async {
    String? token = await getToken();
    if (token == null) {
      print("No token found, already logged out locally.");
      return;
    }

    try {
      await http.post(
        Uri.parse('$_apiBaseUrl/logout'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('Error during server logout API call: $e');
    } finally {
      // Always delete the local token regardless of server response.
      await deleteToken();
    }
  }

  /// Updates the user's profile, including an optional image file.
  Future<Map<String, dynamic>> updateUserProfile({
    required String name,
    required String email,
    File? imageFile,
  }) async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    final uri = Uri.parse('$_apiBaseUrl/user/profile');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json';

    request.fields['name'] = name;
    request.fields['email'] = email;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'user_image',
          imageFile.path,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      String errorMessage = responseBody['message'] ?? 'Failed to update profile.';
      if (responseBody['errors'] != null && responseBody['errors'] is Map) {
        errorMessage = (responseBody['errors'] as Map).entries.map((entry) {
          final errors = entry.value;
          return errors is List ? '${entry.key}: ${errors.join(', ')}' : '${entry.key}: $errors';
        }).join('; ');
      }
      throw Exception(errorMessage);
    }
  }

  /// Fetches the user's activity statistics (course counts).
  Future<Map<String, dynamic>> getActivityStats() async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/user/activity-stats'),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load activity stats.');
    }
  }

  /// Fetches the user's profile summary (name, email, image_url) from the specific endpoint.
  Future<Map<String, dynamic>> getUserProfile() async {
    String? token = await getToken();
    if (token == null) {
      throw Exception('User not authenticated.');
    }

    final response = await http.get(
      Uri.parse('$_apiBaseUrl/user/profile'),
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile.');
    }
  }
}