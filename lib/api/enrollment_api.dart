import 'dart:convert';
import 'package:android_basic/config/server.dart';
import 'package:http/http.dart' as http;

class EnrollmentApi {
  static Future<bool> enrollCourse({required int courseId, required int userId}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/enrollments/$courseId/enroll'),
      body: jsonEncode({'userId': userId}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }
static Future<bool> checkEnrolled({
    required int courseId,
    required int userId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/enrollments/$courseId/check-enrollment?userId=$userId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['enrolled'] == true;
    }
    return false;
  }
}

// Example of how to use the EnrollmentApi
