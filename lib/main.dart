import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

import 'helpers/app_logger.dart';
import 'helpers/root_detector.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo media_kit
  MediaKit.ensureInitialized();

  // Kiểm tra root/jailbreak
  final isCompromised = await RootDetector.isDeviceCompromised();

  runApp(MyApp(showRootWarning: isCompromised));
}

/* -----------------------------------------------------------
   METHOD CHANNEL gọi sang Android để chạy OpenGL animation
----------------------------------------------------------- */
class ScreenTransition {
  static const _channel = MethodChannel('screen_transition');

  static Future<void> playZoomTransition() async {
    try {
      await _channel.invokeMethod('playZoom');
    } catch (e) {
      AppLogger.error('Lỗi gọi native OpenGL transition', e);
    }
  }
}

/* -----------------------------------------------------------
   Widget bọc screen để tự trigger animation khi update
----------------------------------------------------------- */
class OpenGLTransition extends StatefulWidget {
  final Widget child;

  const OpenGLTransition({super.key, required this.child});

  @override
  State<OpenGLTransition> createState() => _OpenGLTransitionState();
}

class _OpenGLTransitionState extends State<OpenGLTransition> {
  @override
  void didUpdateWidget(OpenGLTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    ScreenTransition.playZoomTransition(); // Gọi hiệu ứng GL
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/* -----------------------------------------------------------
   MyApp – TOÀN BỘ APP ĐƯỢC BỌC OPENGL WRAPPER
----------------------------------------------------------- */
class MyApp extends StatelessWidget {
  final bool showRootWarning;

  const MyApp({super.key, this.showRootWarning = false});

  @override
  Widget build(BuildContext context) {
    return OpenGLTransition(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Auth Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
        builder: (context, child) {
          // Hiển thị cảnh báo root trong lần build đầu tiên
          if (showRootWarning) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRootWarningDialog(context);
            });
          }
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }

  void _showRootWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Cảnh báo bảo mật'),
          ],
        ),
        content: const Text(
          'Thiết bị của bạn đã được root/jailbreak hoặc đang ở chế độ nhà phát triển.\n\n'
          'Điều này có thể gây ra rủi ro bảo mật cho dữ liệu của bạn. '
          'Khuyến nghị sử dụng ứng dụng trên thiết bị chưa root.',
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(), // Thoát app
            child: const Text('Thoát'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(), // Tiếp tục
            child: const Text('Tôi hiểu, tiếp tục'),
          ),
        ],
      ),
    );
  }
}
