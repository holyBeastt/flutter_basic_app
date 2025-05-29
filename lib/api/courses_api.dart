import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server.dart';

class CoursesApi {
  static Future<List<dynamic>> getCoursesList() async {
    final url = Uri.parse('$baseUrl/api/courses/top-courses-list');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body); // Trả về list courses
    } else {
      throw Exception('Failed to load courses');
    }
  }
}
