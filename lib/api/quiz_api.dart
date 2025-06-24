// lib/api/quiz_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/server.dart';

class QuizApi {
  static Future<List<Map<String, dynamic>>> getCheckpointsByLesson(
    int lessonId,
  ) async {
    final url = Uri.parse('$baseUrl/api/v1/checkpoints/$lessonId');
    final response = await http.get(url);

    print("gà");
    print(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load quiz checkpoints');
    }
  }

  static Future<List<Map<String, dynamic>>> getQuizQuestions(int quizId) async {
    final url = Uri.parse('$baseUrl/api/v1/quiz/$quizId/questions');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Failed to load quiz questions');
    }
  }
}
