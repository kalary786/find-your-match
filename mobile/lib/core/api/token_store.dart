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

class PrefsTokenStore implements TokenStore {
  static const _key = 'session_token';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, token);
  }
}
