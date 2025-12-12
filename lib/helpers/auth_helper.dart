import 'dart:convert'; // Để encode/decode JSON User
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

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

  // --- 3. LẤY THÔNG TIN USER (TỪ STORAGE, KHÔNG PHẢI TỪ TOKEN) ---
  // Lấy tên hiển thị
  static Future<String?> getUsername() async {
    final userStr = await _storage.read(key: _kUserInfo);
    if (userStr == null) return null;

    final userMap = jsonDecode(userStr);
    return userMap['username']; // Backend đã giải mã sẵn rồi mới trả về
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

  // --- 5. LOGOUT ---
  static Future<void> logout() async {
    await _storage.deleteAll();
  }
}
