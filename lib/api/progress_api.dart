// lib/api/progress_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server.dart'; // chứa baseUrl

class ProgressApi {
  /// -------------------------------
  /// 1. Ghi mốc thời gian đã xem (giây)
  /// -------------------------------
  static Future<void> saveProgress({
    required int lessonId,
    required int seconds,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/save-progress');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lessonId': lessonId, 'seconds': seconds}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to save progress: ${res.body}');
    }
  }

  /// -------------------------------
  /// 2. Đánh dấu hoàn thành bài học
  /// -------------------------------
  static Future<void> markCompleted(int lessonId) async {
    final url = Uri.parse('$baseUrl/api/v1/progress/complete');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lessonId': lessonId}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to mark completed: ${res.body}');
    }
  }

  /// -------------------------------
  /// 3. Lấy map bài học đã hoàn thành trong 1 khoá
  ///    Trả về: { lessonId: isCompleted, ... }
  /// -------------------------------
  static Future<Map<int, bool>> fetchCourseProgress(int courseId) async {
    final url = Uri.parse('$baseUrl/api/progress/$courseId');
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      // [{ "lesson_id": 12, "is_completed": true }, ...]
      return {
        for (final item in data)
          item['lesson_id'] as int: item['is_completed'] == true,
      };
    } else {
      throw Exception('Failed to load progress');
    }
  }
}
