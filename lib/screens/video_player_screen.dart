import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../api/quiz_api.dart';
import '../models/quiz_question.dart';
import '../widgets/quiz_dialog.dart';
import '../api/progress_api.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  final int lessonId;

  const VideoPlayerScreen({
    super.key,
    required this.url,
    required this.lessonId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final Player player;
  late final VideoController controller;
  Timer? _timer;
  List<Map<String, dynamic>> _checkpoints = [];
  Set<int> _triggeredQuizzes = {};
  bool _isQuizActive = false; // NEW: đánh dấu đang hiển thị quiz

  static const _kSaveInterval = 15; // gửi progress mỗi 15 s
  int _lastSavedSec = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    player.open(Media(widget.url));
    _loadCheckpoints();
    _startTimeMonitoring();
  }

  @override
  void dispose() {
    final last = player.state.position?.inSeconds ?? 0;
    if (!_isCompleted && last > 0) {
      unawaited(
        ProgressApi.saveProgress(lessonId: widget.lessonId, seconds: last),
      );
    }
    _timer?.cancel();
    player.dispose();
    super.dispose();
  }

  void _loadCheckpoints() async {
    try {
      final data = await QuizApi.getCheckpointsByLesson(widget.lessonId);
      setState(() {
        _checkpoints = data;
      });
    } catch (e) {
      print("Error loading checkpoints: $e");
    }
  }

  void _startTimeMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 1. Bỏ qua nếu video đang pause hoặc đang show quiz
      if (!player.state.playing || _isQuizActive) return;

      final pos = player.state.position;
      final dur = player.state.duration; // ← NEW
      if (pos == null || dur == null) return;

      final seconds = pos.inSeconds;

      // ---------- PROGRESS : lưu định kỳ ----------
      if (seconds - _lastSavedSec >= _kSaveInterval) {
        _lastSavedSec = seconds;
        unawaited(
          ProgressApi.saveProgress(lessonId: widget.lessonId, seconds: seconds),
        );
      }

      // Kiểm tra checkpoint để bật quiz
      for (var cp in _checkpoints) {
        final quizId = cp["quiz_id"] as int;
        final time = cp["time_in_video"] as int;

        if (seconds >= time && !_triggeredQuizzes.contains(quizId)) {
          _triggeredQuizzes.add(quizId);
          _pauseAndShowQuiz(quizId);
          break; // tránh kích hoạt nhiều quiz cùng tick
        }
      }

      // ---------- PROGRESS : đánh dấu hoàn thành ----------
      const tol = 3;
      if (!_isCompleted &&
          seconds >= dur.inSeconds - tol &&
          _triggeredQuizzes.length == _checkpoints.length) {
        _isCompleted = true;
        unawaited(ProgressApi.markCompleted(widget.lessonId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎉 Bạn đã hoàn thành bài học!')),
          );
        }
      }
    });
  }

  void _pauseAndShowQuiz(int quizId) async {
    _isQuizActive = true;
    await player.pause();

    try {
      final response = await QuizApi.getQuizQuestions(quizId);
      final questions = response.map((e) => QuizQuestion.fromJson(e)).toList();

      final bool? passed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => QuizDialog(questions: questions),
      );

      if (passed == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Chính xác! Tiếp tục video.'),
            duration: Duration(seconds: 1),
          ),
        );
        await player.play();
      } else {
        // ❌ Trả lời sai
        final int? previousTime = _getPreviousCheckpointTime(quizId);
        final targetTime =
            previousTime != null
                ? Duration(seconds: previousTime)
                : Duration.zero;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              previousTime != null
                  ? '❌ Sai rồi! Quay lại checkpoint trước đó.'
                  : '❌ Sai rồi! Quay lại đầu video.',
            ),
            duration: Duration(seconds: 1),
          ),
        );

        _triggeredQuizzes.remove(quizId); // Cho phép quiz xuất hiện lại
        await player.seek(targetTime);
        await player.play();
      }
    } catch (e) {
      print('Error loading quiz questions: $e');
      await player.play();
    } finally {
      _isQuizActive = false;
    }
  }

  /// Tìm checkpoint gần nhất phía trước quiz hiện tại
  int? _getPreviousCheckpointTime(int quizId) {
    // Tìm checkpoint hiện tại
    final current = _checkpoints.firstWhere(
      (cp) => cp['quiz_id'] == quizId,
      orElse: () => {},
    );

    if (current.isEmpty) return null;

    final currentTime = current['time_in_video'] as int;

    // Lọc ra các checkpoint phía trước
    final previous =
        _checkpoints.where((cp) => cp['time_in_video'] < currentTime).toList();

    if (previous.isEmpty) return null;

    // Lấy checkpoint có thời gian lớn nhất < current
    previous.sort(
      (a, b) =>
          (b['time_in_video'] as int).compareTo(a['time_in_video'] as int),
    );

    return previous.first['time_in_video'] as int;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Video(controller: controller)),
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
