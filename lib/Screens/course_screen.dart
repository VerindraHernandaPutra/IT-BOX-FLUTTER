// lib/Screens/course_screen.dart
import 'package:flutter/material.dart';
import '../Models/course.dart';
import '../services/course_service.dart';
import '../Services/auth_services.dart'; // Needed to get the token

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  Future<List<Course>>? _coursesFuture; // Make nullable for easier refresh
  Future<Set<int>>? _enrolledCourseIdsFuture; // To store IDs of enrolled courses

  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService(); // For getting the token

  Set<int> _currentlyEnrolledIds = {}; // Store fetched enrolled IDs

  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    String? token = await _authService.getToken();
    if (token == null) {
      // Handle not logged in case for enrolled courses if necessary,
      // or rely on UI to prompt login for enrollment.
      // For now, if no token, enrolled courses will be empty.
      print("No token found, cannot fetch enrolled courses.");
      setState(() {
        _coursesFuture = _courseService.fetchCourses();
        _enrolledCourseIdsFuture = Future.value({}); // Empty set if no token
      });
      return;
    }
    setState(() {
      _coursesFuture = _courseService.fetchCourses();
      _enrolledCourseIdsFuture = _courseService.fetchEnrolledCourseIds(token);
    });
  }

  void _refreshAllData() {
    // To ensure UI updates correctly after enrollment, re-fetch enrolled IDs
    // and potentially the main course list if its status changes.
    _loadData();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( /* ... same AppBar ... */
        title: const Text('All Courses'),
        backgroundColor: surfaceDark,
        titleTextStyle: const TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: _refreshAllData, // Refresh all data
            tooltip: 'Refresh Courses',
          )
        ],
      ),
      backgroundColor: primaryDark,
      body: FutureBuilder<List<dynamic>>( // Use Future.wait to combine two futures
        future: Future.wait([
          _coursesFuture ?? Future.value([]), // Provide default if null during initial load
          _enrolledCourseIdsFuture ?? Future.value(<int>{}),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentRed));
          } else if (snapshot.hasError) {
            return Center( /* ... same error handling ... */
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load data: ${snapshot.error.toString()}',
                      style: const TextStyle(color: textSecondary, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        onPressed: _refreshAllData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: surfaceDark,
                          foregroundColor: textPrimary,
                        ))
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center( /* ... same no data handling ... */
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No data available at the moment.',
                    style: TextStyle(fontSize: 18, color: textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                      onPressed: _refreshAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceDark,
                        foregroundColor: textPrimary,
                      ))
                ],
              ),
            );
          }

          final List<Course> courses = snapshot.data![0] as List<Course>;
          final Set<int> enrolledIds = snapshot.data![1] as Set<int>;
          _currentlyEnrolledIds = enrolledIds; // Update the local set

          if (courses.isEmpty) {
            return Center( /* ... same no courses available handling ... */
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No courses available at the moment.',
                    style: TextStyle(fontSize: 18, color: textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                      onPressed: _refreshAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: surfaceDark,
                        foregroundColor: textPrimary,
                      ))
                ],
              ),
            );
          }

          return LayoutBuilder( /* ... same LayoutBuilder logic ... */
            builder: (BuildContext layoutContext, BoxConstraints constraints) {
              int crossAxisCount;
              double childAspectRatio;

              if (constraints.maxWidth < 390) {
                crossAxisCount = 1;
                childAspectRatio = 0.8;
              } else if (constraints.maxWidth < 720) {
                crossAxisCount = 2;
                childAspectRatio = 0.75;
              } else if (constraints.maxWidth < 1100) {
                crossAxisCount = 3;
                childAspectRatio = 0.85;
              } else {
                crossAxisCount = 4;
                childAspectRatio = 0.9;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: childAspectRatio,
                ),
                itemCount: courses.length,
                itemBuilder: (BuildContext itemContext, int index) {
                  final course = courses[index];
                  return CourseCard(
                    course: course,
                    isInitiallyEnrolled: _currentlyEnrolledIds.contains(course.id),
                    onEnrollSuccess: () {
                      // This callback is called from CourseCard on successful enrollment
                      // We update the local set and trigger a rebuild to reflect the change
                      setState(() {
                        _currentlyEnrolledIds.add(course.id);
                      });
                      // Optionally, you can show a snackbar or further feedback
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Successfully enrolled in ${course.courseName}!'), backgroundColor: Colors.green,)
                      );
                    },
                  );
                },
              );
            },
          );

        },
      ),
    );
  }
}


