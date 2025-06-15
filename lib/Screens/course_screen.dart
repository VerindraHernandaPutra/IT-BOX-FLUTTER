// lib/Screens/course_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Models/course.dart';
import '../services/course_service.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  late Future<List<Course>> _coursesFuture;
  final CourseService _courseService = CourseService();

  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    _coursesFuture = _courseService.fetchCourses();
  }

  void _refreshCourses() {
    setState(() {
      _coursesFuture = _courseService.fetchCourses();
    });
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
      body: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentRed));
          } else if (snapshot.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child:
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      'Failed to load courses: ${snapshot.error.toString().split(':').skip(1).join(':').trim()}',
                      style: const TextStyle(color: textSecondary, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        onPressed: _refreshCourses,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: surfaceDark,
                          foregroundColor: textPrimary,
                        ))
                  ]),
                ));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
                  'No courses available at the moment.',
                  style: TextStyle(fontSize: 18, color: textSecondary),
                ));
          } else {
            final List<Course> courses = snapshot.data!;
            return LayoutBuilder(
              builder: (BuildContext layoutContext, BoxConstraints constraints) {
                int crossAxisCount;
                double childAspectRatio;

                if (constraints.maxWidth < 400) {
                  crossAxisCount = 1;
                  childAspectRatio = 0.8;
                } else if (constraints.maxWidth < 720) {
                  crossAxisCount = 2;
                  // Giving it slightly more height to accommodate two-line titles reliably
                  childAspectRatio = 0.76; // <<< ADJUSTED THIS VALUE
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
                    return CourseCard(course: courses[index]);
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

class CourseCard extends StatelessWidget {
  final Course course;

  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color accentRed = Color(0xFF680d13);

  const CourseCard({super.key, required this.course});

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: textMuted),
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
              softWrap: false, // Prevents wrapping that might increase height
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? imageUrl = course.thumbnail;
    String priceText = course.courseType.toLowerCase() == 'free' ? 'Gratis' : 'Rp ${course.coursePrice}';

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
          // Thumbnail
          Expanded(
            flex: 5, // Image gets 5 parts of height
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network( /* ... same Image.network code ... */
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
          // Content Area
          Expanded(
            flex: 5, // Text area also gets 5 parts of height
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // This works well if content is compact
                children: <Widget>[
                  // Top content (Title and details)
                  // Wrapped title in Flexible to allow it to shrink if needed.
                  Flexible(
                    child: Text(
                      course.courseName,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        height: 1.2, // Reduced line height
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4.0),
                      _buildDetailRow(
                          icon: Icons.timer_outlined,
                          label: "Durasi",
                          value: "${course.courseHour} jam"
                      ),
                      _buildDetailRow(
                          icon: Icons.sell_outlined,
                          label: "Harga",
                          value: priceText
                      ),
                    ],
                  ),

                  // Enroll Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Implement enroll logic
                        print('Enroll button pressed for ${course.courseName}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentRed,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Enroll', style: TextStyle(color: textPrimary)),
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
