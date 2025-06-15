// lib/Screens/course_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Models/course.dart';
import '../services/course_service.dart';
import '../services/auth_services.dart';

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
          token != null
              ? _courseService.fetchEnrolledCourseIds(token)
              : Future.value(<int>{}),
        ]);
      });
    }
  }

  void _refreshCourses() => _loadInitialData();

  void _updateEnrollmentStatus(int courseId) {
    if (mounted) {
      setState(() => _enrolledIds.add(courseId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment successful!'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Courses'),
        backgroundColor: surfaceDark,
        titleTextStyle: const TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
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
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available.', style: TextStyle(color: textSecondary)));
          }

          final courses = snapshot.data![0] as List<Course>;
          _enrolledIds = snapshot.data![1] as Set<int>;

          return LayoutBuilder(builder: (context, constraints) {
            int crossCount;
            double aspect;

            if (constraints.maxWidth < 400) {
              crossCount = 1;
              aspect = 0.8;
            } else if (constraints.maxWidth < 720) {
              crossCount = 2;
              aspect = 0.75;
            } else {
              crossCount = 3;
              aspect = 0.78;
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspect,
              ),
              itemCount: courses.length,
              itemBuilder: (ctx, i) => CourseCard(
                course: courses[i],
                isInitiallyEnrolled: _enrolledIds.contains(courses[i].id),
                onEnrollSuccess: () => _updateEnrollmentStatus(courses[i].id),
              ),
            );
          });
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
      setState(() => _isEnrolled = widget.isInitiallyEnrolled);
    }
  }

  Future<void> _handleEnroll() async {
    setState(() => _isEnrolling = true);
    final token = await _authService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to enroll.'), backgroundColor: Colors.orangeAccent),
      );
      setState(() => _isEnrolling = false);
      return;
    }
    try {
      await _courseService.enrollInCourse(widget.course.id, token);
      setState(() => _isEnrolled = true);
      widget.onEnrollSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enrollment failed: ${e.toString()}'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isEnrolling = false);
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: fontSize * .9, color: textMuted),
          const SizedBox(width: 5),
          Text('$label: ', style: TextStyle(fontSize: fontSize, color: textMuted, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: fontSize, color: textSecondary), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? img = widget.course.thumbnail;
    if (img != null && img.isNotEmpty && defaultTargetPlatform == TargetPlatform.android) {
      img = img.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
    }

    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;
      final imgH = w * .55;

      // Atur nilai minimum agar teks tidak terlalu kecil
      final titleFS = w * .07 < 18 ? 18.0 : w * .07;
      final detailFS = w * .045 < 14 ? 14.0 : w * .045;
      final btnFS = w * .045 < 14 ? 14.0 : w * .045;

      return Card(
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: imgH,
              width: double.infinity,
              child: img != null && img.isNotEmpty
                  ? Image.network(
                img,
                fit: BoxFit.cover,
                loadingBuilder: (c, ch, lp) => lp == null
                    ? ch
                    : Center(
                  child: CircularProgressIndicator(
                    value: lp.expectedTotalBytes != null
                        ? lp.cumulativeBytesLoaded / lp.expectedTotalBytes!
                        : null,
                    color: accentRed,
                  ),
                ),
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[850],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 36)),
                ),
              )
                  : Container(color: Colors.grey[850], child: const Center(child: Icon(Icons.image_not_supported_outlined, color: textMuted, size: 36))),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.courseName,
                    style: TextStyle(fontSize: titleFS, fontWeight: FontWeight.bold, color: textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.timer_outlined, 'Durasi', '${widget.course.courseHour} jam', detailFS),
                  _buildDetailRow(
                    Icons.sell_outlined,
                    'Harga',
                    widget.course.courseType.toLowerCase() == 'free' ? 'Gratis' : 'Rp ${widget.course.coursePrice}',
                    detailFS,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _isEnrolling
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentRed))
                        : ElevatedButton(
                      onPressed: _isEnrolled ? null : _handleEnroll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEnrolled ? enrolledColor : accentRed,
                        disabledBackgroundColor: enrolledColor.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        textStyle: TextStyle(fontSize: btnFS, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(_isEnrolled ? 'Enrolled' : 'Enroll', style: const TextStyle(color: textPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
