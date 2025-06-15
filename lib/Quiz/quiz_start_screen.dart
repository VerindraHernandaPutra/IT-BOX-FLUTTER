// lib/Quiz/quiz_start_screen.dart
import 'package:flutter/material.dart';
import 'package:untitled/Quiz/quiz_screen.dart'; // The actual quiz screen
import '../services/course_service.dart';
import '../services/auth_services.dart';
import '../Models/quiz_question.dart';

class QuizStartScreen extends StatefulWidget {
  final int courseId;
  final String courseName;

  const QuizStartScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<QuizStartScreen> createState() => _QuizStartScreenState();
}

class _QuizStartScreenState extends State<QuizStartScreen> {
  bool _isLoading = false;
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  Future<void> _startQuiz() async {
    setState(() { _isLoading = true; });

    final token = await _authService.getToken();
    if (token == null || !mounted) return;

    try {
      final response = await _courseService.startQuiz(widget.courseId, token);
      final attemptId = response['attempt_id'];
      final questionsData = response['questions'] as List;
      final List<QuizQuestion> questions = questionsData
          .map((q) => QuizQuestion.fromJson(q))
          .toList();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              courseId: widget.courseId,
              courseName: widget.courseName,
              attemptId: attemptId,
              questions: questions,
            ),
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xFF131519);
    const Color accentRed = Color(0xFF680d13);

    return Scaffold(
      appBar: AppBar(title: Text(widget.courseName)),
      backgroundColor: primaryDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Quiz Rules',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                '• The quiz consists of 20 random questions.\n'
                    '• You must score >= 90% to pass and be eligible for a certificate.\n'
                    '• You can retake the quiz if you fail.',
                style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator(color: accentRed)
                  : ElevatedButton.icon(
                onPressed: _startQuiz,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text('Start Quiz Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}