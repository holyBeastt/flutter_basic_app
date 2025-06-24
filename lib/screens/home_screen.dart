import 'package:android_basic/screens/course_detail.dart';
import 'package:android_basic/screens/personal_courses_screen.dart';
import 'package:android_basic/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import '../helpers/auth_helper.dart';
import 'package:android_basic/api/courses_api.dart';

class HomeScreen extends StatefulWidget {
  final String? category;
  final String? searchQuery;
  
  const HomeScreen({Key? key, this.category , this.searchQuery}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String username = "Username";
  int? userID;
  List<dynamic> coursesData = [];
  List<Map<String, dynamic>> allCourses = [];
  List<Map<String, dynamic>> displayCourses = [];
  String? _selectedCategory;
    bool _isLoading = false;
  @override
void initState() {
    super.initState();
    getUserName();
    getCoursesList();
  }

  Future<void> getUserData() async {
    // Lấy tên người dùng
    final name = await AuthHelper.getUsernameFromToken();
    // Lấy id người dùng
    final id = await AuthHelper.getUserIdFromToken();
    setState(() {
      username = name ?? 'Ẩn danh';
      userID = id ?? 0;
    });
  }

 Future<void> getCoursesList() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Calling getCoursesList API...');
      final data = await CoursesApi.getCoursesList();
      print('API returned ${data.length} courses');

      setState(() {
        coursesData = data;
        _selectedCategory = null; // Reset category khi load tất cả
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi lấy courses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
Future<void> searchCourses(String query) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Calling searchCourses API with query: $query');
      final data = await CoursesApi.getCoursesBySearch(query);
      print('API returned ${data.length} courses for query: $query');

      setState(() {
        coursesData = data;
        _selectedCategory = null; // Reset category khi tìm kiếm
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tìm kiếm khóa học: $e');
      setState(() {
        _isLoading = false;
      });

      // Hiển thị thông báo lỗi cho user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tìm thấy khóa học: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Tách riêng method cho category
  Future<void> getCoursesByCategory(String category) async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('Calling getCoursesByCategory API with: $category');
      final data = await CoursesApi.getCoursesByCategory(category);
      print('API returned ${data.length} courses for category: $category');

      setState(() {
        coursesData = data;
        _selectedCategory = category;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi lấy courses theo category: $e');
      setState(() {
        _isLoading = false;
      });

      // Hiển thị thông báo lỗi cho user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải khóa học cho danh mục này: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // void _onItemTapped(int index) {
  //   if (index == 3) {
  //     // Nếu bấm vào tab "Tài khoản" thì chuyển sang màn hình tài khoản
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (context) => const ProfileScreen()),
  //     );
  //     // Không đổi _selectedIndex để không làm đổi giao diện Home
  //     return;
  //   }
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  void _onItemTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildLoginHeader(),
            Expanded(child: _buildPromoSection()),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildLoginHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.black,
      alignment: Alignment.centerRight,
      child: Text(
        username,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildPromoSection() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeaturePromo(),
          // _buildSkillsHeadline(),
          // _buildCourseRecommendation(),
          _buildIntroSection(),
          _buildCoursesList(),
        ],
      ),
    );
  }

  Widget _buildFeaturePromo() {
    return Container(
      height: 240,
      width: double.infinity,
      color: const Color(0xFF8A56FF),
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Ảnh full chiều ngang
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://jrmaxpvxillhwsuvmagp.supabase.co/storage/v1/object/public/images/home_main_img/main_home.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Nội dung đè lên ảnh (tuỳ chọn)
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.all(12),
              width: 250,
              child: const Text(
                '',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 4,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroSection() {
    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Khám phá kỹ năng mới mỗi ngày',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Chinh phục các khóa học hot nhất hiện nay và nâng tầm sự nghiệp của bạn.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }

  // 1. Cập nhật _buildCoursesList() để thêm onTap
  Widget _buildCoursesList() {
    if (_isLoading) {
    return Container(
      height: 300,
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }

  // Hiển thị thông báo khi không có khóa học
  if (coursesData.isEmpty) {
    return Container(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              color: Colors.grey,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
                widget.searchQuery != null && widget.searchQuery!.isNotEmpty
                    ? 'Không tìm thấy khóa học nào với từ khóa "${widget.searchQuery}"'
                    : _selectedCategory != null
                    ? 'Không tìm thấy khóa học nào trong danh mục'
                    : 'Không tìm thấy khóa học nào',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            if ((_selectedCategory != null ||
                  (widget.searchQuery != null &&
                      widget.searchQuery!.isNotEmpty))) ...[
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: getCoursesList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: Text('Xem tất cả khóa học'),
              ),
            ],
          ],
        ),
      ),
    );
  }
    return Container(
      padding: const EdgeInsets.only(top: 16),
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: coursesData.length,
        itemBuilder: (context, index) {
          final course = coursesData[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailPage(course: course),
                ),
              );
            },
            child: _buildCourseCard(
              course.title ?? '',
              course.userName ?? 'Giảng viên chưa rõ',
              _formatCurrency(course.discountPrice),
              course.price != null ? _formatCurrency(course.price) : '',
              (course.rating as num?)?.toDouble() ?? 0.0, // ✅ ép kiểu an toàn
              course.studentCount ?? 0,
              course.thumbnailUrl ?? '',
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(num? value) {
    if (value == null) return '';
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  Widget _buildCourseCard(
    String title,
    String author,
    String price,
    String originalPrice,
    double rating,
    int reviews,
    String imageUrl, {
    bool hasBlenderLogo = false,
  }) {
    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (hasBlenderLogo)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue[800],
                      ),
                      child: Center(
                        child: Container(
                          width: 25,
                          height: 25,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(author, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                rating.toString(),
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
              const SizedBox(width: 4),
              _buildStarRating(rating),
              const SizedBox(width: 4),
              Text(
                '($reviews)',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (originalPrice.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    originalPrice,
                    style: TextStyle(
                      color: Colors.grey[400],
                      decoration: TextDecoration.lineThrough,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.orange, size: 14);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return const Icon(Icons.star_half, color: Colors.orange, size: 14);
        } else {
          return const Icon(Icons.star_border, color: Colors.orange, size: 14);
        }
      }),
    );
  }
}

class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
