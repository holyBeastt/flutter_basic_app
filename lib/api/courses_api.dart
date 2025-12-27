import 'dart:convert';
import 'package:android_basic/models/course.dart';
import 'package:android_basic/models/review.dart';
import 'package:android_basic/models/section.dart';
import 'package:android_basic/models/teacher_course.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';
import '../helpers/app_logger.dart';
import '../helpers/auth_helper.dart';

class CoursesApi {
  static Future<List<Course>> getCoursesList() async {
    final url = Uri.parse('$baseUrl/api/courses/top-courses-list');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  static Future<List<Course>> getCoursesBySearch(String query) async {
    final url = Uri.parse('$baseUrl/api/courses/search?query=$query');
    final response = await http.get(url);
    AppLogger.api('/api/courses/search', response.statusCode);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load courses by search');
    }
  }

  static Future<List<Course>> getCoursesByCategory(String category) async {
    final url = Uri.parse('$baseUrl/api/courses/category/$category');
    final response = await http.get(url);
    AppLogger.api('/api/courses/category', response.statusCode);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data as List)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load courses by category');
    }
  }

  static Future<List<Section>> fetchSections(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/courses/$courseId/sections'),
      );
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        if (decodedData is List) {
          return decodedData
              .map((e) => Section.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          AppLogger.debug('Expected List but got ${decodedData.runtimeType}');
          return [];
        }
      } else {
        throw Exception(
          'Failed to load sections. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Error in fetchSections', e);
      rethrow;
    }
  }

  static Future<List<Review>> fetchReviews(int courseId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/courses/$courseId/reviews'),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        if (decodedData is List) {
          return decodedData
              .map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList();
        } else {
          AppLogger.debug('Expected List but got ${decodedData.runtimeType}');
          return [];
        }
      } else {
        throw Exception(
          'Failed to load reviews. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Error in fetchReviews', e);
      rethrow;
    }
  }

  static Future<bool> submitReview({
    required int courseId,
    required int rating,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/api/courses/$courseId/reviews');

    // 1. Lấy Access Token từ Android Keystore/Keychain thông qua AuthHelper
    String? token = await AuthHelper.getAccessToken();

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      // 2. Gắn Token vào header để thực hiện phân quyền JWT
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Chỉ gửi rating và comment - server sẽ lấy userId từ JWT token
    final Map<String, dynamic> bodyData = {
      'rating': rating,
      'comment': comment,
    };

    try {
      // 3. Thực hiện gửi yêu cầu lần 1
      var response = await http.post(
        url,
        headers: headers,
        body: json.encode(bodyData),
      );

      // 4. Kiểm tra nếu Access Token hết hạn (401 Unauthorized)
      if (response.statusCode == 401) {
        print("[API] Access Token hết hạn, đang thử làm mới...");

        // Thực hiện cơ chế làm mới phiên làm việc
        bool isRefreshed = await AuthHelper.refreshSession();

        if (isRefreshed) {
          // Lấy lại token mới từ kho lưu trữ bảo mật
          token = await AuthHelper.getAccessToken();

          // 5. Thử lại (Retry) yêu cầu lần 2 với token mới
          response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(bodyData),
          );
        }
      }

      AppLogger.api('/api/courses/reviews', response.statusCode);

      // Trả về kết quả thành công (200 OK hoặc 201 Created)
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Lỗi khi gửi đánh giá: $e");
      return false;
    }
  }

  // Kiểm tra xem user đã đánh giá khóa học chưa
  static Future<Map<String, dynamic>> checkUserReview(int courseId) async {
    final url = Uri.parse('$baseUrl/api/courses/$courseId/check-review');

    // Lấy Access Token
    String? token = await AuthHelper.getAccessToken();

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      var response = await http.get(url, headers: headers);

      // Xử lý token hết hạn
      if (response.statusCode == 401) {
        print("[API] Access Token hết hạn, đang thử làm mới...");
        bool isRefreshed = await AuthHelper.refreshSession();

        if (isRefreshed) {
          token = await AuthHelper.getAccessToken();
          response = await http.get(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          );
        }
      }

      AppLogger.api('/api/courses/check-review', response.statusCode);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'hasReviewed': data['hasReviewed'] ?? false,
          'review': data['review'],
        };
      } else {
        return {'success': false, 'hasReviewed': false};
      }
    } catch (e) {
      AppLogger.error('Error in checkUserReview', e);
      return {'success': false, 'hasReviewed': false};
    }
  }

  // static Future<bool> submitReview({
  //   required int courseId,
  //   required int userId,
  //   required String userName,
  //   required int rating,
  //   required String comment,
  // }) async {
  //   final url = Uri.parse('$baseUrl/api/courses/$courseId/reviews');
  //   final response = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({
  //       'user_id': userId,
  //       'user_name': userName,
  //       'rating': rating,
  //       'comment': comment,
  //     }),
  //   );

  //   AppLogger.api('/api/courses/reviews', response.statusCode);

  //   return response.statusCode == 200 || response.statusCode == 201;
  // }

  static Future<TeacherInfoResponse> fetchTeacherInfo(int userID) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/courses/$userID/gv-info'),
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        // Kiểm tra xem response có đúng format không
        if (decodedData is Map<String, dynamic>) {
          // Kiểm tra có key 'teacher' và 'courses' không
          if (decodedData.containsKey('teacher') &&
              decodedData.containsKey('courses')) {
            return TeacherInfoResponse.fromJson(decodedData);
          } else {
            AppLogger.debug(
              "Response format không đúng. Expected keys: 'teacher', 'courses'",
            );
            AppLogger.debug('Actual response: $decodedData');
            throw Exception('Invalid response format');
          }
        } else {
          AppLogger.debug(
            'Expected Map<String, dynamic> but got ${decodedData.runtimeType}',
          );
          AppLogger.debug('Actual response: $decodedData');
          throw Exception('Invalid response type');
        }
      } else {
        throw Exception(
          'Failed to load teacher info. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Error in fetchTeacherInfo', e);
      rethrow;
    }
  }

  static Future<Map<String, List<Course>>> fetchPersonalCourses(
    int userID,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/personal-courses/$userID/personal-courses-list',
      ),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      // Parse danh sách ownedCourses
      final List<Course> ownedCourses =
          (jsonData['ownedCourses'] as List)
              .map((e) => Course.fromJson(e))
              .toList();

      // Parse danh sách enrolledCourses (dữ liệu nằm trong key 'courses')
      final List<Course> enrolledCourses =
          (jsonData['enrolledCourses'] as List)
              .map((e) => Course.fromJson(e['courses']))
              .toList();

      return {'ownedCourses': ownedCourses, 'enrolledCourses': enrolledCourses};
    } else {
      throw Exception(
        'Không thể tải danh sách khóa học (${response.statusCode})',
      );
    }
  }
}
