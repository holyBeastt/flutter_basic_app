import 'package:flutter/foundation.dart';

/// Secure logging utility - only logs in debug mode
class AppLogger {
  /// Log debug messages (debug builds only)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }

  /// Log info messages (debug builds only)
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log errors - sanitized for release
  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message${error != null ? ': $error' : ''}');
    }
    // In release: consider sending to crash reporting service
  }

  /// Log API responses (debug builds only)
  static void api(String endpoint, int statusCode) {
    if (kDebugMode) {
      debugPrint('[API] $endpoint -> $statusCode');
    }
  }
}
