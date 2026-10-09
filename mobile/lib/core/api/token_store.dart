import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStore {
  Future<String?> read();

  Future<void> write(String? token);
}

class MemoryTokenStore implements TokenStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String? token) async {
    value = token;
  }
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? secure})
    : _secure = secure ?? const FlutterSecureStorage();

  static const legacyKey = 'session_token';

  final FlutterSecureStorage _secure;

  @override
  Future<String?> read() async {
    final current = await _secure.read(key: legacyKey);
    if (current != null && current.isNotEmpty) return current;
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(legacyKey);
    if (legacy == null || legacy.isEmpty) return null;
    await _secure.write(key: legacyKey, value: legacy);
    await prefs.remove(legacyKey);
    return legacy;
  }

  @override
  Future<void> write(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(legacyKey);
    if (token == null || token.isEmpty) {
      await _secure.delete(key: legacyKey);
      return;
    }
    await _secure.write(key: legacyKey, value: token);
  }
}
