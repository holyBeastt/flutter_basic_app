import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server.dart';
import '../helpers/auth_helper.dart';

class LessonApi {
  /// Request signed URL for a lesson video
  static Future<String?> getSignedUrl(
    int lessonId, {
    int expiresIn = 3600,
  }) async {
    final token = await AuthHelper.getAccessToken();
    final url = Uri.parse(
      '$baseUrl/api/courses/lessons/$lessonId/signed-url?expiresIn=$expiresIn',
    );

    final res = await http.get(
      url,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return json['signedUrl'] as String?;
    }

    return null;
  }
}
