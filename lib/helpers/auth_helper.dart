import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../config/server.dart';
import '../services/http_client.dart';
import 'app_logger.dart';

class AuthHelper {
  // Nên dùng AndroidOptions để mã hóa trên Android (tránh lỗi trên một số máy)
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Key lưu trữ
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserInfo = 'user_info';

  // --- 1. LƯU DATA KHI LOGIN THÀNH CÔNG ---
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user, // Object user trả về từ API
  }) async {
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
    // Lưu user object dưới dạng chuỗi JSON để tiện lấy ra hiển thị (Tên, Avatar...)
    await _storage.write(key: _kUserInfo, value: jsonEncode(user));
  }

  // Chỉ lưu lại Access Token mới (khi Refresh thành công)
  static Future<void> updateAccessToken(String newAccessToken) async {
    await _storage.write(key: _kAccessToken, value: newAccessToken);
  }

  // --- 2. LẤY TOKEN ---
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _kAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _kRefreshToken);
  }

  static Future<bool> refreshSession() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      // Gọi API refresh token đã viết ở Backend
      final response = await AppHttpClient.post(
        Uri.parse(
          '$baseUrl/api/auth/user/refresh-token',
        ), // Đường dẫn route auth của bạn
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['accessToken'];

        // Cập nhật Access Token mới vào Storage
        await updateAccessToken(newAccessToken);
        return true;
      } else {
        // Nếu Refresh Token cũng hết hạn (403), bắt buộc logout
        await logout();
        return false;
      }
    } catch (e) {
      AppLogger.error('Error refreshing session', e);
      return false;
    }
  }

  // --- 3. LẤY THÔNG TIN USER (TỪ STORAGE, KHÔNG PHẢI TỪ TOKEN) ---
  // Lấy tên hiển thị
  static Future<String?> getUsername() async {
    final userStr = await _storage.read(key: _kUserInfo);
    if (userStr == null) return null;

    final userMap = jsonDecode(userStr);
    // Thử lấy 'username' trước, nếu không có thì lấy 'username_acc'
    return userMap['username'] ?? userMap['username_acc'];
  }

  // Lấy User ID (Ưu tiên lấy từ Storage cho nhanh, không cần decode)
  static Future<int?> getUserId() async {
    final userStr = await _storage.read(key: _kUserInfo);
    if (userStr != null) {
      final userMap = jsonDecode(userStr);
      return userMap['id'];
    }
    // Backup: Nếu mất user info thì mới decode token
    return getUserIdFromToken();
  }

  // --- 4. GIẢI MÃ TOKEN (Dùng để check hạn sử dụng) ---
  static Future<bool> isAccessTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;
    return Jwt.isExpired(token);
  }

  // Hàm cũ của bạn (Giữ lại để backup nếu cần)
  static Future<int?> getUserIdFromToken() async {
    final token = await getAccessToken();
    if (token == null) return null;

    final payload = Jwt.parseJwt(token);
    return payload['id'] is int
        ? payload['id'] as int
        : int.tryParse(payload['id'].toString());
  }

  static Future<String?> getRawUserInfo() async {
    return await _storage.read(key: _kUserInfo);
  }

  // Lấy user object đầy đủ
  static Future<Map<String, dynamic>?> getUser() async {
    final userStr = await _storage.read(key: _kUserInfo);
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  static Future<void> saveUserInfo(Map<String, dynamic> user) async {
    await _storage.write(key: _kUserInfo, value: jsonEncode(user));
  }

  // --- 5. LOGOUT ---
  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
