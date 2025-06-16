// lib/Quiz/quiz_screen.dart
import 'package:flutter/material.dart';
import '../Models/quiz_question.dart';
import 'quiz_result_screen.dart'; // The screen to show results
import '../services/course_service.dart';
import '../services/auth_services.dart';

class QuizScreen extends StatefulWidget {
  final int courseId;
  final String courseName;
  final int attemptId;
  final List<QuizQuestion> questions;

  const QuizScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.attemptId,
    required this.questions,
  });

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final PageController _pageController = PageController();
  final Map<int, String> _answers = {};
  bool _isSubmitting = false;

  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  Future<void> _submitQuiz() async {
    setState(() { _isSubmitting = true; });

    // Convert map to format API expects: { "questionId": "selected_option" }
    final Map<String, String> formattedAnswers =
    _answers.map((key, value) => MapEntry(key.toString(), value));

    final token = await _authService.getToken();
    if (token == null || !mounted) return;

    try {
      final result = await _courseService.submitQuiz(
        widget.courseId,
        widget.attemptId,
        formattedAnswers,
        token,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              courseId: widget.courseId,
              courseName: widget.courseName,
              score: (result['score'] as num).toDouble(),
              certificateIssued: result['certificate_issued'] as bool,
            ),
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Submission Error: ${e.toString()}'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        automaticallyImplyLeading: false, // Prevent going back
      ),
      backgroundColor: const Color(0xFF131519),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              itemCount: widget.questions.length,
              itemBuilder: (context, index) {
                final question = widget.questions[index];
                return _buildQuestionCard(question, index + 1);
              },
            ),
          ),
          _buildNavigation(),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, int questionNumber) {
    return Card(
      color: const Color(0xFF1E2125),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question $questionNumber/${widget.questions.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              question.questionText,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildOption(question, 'option_a', question.optionA),
            _buildOption(question, 'option_b', question.optionB),
            _buildOption(question, 'option_c', question.optionC),
            _buildOption(question, 'option_d', question.optionD),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(QuizQuestion question, String optionValue, String optionText) {
    final bool isSelected = _answers[question.id] == optionValue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: RadioListTile<String>(
        title: Text(optionText, style: const TextStyle(color: Colors.white)),
        value: optionValue,
        groupValue: _answers[question.id],
        onChanged: (value) {
          setState(() {
            _answers[question.id] = value!;
          });
        },
        activeColor: const Color(0xFF680d13),
        tileColor: isSelected ? const Color(0xFF680d13).withOpacity(0.2) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildNavigation() {
    int currentPage = _pageController.hasClients ? _pageController.page!.round() : 0;
    bool isLastPage = currentPage == widget.questions.length - 1;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentPage > 0)
            TextButton.icon(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              ),
              icon: const Icon(Icons.arrow_back_ios_new),
              label: const Text('Back'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          const Spacer(), // Pushes next/submit to the right
          if (!isLastPage)
            ElevatedButton.icon(
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeIn,
                ),
                icon: const Icon(Icons.arrow_forward_ios_rounded),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF680d13), foregroundColor: Colors.white)
            ),
          if (isLastPage)
            ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitQuiz,
                icon: _isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white)
            ),
        ],
      ),
    );
  }
}