import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server.dart';
import '../helpers/auth_helper.dart';
import '../helpers/app_logger.dart';

class LessonApi {
  /// Request signed URL for a lesson video
  // static Future<String?> getSignedUrl(
  //   int lessonId, {
  //   int expiresIn = 3600,
  // }) async {
  //   final token = await AuthHelper.getAccessToken();
  //   final url = Uri.parse(
  //     '$baseUrl/api/courses/lessons/$lessonId/signed-url?expiresIn=$expiresIn',
  //   );

  //   final res = await http.get(
  //     url,
  //     headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  //   );

  //   if (res.statusCode == 200) {
  //     final json = jsonDecode(res.body);
  //     return json['signedUrl'] as String?;
  //   }

  //   return null;
  // }

  static Future<String?> getSignedUrl(
    int lessonId, {
    int expiresIn = 60,
  }) async {
    String? token = await AuthHelper.getAccessToken();

    final url = Uri.parse(
      '$baseUrl/api/courses/lessons/$lessonId/signed-url?expiresIn=$expiresIn',
    );

    // Lần gọi 1
    AppLogger.debug('Getting signed URL for lesson $lessonId');
    var res = await http.get(
      url,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    // XỬ LÝ REFRESH TOKEN TỰ ĐỘNG
    if (res.statusCode == 401) {
      AppLogger.debug('Access Token expired, refreshing...');

      bool success = await AuthHelper.refreshSession();

      if (success) {
        // Lấy token mới vừa được lưu
        token = await AuthHelper.getAccessToken();

        // Lần gọi 2 (Retry)
        res = await http.get(
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

    return null;
  }
}
