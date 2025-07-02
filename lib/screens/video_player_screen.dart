import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../helpers/auth_helper.dart';

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
  int userId = 0;

  bool _progressRestored = false; // chặn seek nhiều lần
  StreamSubscription<Duration>? _durationSub; // hủy khi dispose

  Timer? _timer;
  List<Map<String, dynamic>> _checkpoints = [];
  Set<int> _triggeredQuizzes = {};
  bool _isQuizActive = false; // NEW: đánh dấu đang hiển thị quiz

  static const _kSaveInterval = 15; // gửi progress mỗi 15 s
  int _lastSavedSec = 0;
  bool _isCompleted = false;

  bool _hasPopped = false; // đặt ở đầu State

  @override
  void initState() {
    super.initState();
    getUserData();
    player = Player();
    controller = VideoController(player);

    /// Bước 1: mở media
    player.open(Media(widget.url));

    /// Bước 2: lắng nghe khi duration > 0 ⇒ player đã sẵn sàng
    _durationSub = player.stream.duration.listen((d) async {
      if (!_progressRestored && d > Duration.zero) {
        _progressRestored = true;
        await _restoreProgress();
      }
    });

    /// Bước 3: lắng nghe khi player đã sẵn sàng
    _loadCheckpoints();
    _startTimeMonitoring();
  }

  Future<void> getUserData() async {
    // Lấy id người dùng
    final id = await AuthHelper.getUserIdFromToken();
    setState(() {
      userId = id ?? 0;
    });
  }

  Future<void> _restoreProgress() async {
    try {
      if (userId == null) return;

      final saved = await ProgressApi.getProgress(widget.lessonId, userId);
      if (saved != null && saved > 0) {
        final duration = player.state.duration ?? Duration.zero;
        final target = clampDuration(
          Duration(seconds: saved),
          Duration.zero,
          duration > Duration.zero ? duration : Duration(seconds: saved),
        );

        _markPassedQuizzesUpTo(saved); // ← thêm dòng này

        debugPrint('Restoring to ${target.inSeconds}s');
        await player.seek(target);
      }
    } catch (e) {
      debugPrint('restore progress error: $e');
    }
  }

  Duration clampDuration(Duration value, Duration min, Duration max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _timer?.cancel();

    // lưu vị trí cuối cùng nếu chưa hoàn thành
    final last = player.state.position?.inSeconds ?? 0;
    if (!_isCompleted && last > 0) {
      print('Saving last position: $userId');
      unawaited(
        ProgressApi.saveProgress(
          lessonId: widget.lessonId,
          seconds: last,
          userId: userId,
        ),
      );
    }

    // ✅ Đảm bảo trả kết quả về trước khi super.dispose()
    if (!_hasPopped && Navigator.canPop(context)) {
      _hasPopped = true; // tránh pop trùng
      Navigator.pop(context, _isCompleted);
    }

    player.dispose();
    super.dispose();
  }

  void _loadCheckpoints() async {
    try {
      final data = await QuizApi.getCheckpointsByLesson(widget.lessonId);
      if (!mounted) return; // tránh setState sau khi dispose
      setState(() {
        _checkpoints = data;
      });

      if (_progressRestored) {
        final sec = player.state.position?.inSeconds ?? 0;
        _markPassedQuizzesUpTo(sec);
      }
    } catch (e) {
      print("Error loading checkpoints: $e");
    }
  }

  void _markPassedQuizzesUpTo(int seconds) {
    for (final cp in _checkpoints) {
      final quizId = cp['quiz_id'] as int;
      final time = cp['time_in_video'] as int;
      if (time <= seconds) {
        _triggeredQuizzes.add(quizId);
      }
    }
  }

  void _startTimeMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final isPlaying = player.state.playing;

      // 🔹 1. Nếu video đang PAUSE (và không phải do hiện quiz) ➜ lưu ngay lập tức
      if (!isPlaying && !_isQuizActive) {
        final sec = player.state.position?.inSeconds ?? 0;
        if (sec > _lastSavedSec) {
          _lastSavedSec = sec;
          unawaited(
            ProgressApi.saveProgress(
              lessonId: widget.lessonId,
              seconds: sec,
              userId: userId,
            ),
          );
        }
      }

      // 🔹 2. Sau khi đã xử lý lưu, nếu đang pause hoặc đang hiện quiz ➜ bỏ qua các bước còn lại
      if (!isPlaying || _isQuizActive) return;

      // ---------- (phần cũ giữ nguyên từ đây) ----------
      final pos = player.state.position;
      final dur = player.state.duration;
      if (pos == null || dur == null) return;

      final seconds = pos.inSeconds;

      // Lưu định kỳ mỗi 15 s
      if (seconds - _lastSavedSec >= _kSaveInterval) {
        _lastSavedSec = seconds;
        unawaited(
          ProgressApi.saveProgress(
            lessonId: widget.lessonId,
            seconds: seconds,
            userId: userId,
          ),
        );
      }

      // Kiểm tra checkpoint để bật quiz …
      for (var cp in _checkpoints) {
        final quizId = cp["quiz_id"] as int;
        final time = cp["time_in_video"] as int;

        if (seconds >= time && !_triggeredQuizzes.contains(quizId)) {
          _triggeredQuizzes.add(quizId);
          _pauseAndShowQuiz(quizId);
          break;
        }
      }

      const tol = 2;
      if (!_isCompleted &&
          dur.inSeconds > tol && // ⚠️ chặn lỗi vừa vào video đã hoàn thành
          seconds >= dur.inSeconds - tol &&
          (_checkpoints.isEmpty ||
              _triggeredQuizzes.length == _checkpoints.length)) {
        _isCompleted = true;
        unawaited(ProgressApi.markCompleted(widget.lessonId, userId));

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
                // onPressed: () => Navigator.pop(context),
                onPressed: () {
                  if (!_hasPopped) {
                    _hasPopped = true;
                    Navigator.pop(context, _isCompleted);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
