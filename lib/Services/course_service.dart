// lib/services/course_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/course.dart';
import '../Models/material.dart'; // Ensure this model exists at this path
import '../Models/quiz_question.dart'; // Ensure this model exists at this path

class CourseService {
  // TODO: Make sure this URL is correct for your Laravel API backend
  // For Android Emulator connecting to localhost: 'http://10.0.2.2/your_laravel_folder/public/api'
  // Or if using `php artisan serve`: 'http://10.0.2.2:8000/api'
  final String _apiBaseUrl = 'http://10.0.2.2/for_mobapp/public/api';

  // --- Course and Material Methods ---

  Future<List<Course>> fetchCourses() async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/courses'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> decodedResponse = jsonDecode(response.body);
      if (decodedResponse.containsKey('data') && decodedResponse['data'] is List) {
        List<dynamic> coursesList = decodedResponse['data'] as List<dynamic>;
        return coursesList.map((item) => Course.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        print('API Response for fetchCourses: ${response.body}');
        throw Exception('Failed to parse courses: "data" key missing or invalid structure.');
      }
    } else {
      print('Failed to load courses. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load courses. Status: ${response.statusCode}');
    }
  }

  Future<List<Course>> fetchMyEnrolledCourses(String token) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/user/enrolled-courses'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> decodedResponse = jsonDecode(response.body);
      if (decodedResponse.containsKey('data') && decodedResponse['data'] is List) {
        List<dynamic> coursesList = decodedResponse['data'] as List<dynamic>;
        return coursesList
            .map((item) => Course.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to parse enrolled courses: "data" key missing or invalid.');
      }
    } else {
      throw Exception('Failed to fetch enrolled courses. Status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> enrollInCourse(int courseId, String token) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/courses/$courseId/enroll'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return responseBody;
    } else if (response.statusCode == 409) {
      return {'message': responseBody['message'] ?? 'Already enrolled.', 'alreadyEnrolled': true};
    } else {
      throw Exception(responseBody['message'] ?? 'Failed to enroll in course.');
    }
  }

  Future<Set<int>> fetchEnrolledCourseIds(String token) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/user/enrolled-courses-ids'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> decodedResponse = jsonDecode(response.body);
      if (decodedResponse.containsKey('data') && decodedResponse['data'] is List) {
        List<dynamic> idsList = decodedResponse['data'] as List<dynamic>;
        return idsList.map((id) => id as int).toSet();
      } else {
        throw Exception('Failed to parse enrolled course IDs: "data" key missing or invalid.');
      }
    } else {
      throw Exception('Failed to fetch enrolled course IDs. Status: ${response.statusCode}');
    }
  }

  Future<List<MaterialModel>> fetchCourseMaterials(int courseId, String token) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/courses/$courseId/materials'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      Map<String, dynamic> decodedResponse = jsonDecode(response.body);
      if (decodedResponse.containsKey('data') && decodedResponse['data'] is List) {
        List<dynamic> materialsList = decodedResponse['data'] as List<dynamic>;
        return materialsList.map((item) => MaterialModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to parse materials: "data" key missing or invalid.');
      }
    } else if (response.statusCode == 403) {
      throw Exception('Not enrolled in this course to view materials.');
    } else {
      throw Exception('Failed to fetch course materials. Status: ${response.statusCode}');
    }
  }

  // --- Quiz Methods ---

  /// Starts a quiz attempt for a given course.
  /// Returns a map containing the `attempt_id` and a list of `questions`.
  Future<Map<String, dynamic>> startQuiz(int courseId, String token) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/courses/$courseId/quiz/start'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Should return { attempt_id, course_id, questions }
    } else {
      print('Failed to start quiz. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to start quiz. Status: ${response.statusCode}');
    }
  }

  /// Submits the user's answers for a specific quiz attempt.
  /// The `answers` map should be in the format { "questionId": "selectedOption" }.
  /// Returns a map containing the final `score` and `certificate_issued` status.
  Future<Map<String, dynamic>> submitQuiz(int courseId, int attemptId, Map<String, String> answers, String token) async {
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/courses/$courseId/quiz/submit'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'attempt_id': attemptId,
        'answers': answers,
      }),
    );

    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseBody; // Should return { score, certificate_issued }
    } else {
      print('Failed to submit quiz. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception(responseBody['message'] ?? 'Failed to submit quiz.');
    }
  }
}
