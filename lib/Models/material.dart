// lib/Models/material.dart
class MaterialModel {
  final int id;
  final String topic;
  final String? videoUrl; // Embed URL, can be null if conversion failed or not a video
  final int courseId;

  MaterialModel({
    required this.id,
    required this.topic,
    this.videoUrl,
    required this.courseId,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] as int,
      topic: json['topic'] as String,
      videoUrl: json['video_url'] as String?,
      courseId: json['course_id'] as int,
    );
  }
}