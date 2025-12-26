1. Chặn HTTP Cleartext Traffic (Critical Fix)
   File	Thay đổi
   android/app/src/main/res/xml/network_security_config.xml
   [NEW] - Tạo file config chặn toàn bộ HTTP, chỉ cho phép HTTPS
   android/app/src/main/AndroidManifest.xml
   Thêm android:usesCleartextTraffic="false" và android:networkSecurityConfig="@xml/network_security_config"
   → Hiệu quả: App sẽ từ chối mọi kết nối HTTP, chỉ cho phép HTTPS.

2. Chuyển baseUrl sang HTTPS Production
   File	Trước	Sau
   lib/config/server.dart
   http://192.168.1.101:3000	https://app-hoc-tap.onrender.com
   → Hiệu quả: Tất cả API calls đều qua HTTPS với SSL/TLS encryption.

3. Bảo mật Debug Logging
   File	Thay đổi
   lib/helpers/app_logger.dart
   [NEW] - Logger utility chỉ log trong debug mode (kDebugMode)
   lib/api/auth_api.dart
   Thay print() → AppLogger.error()
   lib/api/courses_api.dart
   Thay 11 print() →
   AppLogger
   calls
   lib/api/progress_api.dart
   Thay 2 print() → AppLogger.debug()
   lib/api/payment_api.dart
   Thay 4 print() →
   AppLogger
   calls
   lib/api/lesson_api.dart
   Thay 5 print() → AppLogger.debug()
   lib/helpers/auth_helper.dart
   Thay 1 print() → AppLogger.error()
   → Hiệu quả: Release builds không log thông tin nhạy cảm (token, userId, response data).

✅ Checklist bảo mật đã đạt
Tiêu chí	Status
Toàn bộ request dùng https://	✅
Chặn cleartext traffic (usesCleartextTraffic=false)	✅
Network security config (cleartextTrafficPermitted=false)	✅
Không có "trust all certs" / SSL bypass	✅ (đã sẵn)
Không log sensitive data ở release	✅
Token dùng Authorization Bearer header	✅ (đã sẵn)
Login dùng POST body	✅ (đã sẵn)
Token storage encrypted	✅ (đã sẵn với flutter_secure_storage)