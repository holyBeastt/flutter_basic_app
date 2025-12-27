@echo off
echo ============================================
echo Building Flutter App with Code Obfuscation
echo ============================================

echo.
echo [1/2] Building Android APK...
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

echo.
echo [2/2] Building Android App Bundle...
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

echo.
echo ============================================
echo Build Complete!
echo ============================================
echo APK: build\app\outputs\flutter-apk\app-release.apk
echo AAB: build\app\outputs\bundle\release\app-release.aab
echo Debug symbols: build\debug-info\
echo.
pause
