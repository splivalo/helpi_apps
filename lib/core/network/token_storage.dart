import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sigurno spremanje JWT tokena i korisničkih podataka.
class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _keyToken = 'access_token';
  static const _keyUserId = 'user_id';
  static const _keyUserType = 'user_type';
  static const _keySeniorId = 'senior_id';

  // ── Token ──
  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<bool> hasToken() async => (await getToken()) != null;

  // ── User ID ──
  Future<void> saveUserId(int userId) =>
      _storage.write(key: _keyUserId, value: userId.toString());

  Future<int?> getUserId() async {
    final value = await _storage.read(key: _keyUserId);
    return value != null ? int.tryParse(value) : null;
  }

  // ── User Type ──
  Future<void> saveUserType(String userType) =>
      _storage.write(key: _keyUserType, value: userType);

  Future<String?> getUserType() => _storage.read(key: _keyUserType);

  // ── Senior ID ──
  Future<void> saveSeniorId(int seniorId) =>
      _storage.write(key: _keySeniorId, value: seniorId.toString());

  Future<int?> getSeniorId() async {
    final value = await _storage.read(key: _keySeniorId);
    return value != null ? int.tryParse(value) : null;
  }

  // ── Clear ──
  Future<void> clearAll() => _storage.deleteAll();
}
