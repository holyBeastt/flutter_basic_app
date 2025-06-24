import 'package:flutter/material.dart';
import '../models/quiz_question.dart';

class QuizDialog extends StatelessWidget {
  final List<QuizQuestion> questions;
  const QuizDialog({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    // Lưu lựa chọn của người dùng cho từng câu
    final Map<QuizQuestion, String?> answers = {};

    return AlertDialog(
      title: const Text('Quiz Kiểm Tra'),
      // Dùng StatefulBuilder để cập nhật UI Radio trong dialog
      content: StatefulBuilder(
        builder:
            (context, setState) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    questions
                        .map((q) => _buildQuestion(q, answers, setState))
                        .toList(),
              ),
            ),
      ),
      actions: [
        TextButton(
          child: const Text('Nộp bài'),
          onPressed: () {
            // Tính xem tất cả câu trả lời đã đúng chưa
            final passed = questions.every(
              (q) => answers[q] != null && answers[q] == q.correctOption,
            );
            Navigator.pop(context, passed); // <-- trả kết quả true/false
          },
        ),
      ],
    );
  }

  Widget _buildQuestion(
    QuizQuestion question,
    Map<QuizQuestion, String?> answers,
    void Function(void Function()) setState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.questionText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...question.options.entries.map(
          (entry) => RadioListTile<String>(
            title: Text('${entry.key}: ${entry.value}'),
            value: entry.key,
            groupValue: answers[question],
            onChanged: (val) => setState(() => answers[question] = val),
          ),
        ),
        const Divider(),
      ],
    );
  }
}
