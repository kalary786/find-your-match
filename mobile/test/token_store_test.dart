import 'package:find_your_match/core/api/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secureData;

  setUp(() {
    secureData = {};
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      secureData,
    );
    SharedPreferences.setMockInitialValues({});
  });

  test('a token saved by the old app moves out of plain preferences', () async {
    SharedPreferences.setMockInitialValues({
      SecureTokenStore.legacyKey: 'legacy-token',
    });
    final store = SecureTokenStore(secure: const FlutterSecureStorage());

    expect(await store.read(), 'legacy-token');
    expect(secureData[SecureTokenStore.legacyKey], 'legacy-token');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SecureTokenStore.legacyKey), isNull);
  });

  test('signing out removes the token from secure storage', () async {
    final store = SecureTokenStore(secure: const FlutterSecureStorage());
    await store.write('current-token');
    expect(secureData[SecureTokenStore.legacyKey], 'current-token');

    await store.write(null);

    expect(await store.read(), isNull);
    expect(secureData.containsKey(SecureTokenStore.legacyKey), isFalse);
  });
}
