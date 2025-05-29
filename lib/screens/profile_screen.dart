import 'package:flutter/material.dart';
import 'package:android_basic/api/user_api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController sexController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController numberOfStudentsController =
      TextEditingController();
  final TextEditingController usernameAccController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController avatarUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Giả sử bạn có API để load data
    loadUserProfile();
  }

  void loadUserProfile() {
    // Gắn dữ liệu demo
    usernameController.text = "john_doe";
    sexController.text = "male";
    ageController.text = "25";
    numberOfStudentsController.text = "10";
    usernameAccController.text = "john123";
    passwordController.text = "password123";
    avatarUrlController.text = "https://example.com/avatar.jpg";
  }

  void _saveProfile() {
    final data = {
      "username": usernameController.text,
      "sex": sexController.text,
      "age": int.tryParse(ageController.text) ?? 0,
      "number_of_students": int.tryParse(numberOfStudentsController.text) ?? 0,
      "username_acc": usernameAccController.text,
      "password": passwordController.text,
      "avatar_url": avatarUrlController.text,
    };

    UserAPI.saveProfileToServer(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thông tin cá nhân")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField("Username", usernameController),
            _buildTextField("Sex", sexController),
            _buildTextField(
              "Age",
              ageController,
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              "Number of Students",
              numberOfStudentsController,
              keyboardType: TextInputType.number,
            ),
            _buildTextField("Username Acc", usernameAccController),
            _buildTextField("Password", passwordController, obscureText: true),
            _buildTextField("Avatar URL", avatarUrlController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text("Lưu thay đổi"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
