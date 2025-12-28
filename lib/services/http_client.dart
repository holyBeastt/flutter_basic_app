import 'package:cronet_http/cronet_http.dart';
import 'package:http/http.dart' as http;

/// HTTP Client singleton sử dụng Cronet (Native Android)
/// Tuân thủ network_security_config.xml - chặn HTTP cleartext
class AppHttpClient {
  static CronetClient? _client;
  static CronetEngine? _engine;

  /// Lấy HTTP client instance
  static http.Client get instance {
    if (_client == null) {
      _engine = CronetEngine.build();
      _client = CronetClient.fromCronetEngine(_engine!);
    }
    return _client!;
  }

  /// Đóng client (gọi khi app terminate)
  static void close() {
    _client?.close();
    _client = null;
    _engine = null;
  }

  // ============ HELPER METHODS ============

  /// GET request
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return instance.get(url, headers: headers);
  }

  /// POST request
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return instance.post(url, headers: headers, body: body);
  }

  /// PUT request
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return instance.put(url, headers: headers, body: body);
  }

  /// DELETE request
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return instance.delete(url, headers: headers, body: body);
  }

  /// Multipart request (upload file)
  static Future<http.StreamedResponse> sendMultipart(
    http.MultipartRequest request,
  ) async {
    // Cronet client hỗ trợ send() cho BaseRequest
    return await instance.send(request);
  }
}
