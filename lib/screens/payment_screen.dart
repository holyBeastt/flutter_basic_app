import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/payment.dart';
import '../api/payment_api.dart';
import '../widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class PaymentScreen extends StatefulWidget {
  final Course course;
  final int userId;

  const PaymentScreen({
    Key? key,
    required this.course,
    required this.userId,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentMethod = PaymentMethod.creditCard;
  bool isProcessing = false;
  bool showCardForm = true;

  // Card form controllers
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
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
      appBar: AppBar(
        title: Text('Thanh toán khóa học'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourseInfo(),
            SizedBox(height: 24),
            _buildPriceBreakdown(),
            SizedBox(height: 24),
            _buildPaymentMethods(),
            SizedBox(height: 24),
            if (showCardForm) _buildPaymentForm(),
            SizedBox(height: 32),
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
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
                    child: Icon(Icons.image),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.course.title ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.course.userName ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giá gốc:'),
                Text(
                  '${originalPrice.toStringAsFixed(0)}đ',
                  style: discountAmount > 0
                      ? TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ],
            ),
            if (discountAmount > 0) ...[
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Giảm giá:'),
                  Text(
                    '-${discountAmount.toStringAsFixed(0)}đ',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ],
            Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
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
    final isSelected = selectedPaymentMethod == method;
    return RadioListTile<String>(
      value: method,
      groupValue: selectedPaymentMethod,
      onChanged: (value) {
        setState(() {
          selectedPaymentMethod = value!;
          showCardForm = method == PaymentMethod.creditCard || method == PaymentMethod.debitCard;
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 12),
          Text(title),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin thẻ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: cardNumberController,
              decoration: InputDecoration(
                labelText: 'Số thẻ',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: expiryController,
                    decoration: InputDecoration(
                      labelText: 'MM/YY',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: cvvController,
                    decoration: InputDecoration(
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
            SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
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
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child: isProcessing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Đang xử lý...'),
                ],
              )
            : Text(
                'Thanh toán ${finalPrice.toStringAsFixed(0)}đ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }



Future<void> _processPayment() async {
  String urlNgrok = dotenv.env['URL_NGROK']??'';
  if (!_validateForm()) return;

  setState(() {
    isProcessing = true;
  });

  try {
    // Nếu chọn MoMo thì xử lý riêng
    if (selectedPaymentMethod == PaymentMethod.momo) {
      // Gọi API backend để lấy link payUrl MoMo (hiện mã QR)
      final response = await PaymentApi.createMomoPayment(
        amount: finalPrice,
        orderId: '${widget.userId}_${widget.course.id}_${DateTime.now().millisecondsSinceEpoch}', // hoặc sinh mã đơn hàng riêng
        orderInfo: "Thanh toán khoá học ${widget.course.title}",
        returnUrl: "https://chatgpt.com/c/68dbdd3f-78cc-832c-b369-292087e12318", // deep link về app của bạn
        notifyUrl: "${urlNgrok}/api/momo/webhook"
      );
      if (response['success']) {
        final payUrl = response['payUrl'];
        if (payUrl != null && await canLaunchUrl(Uri.parse(payUrl))) {
          await launchUrl(Uri.parse(payUrl)); // Chuyển sang web MoMo, hiện mã QR
        } else {
          _showErrorDialog('Không mở được trang MoMo!');
        }
      } else {
        _showErrorDialog(response['message'] ?? 'Lỗi khi tạo đơn MoMo');
      }
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
        final processResult = await PaymentApi.processPayment(paymentId, selectedPaymentMethod);

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Thanh toán thành công!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn đã đăng ký thành công khóa học "${widget.course.title}"',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success
            },
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thanh toán thất bại'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
