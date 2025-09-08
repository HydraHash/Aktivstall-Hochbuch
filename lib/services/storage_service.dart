import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final _secure = const FlutterSecureStorage();
  static const _keyToken = 'jwt_token';

  static Future<void> saveToken(String token) async {
    await _secure.write(key: _keyToken, value: token);
  }

  static Future<String?> readToken() async {
    return await _secure.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    await _secure.delete(key: _keyToken);
  }
}
