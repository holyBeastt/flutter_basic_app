import 'package:android_basic/models/lesson.dart';
import '../helpers/app_logger.dart';

class Section {
  final int id;
  final String? title;
  final List<Lesson> lessons;

  Section({required this.id, required this.title, required this.lessons});

  factory Section.fromJson(Map<String, dynamic> json) {
    try {
      List<Lesson> lessons = [];
      if (json['lessons'] != null) {
        lessons =
            (json['lessons'] as List<dynamic>)
                .map((lessonJson) => Lesson.fromJson(lessonJson))
                .toList();
      }

      return Section(
        id: _parseToInt(json['id']),
        title: json['title'] ?? '',
        lessons: lessons,
      );
    } catch (e) {
      AppLogger.error('Error parsing Section', e);
      AppLogger.debug('JSON data: $json');
      rethrow;
    }
  }

  // Helper method to safely parse int
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
