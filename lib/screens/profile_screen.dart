import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../helpers/auth_helper.dart';
import '../services/http_client.dart';

import '../config/server.dart';
import '../api/user_api.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  bool isLoading = true;
  Map<String, dynamic> userMap = {};
  File? avatarFile;

  @override
  void initState() {
    super.initState();
    // getUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
    });
  }

  // / Load user info từ server (đã decrypt ở backend)
  Future<void> _loadUserInfo() async {
    try {
      debugPrint('🔥 loadUserInfo start');

      final token = await AuthHelper.getAccessToken();
      if (token == null) throw Exception('Chưa đăng nhập');

      final userStr = await AuthHelper.getRawUserInfo();
      if (userStr == null) throw Exception('Không tìm thấy user_info');

      final localUser = jsonDecode(userStr);
      final userId = localUser['id']?.toString();
      if (userId == null) throw Exception('UserId null');

      final response = await AppHttpClient.get(
        Uri.parse('$baseUrl/api/users/$userId/get-user-info'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) {
        throw Exception('API lỗi ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        userMap = {
          'id': data['id'],
          'username': data['username'],
          'bio': data['bio'],
          'sex': data['sex'],
          'avatar_url': data['avatar_url'],
        };
        isLoading = false;
      });

      await AuthHelper.saveUserInfo(userMap);
    } catch (e) {
      debugPrint('❌ loadUserInfo error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }



  Future<void> updateUserInfo({
    String? newUsername,
    String? newPassword,
    String? oldPassword,
    String? newBio,
    String? newSex,
    String? newAvatarUrl,
  }) async {
    final userId = userMap['id'];

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID không hợp lệ')));
      return;
    }

    final updatedData = <String, dynamic>{};

    if (newUsername != null) updatedData['username'] = newUsername;
    if (newBio != null) updatedData['bio'] = newBio;
    if (newSex != null) updatedData['sex'] = newSex;
    if (newAvatarUrl != null) updatedData['avatar_url'] = newAvatarUrl;

    if (newPassword != null &&
        oldPassword != null &&
        newPassword.isNotEmpty &&
        oldPassword.isNotEmpty) {
      updatedData['password'] = newPassword;
      updatedData['oldPassword'] = oldPassword;
    }

    if (updatedData.isEmpty) return;

    try {
      final resp = await UserAPI.updateUserInfo(
        int.parse(userId.toString()),
        updatedData,
      );

      final returnedUser = resp['user'] ?? resp;

      setState(() {
        userMap = {...userMap, ...returnedUser};
      });

      await _storage.write(key: 'user_info', value: jsonEncode(userMap));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
    } catch (e) {
      debugPrint('❌ Update user info error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi cập nhật thông tin')),
      );
    }
  }

  void _showPasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Đổi mật khẩu'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu cũ'),
                ),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  updateUserInfo(
                    newPassword: newPassCtrl.text,
                    oldPassword: oldPassCtrl.text,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  String? normalizeSex(String value) {
    if (value.isEmpty) return null;

    switch (value.toLowerCase()) {
      case 'nam':
      case 'male':
        return 'Nam';
      case 'nữ':
      case 'nu':
      case 'female':
        return 'Nữ';
      case 'khác':
      case 'other':
        return 'Khác';
      default:
        return null;
    }
  }

  void _showEditDialog(
    String title,
    String initialValue,
    Function(String) onSave, {
    bool issex = false,
  }) {
    final controller = TextEditingController(text: initialValue);
    String? selectedSex = normalizeSex(initialValue);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Đổi $title'),
            content:
                issex
                    ? StatefulBuilder(
                      builder:
                          (context, setState) =>
                              DropdownButtonFormField<String>(
                                value: selectedSex,
                                decoration: const InputDecoration(
                                  labelText: 'Chọn giới tính',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Nam',
                                    child: Text('Nam'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Nữ',
                                    child: Text('Nữ'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Khác',
                                    child: Text('Khác'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => selectedSex = value);
                                },
                              ),
                    )
                    : TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Nhập $title mới',
                        border: const OutlineInputBorder(),
                      ),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  if (issex) {
                    if (selectedSex != null) onSave(selectedSex!);
                  } else {
                    onSave(controller.text.trim());
                  }
                  Navigator.pop(context);
                },
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => avatarFile = File(picked.path));
      final userId = userMap['id'];

      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User ID không hợp lệ')));
        return;
      }

      try {
        // Upload qua server thay vì trực tiếp Supabase
        final result = await UserAPI.uploadAvatar(
          int.parse(userId.toString()),
          avatarFile!,
        );

        final avatarUrl = result['user']?['avatar_url'];
        debugPrint('🔍 avatarUrl from server: $avatarUrl');

        if (avatarUrl != null) {
          setState(() {
            userMap['avatar_url'] = avatarUrl;
          });
          await _storage.write(key: 'user_info', value: jsonEncode(userMap));
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cập nhật avatar thành công!')));
        }
      } catch (e) {
        debugPrint('❌ Upload avatar error: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload ảnh thất bại: $e')));
      }
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      avatarFile != null
                          ? FileImage(avatarFile!)
                          : (userMap['avatar_url'] != null &&
                                  userMap['avatar_url'].toString().isNotEmpty
                              ? NetworkImage(userMap['avatar_url'])
                              : const AssetImage(
                                    'assets/images/default_avatar.png',
                                  )
                                  as ImageProvider),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.edit, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoRow('Tên tài khoản', userMap['username'] ?? '', () {
            _showEditDialog(
              'tên tài khoản',
              userMap['username'] ?? '',
              (v) => updateUserInfo(newUsername: v),
            );
          }),
          const Divider(),
          _buildInfoRow('Mật khẩu', '********', _showPasswordDialog),
          const Divider(),
          _buildInfoRow('Bio', userMap['bio'] ?? '', () {
            _showEditDialog(
              'bio',
              userMap['bio'] ?? '',
              (v) => updateUserInfo(newBio: v),
            );
          }),
          const Divider(),
          _buildInfoRow('Giới tính', userMap['sex'] ?? '', () {
            _showEditDialog(
              'giới tính',
              userMap['sex'] ?? '',
              (v) => updateUserInfo(newSex: v),
              issex: true,
            );
          }),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, VoidCallback onEdit) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
      trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
    );
  }
}
