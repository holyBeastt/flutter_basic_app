import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/payment.dart';
import '../api/payment_api.dart';
import '../widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/server.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../helpers/app_logger.dart';

class PaymentScreen extends StatefulWidget {
  final Course course;
  final int userId;

  const PaymentScreen({Key? key, required this.course, required this.userId})
    : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = PaymentMethod.creditCard;
  bool isProcessing = false;
  bool showCardForm = true;
  String? momoQRData;
  String? momoOrderId;
  Timer? _pollingTimer;

  // Card form controllers
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    _pollingTimer?.cancel();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    nameController.dispose();
    super.dispose();
  }

  double get originalPrice => widget.course.price ?? 0.0;
  double get discountPrice => widget.course.discountPrice ?? 0.0;
  double get finalPrice => discountPrice > 0 ? discountPrice : originalPrice;
  double get discountAmount => originalPrice - finalPrice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán khóa học')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseInfo(),
            const SizedBox(height: 24),
            _buildPriceBreakdown(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
            const SizedBox(height: 24),
            if (showCardForm) _buildPaymentForm(),
            const SizedBox(height: 32),
            _buildPaymentButton(),
            // Hiển thị QR MoMo nếu chọn MoMo và đã nhận được dữ liệu QR
            if (selectedPaymentMethod == PaymentMethod.momo &&
                momoQRData != null) ...[
              const SizedBox(height: 20),
              Center(child: QrImageView(data: momoQRData!, size: 220)),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Quét mã này bằng app MoMo để thanh toán',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.course.thumbnailUrl ?? '',
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.title ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.course.userName ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chi tiết thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Giá gốc:'),
                Text(
                  '${originalPrice.toStringAsFixed(0)}đ',
                  style:
                      discountAmount > 0
                          ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          )
                          : null,
                ),
              ],
            ),
            if (discountAmount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giảm giá:'),
                  Text(
                    '-${discountAmount.toStringAsFixed(0)}đ',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${finalPrice.toStringAsFixed(0)}đ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethodOption(
              PaymentMethod.creditCard,
              'Thẻ tín dụng',
              Icons.credit_card,
            ),
            _buildPaymentMethodOption(
              PaymentMethod.debitCard,
              'Thẻ ghi nợ',
              Icons.payment,
            ),
            _buildPaymentMethodOption(
              PaymentMethod.momo,
              'MoMo',
              Icons.account_balance_wallet,
            ),
            _buildPaymentMethodOption(
              PaymentMethod.zalopay,
              'ZaloPay',
              Icons.payment,
            ),
            _buildPaymentMethodOption(
              PaymentMethod.vnpay,
              'VNPay',
              Icons.account_balance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(String method, String title, IconData icon) {
    return RadioListTile<String>(
      value: method,
      groupValue: selectedPaymentMethod,
      onChanged: (value) {
        setState(() {
          selectedPaymentMethod = value!;
          showCardForm =
              method == PaymentMethod.creditCard ||
              method == PaymentMethod.debitCard;
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin thẻ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Số thẻ',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: 'MM/YY',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên chủ thẻ',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child:
            isProcessing
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Đang xử lý...'),
                  ],
                )
                : Text(
                  'Thanh toán ${finalPrice.toStringAsFixed(0)}đ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Future<void> _processPayment() async {
   
    if (!_validateForm()) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Nếu chọn MoMo thì xử lý riêng
      if (selectedPaymentMethod == PaymentMethod.momo) {
        String orderId =
            '${widget.userId}_${widget.course.id}_${DateTime.now().millisecondsSinceEpoch}';
             AppLogger.debug('Trước khi gọi createMomoPayment');
        final response = await PaymentApi.createMomoPayment(
          user_id: widget.userId,
          course_id: widget.course.id,
          amount: finalPrice,
          orderId: orderId,
          orderInfo: "Thanh toán khoá học ${widget.course.title}",
          returnUrl:
              "https://your-app.com/return", // truyền URL của bạn nếu cần
          notifyUrl: "$baseUrl/api/momo/webhook",

        );
        AppLogger.debug('===> Create MoMo payment response: $response');
        if (response['success'] && response['qrData'] != null) {
          setState(() {
            momoQRData = response['qrData'];
            momoOrderId = response['orderId'] ?? orderId;
          });
          AppLogger.debug('===> Đã nhận QR data, bắt đầu polling status: $momoOrderId');
          _startPollingPaymentStatus(momoOrderId!);
        } else {
          _showErrorDialog(response['message'] ?? 'Lỗi khi tạo đơn MoMo');
        }
        setState(() {
          isProcessing = false; // Dừng loading sau khi lấy QR
        });
        return;
      } else {
        // Xử lý các phương thức khác như cũ
        final payment = Payment(
          userId: widget.userId,
          courseId: widget.course.id,
          amount: finalPrice,
          originalPrice: originalPrice,
          discountAmount: discountAmount,
          paymentMethod: selectedPaymentMethod,
          status: PaymentStatus.pending,
        );

        final createResult = await PaymentApi.createPayment(payment);

        if (createResult['success']) {
          final paymentData = createResult['data'];
          final paymentId = paymentData['id'];

          // Process payment
          final processResult = await PaymentApi.processPayment(
            paymentId,
            selectedPaymentMethod,
          );

          if (processResult['success']) {
            _showSuccessDialog();
          } else {
            _showErrorDialog(processResult['message']);
          }
        } else {
          _showErrorDialog(createResult['message']);
        }
      }
    } catch (e) {
      _showErrorDialog('Đã xảy ra lỗi: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

void _startPollingPaymentStatus(String orderId) {
  AppLogger.debug('===> Bắt đầu polling status cho orderId: $orderId');
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      final response = await PaymentApi.checkMomoStatus(orderId);
      AppLogger.debug('===> Polling response: $response');

      if (response['success'] && response['paid'] == true) {
        AppLogger.debug('===> Status PAID, chuyển trang');
        _pollingTimer?.cancel();
        _showSuccessDialog();
      }
    });
  }

  bool _validateForm() {
    if (showCardForm) {
      if (cardNumberController.text.isEmpty ||
          expiryController.text.isEmpty ||
          cvvController.text.isEmpty ||
          nameController.text.isEmpty) {
        _showErrorDialog('Vui lòng điền đầy đủ thông tin thẻ');
        return false;
      }
    }
    return true;
  }

void _showSuccessDialog() {
    // Đợi 1 giây để user nhìn thấy dialog, sau đó tự động đóng
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Thanh toán thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  'Bạn đã đăng ký thành công khóa học "${widget.course.title}"',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
    );

    // Đóng dialog và quay về sau 1.5 giây
    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context, rootNavigator: true).pop(); // đóng dialog
      Navigator.of(
        context,
      ).pop(true); // quay về trang trước (CourseDetail), trả về true
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Thanh toán thất bại'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Thử lại'),
              ),
            ],
          ),
    );
  }
}
