import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const _keyAuthToken = 'auth_token';
  static const _keyUserRole = 'user_role';
  static const _keyUserPhone = 'user_phone';
  static const _keyUserName = 'user_name';

  Future<void> saveUserSession({
    required String token, 
    required String role, 
    required String phone,
    String? name,
  }) async {
    await _storage.write(key: _keyAuthToken, value: token);
    await _storage.write(key: _keyUserRole, value: role);
    await _storage.write(key: _keyUserPhone, value: phone);
    if (name != null) {
      await _storage.write(key: _keyUserName, value: name);
    }
  }

  Future<void> saveUserPhone({required String phone}) async {
    await _storage.write(key: _keyUserPhone, value: phone);
  }

  // DÉCONNEXION TOTALE : On nettoie tout pour le prochain utilisateur
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  Future<String?> getAuthToken() async => await _storage.read(key: _keyAuthToken);
  Future<String?> getUserRole() async => await _storage.read(key: _keyUserRole);
  Future<String?> getUserPhone() async => await _storage.read(key: _keyUserPhone);
  Future<String?> getUserName() async => await _storage.read(key: _keyUserName);

  Future<bool> hasActiveSession() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }
}
