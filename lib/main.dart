import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Thêm dòng này để tắt banner DEBUG
      title: 'Auth Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
