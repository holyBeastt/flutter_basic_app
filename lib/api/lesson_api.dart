import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server.dart';
import '../helpers/auth_helper.dart';

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
    print("hoi hoi");
    var res = await http.get(
      url,
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );

    // XỬ LÝ REFRESH TOKEN TỰ ĐỘNG
    if (res.statusCode == 401) {
      print("Access Token hết hạn, đang tiến hành làm mới...");

      bool success = await AuthHelper.refreshSession();

      if (success) {
        // Lấy token mới vừa được lưu
        token = await AuthHelper.getAccessToken();

        // Lần gọi 2 (Retry)
        res = await http.get(
          url,
          headers: token != null ? {'Authorization': 'Bearer $token'} : {},
        );
        print("Refresh thành công, đã lấy được URL mới.");
      } else {
        print("Refresh thất bại, người dùng cần đăng nhập lại.");
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
