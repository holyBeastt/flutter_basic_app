import 'package:flutter/material.dart';
import 'package:cronet_http/cronet_http.dart';

/// Màn hình test bảo mật HTTPS
/// Cronet tuân thủ network_security_config.xml
class SecurityTestScreen extends StatefulWidget {
  const SecurityTestScreen({super.key});

  @override
  State<SecurityTestScreen> createState() => _SecurityTestScreenState();
}

class _SecurityTestScreenState extends State<SecurityTestScreen> {
  static const String httpUrl = 'http://httpbin.org/get';
  static const String httpsUrl = 'https://httpbin.org/get';
  
  String _result = '';
  bool _isLoading = false;

  // Test HTTP - sẽ BỊ CHẶN
  Future<void> _testHttp() async {
    setState(() {
      _isLoading = true;
      _result = 'Đang test HTTP...';
    });

    try {
      final engine = CronetEngine.build();
      final client = CronetClient.fromCronetEngine(engine);
      
      final response = await client.get(Uri.parse(httpUrl))
          .timeout(const Duration(seconds: 10));

      setState(() {
        _result = '⚠️ HTTP KHÔNG BỊ CHẶN!\nStatus: ${response.statusCode}';
      });
      
      client.close();
    } catch (e) {
      setState(() {
        _result = '🔒 HTTP ĐÃ BỊ CHẶN!\n\n'
            'Network Security Config đã hoạt động!\n\n'
            'Lỗi: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Test HTTPS - sẽ THÀNH CÔNG
  Future<void> _testHttps() async {
    setState(() {
      _isLoading = true;
      _result = 'Đang test HTTPS...';
    });

    try {
      final engine = CronetEngine.build();
      final client = CronetClient.fromCronetEngine(engine);
      
      final response = await client.get(Uri.parse(httpsUrl))
          .timeout(const Duration(seconds: 10));

      setState(() {
        _result = '✅ HTTPS THÀNH CÔNG!\nStatus: ${response.statusCode}';
      });
      
      client.close();
    } catch (e) {
      setState(() {
        _result = '❌ HTTPS thất bại\n\nLỗi: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Bảo Mật HTTPS'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Cronet = Native Android HTTP Stack\n'
                '→ Tuân thủ network_security_config.xml',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),

            // Test HTTP (BỊ CHẶN)
            Text('🔗 $httpUrl', style: const TextStyle(fontSize: 10, color: Colors.red)),
            ElevatedButton(
              onPressed: _isLoading ? null : _testHttp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Column(
                children: [
                  Text('TEST HTTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Sẽ BỊ CHẶN bởi Android', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Test HTTPS (THÀNH CÔNG)
            Text('🔗 $httpsUrl', style: const TextStyle(fontSize: 10, color: Colors.green)),
            ElevatedButton(
              onPressed: _isLoading ? null : _testHttps,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Column(
                children: [
                  Text('TEST HTTPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Sẽ thành công', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Kết quả
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(
                          _result.isEmpty ? 'Nhấn nút để test...' : _result,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
