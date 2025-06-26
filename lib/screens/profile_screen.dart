import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/server.dart';

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
    getUserInfo();
  }

  // Hàm upload avatar lên Supabase Storage
 Future<String?> uploadAvatarToSupabase(File file, String userId) async {
    final supabase = Supabase.instance.client;
    final fileExt = file.path.split('.').last;
    final fileName =
        'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'avatar/$fileName';

    try {
      final fileBytes = await file.readAsBytes();

      final response = await supabase.storage
          .from('images')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      if (response.isEmpty) {
        print('❌ Upload thất bại: Không có phản hồi');
        return null;
      }

      final publicUrl = supabase.storage.from('images').getPublicUrl(filePath);

      print('✅ Upload thành công. Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Lỗi khi upload: $e');
      return null;
    }
  }


  Future<void> getUserInfo() async {
    final token = await _storage.read(key: 'jwt_token');
    final userStr = await _storage.read(key: 'user');
    String? userId;

    if (userStr != null) {
      userMap = jsonDecode(userStr); // Gán cho biến toàn cục
      userId = userMap['id'].toString();
      await _storage.write(key: 'userId', value: userId);
    }

    print('🔍 userStr = $userStr');
    print('🔍 userId = $userId');

    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/get-user-info'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('📥 Calling API: $baseUrl/api/users/$userId/get-user-info');
      print('📥 Response body: ${response.body}');
print('📥 Response code======: $response');
      if (response.statusCode == 200) {
       final user = jsonDecode(response.body);

        print('✅ API trả về user====: $user');
        print(
          '🧠 Avatar URL khi load lại=========: ${user['avatar_url'] ?? user['avatar']}',
        );
      setState(() {
          userMap = {
            'id': user['id'],
            'username': user['username'] ?? user['username_acc'],
            'password': user['password'],
            'bio': user['bio'],
            'sex': user['sex'],
            'avatar_url': user['avatar_url'],

          };
          isLoading = false;
        });
      

        await _storage.write(key: 'user', value: jsonEncode(userMap));
      } else {
        print('Lỗi response ${response.statusCode}: ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Lỗi lấy user info: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateUserInfo({
    String? newUsername,
    String? newPassword,
    String? oldPassword,
    String? newBio,
    String? newsex,
    String? newAvatarUrl,
  }) async {
    final userId = userMap['id']?.toString();

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User ID không hợp lệ')));
      return;
    }

final updatedData = <String, dynamic>{
      "username": newUsername ?? userMap['username'],
      "bio": newBio ?? userMap['bio'],
      "sex": newsex ?? userMap['sex'],
      "avatar_url": newAvatarUrl ?? userMap['avatar_url'],
    };

    if (newPassword != null &&
        newPassword.isNotEmpty &&
        oldPassword != null &&
        oldPassword.isNotEmpty) {
      updatedData["password"] = newPassword;
      updatedData["oldPassword"] = oldPassword;
    }


    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/update/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        final updatedMap = {...userMap, ...updatedData};
        setState(() => userMap = updatedMap);
        await _storage.write(key: 'user', value: jsonEncode(updatedMap));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cập nhật thất bại!')));
      }
    } catch (e) {
      print('Error updating user info: $e');
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
  void _showEditDialog(
    String title,
    String initialValue,
    Function(String) onSave, {
    bool issex = false,
  }) {
    final controller = TextEditingController(text: initialValue);
    String selectedsex = initialValue;

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
                                value:
                                    selectedsex.isNotEmpty
                                        ? selectedsex
                                        : null,
                                decoration: const InputDecoration(
                                  labelText: 'Chọn giới tính',
                                ),
                                items:
                                    ['Nam', 'Nữ', 'Khác']
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null)
                                    setState(() => selectedsex = value);
                                },
                              ),
                    )
                    : TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: 'Nhập $title mới'),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () {
                  if (issex) {
                    onSave(selectedsex);
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
      final userId = userMap['id']?.toString() ?? '';

      if (userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User ID không hợp lệ')));
        return;
      }

      final avatarUrl = await uploadAvatarToSupabase(avatarFile!, userId);
      print('🔍 avatarUrl =================$avatarUrl');
      if (avatarUrl != null) {
        await updateUserInfo(newAvatarUrl: avatarUrl);
        setState(() {
          userMap['avatar_url'] = avatarUrl;
        });
        print('Avatar URL show: ${userMap['avatar_url']}');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload ảnh thất bại!')));
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
              (v) => updateUserInfo(newsex: v),
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
