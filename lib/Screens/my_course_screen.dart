// lib/Screens/my_course_screen.dart
import 'package:flutter/material.dart';
import '../Models/course.dart';
import '../services/course_service.dart';
import '../Services/auth_services.dart';
import '../Materials/material_screen.dart'; // Adjust path if your MaterialScreen is elsewhere

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen> {
  Future<List<Course>>? _myCoursesFuture;
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54; // For consistency if needed
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    String? token = await _authService.getToken();
    if (token != null) {
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _myCoursesFuture = _courseService.fetchMyEnrolledCourses(token);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _myCoursesFuture = Future.value([]); // Show empty list if not logged in
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to see your courses.'), backgroundColor: Colors.orangeAccent)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Enrolled Courses'),
        backgroundColor: surfaceDark,
        titleTextStyle: const TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: _loadMyCourses,
            tooltip: 'Refresh My Courses',
          )
        ],
      ),
      backgroundColor: primaryDark,
      body: FutureBuilder<List<Course>>(
        future: _myCoursesFuture,
        builder: (context, snapshot) {
          if (_myCoursesFuture == null) {
            return const Center(child: Text('Login to view your courses.', style: TextStyle(color: textSecondary, fontSize: 18)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentRed));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                      style: const TextStyle(color: textSecondary, fontSize: 16), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again'),
                      onPressed: _loadMyCourses,
                      style: ElevatedButton.styleFrom(backgroundColor: surfaceDark, foregroundColor: textPrimary))
                ]),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You are not enrolled in any courses yet.\nExplore courses and enroll!',
                style: TextStyle(fontSize: 18, color: textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final List<Course> myCourses = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: myCourses.length,
              itemBuilder: (context, index) {
                final course = myCourses[index];
                String? imageUrl = course.thumbnail; // Assuming API provides full URL

                return Card(
                  color: surfaceDark,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  clipBehavior: Clip.antiAlias,
                  elevation: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          height: 160, // Consistent image height
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                              height: 160,
                              color: Colors.grey[800],
                              child: const Center(child: Icon(Icons.broken_image_outlined, color: textMuted, size: 40))),
                        )
                      else
                        Container(
                            height: 160,
                            color: Colors.grey[800],
                            child: const Center(child: Icon(Icons.image_not_supported_outlined, color: textMuted, size: 40))),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.courseName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.timer_outlined, size: 14, color: textMuted),
                                const SizedBox(width: 4),
                                Text("${course.courseHour} hours", style: const TextStyle(color: textSecondary, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                                label: const Text('Start Learning'),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MaterialScreen( // Ensure MaterialScreen is imported
                                        courseId: course.id,
                                        courseName: course.courseName,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: accentRed,
                                    foregroundColor: textPrimary,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}