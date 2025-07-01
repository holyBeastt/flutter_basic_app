class Payment {
  final int? id;
  final DateTime? createdAt;
  final int userId;
  final int courseId;
  final double amount;
  final double originalPrice;
  final double discountAmount;
  final String paymentMethod;
  final String? transactionId;
  final String status;
  final DateTime? paymentDate;
  final DateTime? completedAt;
  final DateTime? refundedAt;

  Payment({
    this.id,
    this.createdAt,
    required this.userId,
    required this.courseId,
    required this.amount,
    required this.originalPrice,
    required this.discountAmount,
    required this.paymentMethod,
    this.transactionId,
    required this.status,
    this.paymentDate,
    this.completedAt,
    this.refundedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      userId: json['user_id'],
      courseId: json['course_id'],
      amount: json['amount']?.toDouble() ?? 0.0,
      originalPrice: json['original_price']?.toDouble() ?? 0.0,
      discountAmount: json['discount_amount']?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] ?? '',
      transactionId: json['transaction_id'],
      status: json['status'] ?? 'pending',
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      refundedAt: json['refunded_at'] != null
          ? DateTime.parse(json['refunded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt?.toIso8601String(),
      'user_id': userId,
      'course_id': courseId,
      'amount': amount,
      'original_price': originalPrice,
      'discount_amount': discountAmount,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'status': status,
      'payment_date': paymentDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'refunded_at': refundedAt?.toIso8601String(),
    };
  }

  Payment copyWith({
    int? id,
    DateTime? createdAt,
    int? userId,
    int? courseId,
    double? amount,
    double? originalPrice,
    double? discountAmount,
    String? paymentMethod,
    String? transactionId,
    String? status,
    DateTime? paymentDate,
    DateTime? completedAt,
    DateTime? refundedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      amount: amount ?? this.amount,
      originalPrice: originalPrice ?? this.originalPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
    );
  }
}

// Payment status constants
class PaymentStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String completed = 'completed';
  static const String failed = 'failed';
  static const String cancelled = 'cancelled';
  static const String refunded = 'refunded';
}

// Payment method constants
class PaymentMethod {
  static const String creditCard = 'credit_card';
  static const String debitCard = 'debit_card';
  static const String paypal = 'paypal';
  static const String bankTransfer = 'bank_transfer';
  static const String momo = 'momo';
  static const String zalopay = 'zalopay';
  static const String vnpay = 'vnpay';
}
