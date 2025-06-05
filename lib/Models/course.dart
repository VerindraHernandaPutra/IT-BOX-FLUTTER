// lib/Models/course.dart
class Course {
  final int id;
  final String courseName;
  final int courseHour;
  final int coursePrice;
  final String courseType;
  final String description;
  final String? thumbnail; // Nullable, assuming API provides full URL or null

  Course({
    required this.id,
    required this.courseName,
    required this.courseHour,
    required this.coursePrice,
    required this.courseType,
    required this.description,
    this.thumbnail,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      courseName: json['name'] as String,         // Matches API key 'name'
      courseHour: json['hours'] as int,           // Matches API key 'hours'
      coursePrice: json['price'] as int,         // Matches API key 'price'
      courseType: json['type'] as String,         // Matches API key 'type'
      description: json['description'] as String,
      thumbnail: json['thumbnail'] as String?,
    );
  }
}