import 'dart:convert';
import 'package:android_basic/models/course.dart';
import 'package:android_basic/models/review.dart';
import 'package:android_basic/models/section.dart';
import 'package:android_basic/models/teacher_course.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';

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
          print("Expected List but got ${decodedData.runtimeType}");
          return [];
        }
      } else {
        throw Exception(
          'Failed to load sections. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in fetchSections: $e');
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
          print("Expected List but got ${decodedData.runtimeType}");
          return [];
        }
      } else {
        throw Exception(
          'Failed to load reviews. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in fetchReviews: $e');
      rethrow;
    }
  }

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
            print(
              "Response format không đúng. Expected keys: 'teacher', 'courses'",
            );
            print("Actual response: $decodedData");
            throw Exception('Invalid response format');
          }
        } else {
          print(
            "Expected Map<String, dynamic> but got ${decodedData.runtimeType}",
          );
          print("Actual response: $decodedData");
          throw Exception('Invalid response type');
        }
      } else {
        throw Exception(
          'Failed to load teacher info. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in fetchTeacherInfo: $e');
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
