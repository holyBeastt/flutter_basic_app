import 'package:flutter/material.dart';
import 'package:android_basic/api/courses_api.dart';
import 'package:android_basic/screens/course_detail.dart';
import 'package:android_basic/models/course.dart'; // Import model Course
import 'package:android_basic/screens/personal_courses_screen.dart';
import 'package:android_basic/helpers/auth_helper.dart';
import 'package:android_basic/screens/home_screen.dart';
import 'package:android_basic/screens/profile_screen.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Course> _searchResults = [];
  bool _isSearching = false;
  int? userID;
  bool _hasSearched = false;
  // Danh sách category
  final List<Map<String, dynamic>> _categories = [
    {'title': 'Kinh doanh', 'icon': Icons.business},
    {'title': 'Tài chính & Kế toán', 'icon': Icons.account_balance},
    {'title': 'CNTT & Phần mềm', 'icon': Icons.computer},
    {'title': 'Phát triển cá nhân', 'icon': Icons.person},
    {'title': 'Thiết kế', 'icon': Icons.design_services},
    {'title': 'Marketing', 'icon': Icons.campaign},
    {'title': 'Âm nhạc', 'icon': Icons.music_note},
    {'title': 'Nhiếp ảnh & Video', 'icon': Icons.camera_alt},
    {'title': 'Sức khỏe & Thể hình', 'icon': Icons.fitness_center},
    {'title': 'Ngôn ngữ', 'icon': Icons.language},
    {'title': 'Giáo dục', 'icon': Icons.school},
    {'title': 'Du lịch & Ẩm thực', 'icon': Icons.restaurant_menu},
    {'title': 'Khoa học & Công nghệ', 'icon': Icons.science},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
      Expanded(
              child:
                  _isSearching
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : _searchResults.isNotEmpty
                      ? _buildSearchResults()
                      : !_hasSearched
                      ? _buildCategoriesSection() // Hiển thị danh mục khi chưa tìm kiếm
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.search_off,
                              color: Colors.white54,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Không tìm thấy khóa học nào',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
            )
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm khóa học...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  _performSearch(_searchController.text);
                }
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _performSearch(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const Text(
          'Duyệt qua thể loại',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._categories.map((category) => _buildCategoryItem(category)).toList(),
      ],
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category['title']),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(category['icon'], color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category['title'],
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final course = _searchResults[index];
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
            course.rating ?? 0.0,
            course.studentCount ?? 0,
            course.thumbnailUrl ?? '',
          ),
        );
      },
    );
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.02), blurRadius: 2),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    author,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        rating.toString(),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 3),
                      _buildStarRating(rating),
                      const SizedBox(width: 4),
                      Text(
                        '($reviews)',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (originalPrice.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            originalPrice,
                            style: const TextStyle(
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
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

  String _formatCurrency(num? value) {
    if (value == null) return '';
    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      currentIndex: 1, // Tìm kiếm đang active
    onTap: (index) {
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false, // Xóa hết các route cũ, chỉ giữ lại Home
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalCoursesScreen(userId: userID ?? 0),
            ), // Thay bằng tên màn hình học tập của bạn
          );
        } else if (index == 3) {
          
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Nổi bật'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle_outline),
          label: 'Học tập',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Tài khoản',
        ),
      ],
    );
  }
Future<void> getUserData() async {
    // Lấy id người dùng
    final id = await AuthHelper.getUserIdFromToken();
    setState(() {
      userID = id ?? 0;
    });
  }
  void _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchResults.clear();
    });

    try {
      final results = await CoursesApi.getCoursesBySearch(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tìm kiếm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToCategory(String categoryName) async {
    try {
      final dbCategory = _mapCategoryToDbName(categoryName);
      setState(() {
        _isSearching = true;
        _hasSearched = true; 
        _searchResults.clear();
      });

      final results = await CoursesApi.getCoursesByCategory(dbCategory);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  String _mapCategoryToDbName(String displayName) {
    final Map<String, String> categoryMapping = {
      'CNTT & Phần mềm': 'develop',
      'Kinh doanh': 'business',
      'Tài chính & Kế toán': 'finance',
      'Phát triển cá nhân': 'personal',
      'Thiết kế': 'design',
      'Marketing': 'marketing',
      'Âm nhạc': 'music',
      'Nhiếp ảnh & Video': 'photo',
      'Sức khỏe & Thể hình': 'health',
      'Ngôn ngữ': 'language',
      'Giáo dục': 'education',
      'Du lịch & Ẩm thực': 'travel',
      'Khoa học & Công nghệ': 'science',
    };

    return categoryMapping[displayName] ?? displayName.toLowerCase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
