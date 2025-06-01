import 'package:android_basic/api/courses_api.dart';
import 'package:android_basic/models/course.dart';
import 'package:android_basic/models/review.dart';
import 'package:android_basic/models/section.dart';
import 'package:android_basic/models/teacher_course.dart';
import 'package:android_basic/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:intl/intl.dart'; // import để dùng NumberFormat
import 'dart:convert';

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailPage({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Player? _player;
  VideoController? _videoController;

  bool _isEnrolled = false;
  bool _isFavorite = false;
  bool _isVideoInitialized = false;
  bool _showVideoPlayer = false;
  bool _isBuffering = true;
  bool _isVideoReady = false;
  bool _isFullScreen = false;

  // Dữ liệu bài học
  List<Section> _sections = [];
  bool _isLoadingSections = true;

  // Dữ liệu reviews
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  Map<String, dynamic>? _ratingStats;

  // Dữ liệu giảng viên
  late Future<TeacherInfoResponse> _futureTeacherInfo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeVideo();
    _loadSections();
    _loadReviews();

    final int teacherId = widget.course['user_id']; // hoặc ID bạn truyền vào
    _futureTeacherInfo = CoursesApi.fetchTeacherInfo(teacherId);
  }

  Future<void> _initializeVideo() async {
    String? videoUrl = widget.course['preview_video_url'];
    print('Video URL from database: $videoUrl');

    if (videoUrl != null && videoUrl.isNotEmpty) {
      print('Initializing media_kit player...');

      try {
        await _player?.dispose();

        _player = Player(
          configuration: PlayerConfiguration(
            bufferSize: 8 * 1024 * 1024,
            pitch: false,
            logLevel: MPVLogLevel.warn,
          ),
        );

        _videoController = VideoController(
          _player!,
          configuration: const VideoControllerConfiguration(
            enableHardwareAcceleration: true,
            androidAttachSurfaceAfterVideoParameters: false,
          ),
        );

        setState(() {
          _isVideoInitialized = false;
          _isVideoReady = false;
          _isBuffering = true;
        });

        _player!.stream.duration.listen((duration) async {
          print('Video duration received: $duration');
          if (duration != null && duration > Duration.zero && mounted) {
            setState(() {
              _isVideoInitialized = true;
            });

            if (!_isVideoReady) {
              print('Seeking to start after duration is available...');
              await _player!.seek(Duration.zero);
            }
          }
        });

        _player!.stream.buffering.listen((isBuffering) {
          print('Buffering state: $isBuffering');
          if (mounted) {
            setState(() {
              _isBuffering = isBuffering;
              if (!isBuffering && _isVideoInitialized) {
                _isVideoReady = true;
              }
            });
          }
        });

        _player!.stream.error.listen((error) {
          print('Player error: $error');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Video error: $error')));
          }
        });

        print('Opening video: $videoUrl');
        await _player!.open(Media(videoUrl), play: false);

        print('Video opened, seeking to start...');
        await Future.delayed(Duration(milliseconds: 500));
        await _player!.seek(Duration.zero);

        print('Video setup completed');
      } catch (error) {
        print('Error initializing video: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading video: $error')),
          );
        }
      }
    }
  }

  void _loadSections() async {
    try {
      final int courseId = widget.course['id']; // 👈 Lấy từ Map course
      final sections = await CoursesApi.fetchSections(courseId);

      setState(() {
        _sections = sections;
        _isLoadingSections = false;
      });
    } catch (e) {
      print('Lỗi khi load section: $e');
      setState(() => _isLoadingSections = false);
    }
  }

  void _loadReviews() async {
    try {
      final int courseId = widget.course['id']; // 👈 Lấy từ Map course

      final reviews = await CoursesApi.fetchReviews(
        courseId,
      ); // Đảm bảo bạn có courseId ở widget

      final stats = calculateRatingStats(reviews); // 👈 Gọi hàm tính thống kê

      setState(() {
        _reviews = reviews;
        _ratingStats = stats; // 👈 Lưu kết quả thống kê
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('Lỗi khi tải đánh giá: $e');
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Map<String, dynamic> calculateRatingStats(List<Review> reviews) {
    final ratingCount = List.filled(5, 0);

    for (var review in reviews) {
      final rating = review.rating ?? 0;
      if (rating >= 1 && rating <= 5) {
        ratingCount[rating - 1]++;
      }
    }

    final totalReviews = ratingCount.reduce((a, b) => a + b);
    final avgRating =
        totalReviews > 0
            ? List.generate(
                  5,
                  (i) => (i + 1) * ratingCount[i],
                ).reduce((a, b) => a + b) /
                totalReviews
            : 0.0;

    return {
      'average': avgRating,
      'total': totalReviews,
      'distribution': ratingCount,
    };
  }

  // Hàm chuyển sang fullscreen và phát video
  Future<void> _playVideoFullscreen() async {
    if (!_isVideoReady) {
      print('Video not ready yet');
      return;
    }

    // Chuyển sang fullscreen
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    setState(() {
      _isFullScreen = true;
      _showVideoPlayer = true;
    });

    // Phát video từ đầu
    try {
      await _player!.seek(Duration.zero);
      await Future.delayed(Duration(milliseconds: 100));
      await _player!.play();
      print('Video playing in fullscreen');
    } catch (error) {
      print('Error playing video: $error');
    }
  }

  // Hàm thoát fullscreen và dừng video
  Future<void> _exitFullscreen() async {
    // Dừng video
    if (_player != null) {
      await _player!.pause();
      await _player!.seek(Duration.zero);
    }

    // Thoát fullscreen
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    setState(() {
      _isFullScreen = false;
      _showVideoPlayer = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _player?.dispose();
    // Reset system UI khi dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _seekVideo(Duration position) async {
    if (_player != null && _isVideoReady) {
      try {
        final duration = _player!.state.duration;

        if (position < Duration.zero) {
          position = Duration.zero;
        } else if (position > duration) {
          position = duration;
        }

        print('Seeking to: $position');
        await _player!.seek(position);
        await Future.delayed(Duration(milliseconds: 200));
      } catch (error) {
        print('Error seeking: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nếu đang fullscreen, chỉ hiển thị video player
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildFullScreenVideoPlayer(),
      );
    }

    // Giao diện bình thường
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseHeader(),
                _buildPriceAndActions(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenVideoPlayer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Video player
          if (_videoController != null && _isVideoReady)
            Positioned.fill(
              child: Video(
                controller: _videoController!,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),

          // Custom controls overlay
          if (_isVideoReady) _buildFullScreenVideoControls(),

          // Loading overlay
          if (!_isVideoReady)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      _isBuffering ? 'Đang tải...' : 'Khởi tạo video...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullScreenVideoControls() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.5),
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Top bar với nút thoát (X)
            Padding(
              padding: EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Row(
                children: [
                  // Thông tin khóa học
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.course['title'] ?? 'Khóa học',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.course['instructor'] != null)
                          Text(
                            'Giảng viên: ${widget.course['instructor']}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Nút thoát fullscreen (X)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _exitFullscreen,
                      icon: Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),

            Spacer(),

            // Bottom controls
            Column(
              children: [
                // Progress bar
                StreamBuilder<Duration>(
                  stream: _player!.stream.position,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = _player!.state.duration;

                    if (duration == Duration.zero) {
                      return SizedBox.shrink();
                    }

                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble(),
                              min: 0.0,
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                final seekPosition = Duration(
                                  milliseconds: value.round(),
                                );
                                _seekVideo(seekPosition);
                              },
                              activeColor: Colors.red,
                              inactiveColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Control buttons
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          final currentPos = _player!.state.position;
                          _seekVideo(currentPos - Duration(seconds: 15));
                        },
                        icon: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.replay, color: Colors.white, size: 32),
                            Positioned(
                              bottom: 2,
                              child: Text(
                                '15',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      StreamBuilder<bool>(
                        stream: _player!.stream.playing,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () async {
                                if (isPlaying) {
                                  await _player!.pause();
                                } else {
                                  await _player!.play();
                                }
                              },
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.black,
                                size: 36,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          final currentPos = _player!.state.position;
                          _seekVideo(currentPos + Duration(seconds: 15));
                        },
                        icon: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(Icons.forward, color: Colors.white, size: 32),
                            Positioned(
                              bottom: 2,
                              child: Text(
                                '15',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.black,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.course['thumbnail_url'] != null
                ? Image.network(
                  widget.course['thumbnail_url'],
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(color: Colors.grey[300]),
                )
                : Container(color: Colors.grey[300]),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: _isVideoInitialized ? _playVideoFullscreen : null,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child:
                      _isVideoInitialized
                          ? Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: Colors.black,
                          )
                          : CircularProgressIndicator(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.share, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  // Widget _buildCourseHeader() {
  //   return Padding(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           widget.course['title'] ?? 'Tên khóa học',
  //           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           widget.course['subtitle'] ?? 'Tên khóa học',
  //           style: TextStyle(fontSize: 16, color: Colors.grey[600]),
  //         ),
  //         const SizedBox(height: 12),
  //         Row(
  //           children: [
  //             Icon(Icons.star, color: Colors.amber, size: 20),
  //             const SizedBox(width: 4),
  //             Text('4.8', style: TextStyle(fontWeight: FontWeight.bold)),
  //             const SizedBox(width: 8),
  //             Text(
  //               '(2,847 đánh giá)',
  //               style: TextStyle(color: Colors.grey[600]),
  //             ),
  //             const SizedBox(width: 16),
  //             Icon(Icons.people, color: Colors.grey[600], size: 20),
  //             const SizedBox(width: 4),
  //             Text(
  //               '15,234 học viên',
  //               style: TextStyle(color: Colors.grey[600]),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         Row(
  //           children: [
  //             CircleAvatar(
  //               radius: 16,
  //               backgroundColor: Colors.grey[300],
  //               child: Icon(Icons.person, size: 20),
  //             ),
  //             const SizedBox(width: 8),
  //             Text(
  //               'Tạo bởi ${widget.course['user_name'] ?? 'Giảng viên'}',
  //               style: TextStyle(
  //                 color: Colors.blue[600],
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           children: [
  //             Icon(Icons.update, size: 16, color: Colors.grey[600]),
  //             const SizedBox(width: 4),
  //             Text(
  //               'Cập nhật lần cuối 3/2024',
  //               style: TextStyle(color: Colors.grey[600]),
  //             ),
  //             const SizedBox(width: 16),
  //             Icon(Icons.language, size: 16, color: Colors.grey[600]),
  //             const SizedBox(width: 4),
  //             Text('Tiếng Việt', style: TextStyle(color: Colors.grey[600])),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  String _formatNumber(int number) {
    return NumberFormat.decimalPattern('vi').format(number);
  }

  Widget _buildCourseHeader() {
    final title = widget.course['title'] ?? 'Tên khóa học';
    final subtitle = widget.course['subtitle'] ?? '';
    final rating = (widget.course['rating'] ?? 0.0).toDouble();
    final reviewCount = widget.course['review_count'] ?? 0;
    final studentCount = widget.course['student_count'] ?? 0;
    final userName = widget.course['user_name'] ?? 'Giảng viên';
    final lastUpdated =
        widget.course['last_updated'] ?? '3/2024'; // Có thể là date string

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_formatNumber(reviewCount)} đánh giá)',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, color: Colors.grey[600], size: 20),
              const SizedBox(width: 4),
              Text(
                '${_formatNumber(studentCount)} học viên',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Tạo bởi $userName',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.update, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Cập nhật lần cuối $lastUpdated',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.language, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Tiếng Việt', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _formatCurrency(widget.course['discount_price']),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.course['price'] != null)
                Text(
                  _formatCurrency(widget.course['price']),
                  style: TextStyle(
                    fontSize: 18,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (widget.course['discount_price'] != null &&
              widget.course['price'] != null)
            Text(
              '🔥 Giảm giá ${_calculateDiscountPercent(widget.course['price'], widget.course['discount_price'])}%',
              style: TextStyle(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEnrolled = !_isEnrolled;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isEnrolled ? Colors.green : Colors.purple[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isEnrolled ? 'Đã đăng ký' : 'Đăng ký ngay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('Thêm vào giỏ hàng'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _calculateDiscountPercent(dynamic original, dynamic discounted) {
    try {
      final double originalPrice = double.parse(original.toString());
      final double discountedPrice = double.parse(discounted.toString());

      if (originalPrice <= 0 || discountedPrice >= originalPrice) return 0;

      final percent = ((originalPrice - discountedPrice) / originalPrice) * 100;
      return percent.round(); // làm tròn %
    } catch (e) {
      return 0;
    }
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Colors.purple[700],
        tabs: [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Nội dung'),
          Tab(text: 'Đánh giá'),
          Tab(text: 'Giảng viên'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoadingSections) {
      return const Center(child: CircularProgressIndicator());
    }

    print('Sections: ${_sections.length}');

    return Container(
      height: 600,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildContentTab(_sections),
          _buildReviewsTab(),
          _buildInstructorTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Bạn sẽ học được gì'),
          _buildLearningOutcomes(),
          const SizedBox(height: 24),
          _buildSectionTitle('Mô tả khóa học'),
          _buildCourseDescription(),
          const SizedBox(height: 24),
          _buildSectionTitle('Yêu cầu'),
          _buildRequirements(),
        ],
      ),
    );
  }

  String _decodeEscaped(String input) {
    return const JsonDecoder().convert('"$input"');
  }

  Widget _buildLearningOutcomes() {
    final raw = widget.course['what_you_learn']?.toString() ?? '';
    final decoded = _decodeEscaped(raw);
    final List<String> outcomes =
        decoded.split('\n').where((e) => e.trim().isNotEmpty).toList();

    if (outcomes.isEmpty) {
      return Text('Không có dữ liệu.');
    }

    return Column(
      children:
          outcomes
              .map(
                (outcome) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(outcome)),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCourseDescription() {
    final description =
        widget.course['description']?.toString() ?? 'Chưa có mô tả khóa học.';

    return Text(
      description,
      style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey[700]),
    );
  }

  Widget _buildRequirements() {
    final raw = widget.course['requirements']?.toString() ?? '';
    final decoded = _decodeEscaped(raw);
    final List<String> requirements =
        decoded.split('\n').where((e) => e.trim().isNotEmpty).toList();

    if (requirements.isEmpty) {
      return Text('Không có yêu cầu nào.');
    }

    return Column(
      children:
          requirements
              .map(
                (req) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(req)),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  // Phần content
  Widget _buildContentTab(List<Section> sections) {
    int totalLessons = sections.fold(0, (sum, s) => sum + s.lessons.length);
    int totalDuration = sections.fold(
      0,
      (sum, s) =>
          sum + s.lessons.fold(0, (lSum, l) => lSum + (l.duration ?? 0)),
    );
    double hours = totalDuration / 3600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${sections.length} chương • $totalLessons bài học • ${hours.toStringAsFixed(1)} giờ tổng thời lượng',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sections
              .asMap()
              .entries
              .map((entry) => _buildChapterItem(entry.key + 1, entry.value))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildChapterItem(int index, Section section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chương $index: ${section.title}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ...section.lessons.map(
          (lesson) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(lesson.title ?? 'Chưa có tiêu đề')),
                Text(
                  '${((lesson.duration ?? 0) / 60).toStringAsFixed(0)} phút',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingOverview(_ratingStats!),
          const SizedBox(height: 24),
          _buildSectionTitle('Đánh giá từ học viên'),
          _isLoadingReviews
              ? Center(child: CircularProgressIndicator())
              : _reviews.isEmpty
              ? Text('Chưa có đánh giá nào.')
              : Column(
                children:
                    _reviews.map((review) => _buildReviewItem(review)).toList(),
              ),
        ],
      ),
    );
  }

  // Widget _buildInstructorTab() {
  //   return SingleChildScrollView(
  //     padding: const EdgeInsets.all(16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         _buildInstructorInfo(),
  //         const SizedBox(height: 24),
  //         _buildSectionTitle('Khóa học khác của giảng viên'),
  //         ...List.generate(3, (index) => _buildInstructorCourse(index)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildInstructorTab() {
    return FutureBuilder<TeacherInfoResponse>(
      future: _futureTeacherInfo, // <-- biến đã khởi tạo trong initState
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(child: Text('Không có dữ liệu'));
        }

        final teacher = snapshot.data!.teacher;
        final courses = snapshot.data!.courses;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructorInfo(teacher), // <-- truyền dữ liệu giảng viên
              const SizedBox(height: 24),
              _buildSectionTitle('Khóa học khác của giảng viên'),
              ...courses
                  .map((course) => _buildInstructorCourse(course))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRatingOverview(Map<String, dynamic> stats) {
    final double averageRating = stats['average'];
    final int totalReviews = stats['total'];
    final List<int> distribution = List<int>.from(stats['distribution']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < averageRating.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
              ),
              Text('$totalReviews đánh giá'),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = distribution[star - 1];
                final percent = totalReviews > 0 ? count / totalReviews : 0.0;
                final percentLabel = (percent * 100).toStringAsFixed(0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('$star'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(Colors.amber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$percentLabel%'),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(Review review) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${review.userName}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          review.rating ?? 0,
                          (index) =>
                              Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                        ...List.generate(
                          5 - (review.rating ?? 0),
                          (index) => Icon(
                            Icons.star_border,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(review.createdAt ?? ''),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment ?? ""),
        ],
      ),
    );
  }

  String _formatTimeAgo(String isoTime) {
    final date = DateTime.tryParse(isoTime);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays >= 7) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  Widget _buildInstructorInfo(User teacher) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage:
                teacher.avatarUrl != null
                    ? NetworkImage(teacher.avatarUrl!)
                    : null,
            backgroundColor: Colors.grey[300],
            child:
                teacher.avatarUrl == null ? Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacher.username ?? 'Giảng viên',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(teacher.bio ?? 'Chức danh'),
                const SizedBox(height: 8),
                // Row(
                //   children: [
                //     const Icon(Icons.star, color: Colors.amber, size: 16),
                //     Text(' ${teacher.rating ?? '4.9'} • '),
                //     Text('${teacher.students ?? 0} học viên • '),
                //     Text('${teacher.totalCourses ?? 0} khóa học'),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCourse(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
              image:
                  course.thumbnailUrl != null
                      ? DecorationImage(
                        image: NetworkImage(course.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title ?? 'Tên khóa học',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(' ${course.rating ?? '4.7'} • '),
                    Text(_formatCurrency(course.price)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic price) {
    if (price == null) return '';
    return '₫${price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}
