import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/server.dart';

class UserAPI {
  // Kho lưu trữ an toàn cho token (mobile)
  static final _storage = const FlutterSecureStorage();

  /// Đọc token đã lưu sau khi login
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token'); // key bạn đặt khi lưu
  }
  /// Lấy tên user bằng JWT
  static Future<Map<String, dynamic>> getUserInfo() async {
    final token = await _getToken();
    final userJson = await _storage.read(key: 'user');
    int? id;
    if (userJson != null) {
      final user = jsonDecode(userJson);
      id = user['id'];
      print('User id: $id');
      // sử dụng id ở đây
    }
    if (token == null) throw Exception('Chưa đăng nhập');
    if (id == null) throw Exception('Không tìm thấy thông tin user');

    final response = await http.get(
      Uri.parse('$baseUrl/api/users/$id/get-user-info'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("Thông tin người dùng: $data");
      return data;
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại');
    } else {
      throw Exception('Lỗi tải dữ liệu: ${response.statusCode}');
    }
  }

  static Future<void> saveProfileToServer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('https://your-backend.com/update_profile'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      debugPrint("Cập nhật thành công");
    } else {
      debugPrint("Lỗi cập nhật: ${response.statusCode}");
    }
  }
}
