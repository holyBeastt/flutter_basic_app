import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/server.dart';
import '../helpers/app_logger.dart'; // Đảm bảo baseUrl đúng: http://10.0.2.2:3000 (Android) hoặc localhost (iOS)

class AuthApi {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // Thay bằng Web Client ID của bạn
    serverClientId:
        '1002429183208-3r4dlqhen80lhiketnlq0neh59rp8b25.apps.googleusercontent.com',
  );

  // --- 1. LOGIN VỚI GOOGLE ---
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // Logout phiên cũ
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Đã hủy đăng nhập Google'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        return {'success': false, 'message': 'Lỗi: Không lấy được ID Token'};
      }

      // Gọi Server
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

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ SỬA: Không lưu storage ở đây nữa.
        // Chỉ trả data về để UI dùng AuthHelper lưu.
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Lỗi xác thực Server',
        };
      }
    } catch (e) {
      AppLogger.error('Google Login Error', e);
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- 2. LOGIN THƯỜNG ---
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      return {'success': false, 'message': 'Vui lòng nhập đầy đủ thông tin!'};
    }

    final url = Uri.parse('$baseUrl/api/auth/user/login');

    // Biến này là Request Body gửi đi
    final requestBody = jsonEncode({
      'username': username.trim(),
      'password': password.trim(),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      // Biến này là Response Data nhận về (chứa Token)
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Đăng nhập thành công!',
          'data':
              responseData, // ✅ SỬA QUAN TRỌNG: Trả về responseData, KHÔNG PHẢI requestBody
        };
      } 
      // ========== [NEW] XỬ LÝ TÀI KHOẢN BỊ KHÓA ==========
      else if (response.statusCode == 423) {
        final remainingTime = responseData['remainingTime'] ?? 60;
        return {
          'success': false,
          'locked': true, // Đánh dấu là bị khóa
          'message': responseData['error'] ?? 'Tài khoản đã bị khóa',
          'remainingTime': remainingTime,
          'locked_until': responseData['locked_until'],
        };
      } 
      // ========== XỬ LÝ SAI MẬT KHẨU (CÒN LẦN THỬ) ==========
      else if (response.statusCode == 401) {
        final attemptsRemaining = responseData['attempts_remaining'];
        String message = responseData['error'] ?? 'Đăng nhập thất bại!';
        
        // Nếu có thông tin số lần còn lại
        if (attemptsRemaining != null) {
          message = 'Sai mật khẩu. Còn $attemptsRemaining lần thử.';
        }
        
        return {
          'success': false,
          'message': message,
          'attempts_remaining': attemptsRemaining,
        };
      } 
      else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              responseData['error'] ??
              'Đăng nhập thất bại!',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi mạng: $e'};
    }
  }

  // --- 3. ĐĂNG KÝ TÀI KHOẢN MỚI ---
  Future<Map<String, dynamic>> register({
    required String usernameAcc,
    required String password,
    required String confirmPassword,
    required String username,
    required String email,
    required String sex,

  }) async {
    // Validation cơ bản
    if (usernameAcc.trim().isEmpty ||
        password.trim().isEmpty ||
        confirmPassword.trim().isEmpty ||
        username.trim().isEmpty ||
        email.trim().isEmpty) {
      return {'success': false, 'message': 'Vui lòng nhập đầy đủ thông tin!'};
    }

    // Kiểm tra mật khẩu khớp
    if (password != confirmPassword) {
      return {'success': false, 'message': 'Mật khẩu xác nhận không khớp!'};
    }

    // Kiểm tra độ dài mật khẩu
    if (password.length < 6) {
      return {'success': false, 'message': 'Mật khẩu phải có ít nhất 6 ký tự!'};
    }

    // Kiểm tra email hợp lệ
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return {'success': false, 'message': 'Email không hợp lệ!'};
    }

    final url = Uri.parse('$baseUrl/api/auth/user/signup');

    final requestBody = jsonEncode({
      'username_acc': usernameAcc.trim(),
      'password': password.trim(),
      'confirmPassword': confirmPassword.trim(),
      'username': username.trim(),
      'email': email.trim(),
      'sex': sex,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Đăng ký thành công!',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ??
              responseData['message'] ??
              'Đăng ký thất bại!',
        };
      }
    } catch (e) {
      AppLogger.error('Register Error', e);
      return {'success': false, 'message': 'Lỗi mạng: $e'};
    }
  }

  // Logout Google (Giữ nguyên)
  Future<void> logoutGoogle() async {
    await _googleSignIn.signOut();
  }
}
