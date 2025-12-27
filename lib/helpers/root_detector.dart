import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class to detect rooted/jailbroken devices
/// Uses basic checks without external dependencies (AGP 8 compatible)
class RootDetector {
  // Common root indicators on Android
  static const List<String> _rootIndicators = [
    '/system/app/Superuser.apk',
    '/sbin/su',
    '/system/bin/su',
    '/system/xbin/su',
    '/data/local/xbin/su',
    '/data/local/bin/su',
    '/system/sd/xbin/su',
    '/system/bin/failsafe/su',
    '/data/local/su',
    '/su/bin/su',
    '/system/xbin/daemonsu',
    '/system/etc/.installed_su_daemon',
    '/system/etc/.has_su_daemon',
  ];

  // Common root management apps
  static const List<String> _rootApps = [
    'com.noshufou.android.su',
    'com.noshufou.android.su.elite',
    'eu.chainfire.supersu',
    'com.koushikdutta.superuser',
    'com.thirdparty.superuser',
    'com.yellowes.su',
    'com.topjohnwu.magisk',
    'com.kingroot.kinguser',
    'com.kingo.root',
    'com.smedialink.oneclickroot',
    'com.zhiqupk.root.global',
    'com.alephzain.framaroot',
  ];

  /// Check if device is rooted (Android) or jailbroken (iOS)
  /// Returns false in debug mode for development convenience
  static Future<bool> isDeviceRooted() async {
    // Skip detection in debug mode for development
    if (kDebugMode) {
      return false;
    }

    try {
      if (Platform.isAndroid) {
        return await _checkAndroidRoot();
      } else if (Platform.isIOS) {
        return await _checkiOSJailbreak();
      }
    } catch (e) {
      // If detection fails, allow app to run (fail-safe)
      return false;
    }

    return false;
  }

  /// Check for root indicators on Android
  static Future<bool> _checkAndroidRoot() async {
    // Check for su binary in common locations
    for (final path in _rootIndicators) {
      try {
        if (await File(path).exists()) {
          return true;
        }
      } catch (_) {
        // Ignore file access errors
      }
    }

    // Check if build tags contain test-keys (common on rooted devices)
    try {
      final result = await Process.run('getprop', ['ro.build.tags']);
      final buildTags = result.stdout.toString().toLowerCase();
      if (buildTags.contains('test-keys')) {
        return true;
      }
    } catch (_) {
      // Command not available or failed
    }

    return false;
  }

  /// Check for jailbreak indicators on iOS
  static Future<bool> _checkiOSJailbreak() async {
    // Common jailbreak paths on iOS
    const jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/bin/bash',
      '/usr/sbin/sshd',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/usr/bin/ssh',
      '/private/var/stash',
    ];

    for (final path in jailbreakPaths) {
      try {
        if (await File(path).exists()) {
          return true;
        }
      } catch (_) {
        // Ignore file access errors
      }
    }

    return false;
  }

  /// Check if developer mode is enabled (simplified check)
  static Future<bool> isDeveloperModeEnabled() async {
    if (kDebugMode) {
      return false;
    }
    // This requires platform-specific implementation
    // For now, we skip this check
    return false;
  }

  /// Check if device is compromised (rooted OR developer mode)
  static Future<bool> isDeviceCompromised() async {
    final rooted = await isDeviceRooted();
    final devMode = await isDeveloperModeEnabled();
    return rooted || devMode;
  }
}
