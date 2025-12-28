import 'dart:convert';
import '../services/http_client.dart';
import '../config/server.dart';
import '../helpers/auth_helper.dart';
import '../helpers/app_logger.dart';

class LessonApi {
  /// Request signed URL for a lesson video
  // static Future<String?> (
  //   int lessonId, {
  //   int expiresIn = 3600,
  // }) async {
  //   final token = await AuthHelper.getAccessToken();
  //   final url = Uri.parse(
  //     '$baseUrl/api/courses/lessons/$lessonId/signed-url?expiresIn=$expiresIn',
  //   );

  //   final res = await AppHttpClient.get(
  //     url,
  //     headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  //   );

  //   if (res.statusCode == 200) {
  //     final json = jsonDecode(res.body);
  //     return json['signedUrl'] as String?;
  //   }

  //   return null;
  // }

  /// Request signed URL for a lesson video
  /// Server will determine the expiration time based on video duration
  static Future<String?> getSignedUrl(int lessonId) async {
    String? token = await AuthHelper.getAccessToken();

    final url = Uri.parse(
      '$baseUrl/api/courses/student/lessons/$lessonId/signed-url',
    );

    // Lần gọi 1
    AppLogger.debug('Getting signed URL for lesson $lessonId');
    AppLogger.debug('Full URL: ${url.toString()}');
    AppLogger.debug('Token present: ${token != null}');
    var res = await AppHttpClient.get(
      url,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
    AppLogger.debug('Response status: ${res.statusCode}');
    AppLogger.debug('Response body: ${res.body}');

    // XỬ LÝ REFRESH TOKEN TỰ ĐỘNG
    if (res.statusCode == 401) {
      AppLogger.debug('Access Token expired, refreshing...');

      bool success = await AuthHelper.refreshSession();

      if (success) {
        // Lấy token mới vừa được lưu
        token = await AuthHelper.getAccessToken();

        // Lần gọi 2 (Retry)
        res = await AppHttpClient.get(
          url,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        );
        AppLogger.debug('Refresh success, got new URL');
      } else {
        AppLogger.debug('Refresh failed, user needs to login again');
        return null;
      }
    }

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['signedUrl'] as String?;
    }

    // Log detailed error for debugging
    AppLogger.error(
      'Failed to get signed URL - Status: ${res.statusCode}, Body: ${res.body}',
    );
    return null;
  }
}
