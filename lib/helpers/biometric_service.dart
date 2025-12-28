import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service xử lý xác thực sinh trắc học (vân tay, Face ID)
/// Vân tay được gắn với TÀI KHOẢN CỤ THỂ đã bật
class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  // Key lưu tài khoản đã bật biometric
  static const String _biometricAccountKey = 'biometric_account';
  // Lưu: { username, userId, accessToken, refreshToken }

  /// Kiểm tra thiết bị có hỗ trợ biometric không
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  /// Kiểm tra có biometric nào được đăng ký chưa
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  /// Lấy danh sách các loại biometric có sẵn
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Kiểm tra đã có tài khoản nào bật biometric chưa
  static Future<bool> isBiometricEnabled() async {
    try {
      final account = await _storage.read(key: _biometricAccountKey);
      return account != null && account.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Lấy thông tin tài khoản đã bật biometric
  static Future<Map<String, dynamic>?> getBiometricAccount() async {
    try {
      final accountStr = await _storage.read(key: _biometricAccountKey);
      if (accountStr == null || accountStr.isEmpty) return null;
      return jsonDecode(accountStr);
    } catch (e) {
      print('Error reading biometric account: $e');
      return null;
    }
  }

  /// Bật biometric cho tài khoản cụ thể
  static Future<void> enableBiometricForAccount({
    required String username,
    required int userId,
    required String accessToken,
    required String refreshToken,
  }) async {
    final accountData = {
      'username': username,
      'userId': userId,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
    await _storage.write(key: _biometricAccountKey, value: jsonEncode(accountData));
    print('🔐 Biometric enabled for: $username');
  }

  /// Cập nhật token cho tài khoản đã bật biometric
  static Future<void> updateBiometricTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    final account = await getBiometricAccount();
    if (account == null) return;
    
    account['accessToken'] = accessToken;
    if (refreshToken != null) {
      account['refreshToken'] = refreshToken;
    }
    
    await _storage.write(key: _biometricAccountKey, value: jsonEncode(account));
    print('🔐 Biometric tokens updated');
  }

  /// Tắt biometric
  static Future<void> disableBiometric() async {
    await _storage.delete(key: _biometricAccountKey);
    print('🔐 Biometric disabled');
  }

  /// Lấy username đã bật biometric
  static Future<String?> getLastUsername() async {
    final account = await getBiometricAccount();
    return account?['username'];
  }

  /// Thực hiện xác thực biometric
  static Future<bool> authenticate({
    String reason = 'Xác thực để đăng nhập',
  }) async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      final canCheck = await canCheckBiometrics();
      if (!canCheck) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric auth error: ${e.message}');
      return false;
    } catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }

  /// Kiểm tra có thể dùng biometric login không
  static Future<bool> canUseBiometricLogin() async {
    final isSupported = await isDeviceSupported();
    if (!isSupported) return false;

    final canCheck = await canCheckBiometrics();
    if (!canCheck) return false;

    // Kiểm tra đã có tài khoản bật biometric chưa
    final account = await getBiometricAccount();
    if (account == null) return false;

    // Kiểm tra có token
    final token = account['accessToken'];
    if (token == null || token.isEmpty) return false;

    return true;
  }

  /// Lấy tên loại biometric
  static Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'vân tay';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'mống mắt';
    } else if (biometrics.contains(BiometricType.strong)) {
      return 'vân tay';
    }
    
    return 'vân tay';
  }

  /// Kiểm tra tài khoản hiện tại có phải là tài khoản đã bật biometric không
  static Future<bool> isAccountRegistered(int userId) async {
    final account = await getBiometricAccount();
    if (account == null) return false;
    return account['userId'] == userId;
  }
}
