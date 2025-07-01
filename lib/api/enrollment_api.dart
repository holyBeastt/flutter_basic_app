import 'dart:convert';
import 'package:android_basic/config/server.dart';
import 'package:http/http.dart' as http;

class EnrollmentApi {
  // Cache để lưu trạng thái đăng ký locally (thay thế cho PaymentApi storage)
  static final Map<String, bool> _enrolledCourses = {};

  static Future<bool> enrollCourse({required int courseId, required int userId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/enrollments/$courseId/enroll'),
      body: jsonEncode({'userId': userId}),
      headers: {'Content-Type': 'application/json'},
    );

    // Nếu đăng ký thành công, lưu vào cache
    if (response.statusCode == 200) {
      final key = '${userId}_$courseId';
      _enrolledCourses[key] = true;
      return true;
    }
    return false;
  }

  static Future<bool> checkEnrolled({
    required int courseId,
    required int userId,
  }) async {
    // Kiểm tra cache trước
    final key = '${userId}_$courseId';
    if (_enrolledCourses.containsKey(key) && _enrolledCourses[key] == true) {
      return true;
    }

    // Nếu không có trong cache, gọi API
    final response = await http.get(
      Uri.parse('$baseUrl/api/enrollments/$courseId/check-enrollment?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final isEnrolled = data['enrolled'] == true;

      // Lưu kết quả vào cache
      _enrolledCourses[key] = isEnrolled;
      return isEnrolled;
    }
    return false;
  }

  // Phương thức hỗ trợ để đánh dấu khóa học đã được đăng ký (dùng sau khi thanh toán thành công)
  static void markCourseEnrolled(int userId, int courseId) {
    final key = '${userId}_$courseId';
    _enrolledCourses[key] = true;
  }

  // Phương thức kiểm tra khóa học đã mua/đăng ký chưa (thay thế checkCoursePurchase)
  static Future<Map<String, dynamic>> checkCourseAccess(int userId, int courseId) async {
    try {
      final isEnrolled = await checkEnrolled(courseId: courseId, userId: userId);

      return {
        'success': true,
        'data': {
          'is_purchased': isEnrolled, // Coi như đã "mua" nếu đã đăng ký
          'is_enrolled': isEnrolled,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kiểm tra trạng thái khóa học: $e',
        'data': {
          'is_purchased': false,
          'is_enrolled': false,
        }
      };
    }
  }
}

// Example of how to use the EnrollmentApi
