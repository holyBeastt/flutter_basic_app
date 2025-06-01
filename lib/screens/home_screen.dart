import 'package:android_basic/screens/course_detail.dart';
import 'package:android_basic/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import '../helpers/auth_helper.dart';
import 'package:android_basic/api/courses_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String username = "Username";
  List<dynamic> coursesData = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserName();
    getCoursesList();
  }

  Future<void> getUserName() async {
    final name = await AuthHelper.getUsernameFromToken();

    setState(() {
      username = name ?? 'Ẩn danh';
    });
  }

  Future<void> getCoursesList() async {
    try {
      final data = await CoursesApi.getCoursesList();

      setState(() {
        coursesData = data;
      });
    } catch (e) {
      print('Lỗi khi lấy courses: $e');
    }
  }

   void _onItemTapped(int index) {
    if (index == 3) {
      // Nếu bấm vào tab "Tài khoản" thì chuyển sang màn hình tài khoản
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
      // Không đổi _selectedIndex để không làm đổi giao diện Home
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
      bottomNavigationBar: _buildBottomNavigationBar(),
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
          _buildSkillsHeadline(),
          _buildCourseRecommendation(),
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
          Positioned(
            right: 0,
            top: 20,
            child: Container(
              width: 200,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(100),
              ),
              child: ClipPath(
                child: Image.network(
                  'https://jrmaxpvxillhwsuvmagp.supabase.co/storage/v1/object/public/images/home_main_img/main_home.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Positioned(
          //   left: 0,
          //   right: 100,
          //   bottom: 40,
          //   child: Container(
          //     width: 200,
          //     child: const Text(
          //       'Các kỹ năng mở ra cánh cửa thành công cho bạn',
          //       style: TextStyle(
          //         color: Colors.white,
          //         fontWeight: FontWeight.bold,
          //         fontSize: 24,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildSkillsHeadline() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Đây là đợt ưu đãi hấp dẫn nhất mùa này của chúng tôi. Mở ra các cơ hội nghề nghiệp mới với các khóa học có giá từ 199.000 đ. Ưu đãi sẽ kết',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildCourseRecommendation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: RichText(
        text: const TextSpan(
          style: TextStyle(color: Colors.white, fontSize: 14),
          children: [
            TextSpan(text: 'Vì bạn đã xem "'),
            TextSpan(
              text: 'Canva 101 - Làm chủ kỹ năng thiết kế Canva cho ...',
              style: TextStyle(color: Color(0xFF9370DB)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildCoursesList() {
  //   return Container(
  //     padding: const EdgeInsets.only(top: 16),
  //     height: 300,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       padding: const EdgeInsets.symmetric(horizontal: 8),
  //       itemCount: coursesData.length,
  //       itemBuilder: (context, index) {
  //         final course = coursesData[index];

  //         return _buildCourseCard(
  //           course['title'] ?? '',
  //           course['user_name'] ?? 'Giảng viên chưa rõ',
  //           _formatCurrency(course['discount_price']),
  //           course['price'] != null ? _formatCurrency(course['price']) : '',
  //           4.8, // fake rating
  //           100, // fake student count
  //           course['thumbnail_url'] ?? '',
  //         );
  //       },
  //     ),
  //   );
  // }

  // 1. Cập nhật _buildCoursesList() để thêm onTap
  Widget _buildCoursesList() {
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
              course['title'] ?? '',
              course['user_name'] ?? 'Giảng viên chưa rõ',
              _formatCurrency(course['discount_price']),
              course['price'] != null ? _formatCurrency(course['price']) : '',
              (course['rating'] as num?)?.toDouble() ??
                  0.0, // ✅ ép kiểu an toàn
              course['student_count'] ?? 0,
              course['thumbnail_url'] ?? '',
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

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Nổi bật'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'Học tập',
        ),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.favorite_border),
        //   label: 'Wishlist',
        // ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Tài khoản',
          
        ),
      ],
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
