import 'package:android_basic/constants.dart';
import 'package:android_basic/widgets/custom_button.dart';
import 'package:android_basic/widgets/custom_widgets.dart';
import 'package:android_basic/widgets/simple_toast.dart';
import 'package:flutter/material.dart';
import '../api/auth_api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final AuthApi _authApi = AuthApi();
  bool isLoading = false;
  
  // Các bước: 1 = nhập email, 2 = nhập mã, 3 = nhập mật khẩu mới
  int _currentStep = 1;
  String _email = '';
  String _code = '';

  // Bước 1: Gửi mã về email
  void _handleSendCode() async {
    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      SimpleToast.showError(context, 'Vui lòng nhập email!');
      return;
    }
    
    setState(() => isLoading = true);
    
    final result = await _authApi.forgotPassword(email);
    
    setState(() => isLoading = false);
    
    if (result['success'] == true) {
      setState(() {
        _email = email;
        _currentStep = 2;
      });
      if (mounted) {
        SimpleToast.showSuccess(context, 'Mã xác thực đã được gửi về email!');
      }
    } else {
      if (mounted) {
        SimpleToast.showError(context, result['message'] ?? 'Không thể gửi mã.');
      }
    }
  }

  // Bước 2: Xác thực mã
  void _handleVerifyCode() async {
    final code = codeController.text.trim();
    
    if (code.isEmpty) {
      SimpleToast.showError(context, 'Vui lòng nhập mã xác thực!');
      return;
    }
    
    setState(() => isLoading = true);
    
    final result = await _authApi.verifyResetCode(_email, code);
    
    setState(() => isLoading = false);
    
    if (result['success'] == true) {
      setState(() {
        _code = code;
        _currentStep = 3;
      });
      if (mounted) {
        SimpleToast.showSuccess(context, 'Mã xác thực đúng!');
      }
    } else if (result['codeExpired'] == true) {
      if (mounted) {
        SimpleToast.showError(context, 'Mã đã hết hạn. Vui lòng gửi lại.');
      }
    } else {
      if (mounted) {
        SimpleToast.showError(context, result['message'] ?? 'Mã xác thực không đúng.');
      }
    }
  }

  // Bước 3: Đặt mật khẩu mới
  void _handleResetPassword() async {
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      SimpleToast.showError(context, 'Vui lòng nhập đầy đủ thông tin!');
      return;
    }
    
    if (newPassword != confirmPassword) {
      SimpleToast.showError(context, 'Mật khẩu xác nhận không khớp!');
      return;
    }
    
    if (newPassword.length < 6) {
      SimpleToast.showError(context, 'Mật khẩu phải có ít nhất 6 ký tự!');
      return;
    }
    
    setState(() => isLoading = true);
    
    final result = await _authApi.resetPassword(_email, _code, newPassword);
    
    setState(() => isLoading = false);
    
    if (result['success'] == true) {
      if (mounted) {
        SimpleToast.showSuccess(context, 'Đặt mật khẩu mới thành công!');
        Navigator.pop(context); // Quay lại màn hình login
      }
    } else {
      if (mounted) {
        SimpleToast.showError(context, result['message'] ?? 'Không thể đặt mật khẩu mới.');
      }
    }
  }

  // Gửi lại mã
  void _handleResendCode() async {
    setState(() => isLoading = true);
    
    final result = await _authApi.forgotPassword(_email);
    
    setState(() => isLoading = false);
    
    if (result['success'] == true) {
      if (mounted) {
        SimpleToast.showSuccess(context, 'Mã mới đã được gửi!');
      }
    } else {
      if (mounted) {
        SimpleToast.showError(context, result['message'] ?? 'Không thể gửi lại mã.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quên mật khẩu'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Row(
              children: [
                _buildStepIndicator(1, 'Email'),
                Expanded(child: Divider(color: _currentStep >= 2 ? primary : Colors.grey)),
                _buildStepIndicator(2, 'Mã OTP'),
                Expanded(child: Divider(color: _currentStep >= 3 ? primary : Colors.grey)),
                _buildStepIndicator(3, 'Mật khẩu'),
              ],
            ),
            SizedBox(height: 40),
            
            // ========== BƯỚC 1: NHẬP EMAIL ==========
            if (_currentStep == 1) ...[
              Text(
                'Nhập email của bạn',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Chúng tôi sẽ gửi mã xác thực về email của bạn.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              CustomTextfield(
                hint: 'Email',
                controller: emailController,
              ),
              SizedBox(height: 30),
              CustomButton(
                text: isLoading ? 'Đang gửi...' : 'Gửi mã xác thực',
                isLarge: true,
                onPressed: isLoading ? null : _handleSendCode,
              ),
            ]
            
            // ========== BƯỚC 2: NHẬP MÃ OTP ==========
            else if (_currentStep == 2) ...[
              Text(
                'Nhập mã xác thực',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Mã đã được gửi về $_email',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '------',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 30),
              CustomButton(
                text: isLoading ? 'Đang xác thực...' : 'Xác nhận',
                isLarge: true,
                onPressed: isLoading ? null : _handleVerifyCode,
              ),
              SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: isLoading ? null : _handleResendCode,
                  icon: Icon(Icons.refresh),
                  label: Text('Gửi lại mã'),
                ),
              ),
            ]
            
            // ========== BƯỚC 3: ĐẶT MẬT KHẨU MỚI ==========
            else if (_currentStep == 3) ...[
              Text(
                'Đặt mật khẩu mới',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Nhập mật khẩu mới cho tài khoản của bạn.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 30),
              CustomTextfield(
                hint: 'Mật khẩu mới',
                controller: newPasswordController,
                obscureText: true,
              ),
              SizedBox(height: 16),
              CustomTextfield(
                hint: 'Xác nhận mật khẩu',
                controller: confirmPasswordController,
                obscureText: true,
              ),
              SizedBox(height: 30),
              CustomButton(
                text: isLoading ? 'Đang xử lý...' : 'Đặt mật khẩu mới',
                isLarge: true,
                onPressed: isLoading ? null : _handleResetPassword,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? primary : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? primary : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
