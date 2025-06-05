// lib/Material/material_screen.dart
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../Models/material.dart'; // Your MaterialModel
import '../Services/course_service.dart';
import '../services/auth_services.dart';

class MaterialScreen extends StatefulWidget {
  final int courseId;
  final String courseName;

  const MaterialScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  Future<List<MaterialModel>>? _materialsFuture;
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  Map<int, YoutubePlayerController> _youtubeControllers = {};

  // Consistent theme colors
  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    String? token = await _authService.getToken();
    if (token != null) {
      setState(() {
        _materialsFuture = _courseService.fetchCourseMaterials(widget.courseId, token);
      });
      _materialsFuture?.then((materials) {
        _initializeYoutubeControllers(materials);
      });
    } else {
      // Handle not logged in - though user should be enrolled to reach here
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error.'), backgroundColor: Colors.redAccent)
        );
      }
      setState(() {
        _materialsFuture = Future.value([]);
      });
    }
  }

  void _initializeYoutubeControllers(List<MaterialModel> materials) {
    for (var material in materials) {
      if (material.videoUrl != null && material.videoUrl!.isNotEmpty) {
        String? videoId = YoutubePlayer.convertUrlToId(material.videoUrl!);
        if (videoId != null) {
          _youtubeControllers[material.id] = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              // disableDragSeek: true,
              // loop: true,
              // isLive: false,
              // forceHD: false,
              // enableCaption: true,
            ),
          );
        }
      }
    }
    if(mounted) setState(() {}); // Refresh UI if controllers are ready
  }


  @override
  void dispose() {
    // Dispose all YouTube controllers
    for (var controller in _youtubeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName),
        backgroundColor: surfaceDark,
        titleTextStyle: const TextStyle(
            color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      backgroundColor: primaryDark,
      body: FutureBuilder<List<MaterialModel>>(
        future: _materialsFuture,
        builder: (context, snapshot) {
          if (_materialsFuture == null) {
            return const Center(child: Text('Error loading materials.', style: TextStyle(color: textSecondary)));
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
                      onPressed: _loadMaterials,
                      style: ElevatedButton.styleFrom(backgroundColor: surfaceDark, foregroundColor: textPrimary))
                ]),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No materials available for this course yet.',
                style: TextStyle(fontSize: 18, color: textSecondary),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            final List<MaterialModel> materials = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];
                final controller = _youtubeControllers[material.id];

                return Card(
                  color: surfaceDark,
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ExpansionTile(
                    iconColor: textSecondary,
                    collapsedIconColor: textSecondary,
                    key: PageStorageKey('material_${material.id}'), // For maintaining expansion state
                    title: Text(
                      material.topic,
                      style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                    ),
                    children: <Widget>[
                      if (controller != null && material.videoUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(10.0).copyWith(top:0),
                          child: YoutubePlayer(
                            controller: controller,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: accentRed,
                            progressColors: const ProgressBarColors(
                              playedColor: accentRed,
                              handleColor: accentRed,
                            ),
                            // onReady: () {
                            //   // _isPlayerReady = true;
                            // },
                          ),
                        )
                      else if (material.videoUrl != null && material.videoUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Could not load video: ${material.videoUrl}", style: TextStyle(color: Colors.redAccent)),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No video available for this topic.', style: TextStyle(color: textSecondary)),
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