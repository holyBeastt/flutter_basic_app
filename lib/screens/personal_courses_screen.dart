import 'package:android_basic/screens/course_detail.dart';
import 'package:flutter/material.dart';
import '../models/course.dart';
import '../api/courses_api.dart';
import '../widgets/cusutom_bottom_navbar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'package:android_basic/screens/search_screen.dart';
class PersonalCoursesScreen extends StatefulWidget {
  final int userId;
  final int currentIndex;

  const PersonalCoursesScreen({
    super.key,
    required this.userId,
    this.currentIndex = 2, // mặc định là tab "Học tập"
  });

  @override
  State<PersonalCoursesScreen> createState() => _PersonalCoursesScreenState();
}

class _PersonalCoursesScreenState extends State<PersonalCoursesScreen> {
  late Future<Map<String, List<Course>>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = CoursesApi.fetchPersonalCourses(widget.userId);
  }

  Widget _buildCourseList(String title, List<Course> courses) {
    return ExpansionTile(
      backgroundColor: Colors.black,
      collapsedBackgroundColor: Colors.black,
      textColor: Colors.white,
      iconColor: Colors.white,
      collapsedTextColor: Colors.white,
      collapsedIconColor: Colors.white,
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children:
          courses.isNotEmpty
              ? courses
                  .map((course) => _buildCourseCard(context, course))
                  .toList()
              : const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Không có khóa học nào.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black,
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailPage(course: course),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              child: Image.network(
                course.thumbnailUrl ?? '',
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title ?? 'Không có tiêu đề',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.userName ?? 'Giảng viên chưa rõ',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        (course.rating ?? 0.0).toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildStarRating(course.rating ?? 0.0),
                      const SizedBox(width: 6),
                      Text(
                        '(${course.studentCount ?? 0})',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _formatCurrency(
                          course.discountPrice ?? course.price ?? 0,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (course.discountPrice != null &&
                          course.price != null &&
                          course.discountPrice! < course.price!)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            _formatCurrency(course.price!),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == widget.currentIndex) return;

    if (index == 0) {
      // Chuyển về Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else if (index == 1) {
      // Chuyển sang trang Tìm kiếm
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SearchScreen()),
      );
    } else if (index == 3) {
      // Chuyển về Profile
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false, // ❌ Bỏ nút quay lại
        backgroundColor: Colors.black,
        title: const Text(
          "Khóa học của tôi",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, List<Course>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Lỗi: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final ownedCourses = snapshot.data?['ownedCourses'] ?? [];
          final enrolledCourses = snapshot.data?['enrolledCourses'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseList("📘 Khóa học đã tạo", ownedCourses),
                _buildCourseList("🎓 Khóa học đã mua", enrolledCourses),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

String _formatCurrency(num value) {
  return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}₫';
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
