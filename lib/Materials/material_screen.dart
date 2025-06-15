import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../Models/material.dart';
import '../services/course_service.dart';
import '../services/auth_services.dart';
import '../Quiz/quiz_start_screen.dart';

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

class _MaterialScreenState extends State<MaterialScreen> with WidgetsBindingObserver {
  Future<List<MaterialModel>>? _materialsFuture;
  final CourseService _courseService = CourseService();
  final AuthService _authService = AuthService();

  final Map<int, YoutubePlayerController> _youtubeControllers = {};
  int? _playingVideoId;
  final Map<int, Duration> _videoPositions = {};

  static const Color primaryDark = Color(0xFF131519);
  static const Color surfaceDark = Color(0xFF1E2125);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color accentRed = Color(0xFF680d13);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMaterials();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _youtubeControllers.values) {
      controller.pause();
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      for (var entry in _youtubeControllers.entries) {
        final controller = entry.value;
        final pos = controller.value.position;
        _videoPositions[entry.key] = pos;
      }
    }
  }

  Future<void> _loadMaterials() async {
    String? token = await _authService.getToken();
    if (token != null) {
      var future = _courseService.fetchCourseMaterials(widget.courseId, token);
      setState(() {
        _materialsFuture = future;
      });
      future.then((materials) {
        _initializeYoutubeControllers(materials);
      }).catchError((error) {
        print("Error loading materials for controller init: $error");
      });
    } else {
      setState(() {
        _materialsFuture = Future.value([]);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _initializeYoutubeControllers(List<MaterialModel> materials) {
    for (var controller in _youtubeControllers.values) {
      controller.dispose();
    }
    _youtubeControllers.clear();

    for (var material in materials) {
      if (material.videoUrl != null && material.videoUrl!.isNotEmpty) {
        String? videoId = YoutubePlayer.convertUrlToId(material.videoUrl!);
        if (videoId != null) {
          final controller = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              disableDragSeek: false,
              enableCaption: false,
              forceHD: true,
              useHybridComposition: true,
            ),
          );

          controller.addListener(() {
            if (_videoPositions.containsKey(material.id)) {
              final savedPos = _videoPositions[material.id]!;
              if ((controller.value.position - savedPos).inSeconds.abs() > 1) {
                controller.seekTo(savedPos);
              }
            }

            if (controller.value.isFullScreen) {
              _playingVideoId = material.id;
            } else {
              _playingVideoId = null;
            }
          });

          _youtubeControllers[material.id] = controller;
        }
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            if (isLandscape && _playingVideoId != null) {
              final controller = _youtubeControllers[_playingVideoId];
              return Center(
                child: YoutubePlayer(
                  controller: controller!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: accentRed,
                  progressColors: const ProgressBarColors(
                    playedColor: accentRed,
                    handleColor: accentRed,
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (!isLandscape)
                  AppBar(
                    title: Text(widget.courseName),
                    backgroundColor: surfaceDark,
                    titleTextStyle: const TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    iconTheme: const IconThemeData(color: textPrimary),
                  ),
                Expanded(
                  child: FutureBuilder<List<MaterialModel>>(
                    future: _materialsFuture,
                    builder: (context, snapshot) {
                      if (_materialsFuture == null) {
                        return const Center(child: Text('Error: Not logged in.', style: TextStyle(color: textSecondary)));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: accentRed));
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Error: ${snapshot.error.toString().replaceFirst("Exception: ", "")}',
                                    style: const TextStyle(color: textSecondary, fontSize: 16), textAlign: TextAlign.center),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try Again'),
                                  onPressed: _loadMaterials,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: surfaceDark,
                                    foregroundColor: textPrimary,
                                  ),
                                )
                              ],
                            ),
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
                                key: PageStorageKey('material_${material.id}'),
                                title: Text(
                                  material.topic,
                                  style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
                                ),
                                children: <Widget>[
                                  if (controller != null && material.videoUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.all(10.0).copyWith(top: 0),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: YoutubePlayer(
                                          controller: controller,
                                          showVideoProgressIndicator: true,
                                          progressIndicatorColor: accentRed,
                                          progressColors: const ProgressBarColors(
                                            playedColor: accentRed,
                                            handleColor: accentRed,
                                          ),
                                        ),
                                      ),
                                    )
                                  else if (material.videoUrl != null && material.videoUrl!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text("Could not load video: ${material.videoUrl}", style: const TextStyle(color: Colors.redAccent)),
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
                ),
                if (!isLandscape)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.quiz_rounded),
                      label: const Text('Take The Final Quiz'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizStartScreen(
                              courseId: widget.courseId,
                              courseName: widget.courseName,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentRed,
                        foregroundColor: textPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
              ],
            );
          },
        ),
      ),
    );
  }
}
