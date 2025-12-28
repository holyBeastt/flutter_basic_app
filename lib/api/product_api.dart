import 'dart:convert';
import '../services/http_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProductApi {
  static final _storage = const FlutterSecureStorage();
  static Future<String> fetchUserName() async {
    final response = await AppHttpClient.get(Uri.parse('https://your-api-url.com/user'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final token = data['token'];

      // ✅ Lưu token sau khi đăng nhập
      await _storage.write(key: 'jwt_token', value: token);

      return data['name'] ?? "Ẩn danh";
    } else {
      throw Exception('Lỗi tải dữ liệu');
    }
  }
}
