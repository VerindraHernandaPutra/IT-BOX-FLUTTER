import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Models/course.dart';
import '../services/course_service.dart';
import '../services/auth_services.dart';
import '../Materials/material_screen.dart';

class MyCourseScreen extends StatefulWidget {
  const MyCourseScreen({super.key});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen> {
  Future<List<Course>>? _myCoursesFuture;
  List<Map<String, dynamic>> _certificates = [];
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    _loadMyCourses();
  }

  Future<void> _loadMyCourses() async {
    String? token = await _authService.getToken();
    if (token != null) {
      final certs = await _courseService.fetchUserCertificates(token);
      if (mounted) {
        setState(() {
          _myCoursesFuture = _courseService.fetchMyEnrolledCourses(token);
          _certificates = certs;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _myCoursesFuture = Future.value([]);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to see your courses.'), backgroundColor: Colors.orangeAccent),
        );
      }
    }
  }

  Future<void> _downloadCertificate(int certificateId) async {
    String? token = await _authService.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You are not logged in.")));
      return;
    }

    final permission = await _requestStoragePermission();
    if (!permission) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Storage permission denied.")));
      return;
    }

    try {
      Uint8List pdfBytes = await _courseService.downloadCertificatePdf(certificateId, token);
      Directory directory = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      final filePath = '${directory.path}/certificate_$certificateId.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to Download: certificate_$certificateId.pdf")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to download: $e")));
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  bool _hasCertificate(int courseId) {
    return _certificates.any((c) => c['course_id'] == courseId);
  }

  int? _getCertificateId(int courseId) {
    return _certificates.firstWhere((c) => c['course_id'] == courseId, orElse: () => {})['id'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Enrolled Courses'),
        backgroundColor: surfaceDark,
        titleTextStyle: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
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
                String? imageUrl = course.thumbnail;
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  final isAndroidEmulator = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
                  if (isAndroidEmulator) {
                    imageUrl = imageUrl.replaceAll('localhost', '10.0.2.2');
                  }
                }

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
                          height: 160,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (_hasCertificate(course.id))
                                  IconButton(
                                    icon: const Icon(Icons.download_rounded),
                                    tooltip: 'Download Certificate',
                                    color: Colors.green,
                                    onPressed: () async {
                                      final certId = _getCertificateId(course.id);
                                      if (certId != null) await _downloadCertificate(certId);
                                    },
                                  ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_circle_filled_rounded, size: 18),
                                  label: const Text('Start Learning'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MaterialScreen(
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
                                )
                              ],
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
