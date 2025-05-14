import 'dart:convert';

import 'package:android_basic/constants.dart';
import 'package:android_basic/screens/login_screen.dart';
import 'package:android_basic/widgets/custom_button.dart';
import 'package:android_basic/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  void handleSingup() async {
    final url = Uri.parse('$baseUrl/api/auth/user/signup');

    final body = jsonEncode({
      'username': usernameController.text.trim(),
      'password': passwordController.text.trim(),
      'confirmPassword': confirmPasswordController.text.trim(),
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
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
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
          Padding(
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
                  hint: "Username",
                  controller: usernameController,
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
                  text: "Sign up",
                  isLarge: true,
                  onPressed: handleSingup,
                ),
                const SizedBox(height: 40),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
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
                const SizedBox(height: 50),
                Text(
                  "Or continue with",
                  style: body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialButton(iconPath: "assets/google_icon.png"),
                    const SizedBox(width: 10),
                    SocialButton(iconPath: "assets/facebook_icon.png"),
                    const SizedBox(width: 10),
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
