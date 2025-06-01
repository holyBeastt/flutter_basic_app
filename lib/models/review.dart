class Review {
  final int id;
  final int userId;
  final String? userName;
  final int courseId;
  final int? rating;
  final String? comment;
  final String? createdAt;
  final bool? isVerified;
  final int? helpfulCount;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.courseId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isVerified,
    required this.helpfulCount,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? 'Người dùng ẩn danh',
      courseId: json['course_id'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
      isVerified: json['is_verified'] ?? false,
      helpfulCount: json['helpful_count'] ?? 0,
    );
  }
}
