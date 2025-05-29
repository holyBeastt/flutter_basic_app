import 'package:flutter/material.dart';

class CourseDetailPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailPage({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEnrolled = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, size: 40, color: Colors.black),
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
