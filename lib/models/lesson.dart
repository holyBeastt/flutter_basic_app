class Lesson {
  final int id;
  final String? title;
  final bool? isFree;
  final int? duration;
  final int courseId;
  final int? fileSize;
  final DateTime? createdAt;
  final int sectionId;
  final DateTime? updatedAt;
  final bool? canPreview;
  final String? contentUrl;
  final String? description;
  final int? orderIndex;
  final String? contentText;
  final String? contentType;

  Lesson({
    required this.id,
    required this.title,
    required this.isFree,
    required this.duration,
    required this.courseId,
    this.fileSize,
    required this.createdAt,
    required this.sectionId,
    this.updatedAt,
    required this.canPreview,
    required this.contentUrl,
    required this.description,
    required this.orderIndex,
    this.contentText,
    required this.contentType,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    try {
      return Lesson(
        id: _parseToInt(json['id']),
        title: json['title'] ?? '',
        isFree: json['is_free'] ?? false,
        duration: _parseToInt(json['duration']),
        courseId: _parseToInt(json['course_id']),
        fileSize:
            json['file_size'] != null ? _parseToInt(json['file_size']) : null,
        createdAt: _parseDateTime(json['created_at']),
        sectionId: _parseToInt(json['section_id']),
        updatedAt:
            json['updated_at'] != null
                ? _parseDateTime(json['updated_at'])
                : null,
        canPreview: json['can_preview'] ?? false,
        contentUrl: json['content_url'] ?? '',
        description: json['description'] ?? '',
        orderIndex: _parseToInt(json['order_index']),
        contentText: json['content_text'],
        contentType: json['content_type'] ?? '',
      );
    } catch (e) {
      print('Error parsing Lesson: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Helper methods
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