// CourseCard becomes a StatefulWidget
class CourseCard extends StatefulWidget {
  final Course course;
  final bool isInitiallyEnrolled;
  final VoidCallback onEnrollSuccess; // Callback when enrollment is successful

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
  final AuthService _authService = AuthService(); // For getting token

  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color accentRed = Color(0xFF680d13);
  static const Color enrolledColor = Colors.green; // Color for enrolled button

  @override
  void initState() {
    super.initState();
    _isEnrolled = widget.isInitiallyEnrolled;
  }

  // Handles UI update if parent passes a new isInitiallyEnrolled status
  // This is useful if the parent screen refreshes the enrolled list
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
    setState(() {
      _isEnrolling = true;
    });

    String? token = await _authService.getToken();
    if (token == null) {
      // Handle scenario: user needs to be logged in
      // Maybe navigate to login screen or show a message
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to enroll.'), backgroundColor: Colors.orangeAccent,)
      );
      setState(() {
        _isEnrolling = false;
      });
      return;
    }

    try {
      final response = await _courseService.enrollInCourse(widget.course.id, token);
      if (mounted) {
        setState(() {
          _isEnrolled = true;
          _isEnrolling = false;
        });
        widget.onEnrollSuccess(); // Notify parent
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEnrolling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enrollment failed: ${e.toString().replaceFirst("Exception: ", "")}'), backgroundColor: Colors.redAccent,)
        );
      }
    }
  }


  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    // ... same _buildDetailRow ...
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textMuted),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: const TextStyle(
                fontSize: 11.5,
                color: textMuted,
                fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: textSecondary,
                  fontWeight: FontWeight.normal),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... same image and priceText logic ...
    String? imageUrl = widget.course.thumbnail;
    String priceText = widget.course.courseType.toLowerCase() == 'free' ? 'Gratis' : 'Rp ${widget.course.coursePrice}';

    return Card( /* ... same Card setup ... */
      color: surfaceDark,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(flex: 5, child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network( /* ... same Image.network ... */
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[850],
                child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: textMuted, size: 36)),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                  color: accentRed,
                  strokeWidth: 2.0,
                ),
              );
            },
          )
              : Container(
            color: Colors.grey[850],
            child: const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: textMuted, size: 36)),
          ),),
          Flexible( /* ... same Flexible setup ... */
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 6.0, bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text( /* ... same Course Name ... */
                    widget.course.courseName,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3.0),
                  _buildDetailRow( /* ... same Durasi ... */
                      context,
                      icon: Icons.timer_outlined,
                      label: "Durasi",
                      value: "${widget.course.courseHour} jam"
                  ),
                  _buildDetailRow( /* ... same Harga ... */
                      context,
                      icon: Icons.sell_outlined,
                      label: "Harga",
                      value: priceText
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: _isEnrolling
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.0, color: accentRed))
                          : ElevatedButton(
                        onPressed: _isEnrolled ? null : _handleEnroll, // Disable if enrolled or enrolling
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEnrolled ? enrolledColor : accentRed,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          disabledBackgroundColor: _isEnrolled ? enrolledColor.withOpacity(0.7) : Colors.grey.shade700,
                        ),
                        child: Text(
                          _isEnrolled ? 'Enrolled' : 'Enroll',
                          style: TextStyle(color: _isEnrolled ? Colors.white.withOpacity(0.9) : textPrimary),
                        ),
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