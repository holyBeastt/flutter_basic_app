import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:android_basic/models/review.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:android_basic/api/courses_api.dart';
import 'package:android_basic/api/user_api.dart';
import 'package:android_basic/models/user.dart';

class ReviewPanel extends StatefulWidget {
  final List<Review> reviews;
  final bool isLoading;
  final Function(Review) onSubmit;
  final int courseId;
  final bool canSubmit;
  final Map<String, dynamic>? ratingStats;

  const ReviewPanel({
    Key? key,
    required this.reviews,
    required this.isLoading,
    required this.onSubmit,
    required this.ratingStats,
    required this.courseId,
    this.canSubmit = false,
  }) : super(key: key);

  @override
  _ReviewPanelState createState() => _ReviewPanelState();
}

class _ReviewPanelState extends State<ReviewPanel> {
  double _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingReview = true; // Thêm biến để track trạng thái loading
  User? _currentUser;
  late List<Review> _reviews;
  Review? _myReview;

  @override
  void initState() {
    super.initState();
    _reviews = List.from(widget.reviews);
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      // Thử lấy user info
      User? user;
      try {
        final userMap = await UserAPI.getUserInfo();
        print('Thông tin user: $userMap');
        
        try {
          user = User.fromJson(userMap['user'] ?? userMap);
        } catch (parseError) {
          print('Error parsing User.fromJson: $parseError');
          final data = userMap['user'] ?? userMap;
          user = User(
            id: data['id'] as int? ?? 0,
            username: data['username'] as String? ?? 'Người dùng',
            isActive: data['is_active'] as bool? ?? true,
          );
        }
        print('User loaded: id=${user.id}, username=${user.username}');
      } catch (userError) {
        print('Lỗi getUserInfo: $userError');
        // Tiếp tục vì checkUserReview sẽ dùng token từ AuthHelper
      }
      
      // Gọi API để kiểm tra review từ database (sử dụng JWT token)
      final checkResult = await CoursesApi.checkUserReview(widget.courseId);
      print('=== CHECK REVIEW RESULT ===');
      print('success: ${checkResult['success']}');
      print('hasReviewed: ${checkResult['hasReviewed']}');
      print('review data: ${checkResult['review']}');
      
      Review? myReview;
      if (checkResult['success'] == true && checkResult['hasReviewed'] == true) {
        final reviewData = checkResult['review'];
        print('reviewData: $reviewData');
        if (reviewData != null) {
          myReview = Review(
            courseId: reviewData['course_id'],
            userId: reviewData['user_id'],
            userName: reviewData['user_name'],
            rating: reviewData['rating'],
            comment: reviewData['comment'],
            createdAt: reviewData['created_at'],
            isVerified: false,
            helpfulCount: 0,
          );
          print('myReview created!');
        }
      }

      print('=== SETTING STATE ===');
      print('_myReview is null: ${myReview == null}');
      
      setState(() {
        _currentUser = user;
        _myReview = myReview;
        _isCheckingReview = false;
      });
    } catch (e) {
      print('Lỗi trong _loadUserInfo: $e');
      setState(() {
        _isCheckingReview = false;
      });
    }
  }

  void _handleSubmit() async {
    if (_userRating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn số sao và nhập bình luận')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    print('Đang gửi đánh giá...');
    print(
      'Đánh giá: ${_userRating.toInt()} sao, bình luận: ${_commentController.text.trim()}',
    );
    try {
      final success = await CoursesApi.submitReview(
        courseId: widget.courseId,
        rating: _userRating.toInt(),
        comment: _commentController.text.trim(),
      );

      final submittedRating = _userRating.toInt();
      final submittedComment = _commentController.text.trim();

      setState(() {
        _isSubmitting = false;
        _userRating = 0;
        _commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Gửi đánh giá thành công!' : 'Gửi đánh giá thất bại!',
          ),
        ),
      );

      if (success) {
        // Gọi lại API để lấy review với username đã giải mã từ server
        final checkResult = await CoursesApi.checkUserReview(widget.courseId);
        
        Review? newReview;
        if (checkResult['success'] == true && checkResult['hasReviewed'] == true) {
          final reviewData = checkResult['review'];
          if (reviewData != null) {
            newReview = Review(
              courseId: reviewData['course_id'],
              userId: reviewData['user_id'],
              userName: reviewData['user_name'] ?? 'Người dùng',
              rating: reviewData['rating'],
              comment: reviewData['comment'],
              createdAt: reviewData['created_at'],
              isVerified: false,
              helpfulCount: 0,
            );
          }
        }
        
        // Fallback nếu checkUserReview fail
        newReview ??= Review(
          courseId: widget.courseId,
          userId: _currentUser?.id ?? 0,
          userName: _currentUser?.username ?? 'Người dùng',
          rating: submittedRating,
          comment: submittedComment,
          createdAt: DateTime.now().toIso8601String(),
          isVerified: false,
          helpfulCount: 0,
        );

        setState(() {
          _reviews.insert(0, newReview!);
          _myReview = newReview;
        });

        widget.onSubmit.call(newReview);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      print('Lỗi khi gửi đánh giá: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gửi đánh giá thất bại!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // _buildRatingOverview(widget.ratingStats),
            const SizedBox(height: 8),
            // Hiển thị loading khi đang kiểm tra review
            _isCheckingReview
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : (_myReview != null
                    ? Column(
                        children: [
                          _buildSubmittedReviewBox(),
                          const SizedBox(height: 24),
                        ],
                      )
                    : (widget.canSubmit
                        ? _buildReviewForm()
                        : Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              'Bạn cần đăng ký khóa học để gửi đánh giá.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ))),
            Text(
              'Đánh giá từ học viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            widget.isLoading
                ? Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? Text('Chưa có đánh giá nào.')
                : Column(
                  children:
                      _reviews
                          .map((review) => _buildReviewItem(review))
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedReviewBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text("Bạn đã đánh giá khóa học này.")),
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
                      review.userName ?? '',
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
          Text(review.comment ?? ''),
        ],
      ),
    );
  }

  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá khóa học',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        RatingBar.builder(
          initialRating: _userRating,
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 5,
          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) {
            setState(() {
              _userRating = rating;
            });
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Nhập đánh giá của bạn...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _isSubmitting
            ? Center(child: CircularProgressIndicator())
            : ElevatedButton(
              onPressed: _handleSubmit,
              child: Text('Gửi đánh giá'),
            ),
      ],
    );
  }

  // Widget _buildRatingOverview(Map<String, dynamic>? stats) {
  //   return Text("Tổng quan đánh giá: ⭐⭐⭐⭐☆ (giả lập)");
  // }

  String _formatTimeAgo(String dateTimeString) {
    try {
      final time = DateTime.parse(dateTimeString);
      final diff = DateTime.now().difference(time);
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      return '${diff.inDays} ngày trước';
    } catch (_) {
      return '';
    }
  }
}
