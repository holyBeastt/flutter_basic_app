import 'package:android_basic/screens/onboarding.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String onBoarding = '/onBoarding';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    onBoarding: (context) => OnboardingScreen(),
    login: (context) => LoginScreen(),
    register: (context) => SignupScreen(),
    home: (context) => HomeScreen(),
  };
}
