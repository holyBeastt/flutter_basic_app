import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo media_kit
  MediaKit.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_SERVICE_ROLE_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'SUPABASE_URL hoặc SUPABASE_SERVICE_ROLE_KEY không tìm thấy trong .env',
    );
  }

  // Khởi tạo Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
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
      print('⚠️ Lỗi gọi native OpenGL transition: $e');
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenGLTransition(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Auth Demo',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: AppRoutes.login,
        routes: AppRoutes.routes,
      ),
    );
  }
}
