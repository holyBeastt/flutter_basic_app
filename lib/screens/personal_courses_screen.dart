import 'package:flutter/material.dart';
import '../models/course.dart';
import '../api/courses_api.dart';

class PersonalCoursesScreen extends StatefulWidget {
  final int userId;
  const PersonalCoursesScreen({super.key, required this.userId});

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

  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        leading:
            course.thumbnailUrl != null
                ? Image.network(
                  course.thumbnailUrl!,
                  width: 60,
                  fit: BoxFit.cover,
                )
                : const Icon(Icons.image, size: 60),
        title: Text(course.title ?? 'Không có tiêu đề'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.userName != null)
              Text(
                'Tác giả: ${course.userName!}',
                style: const TextStyle(fontSize: 12),
              ),
            if (course.price != null)
              Text(
                'Giá: ${course.price!.toStringAsFixed(0)}₫',
                style: const TextStyle(fontSize: 12),
              ),
            if (course.rating != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    course.rating!.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        onTap: () {
          // TODO: Điều hướng đến chi tiết khóa học
        },
      ),
    );
  }

  Widget _buildCourseList(String title, List<Course> courses) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children:
          courses.isNotEmpty
              ? courses.map(_buildCourseCard).toList()
              : [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text("Không có khóa học nào."),
                ),
              ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Khóa học của tôi")),
      body: FutureBuilder<Map<String, List<Course>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
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
    );
  }
}
