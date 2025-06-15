// lib/Screens/course_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Models/course.dart';
import '../services/course_service.dart';
import '../services/auth_services.dart'; // Import AuthService to get the token

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  Future<List<dynamic>>? _dataFuture;
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();
  Set<int> _enrolledIds = {};

  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    String? token = await _authService.getToken();
    if (mounted) {
      setState(() {
        _dataFuture = Future.wait([
          _courseService.fetchCourses(),
          token != null ? _courseService.fetchEnrolledCourseIds(token) : Future.value(<int>{}),
        ]);
      });
    }
  }

  void _refreshCourses() {
    _loadInitialData();
  }

  void _updateEnrollmentStatus(int courseId) {
    if (mounted) {
      setState(() {
        _enrolledIds.add(courseId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment successful!'), backgroundColor: Colors.green)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Courses'),
        backgroundColor: surfaceDark,
        titleTextStyle: const TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: _refreshCourses,
            tooltip: 'Refresh Courses',
          )
        ],
      ),
      backgroundColor: primaryDark,
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentRed));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available.', style: TextStyle(color: textSecondary)));
          } else {
            final List<Course> courses = snapshot.data![0] as List<Course>;
            _enrolledIds = snapshot.data![1] as Set<int>;

            return LayoutBuilder(
              builder: (BuildContext layoutContext, BoxConstraints constraints) {
                int crossAxisCount;
                double childAspectRatio;

                if (constraints.maxWidth < 400) {
                  crossAxisCount = 1;
                  childAspectRatio = 0.8;
                } else if (constraints.maxWidth < 720) {
                  crossAxisCount = 2;
                  // Final adjustment to give just enough height to prevent the small overflow.
                  childAspectRatio = 0.75; // <<< FINAL ADJUSTMENT
                } else {
                  crossAxisCount = 3;
                  childAspectRatio = 0.78;
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (BuildContext itemContext, int index) {
                    final course = courses[index];
                    return CourseCard(
                      course: course,
                      isInitiallyEnrolled: _enrolledIds.contains(course.id),
                      onEnrollSuccess: () => _updateEnrollmentStatus(course.id),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class CourseCard extends StatefulWidget {
  final Course course;
  final bool isInitiallyEnrolled;
  final VoidCallback onEnrollSuccess;

  const CourseCard({
    super.key,
    required this.course,
    required this.isInitiallyEnrolled,
    required this.onEnrollSuccess,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _isEnrolled = false;
  bool _isEnrolling = false;

  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color accentRed = Color(0xFF680d13);
  static const Color enrolledColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _isEnrolled = widget.isInitiallyEnrolled;
  }

  @override
  void didUpdateWidget(covariant CourseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isInitiallyEnrolled != oldWidget.isInitiallyEnrolled) {
      setState(() {
        _isEnrolled = widget.isInitiallyEnrolled;
      });
    }
  }

  Future<void> _handleEnroll() async {
    setState(() { _isEnrolling = true; });

    final token = await _authService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to enroll.'), backgroundColor: Colors.orangeAccent)
      );
      if(mounted) setState(() { _isEnrolling = false; });
      return;
    }

    try {
      await _courseService.enrollInCourse(widget.course.id, token);
      if (mounted) {
        setState(() { _isEnrolled = true; });
        widget.onEnrollSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enrollment failed: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent)
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isEnrolling = false; });
      }
    }
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: textMuted),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 11,
                color: textMuted,
                fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.normal),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl = widget.course.thumbnail;
    String priceText = widget.course.courseType.toLowerCase() == 'free' ? 'Gratis' : 'Rp ${widget.course.coursePrice}';

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final isAndroidEmulator = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      if (isAndroidEmulator) {
        imageUrl = imageUrl.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
      }
    }

    return Card(
      color: surfaceDark,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 6,
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[850], child: const Center(child: Icon(Icons.broken_image_outlined, color: textMuted, size: 36))),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null, color: accentRed, strokeWidth: 2.0));
              },
            )
                : Container(color: Colors.grey[850], child: const Center(child: Icon(Icons.image_not_supported_outlined, color: textMuted, size: 36))),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.course.courseName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      _buildDetailRow(
                          icon: Icons.timer_outlined,
                          label: "Durasi",
                          value: "${widget.course.courseHour} jam"
                      ),
                      _buildDetailRow(
                          icon: Icons.sell_outlined,
                          label: "Harga",
                          value: priceText
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _isEnrolling
                        ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.0, color: accentRed),
                    )
                        : ElevatedButton(
                      onPressed: _isEnrolled ? null : _handleEnroll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEnrolled ? enrolledColor : accentRed,
                        disabledBackgroundColor: enrolledColor.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                          _isEnrolled ? 'Enrolled' : 'Enroll',
                          style: const TextStyle(color: textPrimary)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
