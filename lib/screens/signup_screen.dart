import 'dart:convert';

import 'package:android_basic/constants.dart';
import 'package:android_basic/screens/login_screen.dart';
import 'package:android_basic/widgets/custom_button.dart';
import 'package:android_basic/widgets/custom_widgets.dart';
import 'package:android_basic/widgets/simple_toast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final usernameAccController = TextEditingController(); // Tên tài khoản
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController(); // Tên người dùng
  String selectedSex = 'male'; // Giới tính mặc định
  bool isLoading = false;

  void handleSingup() async {
    // Kiểm tra thông tin đầu vào
    if (usernameAccController.text.trim().isEmpty || 
        passwordController.text.trim().isEmpty || 
        confirmPasswordController.text.trim().isEmpty ||
        usernameController.text.trim().isEmpty) {
      SimpleToast.showError(context, 'Vui lòng nhập đầy đủ thông tin!');
      return;
    }

    // Kiểm tra mật khẩu có khớp không
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      SimpleToast.showError(context, 'Mật khẩu xác nhận không khớp!');
      return;
    }

    // Kiểm tra độ dài mật khẩu
    if (passwordController.text.trim().length < 6) {
      SimpleToast.showError(context, 'Mật khẩu phải có ít nhất 6 ký tự!');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('$baseUrl/api/auth/user/signup');

    final body = jsonEncode({
      'username_acc': usernameAccController.text.trim(),
      'password': passwordController.text.trim(),
      'confirmPassword': confirmPasswordController.text.trim(),
      'username': usernameController.text.trim(),
      'sex': selectedSex,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Đăng ký thành công - hiển thị thông báo màu xanh
        SimpleToast.showSuccess(context, 'Đăng ký thành công! Tài khoản của bạn đã được tạo thành công.');
        
        // Chuyển màn hình sau 2 giây
        Future.delayed(Duration(milliseconds: 2000), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        });
      } else {
        // Đăng ký thất bại - hiển thị thông báo lỗi
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Đăng ký thất bại!';
          
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
          
          SimpleToast.showError(context, errorMessage);
        } catch (jsonError) {
          SimpleToast.showError(context, 'Đăng ký thất bại! Lỗi: ${response.statusCode}');
        }
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
  void dispose() {
    usernameAccController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    super.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Text("Create Account", style: h2),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        "Wellcome back",
                        style: h2.copyWith(fontSize: 16, color: black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 60),
                    CustomTextfield(
                      hint: "Tên tài khoản",
                      controller: usernameAccController,
                    ),
                    const SizedBox(height: 20),
                    CustomTextfield(
                      hint: "Họ và tên",
                      controller: usernameController,
                    ),
                    const SizedBox(height: 20),
                    // Dropdown cho giới tính
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSex,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Nam'),
                            ),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('Nữ'),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Text('Khác'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedSex = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextfield(
                      hint: "Password",
                      controller: passwordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    CustomTextfield(
                      hint: "Confirm Password",
                      controller: confirmPasswordController,
                      obscureText: true,
                    ),
                    const SizedBox(height: 25),
                    const SizedBox(height: 50),
                    CustomButton(
                      text: isLoading ? "Đang đăng ký..." : "Sign up",
                      isLarge: true,
                      onPressed: isLoading ? null : handleSingup,
                    ),
                    const SizedBox(height: 40),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Already have an account",
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
