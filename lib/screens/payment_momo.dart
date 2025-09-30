// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:url_launcher/url_launcher.dart';

// class PaymentMomoScreen extends StatelessWidget {
//   final double amount;
//   final String orderId;
//   final String orderInfo;

//   PaymentMomoScreen({
//     required this.amount,
//     required this.orderId,
//     required this.orderInfo,
//   });

//   Future<void> payWithMomo(BuildContext context) async {
//     final response = await http.post(
//       Uri.parse('https://c82969a1c8a5.ngrok-free.app/api/momo/create-payment'),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "amount": amount,
//         "orderId": orderId,
//         "orderInfo": orderInfo,
//         "returnUrl": "https://www.facebook.com/nguyennvuu.113", // deep link về app của bạn
//         "notifyUrl": "https://c82969a1c8a5.ngrok-free.app/api/momo/webhook",
//       }),
//     );

//     final data = jsonDecode(response.body);
//     final payUrl = data['payUrl'] ?? data['deeplink'] ?? '';

//     if (payUrl.isNotEmpty && await canLaunch(payUrl)) {
//       await launch(payUrl); // Tự động mở MoMo app/web
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Không mở được MoMo!')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Thanh toán MoMo')),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () => payWithMomo(context),
//           child: Text('Thanh toán bằng MoMo'),
//         ),
//       ),
//     );
//   }
// }
