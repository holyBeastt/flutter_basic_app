import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';
import 'package:android_basic/screens/home_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();


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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildCategoriesSection(),
                  ],
                ),
              ),
            ),
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
            hintText: 'Tìm kiếm',
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


  Widget _buildSearchTag(String tag) {
    return GestureDetector(
      onTap: () => _performSearch(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          tag,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Column(
          children:
              _categories
                  .map((category) => _buildCategoryItem(category))
                  .toList(),
        ),
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
          Navigator.pop(context); // Quay về Home
        } else if (index == 3) {
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        }
        // Các index khác có thể thêm navigation tương ứng
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

 void _performSearch(String query) {
    // Khi search, về Home và truyền query
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(category: null, searchQuery: query),
      ),
      (route) => false,
    );
  }

 void _navigateToCategory(String categoryName) async {
    try {
      print('Navigate to category: $categoryName');

      // Map tên hiển thị sang tên DB category
      String dbCategory = _mapCategoryToDbName(categoryName);

      // Navigate về HomeScreen với category
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(category: dbCategory),
        ),
        (route) => false, // Clear tất cả routes trước đó
      );
    } catch (e) {
      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Thêm function mapping tên category
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
