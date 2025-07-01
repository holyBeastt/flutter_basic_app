import 'package:flutter/material.dart';
import '../models/payment.dart';

class PaymentMethodSelector extends StatefulWidget {
  final String selectedMethod;
  final Function(String) onMethodChanged;

  const PaymentMethodSelector({
    Key? key,
    required this.selectedMethod,
    required this.onMethodChanged,
  }) : super(key: key);

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  final List<PaymentMethodOption> paymentMethods = [
    PaymentMethodOption(
      method: PaymentMethod.creditCard,
      title: 'Thẻ tín dụng',
      subtitle: 'Visa, Mastercard, JCB',
      icon: Icons.credit_card,
      color: Colors.blue,
    ),
    PaymentMethodOption(
      method: PaymentMethod.debitCard,
      title: 'Thẻ ghi nợ',
      subtitle: 'Thẻ ATM nội địa',
      icon: Icons.payment,
      color: Colors.green,
    ),
    PaymentMethodOption(
      method: PaymentMethod.momo,
      title: 'MoMo',
      subtitle: 'Ví điện tử MoMo',
      icon: Icons.account_balance_wallet,
      color: Colors.pink,
    ),
    PaymentMethodOption(
      method: PaymentMethod.zalopay,
      title: 'ZaloPay',
      subtitle: 'Ví điện tử ZaloPay',
      icon: Icons.account_balance_wallet,
      color: Colors.blue[700]!,
    ),
    PaymentMethodOption(
      method: PaymentMethod.vnpay,
      title: 'VNPay',
      subtitle: 'Cổng thanh toán VNPay',
      icon: Icons.account_balance,
      color: Colors.red,
    ),
    PaymentMethodOption(
      method: PaymentMethod.bankTransfer,
      title: 'Chuyển khoản ngân hàng',
      subtitle: 'Chuyển khoản trực tiếp',
      icon: Icons.account_balance,
      color: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn phương thức thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 16),
        ...paymentMethods.map((option) => _buildPaymentMethodTile(option)),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethodOption option) {
    final isSelected = widget.selectedMethod == option.method;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? option.color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? option.color.withOpacity(0.05) : Colors.white,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: option.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            option.icon,
            color: option.color,
            size: 24,
          ),
        ),
        title: Text(
          option.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? option.color : Colors.grey[800],
          ),
        ),
        subtitle: Text(
          option.subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? option.color : Colors.grey[400]!,
              width: 2,
            ),
            color: isSelected ? option.color : Colors.transparent,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                )
              : null,
        ),
        onTap: () => widget.onMethodChanged(option.method),
      ),
    );
  }
}

class PaymentMethodOption {
  final String method;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  PaymentMethodOption({
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class PaymentSummaryCard extends StatelessWidget {
  final String courseTitle;
  final String? courseImage;
  final double originalPrice;
  final double finalPrice;
  final double discountAmount;
  final String instructor;

  const PaymentSummaryCard({
    Key? key,
    required this.courseTitle,
    this.courseImage,
    required this.originalPrice,
    required this.finalPrice,
    required this.discountAmount,
    required this.instructor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Course info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: courseImage != null
                      ? Image.network(
                          courseImage!,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 60,
                              color: Colors.grey[300],
                              child: Icon(Icons.image, color: Colors.grey[600]),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courseTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Giảng viên: $instructor',
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

            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 12),

            // Price breakdown
            if (discountAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Giá gốc:', style: TextStyle(fontSize: 16)),
                  Text(
                    '${_formatCurrency(originalPrice)}',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Giảm giá:', style: TextStyle(fontSize: 16)),
                  Text(
                    '-${_formatCurrency(discountAmount)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng thanh toán:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatCurrency(finalPrice),
                  style: TextStyle(
                    fontSize: 20,
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

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}đ';
  }
}
