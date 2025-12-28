import 'dart:convert';

import 'package:android_basic/constants.dart';
import 'package:android_basic/screens/home_screen.dart';
import 'package:android_basic/screens/signup_screen.dart';
import 'package:android_basic/widgets/custom_button.dart';
import 'package:android_basic/widgets/custom_widgets.dart';
import 'package:android_basic/widgets/simple_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/server.dart';
import '../api/auth_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  static final _storage = const FlutterSecureStorage();
  bool isLoading = false;
  final AuthApi _authApi = AuthApi();
  
  // Biometric states
  bool _canUseBiometric = false;        // Có thể dùng ngay (đã bật + có token)
  bool _deviceSupportsBiometric = false; // Thiết bị có hỗ trợ
  bool _hasBiometricEnrolled = false;    // Đã đăng ký vân tay trên thiết bị
  bool _biometricEnabled = false;        // Đã bật trong app
  String _biometricTypeName = 'Vân tay';
  String? _lastUsername;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  // Kiểm tra xem có thể sử dụng biometric login không
  Future<void> _checkBiometricAvailability() async {
    final isSupported = await BiometricService.isDeviceSupported();
    final canCheck = await BiometricService.canCheckBiometrics();
    final isEnabled = await BiometricService.isBiometricEnabled();
    final canUse = await BiometricService.canUseBiometricLogin();
    final typeName = await BiometricService.getBiometricTypeName();
    final lastUsername = await BiometricService.getLastUsername();
    
    // Debug log
    print('🔐 Biometric Check:');
    print('   - Device supports: $isSupported');
    print('   - Has enrolled: $canCheck');
    print('   - App enabled: $isEnabled');
    print('   - Can use now: $canUse');
    print('   - Type: $typeName');
    
    if (mounted) {
      setState(() {
        _deviceSupportsBiometric = isSupported;
        _hasBiometricEnrolled = canCheck;
        _biometricEnabled = isEnabled;
        _canUseBiometric = canUse;
        _biometricTypeName = typeName;
        _lastUsername = lastUsername;
      });
    }
    
    // Tự động hiển thị popup vân tay nếu có thể dùng ngay
    if (canUse) {
      _handleBiometricLogin();
    }
  }

  // 3. XỬ LÝ ĐĂNG NHẬP VÂN TAY
  // Dùng token của TÀI KHOẢN ĐÃ BẬT BIOMETRIC (không phải tài khoản gần nhất)
  void _handleBiometricLogin() async {
    setState(() => isLoading = true);
    
    try {
      // Lấy thông tin tài khoản đã bật biometric
      final biometricAccount = await BiometricService.getBiometricAccount();
      
      if (biometricAccount == null) {
        setState(() => isLoading = false);
        if (mounted) {
          SimpleToast.showError(context, 'Chưa có tài khoản nào bật $_biometricTypeName');
        }
        setState(() => _canUseBiometric = false);
        return;
      }
      
      final username = biometricAccount['username'];
      
      // Gọi xác thực biometric
      final authenticated = await BiometricService.authenticate(
        reason: 'Đăng nhập vào tài khoản "$username"',
      );
      
      if (!authenticated) {
        setState(() => isLoading = false);
        if (mounted) {
          SimpleToast.showError(context, 'Xác thực $_biometricTypeName thất bại');
        }
        return;
      }
      
      // Lấy token từ tài khoản đã bật biometric
      final accessToken = biometricAccount['accessToken'] as String?;
      final refreshToken = biometricAccount['refreshToken'] as String?;
      final userId = biometricAccount['userId'];
      
      if (accessToken == null || accessToken.isEmpty) {
        setState(() => isLoading = false);
        if (mounted) {
          SimpleToast.showError(context, 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
        }
        await BiometricService.disableBiometric();
        setState(() => _canUseBiometric = false);
        return;
      }
      
      // Lưu token vào AuthHelper để app sử dụng
      await AuthHelper.saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
        user: {'id': userId, 'username': username},
      );
      
      // Kiểm tra token có hết hạn không
      final isExpired = await AuthHelper.isAccessTokenExpired();
      
      if (isExpired) {
        // Thử refresh token
        final refreshSuccess = await AuthHelper.refreshSession();
        
        if (!refreshSuccess) {
          setState(() => isLoading = false);
          if (mounted) {
            SimpleToast.showError(context, 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại bằng mật khẩu.');
          }
          await BiometricService.disableBiometric();
          await AuthHelper.logout();
          setState(() => _canUseBiometric = false);
          return;
        }
        
        // Cập nhật token mới vào biometric storage
        final newToken = await AuthHelper.getAccessToken();
        if (newToken != null) {
          await BiometricService.updateBiometricTokens(accessToken: newToken);
        }
      }
      
      setState(() => isLoading = false);
      
      if (mounted) {
        SimpleToast.showSuccess(context, 'Đăng nhập thành công với $username!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      }
      
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        SimpleToast.showError(context, 'Lỗi xác thực: $e');
      }
    }
  }

  // 1. XỬ LÝ ĐĂNG NHẬP THƯỜNG
  void handleLogin() async {
    final username = usernameController.text;
    final password = passwordController.text;

    setState(() => isLoading = true);

    final result = await AuthApi().login(username, password);

    setState(() => isLoading = false);

    if (result['success'] == true) {
      // ========== ĐĂNG NHẬP THÀNH CÔNG ==========
      final data = result['data'];
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final user = data['user'];

      // Lưu vào Secure Storage thông qua AuthHelper
      await AuthHelper.saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
      );

      if (!mounted) return;
      
      // Hỏi user có muốn bật biometric login không
      await _askEnableBiometric(
        username: username,
        userId: user['id'],
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      SimpleToast.showSuccess(context, 'Đăng nhập thành công!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    } 
    // ========== TÀI KHOẢN BỊ KHÓA ==========
    else if (result['locked'] == true) {
      if (!mounted) return;
      
      final remainingSeconds = result['remainingTime'] ?? 60;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_clock, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Flexible(child: Text('Tài khoản bị khóa')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tài khoản "${username}" đã bị khóa do nhập sai mật khẩu quá nhiều lần.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.timer, size: 40, color: Colors.red),
                    SizedBox(height: 8),
                    Text(
                      'Thời gian còn lại:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$remainingSeconds giây',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đã hiểu', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    } 
    // ========== SAI MẬT KHẨU ==========
    else {
      if (!mounted) return;
      
      String errorMessage = result['message'] ?? 'Đăng nhập thất bại!';
      
      if (result['attempts_remaining'] != null) {
        final attemptsLeft = result['attempts_remaining'];
        errorMessage = 'Sai mật khẩu! Còn $attemptsLeft lần thử.';
      }
      
      SimpleToast.showError(context, errorMessage);
    }
  }
  
  // Hỏi user có muốn bật biometric login không
  Future<void> _askEnableBiometric({
    required String username,
    required int userId,
    required String accessToken,
    required String refreshToken,
  }) async {
    // Kiểm tra thiết bị có hỗ trợ không
    final isSupported = await BiometricService.isDeviceSupported();
    final canCheck = await BiometricService.canCheckBiometrics();
    
    if (!isSupported || !canCheck) return;
    
    final existingAccount = await BiometricService.getBiometricAccount();
    final biometricType = await BiometricService.getBiometricTypeName();
    
    if (!mounted) return;
    
    // Nếu cùng tài khoản đã bật → chỉ cập nhật token, không hỏi lại
    if (existingAccount != null && existingAccount['userId'] == userId) {
      await BiometricService.updateBiometricTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return;
    }
    
    // Hỏi với tài khoản chưa bật biometric
    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: primary, size: 32),
            SizedBox(width: 12),
            Flexible(child: Text('Bật $biometricType')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tài khoản:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      username,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Lần đăng nhập sau, bạn chỉ cần dùng $biometricType để vào tài khoản này.',
              style: TextStyle(fontSize: 15),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Để sau', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primary),
            child: Text('Bật ngay', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    // Nếu chấp nhận → Lưu tài khoản mới (thay thế cũ nếu có)
    if (shouldEnable == true) {
      await BiometricService.enableBiometricForAccount(
        username: username,
        userId: userId,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      if (mounted) {
        SimpleToast.showSuccess(context, 'Đã bật $biometricType cho tài khoản $username!');
      }
    }
  }
  
  // Dialog hướng dẫn người dùng cài đặt vân tay trên thiết bị
  void _showSetupBiometricDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: primary, size: 32),
            SizedBox(width: 12),
            Flexible(child: Text('Thiết lập $_biometricTypeName')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thiết bị của bạn chưa đăng ký $_biometricTypeName.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Hướng dẫn:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text('1. Mở Cài đặt (Settings)'),
            Text('2. Tìm "Bảo mật" hoặc "Sinh trắc học"'),
            Text('3. Thêm vân tay của bạn'),
            Text('4. Quay lại app và đăng nhập'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  // 2. XỬ LÝ ĐĂNG NHẬP GOOGLE
  void handleGoogleLogin() async {
    setState(() => isLoading = true);

    final result = await _authApi.loginWithGoogle();

    setState(() => isLoading = false);

    if (result['success'] == true) {
      final data = result['data'];
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];
      final user = data['user'];

      await AuthHelper.saveAuthData(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
      );

      if (!mounted) return;
      
      // Hỏi bật biometric
      await _askEnableBiometric(
        username: user['username'] ?? user['email'] ?? 'Google User',
        userId: user['id'],
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      SimpleToast.showSuccess(context, 'Đăng nhập Google thành công!');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      if (!mounted) return;
      SimpleToast.showError(context, result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -330,
            right: -330,
            child: Container(
              height: 600,
              width: 600,
              decoration: BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -((1 / 4) * 500),
            right: -((1 / 4) * 500),
            child: Container(
              height: 450,
              width: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: lightBlue, width: 2),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    SizedBox(height: 100),
                    Text("Login here", style: h2),
                    SizedBox(height: 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 50),
                      child: Text(
                        "Welcome back",
                        style: h2.copyWith(fontSize: 18, color: black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 80),

                    // Gắn controller vào CustomTextfield
                    CustomTextfield(
                      hint: "Username",
                      controller: usernameController,
                    ),
                    SizedBox(height: 20),
                    CustomTextfield(
                      hint: "Password",
                      controller: passwordController,
                      obscureText: true,
                    ),

                    SizedBox(height: 25),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Forgot your password",
                        style: body.copyWith(
                          fontSize: 16,
                          color: primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    CustomButton(
                      text: isLoading ? "Đang đăng nhập..." : "Sign in",
                      isLarge: true,
                      onPressed: isLoading ? null : handleLogin,
                    ),
                    
                    // ========== NÚT ĐĂNG NHẬP VÂN TAY ==========
                    // Trường hợp 1: Có thể dùng ngay (đã bật + có token + có vân tay)
                    if (_canUseBiometric) ...[
                      SizedBox(height: 20),
                      InkWell(
                        onTap: isLoading ? null : _handleBiometricLogin,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 55,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: primary),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fingerprint, color: primary, size: 28),
                              SizedBox(width: 10),
                              Text(
                                "Đăng nhập bằng $_biometricTypeName",
                                style: body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                    // Trường hợp 2: Thiết bị hỗ trợ nhưng chưa đăng ký vân tay
                    else if (_deviceSupportsBiometric && !_hasBiometricEnrolled) ...[
                      SizedBox(height: 20),
                      InkWell(
                        onTap: () => _showSetupBiometricDialog(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 55,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fingerprint, color: Colors.grey, size: 28),
                              SizedBox(width: 10),
                              Text(
                                "Thiết lập $_biometricTypeName",
                                style: body.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                    // Trường hợp 3: Đã đăng ký vân tay nhưng chưa bật trong app
                    else if (_deviceSupportsBiometric && _hasBiometricEnrolled && !_biometricEnabled) ...[
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Đăng nhập để bật $_biometricTypeName",
                                style: body.copyWith(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 30),

                    // Dòng kẻ phân cách "Or continue with"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[400], thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            "Or continue with",
                            style: body.copyWith(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[400], thickness: 1),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Nút Google Login
                    InkWell(
                      onTap: handleGoogleLogin,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 55,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                              ),
                              child: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                height: 24,
                                width: 24,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.g_mobiledata,
                                  size: 30,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Sign in with Google",
                              style: body.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Create new account",
                        style: body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
