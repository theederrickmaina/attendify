import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SecureStore
/// -----------
/// Stores sensitive data using platform secure storage with a fallback to
/// SharedPreferences when secure storage is unavailable.
class SecureStore {
  static const _tokenKey = 'access_token';
  static const _consentKey = 'consent_accepted';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> setToken(String token) async {
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _secure.read(key: _tokenKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    }
  }

  Future<void> clearToken() async {
    try {
      await _secure.delete(key: _tokenKey);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    }
  }

  Future<void> setConsentAccepted(bool value) async {
    try {
      await _secure.write(key: _consentKey, value: value ? '1' : '0');
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, value);
    }
  }

  Future<bool> getConsentAccepted() async {
    try {
      final v = await _secure.read(key: _consentKey);
      return v == '1';
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_consentKey) ?? false;
    }
  }
}

