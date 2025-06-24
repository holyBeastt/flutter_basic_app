// lib/models/quiz_question.dart
class QuizQuestion {
  final String questionText;
  final Map<String, dynamic> options;
  final String correctOption;
  final String explanation;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctOption,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['question_text'],
      options: Map<String, dynamic>.from(json['options']),
      correctOption: json['correct_option'],
      explanation: json['explanation'],
    );
  }
}
