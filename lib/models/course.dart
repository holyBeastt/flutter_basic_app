import '../helpers/app_logger.dart';

class Course {
  final int id;
  final String? title;
  final String? subtitle;
  final String? description;
  final int? userId;
  final int? categoryId;
  final String? thumbnailUrl;
  final double? price;
  final double? discountPrice;
  final String? level;
  final DateTime? updatedAt;
  final DateTime? discountEndDate;
  final String? userName;
  final String? categoryName;
  final double? rating;
  final int? studentCount;
  final String? previewVideoUrl;
  final bool? isPublished;
  final bool? isFeatured;
  final int? totalDuration;
  final int? totalLessons;
  final String? requirements;
  final String? whatYouLearn;
  final int? reviewCount;

  Course({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.userId,
    this.categoryId,
    this.thumbnailUrl,
    this.price,
    this.discountPrice,
    this.level,
    this.updatedAt,
    this.discountEndDate,
    this.userName,
    this.categoryName,
    this.rating,
    this.studentCount,
    this.previewVideoUrl,
    this.isPublished,
    this.isFeatured,
    this.totalDuration,
    this.totalLessons,
    this.requirements,
    this.whatYouLearn,
    this.reviewCount,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      userId: json['user_id'] as int?,
      categoryId: json['category_id'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      discountPrice: (json['discount_price'] as num?)?.toDouble(),
      level: json['level'] as String?,
      updatedAt: parseDate(json['updated_at'] as String?),
      discountEndDate: parseDate(json['discount_end_date'] as String?),

      // updatedAt:
      //     json['updated_at'] != null
      //         ? DateTime.parse(json['updated_at'] as String)
      //         : null,
      // discountEndDate:
      //     json['discount_end_date'] != null
      //         ? DateTime.parse(json['discount_end_date'] as String)
      //         : null,
      userName: json['user_name'] as String?,
      categoryName: json['category_name'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      studentCount: json['student_count'] as int?,
      previewVideoUrl: json['preview_video_url'] as String?,
      isPublished: json['is_published'] as bool?,
      isFeatured: json['is_featured'] as bool?,
      totalDuration: json['total_duration'] as int?,
      totalLessons: json['total_lessons'] as int?,
      requirements: json['requirements'] as String?,
      whatYouLearn: json['what_you_learn'] as String?,
      reviewCount: json['review_count'] as int?,
    );
  }

  static DateTime? parseDate(String? rawDate) {
    try {
      if (rawDate != null) {
        return DateTime.parse(rawDate);
      }
    } catch (e) {
      AppLogger.debug('Không thể parse ngày: $rawDate. Lỗi: $e');
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'user_id': userId,
      'category_id': categoryId,
      'thumbnail_url': thumbnailUrl,
      'price': price,
      'discount_price': discountPrice,
      'level': level,
      'updated_at': updatedAt?.toIso8601String(),
      'discount_end_date': discountEndDate?.toIso8601String(),
      'user_name': userName,
      'category_name': categoryName,
      'rating': rating,
      'student_count': studentCount,
      'preview_video_url': previewVideoUrl,
      'is_published': isPublished,
      'is_featured': isFeatured,
      'total_duration': totalDuration,
      'total_lessons': totalLessons,
      'requirements': requirements,
      'what_you_learn': whatYouLearn,
      'review_count': reviewCount,
    };
  }
}
