import 'dart:convert';
import 'dart:math';
import '../models/payment.dart';
import '../config/server.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
class PaymentApi {
  // Simulate payment processing delay
  static Future<void> _simulateDelay() async {
    await Future.delayed(Duration(seconds: Random().nextInt(3) + 2));
  }

  // Static storage để mô phỏng database (chỉ để demo)
  static final Map<String, bool> _purchasedCourses = {};
  static final List<Map<String, dynamic>> _paymentHistory = [];
  static String apiUrl = dotenv.env['URL_NGROK'] ?? '';
  // Create a new payment
  static Future<Map<String, dynamic>> createPayment(Payment payment) async {
    try {
      await _simulateDelay();

      // Simulate payment creation
      final createdPayment = payment.copyWith(
        id: Random().nextInt(10000) + 1,
        createdAt: DateTime.now(),
        transactionId: _generateTransactionId(),
        status: PaymentStatus.pending,
        paymentDate: DateTime.now(),
      );

      return {
        'success': true,
        'message': 'Payment created successfully',
        'data': createdPayment.toJson(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create payment: $e',
        'data': null,
      };
    }
  }
  // Thanh toán bằng momo
  static Future<Map<String, dynamic>> createMomoPayment({
    required double amount,
    required String orderId,
    required String orderInfo,
    required String returnUrl,
    required String notifyUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${apiUrl}/api/momo/create-payment'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "amount": amount,
        "orderId": orderId,
        "orderInfo": orderInfo,
        "returnUrl": returnUrl,
        "notifyUrl": notifyUrl,
      }),
    );
    return jsonDecode(response.body);
  }

  
  // Process payment (simulate payment gateway)
  static Future<Map<String, dynamic>> processPayment(int paymentId, String paymentMethod) async {
    try {
      await _simulateDelay();

      // Simulate payment processing with 85% success rate
      final isSuccess = Random().nextDouble() < 0.85;

      if (isSuccess) {
        return {
          'success': true,
          'message': 'Payment processed successfully',
          'data': {
            'payment_id': paymentId,
            'transaction_id': _generateTransactionId(),
            'status': PaymentStatus.completed,
            'completed_at': DateTime.now().toIso8601String(),
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Payment processing failed. Please try again.',
          'data': {
            'payment_id': paymentId,
            'status': PaymentStatus.failed,
          },
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Payment processing error: $e',
        'data': null,
      };
    }
  }

  // Lưu trạng thái đã mua khóa học
  static void markCoursePurchased(int userId, int courseId) {
    final key = '${userId}_$courseId';
    _purchasedCourses[key] = true;

    // Lưu vào payment history
    _paymentHistory.add({
      'id': Random().nextInt(10000) + 1,
      'user_id': userId,
      'course_id': courseId,
      'status': PaymentStatus.completed,
      'payment_date': DateTime.now().toIso8601String(),
      'completed_at': DateTime.now().toIso8601String(),
    });
  }

  // Get payment by ID
  static Future<Map<String, dynamic>> getPaymentById(int paymentId) async {
    try {
      await _simulateDelay();

      // Simulate fetching payment data
      final payment = {
        'id': paymentId,
        'created_at': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'user_id': 1,
        'course_id': 1,
        'amount': 299.99,
        'original_price': 399.99,
        'discount_amount': 100.00,
        'payment_method': PaymentMethod.creditCard,
        'transaction_id': _generateTransactionId(),
        'status': PaymentStatus.completed,
        'payment_date': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
        'refunded_at': null,
      };

      return {
        'success': true,
        'message': 'Payment retrieved successfully',
        'data': payment,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get payment: $e',
        'data': null,
      };
    }
  }

  // Get payments by user ID
  static Future<Map<String, dynamic>> getPaymentsByUserId(int userId) async {
    try {
      await _simulateDelay();

      // Simulate fetching user payments
      final payments = [
        {
          'id': 1,
          'created_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          'user_id': userId,
          'course_id': 1,
          'amount': 299.99,
          'original_price': 399.99,
          'discount_amount': 100.00,
          'payment_method': PaymentMethod.creditCard,
          'transaction_id': _generateTransactionId(),
          'status': PaymentStatus.completed,
          'payment_date': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          'completed_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
          'refunded_at': null,
        },
      ];

      return {
        'success': true,
        'message': 'Payments retrieved successfully',
        'data': payments,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get payments: $e',
        'data': null,
      };
    }
  }

  // Check if user has purchased a course
  static Future<Map<String, dynamic>> checkCoursePurchase(int userId, int courseId) async {
    try {
      await _simulateDelay();

      // Kiểm tra trong storage simulation
      final key = '${userId}_$courseId';
      final isPurchased = _purchasedCourses[key] ?? false;

      return {
        'success': true,
        'message': 'Course purchase status checked',
        'data': {
          'is_purchased': isPurchased,
          'purchase_date': isPurchased ? DateTime.now().subtract(Duration(days: 7)).toIso8601String() : null,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to check course purchase: $e',
        'data': null,
      };
    }
  }

  // Calculate course price with discount
  static Map<String, dynamic> calculateCoursePrice(double originalPrice, double? discountPercentage) {
    final discount = discountPercentage ?? 0;
    final discountAmount = originalPrice * (discount / 100);
    final finalPrice = originalPrice - discountAmount;

    return {
      'original_price': originalPrice,
      'discount_percentage': discount,
      'discount_amount': discountAmount,
      'final_price': finalPrice,
    };
  }

  // Generate random transaction ID
  static String _generateTransactionId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'TXN_${String.fromCharCodes(Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))))}';
  }

  // Validate payment method
  static bool isValidPaymentMethod(String method) {
    const validMethods = [
      PaymentMethod.creditCard,
      PaymentMethod.debitCard,
      PaymentMethod.paypal,
      PaymentMethod.bankTransfer,
      PaymentMethod.momo,
      PaymentMethod.zalopay,
      PaymentMethod.vnpay,
    ];
    return validMethods.contains(method);
  }

  // Refund payment (simulate)
  static Future<Map<String, dynamic>> refundPayment(int paymentId, String reason) async {
    try {
      await _simulateDelay();

      // Simulate refund processing with 90% success rate
      final isSuccess = Random().nextDouble() < 0.9;

      if (isSuccess) {
        return {
          'success': true,
          'message': 'Payment refunded successfully',
          'data': {
            'payment_id': paymentId,
            'status': PaymentStatus.refunded,
            'refunded_at': DateTime.now().toIso8601String(),
            'refund_transaction_id': _generateTransactionId(),
          },
        };
      } else {
        return {
          'success': false,
          'message': 'Refund processing failed. Please contact support.',
          'data': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Refund error: $e',
        'data': null,
      };
    }
  }
}
