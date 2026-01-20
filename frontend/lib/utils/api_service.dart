import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'secure_store.dart';

/// APIService
/// ----------
/// Simple HTTP client for Attendify backend with JWT storage.
/// Base URL can be adjusted for emulator/device scenarios.
class APIService {
  // Development: use localhost:5000.
  // Production: set via build-time environment or config.
  static const String _baseUrl = String.fromEnvironment(
    'ATTENDIFY_API',
    defaultValue: 'http://localhost:5000',
  );

  final SecureStore _store = SecureStore();
  final Duration _timeout = const Duration(seconds: 10);

  Future<String?> getToken() => _store.getToken();
  Future<void> setToken(String token) => _store.setToken(token);
  Future<void> clearToken() => _store.clearToken();

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final url = Uri.parse('$_baseUrl/api/login');
      final res = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['access_token'] is String) {
        await setToken(data['access_token'] as String);
      }
      return data is Map<String, dynamic>
          ? data
          : {'error': 'invalid_response'};
    } on TimeoutException catch (_) {
      return {'error': 'network_timeout'};
    } on SocketException catch (_) {
      return {'error': 'network_unreachable'};
    } catch (_) {
      return {'error': 'unknown_error'};
    }
  }

  Future<Map<String, dynamic>> enroll(Map<String, dynamic> payload) async {
    try {
      final url = Uri.parse('$_baseUrl/api/enroll');
      final res = await http
          .post(url, headers: _headers(), body: jsonEncode(payload))
          .timeout(_timeout);
      return jsonDecode(res.body);
    } on TimeoutException catch (_) {
      return {'error': 'network_timeout'};
    } on SocketException catch (_) {
      return {'error': 'network_unreachable'};
    } catch (_) {
      return {'error': 'unknown_error'};
    }
  }

  Future<Map<String, dynamic>> recognize(String imageBase64) async {
    try {
      final url = Uri.parse('$_baseUrl/api/recognize');
      final res = await http
          .post(
            url,
            headers: _headers(),
            body: jsonEncode({'facial_image_base64': imageBase64}),
          )
          .timeout(_timeout);
      return jsonDecode(res.body);
    } on TimeoutException catch (_) {
      return {'error': 'network_timeout'};
    } on SocketException catch (_) {
      return {'error': 'network_unreachable'};
    } catch (_) {
      return {'error': 'unknown_error'};
    }
  }

  Future<Map<String, dynamic>> studentAttendance() async {
    try {
      final token = await getToken();
      final url = Uri.parse('$_baseUrl/api/student/attendance');
      final res = await http
          .get(url, headers: _headers(token: token))
          .timeout(_timeout);
      return jsonDecode(res.body);
    } on TimeoutException catch (_) {
      return {'error': 'network_timeout'};
    } on SocketException catch (_) {
      return {'error': 'network_unreachable'};
    } catch (_) {
      return {'error': 'unknown_error'};
    }
  }

  Future<Map<String, dynamic>> adminReports() async {
    try {
      final token = await getToken();
      final url = Uri.parse('$_baseUrl/api/admin/reports');
      final res = await http
          .get(url, headers: _headers(token: token))
          .timeout(_timeout);
      return jsonDecode(res.body);
    } on TimeoutException catch (_) {
      return {'error': 'network_timeout'};
    } on SocketException catch (_) {
      return {'error': 'network_unreachable'};
    } catch (_) {
      return {'error': 'unknown_error'};
    }
  }

  Future<Map<String, dynamic>> updateConsent(bool consent) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$_baseUrl/api/consent');
      final res = await http
          .post(
            url,
            headers: _headers(token: token),
            body: jsonEncode({'consent': consent}),
          )
          .timeout(_timeout);
      return jsonDecode(res.body);
    } on TimeoutException catch (_) {
      return {'error': 'network_timeout'};
    } on SocketException catch (_) {
      return {'error': 'network_unreachable'};
    } catch (_) {
      return {'error': 'unknown_error'};
    }
  }
}
