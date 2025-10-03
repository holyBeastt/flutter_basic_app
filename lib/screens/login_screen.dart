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

  void handleLogin() async {
    if (usernameController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      SimpleToast.showError(context, 'Vui lòng nhập đầy đủ thông tin!');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$baseUrl/api/auth/user/login');

    final body = jsonEncode({
      'username': usernameController.text.trim(),
      'password': passwordController.text.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'];
        final user = data['user'];

        // ✅ Lưu token sau khi đăng nhập
        await _storage.write(key: 'jwt_token', value: token);

        // Lưu id, họ tên user
        await _storage.write(key: 'user', value: jsonEncode(user));
        
        // Hiển thị thông báo thành công
        SimpleToast.showSuccess(context, 'Đăng nhập thành công! Chào mừng bạn quay trở lại!');
        
        // Chuyển màn hình sau 1.5 giây
        Future.delayed(Duration(milliseconds: 1500), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        });
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = 'Đăng nhập thất bại!';
        
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
        
        SimpleToast.showError(context, errorMessage);
      }
    } catch (e) {
      SimpleToast.showError(context, 'Không thể kết nối đến server. Vui lòng thử lại!');
    } finally {
      setState(() {
        isLoading = false;
      });
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
                    SizedBox(height: 120),

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
                    SizedBox(height: 40),
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
