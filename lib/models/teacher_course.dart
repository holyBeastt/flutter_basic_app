import 'package:android_basic/models/course.dart';
import 'package:android_basic/models/user.dart';

class TeacherInfoResponse {
  final User teacher;
  final List<Course> courses;

  TeacherInfoResponse({required this.teacher, required this.courses});

  factory TeacherInfoResponse.fromJson(Map<String, dynamic> json) {
    return TeacherInfoResponse(
      teacher: User.fromJson(json['teacher'] as Map<String, dynamic>),
      courses:
          (json['courses'] as List<dynamic>?)
              ?.map(
                (courseJson) =>
                    Course.fromJson(courseJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
