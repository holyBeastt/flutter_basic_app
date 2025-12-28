import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/server.dart';
import '../helpers/auth_helper.dart';

class UserAPI {
  static final _storage = const FlutterSecureStorage();

  /// Upload avatar qua server (multipart/form-data)
  static Future<Map<String, dynamic>> uploadAvatar(
    int userId,
    File imageFile,
  ) async {
    final token = await AuthHelper.getAccessToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    final uri = Uri.parse('$baseUrl/api/users/update');

    // Lấy extension và xác định MIME type
    final fileExt = imageFile.path.split('.').last.toLowerCase();
    String mimeType = 'jpeg'; // default
    if (fileExt == 'png') {
      mimeType = 'png';
    } else if (fileExt == 'gif') {
      mimeType = 'gif';
    } else if (fileExt == 'webp') {
      mimeType = 'webp';
    }

    final request =
        http.MultipartRequest('PUT', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            await http.MultipartFile.fromPath(
              'avatar_url',
              imageFile.path,
              contentType: MediaType('image', mimeType),
            ),
          );

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200) {
      return jsonDecode(responseBody);
    }

    if (streamedResponse.statusCode == 401 ||
        streamedResponse.statusCode == 403) {
      throw Exception('Phiên đăng nhập hết hạn');
    }

    throw Exception(
      'Lỗi upload avatar: ${streamedResponse.statusCode} - $responseBody',
    );
  }

  /// Lấy access token
  static Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  /// Lấy user info từ server (đã decrypt ở backend)
  static Future<Map<String, dynamic>> getUserInfo() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    // Lấy user đã lưu sau login
    final userStr = await _storage.read(key: 'user');
    if (userStr == null) {
      throw Exception('Không tìm thấy user trong storage');
    }

    final localUser = jsonDecode(userStr);
    final int? userId = localUser['id'];

    if (userId == null) {
      throw Exception('User id không hợp lệ');
    }

    final uri = Uri.parse('$baseUrl/api/users/$userId/get-user-info');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Chuẩn hóa data trả về (KHÔNG có password)
      final user = <String, dynamic>{
        'id': data['id'],
        'username': data['username'],
        'bio': data['bio'],
        'sex': data['sex'],
        'avatar_url': data['avatar_url'],
      };

      // Lưu lại user mới nhất
      await _storage.write(key: 'user', value: jsonEncode(user));

      debugPrint('User info loaded: $user');
      return user;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Phiên đăng nhập hết hạn');
    }

    throw Exception(
      'Lỗi tải user info: ${response.statusCode} - ${response.body}',
    );
  }

  /// Update user info
  static Future<Map<String, dynamic>> updateUserInfo(
    int id,
    Map<String, dynamic> data,
  ) async {
    final token = await AuthHelper.getAccessToken();
    if (token == null) {
      throw Exception('Chưa đăng nhập');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/api/users/update'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Phiên đăng nhập hết hạn');
    }

    throw Exception(
      'Lỗi cập nhật user: ${response.statusCode} - ${response.body}',
    );
  }
}
