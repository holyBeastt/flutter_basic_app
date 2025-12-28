// lib/api/progress_api.dart
import 'dart:convert';
import '../services/http_client.dart';
import '../config/server.dart';
import '../helpers/app_logger.dart'; // chứa baseUrl

class ProgressApi {
  /// -------------------------------
  /// 1. Ghi mốc thời gian đã xem (giây)
  /// -------------------------------
  static Future<void> saveProgress({
    required int lessonId,
    required int seconds,
    required int userId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/save-progress');
    AppLogger.debug(
      'saveProgress: lessonId=$lessonId, seconds=$seconds, userId=$userId',
    );
    final res = await AppHttpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lessonId': lessonId,
        'seconds': seconds,
        'userId': userId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to save progress: ${res.body}');
    }
  }

  /// -------------------------------
  /// 2. Đánh dấu hoàn thành bài học
  /// -------------------------------
  static Future<void> markCompleted(int lessonId, int userId) async {
    final url = Uri.parse('$baseUrl/api/v1/progress/complete');
    final res = await AppHttpClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'lessonId': lessonId, 'userId': userId}),
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
    final res = await AppHttpClient.get(url);

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

  static Future<int?> getProgress(int lessonId, int userId) async {
    final url = Uri.parse('$baseUrl/api/v1/progress/$lessonId');
    AppLogger.debug('getProgress: lessonId=$lessonId, userId=$userId');
    final res = await AppHttpClient.get(
      url,
      headers: {
        'user-id': '$userId', // 👈 gửi thủ công
      },
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['seconds'] as int?;
    }

    if (res.statusCode == 404) {
      // Chưa có tiến độ → trả về null
      return null;
    }

    throw Exception('Failed to load progress: ${res.body}');
  }

  static Future<Map<int, bool>> getAllProgressForUser(int userId) async {
    final url = Uri.parse('$baseUrl/api/v1/progress-all/user/$userId');
    final res = await AppHttpClient.get(url);

    if (res.statusCode == 200) {
      final raw = jsonDecode(res.body) as Map<String, dynamic>;
      return raw.map((key, value) => MapEntry(int.parse(key), value as bool));
    } else {
      throw Exception('Lỗi lấy tiến độ');
    }
  }
}
