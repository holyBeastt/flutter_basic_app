import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';

class AuthApi {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // ⚠️ Lưu ý: Đây phải là WEB CLIENT ID lấy từ Google Cloud Console
    // chứ không phải Client ID của Android hay iOS.
    serverClientId:
        '1002429183208-3r4dlqhen80lhiketnlq0neh59rp8b25.apps.googleusercontent.com',
  );

  final _storage = const FlutterSecureStorage();

  // Hàm đăng nhập Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // ✅ 1. SỬA QUAN TRỌNG: Đăng xuất phiên cũ trước để luôn hiện bảng chọn tài khoản
      await _googleSignIn.signOut();

      // 2. Trigger popup đăng nhập
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Đã hủy đăng nhập Google'};
      }

      // 3. Lấy thông tin authentication
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ✅ 4. KIỂM TRA idToken (Thêm đoạn này để tránh lỗi gửi null lên server)
      if (googleAuth.idToken == null) {
        return {
          'success': false,
          'message': 'Lỗi: Không lấy được ID Token từ Google',
        };
      }

      // 5. Gửi idToken sang Express Backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/user/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleAuth.idToken,
          'email': googleUser.email,
          'displayName': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        }),
      );

      // Xử lý response từ server (đoạn này giữ nguyên logic cũ của bạn)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        await _storage.write(key: 'jwt_token', value: data['token']);
        await _storage.write(key: 'user', value: jsonEncode(data['user']));

        return {'success': true, 'data': data};
      } else {
        final data = jsonDecode(
          response.body,
        ); // Decode cẩn thận phòng khi body rỗng
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi xác thực Server',
        };
      }
    } catch (e) {
      // In lỗi ra console để debug nếu cần
      print("Google Login Error: $e");
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // Hàm đăng xuất
  Future<void> logoutGoogle() async {
    await _googleSignIn.signOut();
    await _storage.deleteAll();
  }
}
