// lib/Quiz/quiz_result_screen.dart
import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final int courseId;
  final String courseName;
  final double score;
  final bool certificateIssued;

  const QuizResultScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.score,
    required this.certificateIssued,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryDark = Color(0xFF131519);
    final bool isPassed = score >= 90;

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Result: $courseName'),
        automaticallyImplyLeading: false, // No back button
      ),
      backgroundColor: primaryDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isPassed ? 'Congratulations! You Passed!' : 'Try Again!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? Colors.greenAccent.shade400 : Colors.orangeAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Your Score:',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              Text(
                '${score.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: isPassed ? Colors.greenAccent.shade400 : Colors.white),
              ),
              const SizedBox(height: 30),
              if (certificateIssued)
                const Text(
                  'You have earned a certificate!',
                  style: TextStyle(fontSize: 18, color: Colors.amberAccent),
                ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to the materials screen, pop until you reach MainScreen, then go to MyCourses
                  // A simple pop will take them back to the materials list.
                  Navigator.of(context).pop();
                },
                child: const Text('Back to Materials'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}