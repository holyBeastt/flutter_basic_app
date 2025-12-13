import 'dart:convert';

import 'package:android_basic/constants.dart';
import 'package:android_basic/screens/home_screen.dart';
import 'package:android_basic/screens/signup_screen.dart';
import 'package:android_basic/widgets/custom_button.dart';
import 'package:android_basic/widgets/custom_widgets.dart';
import 'package:android_basic/widgets/simple_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';
import '../api/auth_api.dart';
import '../helpers/auth_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  static final _storage = const FlutterSecureStorage();
  bool isLoading = false;
  final AuthApi _authApi = AuthApi(); // Khởi tạo service

  // void handleLogin() async {
  //   final username = usernameController.text;
  //   final password = passwordController.text;

  //   setState(() {
  //     isLoading = true;
  //   });

  //   final result = await AuthApi().login(username, password);

  //   setState(() {
  //     isLoading = false;
  //   });

  //   if (result['success'] == true) {
  //     // Hiển thị toast
  //     SimpleToast.showSuccess(
  //       context,
  //       'Đăng nhập thành công! Chào mừng bạn quay trở lại!',
  //     );

  //     // Chuyển trang (không cần delay nếu bạn không muốn)
  //     Future.delayed(Duration(milliseconds: 1000), () {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => HomeScreen()),
  //       );
  //     });
  //   } else {
  //     SimpleToast.showError(context, result['message']);
  //   }
  // }

  // void handleGoogleLogin() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   // Gọi hàm từ Service
  //   final result = await _authApi.loginWithGoogle();

  //   setState(() {
  //     isLoading = false;
  //   });

  //   if (result['success']) {
  //     SimpleToast.showSuccess(context, 'Đăng nhập Google thành công!');

  //     Future.delayed(Duration(milliseconds: 1000), () {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => HomeScreen()),
  //       );
  //     });
  //   } else {
  //     SimpleToast.showError(context, result['message']);
  //   }
  // }

  // 1. XỬ LÝ ĐĂNG NHẬP THƯỜNG
  void handleLogin() async {
    final username = usernameController.text;
    final password = passwordController.text;

    setState(() => isLoading = true);

    final result = await AuthApi().login(username, password);

    setState(() => isLoading = false);

    if (result['success'] == true) {
      // ========== ĐĂNG NHẬP THÀNH CÔNG ==========
      final data = result['data'];

      // Lưu vào Secure Storage thông qua AuthHelper
      await AuthHelper.saveAuthData(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        user: data['user'],
      );

      if (!mounted) return;

      SimpleToast.showSuccess(context, 'Đăng nhập thành công!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } 
    // ========== TÀI KHOẢN BỊ KHÓA (Backend trả về 423) ==========
    else if (result['locked'] == true) {
      if (!mounted) return;
      
      final remainingMinutes = result['remaining_minutes'] ?? 10;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_clock, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Tài khoản bị khóa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tài khoản "${username}" đã bị khóa do nhập sai mật khẩu quá nhiều lần.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.timer, size: 40, color: Colors.red),
                    SizedBox(height: 8),
                    Text(
                      'Thời gian còn lại:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$remainingMinutes phút',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đã hiểu', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    } 
    // ========== SAI MẬT KHẨU (Backend trả về attempts_remaining) ==========
    else {
      if (!mounted) return;
      
      String errorMessage = result['message'] ?? 'Đăng nhập thất bại!';
      
      // Nếu backend trả về số lần còn lại
      if (result['attempts_remaining'] != null) {
        final attemptsLeft = result['attempts_remaining'];
        errorMessage = 'Sai mật khẩu! Còn $attemptsLeft lần thử.';
      }
      
      SimpleToast.showError(context, errorMessage);
    }
  }

  // 2. XỬ LÝ ĐĂNG NHẬP GOOGLE
  void handleGoogleLogin() async {
    setState(() => isLoading = true);

    final result = await _authApi.loginWithGoogle();

    setState(() => isLoading = false);

    if (result['success'] == true) {
      // --- [BỔ SUNG QUAN TRỌNG] ---
      final data = result['data'];

      await AuthHelper.saveAuthData(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        user: data['user'],
      );
      // ----------------------------

      if (!mounted) return;

      SimpleToast.showSuccess(context, 'Đăng nhập Google thành công!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      if (!mounted) return;
      SimpleToast.showError(context, result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -330,
            right: -330,
            child: Container(
              height: 600,
              width: 600,
              decoration: BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -((1 / 4) * 500),
            right: -((1 / 4) * 500),
            child: Container(
              height: 450,
              width: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: lightBlue, width: 2),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    SizedBox(height: 100),
                    Text("Login here", style: h2),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        "Wellcome back",
                        style: h2.copyWith(fontSize: 18, color: black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 80),

                    // Gắn controller vào CustomTextfield
                    CustomTextfield(
                      hint: "Username",
                      controller: usernameController,
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      hint: "Password",
                      controller: passwordController,
                      obscureText: true,
                    ),

                    SizedBox(height: 25),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Forgot your password",
                        style: body.copyWith(
                          fontSize: 16,
                          color: primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    CustomButton(
                      text: isLoading ? "Đang đăng nhập..." : "Sign in",
                      isLarge: true,
                      onPressed: isLoading ? null : handleLogin,
                    ),
                    SizedBox(height: 30),

                    // Dòng kẻ phân cách "Or continue with"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[400], thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Or continue with",
                            style: body.copyWith(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[400], thickness: 1),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Nút Google Login
                    InkWell(
                      onTap: handleGoogleLogin,
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Bo góc khi nhấn
                      child: Container(
                        height:
                            55, // Chiều cao bằng hoặc nhỏ hơn CustomButton xíu
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10), // Bo góc
                          border: Border.all(
                            color: Colors.grey[300]!,
                          ), // Viền mỏng
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo Google
                            // Nếu bạn có file ảnh thì dùng: Image.asset('assets/images/google_logo.png', height: 24),
                            // Ở đây mình dùng Icon tạm, nhưng Google bắt buộc dùng logo gốc của họ để đúng luật brand
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                              ),
                              // Bạn nên thay icon này bằng ảnh logo Google chuẩn (file png)
                              child: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                height: 24,
                                width: 24,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                      Icons.g_mobiledata,
                                      size: 30,
                                      color: Colors.red,
                                    ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Sign in with Google",
                              style: body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87, // Chữ màu đen/xám đậm
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Create new account",
                        style: body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
