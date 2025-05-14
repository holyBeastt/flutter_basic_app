import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> courses = [
      {
        'title': 'Tay Mơ Blender 3D',
        'instructor': 'Nguyễn Vũ Hoàng Hiệp',
        'image': 'https://img-b.udemycdn.com/course/240x135/123456.jpg',
      },
      {
        'title': 'Figmarketing cho Designer',
        'instructor': 'Telos Academy',
        'image': 'https://img-b.udemycdn.com/course/240x135/654321.jpg',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          children: [
            _buildPromoBanner(),
            _buildMainImageSection(),
            _buildMainText(),
            _buildRecommendationTitle(),
            _buildCourseGrid(courses),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Nổi bật'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill),
            label: 'Học tập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      color: Colors.yellow[200],
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'Sale trong mùa: Các khóa học từ 199.000 ₫\n',
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: 'Còn lại 8 ngày!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.close, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildMainImageSection() {
    return Image.network(
      'https://img.freepik.com/free-photo/young-man-working-laptop-cafe_1303-26457.jpg',
      fit: BoxFit.cover,
    );
  }

  Widget _buildMainText() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Các kỹ năng mở ra cánh cửa thành công cho bạn',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Đây là đợt ưu đãi hấp dẫn nhất mùa này của chúng tôi. Mở ra cơ hội nghề nghiệp mới với các khóa học có giá từ 199.000 ₫.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTitle() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text.rich(
        TextSpan(
          text: 'Vì bạn đã xem ',
          style: GoogleFonts.poppins(color: Colors.white),
          children: [
            TextSpan(
              text: '"Canva 101 - Làm chủ kỹ năng thiết kế Canva..."',
              style: GoogleFonts.poppins(color: Colors.purpleAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseGrid(List<Map<String, String>> courses) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: courses.map((course) => _buildCourseCard(course)).toList(),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, String> course) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            child: Image.network(
              course['image']!,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title']!,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  course['instructor']!,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
