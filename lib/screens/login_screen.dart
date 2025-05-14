import 'dart:convert';

import 'package:android_basic/constants.dart';
import 'package:android_basic/screens/signup_screen.dart';
import 'package:android_basic/widgets/custom_button.dart';
import 'package:android_basic/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
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

  void handleLogin() async {
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
        final data = json.decode(response.body);
        print("Dữ liệu nhận được:");
        print(data);
      } else {
        print("Lỗi: ${response.statusCode}");
        print("Body: ${response.body}");
      }
    } catch (e) {
      print("Đã xảy ra lỗi: $e");
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
          Padding(
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
                  text: "Sign in",
                  isLarge: true,
                  onPressed: handleLogin,
                ),
                SizedBox(height: 40),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignupScreen()),
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
                SizedBox(height: 50),
                Text(
                  "Or continue with",
                  style: body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(iconPath: "assets/google_icon.png"),
                    SizedBox(width: 10),
                    SocialButton(iconPath: "assets/facebook_icon.png"),
                    SizedBox(width: 10),
                    SocialButton(iconPath: "assets/apple_icon.png"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
