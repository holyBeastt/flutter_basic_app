import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeVideo();
    // Không khởi tạo video ngay, chỉ khi user nhấn preview
  }

  Future<void> _initializeVideo() async {
    String? videoUrl = widget.course['preview_video_url'];
    print('Video URL from database: $videoUrl');

    if (videoUrl != null && videoUrl.isNotEmpty) {
      print('Initializing media_kit player...');

      try {
        // Dispose player cũ nếu có
        await _player?.dispose();

        // Tạo player mới với cấu hình tối ưu
        _player = Player(
          configuration: PlayerConfiguration(
            // Giảm buffer để tránh skip frames
            bufferSize: 8 * 1024 * 1024, // 8MB thay vì 32MB
            // Cấu hình cho seeking tốt hơn
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

        // Reset states
        setState(() {
          _isVideoInitialized = false;
          _isVideoReady = false;
          _isBuffering = true;
        });

        // Lắng nghe khi video được load xong
        // _player!.stream.duration.listen((duration) {
        //   print('Video duration received: $duration');
        //   if (duration != Duration.zero && mounted) {
        //     setState(() {
        //       _isVideoInitialized = true;
        //     });
        //   }
        // });
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

        // Lắng nghe khi video sẵn sàng phát
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

        // Lắng nghe position để debug
        _player!.stream.position.listen((position) {
          // print('Current position: $position');
        });

        // Lắng nghe lỗi
        _player!.stream.error.listen((error) {
          print('Player error: $error');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Video error: $error')));
          }
        });

        print('Opening video: $videoUrl');

        // Mở video KHÔNG tự động phát
        await _player!.open(
          Media(videoUrl),
          play: false, // Quan trọng: không tự động phát
        );

        print('Video opened, seeking to start...');

        // Đợi một chút rồi seek về đầu
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

  @override
  void dispose() {
    _tabController.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggleVideoPlayback() async {
    // Nếu chưa khởi tạo video, khởi tạo trước
    if (_player == null) {
      setState(() {
        _showVideoPlayer = true;
      });
      await _initializeVideo();
      return;
    }

    if (_player != null) {
      setState(() {
        _showVideoPlayer = true;
      });

      // Đợi video sẵn sàng
      if (!_isVideoReady) {
        print('Video not ready yet, waiting...');
        return;
      }

      try {
        if (_player!.state.playing) {
          await _player!.pause();
          print('Video paused');
        } else {
          // Luôn seek về đầu trước khi phát
          await _player!.seek(Duration.zero);
          await Future.delayed(Duration(milliseconds: 100));
          await _player!.play();
          print('Video playing from start');
        }
      } catch (error) {
        print('Error toggling playback: $error');
      }
    }
  }

  // Hàm seek an toàn
  Future<void> _seekVideo(Duration position) async {
    if (_player != null && _isVideoReady) {
      try {
        final duration = _player!.state.duration;

        // Đảm bảo position trong phạm vi hợp lệ
        if (position < Duration.zero) {
          position = Duration.zero;
        } else if (position > duration) {
          position = duration;
        }

        print('Seeking to: $position');
        await _player!.seek(position);

        // Đợi một chút để seek hoàn thành
        await Future.delayed(Duration(milliseconds: 200));
      } catch (error) {
        print('Error seeking: $error');
      }
    } else {
      print('Cannot seek: player not ready');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showVideoPlayer) _buildVideoPlayer(),
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

  Widget _buildVideoPlayer() {
    return Container(
      height: 250,
      color: Colors.black,
      child: Stack(
        children: [
          if (_videoController != null && _isVideoReady)
            Video(
              controller: _videoController!,
              controls: NoVideoControls, // Tắt controls mặc định
            ),

          // Custom overlay controls
          if (_isVideoReady) _buildVideoControls(),

          // Loading overlay
          if (!_isVideoReady)
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      _isBuffering ? 'Buffering...' : 'Loading video...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
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
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: 12,
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
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      final currentPos = _player!.state.position;
                      _seekVideo(currentPos - Duration(seconds: 10));
                    },
                    icon: Icon(Icons.replay_10, color: Colors.white, size: 28),
                  ),
                  StreamBuilder<bool>(
                    stream: _player!.stream.playing,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () {
                      final currentPos = _player!.state.position;
                      _seekVideo(currentPos + Duration(seconds: 10));
                    },
                    icon: Icon(Icons.forward_10, color: Colors.white, size: 28),
                  ),
                ],
              ),
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
            // Course thumbnail
            widget.course['thumbnail_url'] != null
                ? Image.network(
                  widget.course['thumbnail_url'],
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Container(color: Colors.grey[300]),
                )
                : Container(color: Colors.grey[300]),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            // Play button
            Center(
              child: GestureDetector(
                onTap: _isVideoInitialized ? _toggleVideoPlayback : null,
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
  // late TabController _tabController;
  // bool _isEnrolled = false;
  // bool _isFavorite = false;

  // @override
  // void initState() {
  //   super.initState();
  //   _tabController = TabController(length: 4, vsync: this);
  // }

  // @override
  // void dispose() {
  //   _tabController.dispose();
  //   super.dispose();
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: CustomScrollView(
  //       slivers: [
  //         _buildAppBar(),
  //         SliverToBoxAdapter(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               _buildCourseHeader(),
  //               _buildPriceAndActions(),
  //               _buildTabBar(),
  //               _buildTabContent(),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildAppBar() {
  //   return SliverAppBar(
  //     expandedHeight: 250,
  //     pinned: true,
  //     backgroundColor: Colors.black,
  //     flexibleSpace: FlexibleSpaceBar(
  //       background: Stack(
  //         fit: StackFit.expand,
  //         children: [
  //           // Course thumbnail
  //           widget.course['thumbnail_url'] != null
  //               ? Image.network(
  //                 widget.course['thumbnail_url'],
  //                 fit: BoxFit.cover,
  //                 errorBuilder:
  //                     (context, error, stackTrace) =>
  //                         Container(color: Colors.grey[300]),
  //               )
  //               : Container(color: Colors.grey[300]),
  //           // Gradient overlay
  //           Container(
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 begin: Alignment.topCenter,
  //                 end: Alignment.bottomCenter,
  //                 colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
  //               ),
  //             ),
  //           ),
  //           // Play button
  //           Center(
  //             child: Container(
  //               padding: const EdgeInsets.all(20),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.9),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: Icon(Icons.play_arrow, size: 40, color: Colors.black),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //     actions: [
  //       IconButton(
  //         icon: Icon(
  //           _isFavorite ? Icons.favorite : Icons.favorite_border,
  //           color: _isFavorite ? Colors.red : Colors.white,
  //         ),
  //         onPressed: () {
  //           setState(() {
  //             _isFavorite = !_isFavorite;
  //           });
  //         },
  //       ),
  //       IconButton(
  //         icon: Icon(Icons.share, color: Colors.white),
  //         onPressed: () {},
  //       ),
  //     ],
  //   );
  // }

  Widget _buildCourseHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.course['title'] ?? 'Tên khóa học',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Khóa học lập trình từ cơ bản đến nâng cao dành cho người mới bắt đầu',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text('4.8', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(
                '(2,847 đánh giá)',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.people, color: Colors.grey[600], size: 20),
              const SizedBox(width: 4),
              Text(
                '15,234 học viên',
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
                child: Icon(Icons.person, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Tạo bởi ${widget.course['user_name'] ?? 'Giảng viên'}',
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
                'Cập nhật lần cuối 3/2024',
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
          Text(
            '🔥 Giảm giá 85%',
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
    return Container(
      height: 600,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildContentTab(),
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

  Widget _buildContentTab() {
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
                    '12 chương • 120 bài học • 40 giờ tổng thời lượng',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildChapterItem(index + 1)),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingOverview(),
          const SizedBox(height: 24),
          _buildSectionTitle('Đánh giá từ học viên'),
          ...List.generate(5, (index) => _buildReviewItem()),
        ],
      ),
    );
  }

  Widget _buildInstructorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructorInfo(),
          const SizedBox(height: 24),
          _buildSectionTitle('Khóa học khác của giảng viên'),
          ...List.generate(3, (index) => _buildInstructorCourse(index)),
        ],
      ),
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

  Widget _buildLearningOutcomes() {
    final outcomes = [
      'Nắm vững các khái niệm cơ bản về lập trình',
      'Xây dựng ứng dụng hoàn chỉnh từ đầu',
      'Hiểu và áp dụng các design pattern',
      'Tối ưu hóa hiệu suất ứng dụng',
      'Deploy ứng dụng lên production',
    ];

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
    return Text(
      'Khóa học này được thiết kế dành cho những người mới bắt đầu với lập trình. Bạn sẽ học từ những khái niệm cơ bản nhất cho đến các kỹ thuật nâng cao. Với hơn 40 giờ video và 50+ bài tập thực hành, bạn sẽ có nền tảng vững chắc để phát triển sự nghiệp lập trình.',
      style: TextStyle(fontSize: 16, height: 1.5, color: Colors.grey[700]),
    );
  }

  Widget _buildRequirements() {
    final requirements = [
      'Không cần kinh nghiệm lập trình trước đó',
      'Máy tính có thể cài đặt phần mềm',
      'Thái độ học hỏi tích cực',
    ];

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

  Widget _buildChapterItem(int chapterNumber) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text('Chương $chapterNumber: Kiến thức cơ bản'),
        subtitle: Text('8 bài học • 3 giờ 20 phút'),
        children: List.generate(
          8,
          (index) => ListTile(
            leading: Icon(Icons.play_circle_outline),
            title: Text('Bài ${index + 1}: Giới thiệu về lập trình'),
            subtitle: Text('15 phút'),
            trailing: Icon(Icons.lock_outline, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                '4.8',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(Icons.star, color: Colors.amber, size: 20),
                ),
              ),
              Text('2,847 đánh giá'),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('${5 - index}'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (5 - index) * 0.2,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(Colors.amber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(5 - index) * 20}%'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem() {
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
                      'Nguyễn Văn A',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) =>
                              Icon(Icons.star, color: Colors.amber, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '2 tuần trước',
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
          Text(
            'Khóa học rất hay và chi tiết. Giảng viên giải thích rõ ràng, dễ hiểu. Tôi đã học được rất nhiều kiến thức hữu ích từ khóa học này.',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course['user_name'] ?? 'Giảng viên',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Senior Developer & Instructor'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(' 4.9 • '),
                        Text('50,000+ học viên • '),
                        Text('25 khóa học'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tôi là một lập trình viên với hơn 10 năm kinh nghiệm trong ngành. Đã từng làm việc tại các công ty lớn và hiện đang giảng dạy lập trình cho hơn 50,000 học viên trên toàn thế giới.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructorCourse(int index) {
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
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khóa học lập trình ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 14),
                    Text(' 4.7 • '),
                    Text('₫299,000'),
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
