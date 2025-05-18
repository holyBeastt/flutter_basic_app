import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class AuthHelper {
  static final _storage = const FlutterSecureStorage();

  static Future<String?> getUsernameFromToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    Map<String, dynamic> payload = Jwt.parseJwt(token);
    return payload['username'];
  }

  static Future<String?> getUserIdFromToken() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return null;

    Map<String, dynamic> payload = Jwt.parseJwt(token);
    return payload['id']?.toString();
  }
}
