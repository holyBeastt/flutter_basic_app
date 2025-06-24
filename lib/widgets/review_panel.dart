import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:android_basic/models/review.dart';

class ReviewPanel extends StatefulWidget {
  final List<Review> reviews;
  final bool isLoading;
  final Function(Review) onSubmit;
  final Map<String, dynamic>? ratingStats;

  const ReviewPanel({
    Key? key,
    required this.reviews,
    required this.isLoading,
    required this.onSubmit,
    required this.ratingStats,
  }) : super(key: key);

  @override
  _ReviewPanelState createState() => _ReviewPanelState();
}

class _ReviewPanelState extends State<ReviewPanel> {
  double _userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_userRating == 0 || _commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn số sao và nhập bình luận')),
      );
      return;
    }

    final newReview = Review(
      id: 0, // gán tạm, nếu có API sẽ cập nhật lại sau
      userId: 0, // tuỳ bạn lấy userId thực tế
      userName: 'Bạn',
      courseId: widget.reviews.isNotEmpty ? widget.reviews.first.courseId : 0,
      rating: _userRating.toInt(),
      comment: _commentController.text.trim(),
      createdAt: DateTime.now().toIso8601String(),
      isVerified: true,
      helpfulCount: 0,
    );

    widget.onSubmit(newReview);

    setState(() {
      _userRating = 0;
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 👉 Ẩn bàn phím khi tap ra ngoài
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRatingOverview(widget.ratingStats),
            const SizedBox(height: 24),
            _buildReviewForm(), // Nhập đánh giá + gửi
            const SizedBox(height: 32),
            Text(
              'Đánh giá từ học viên',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            widget.isLoading
                ? Center(child: CircularProgressIndicator())
                : widget.reviews.isEmpty
                ? Text('Chưa có đánh giá nào.')
                : Column(
                  children:
                      widget.reviews
                          .map((review) => _buildReviewItem(review))
                          .toList(),
                ),
          ],
        ),
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

  Widget _buildRatingOverview(Map<String, dynamic>? stats) {
    // Bạn có thể render biểu đồ cột, trung bình sao ở đây
    return Text("Tổng quan đánh giá: ⭐⭐⭐⭐☆ (giả lập)");
  }

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
