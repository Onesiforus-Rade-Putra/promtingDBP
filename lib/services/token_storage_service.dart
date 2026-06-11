import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/storage_keys.dart';
import '../models/login_response_model.dart';

abstract class TokenStorageService {
  Future<void> saveSession({
    required LoginResponseModel loginResponse,
    required bool rememberMe,
  });

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<String?> readTokenType();

  Future<bool> readRememberMe();

  Future<void> clearSession();
}

class SecureTokenStorageService implements TokenStorageService {
  final FlutterSecureStorage _storage;

  SecureTokenStorageService(this._storage);

  @override
  Future<void> saveSession({
    required LoginResponseModel loginResponse,
    required bool rememberMe,
  }) async {
    await _storage.write(
      key: StorageKeys.accessToken,
      value: loginResponse.accessToken,
    );

    await _storage.write(
      key: StorageKeys.refreshToken,
      value: loginResponse.refreshToken,
    );

    await _storage.write(
      key: StorageKeys.tokenType,
      value: loginResponse.tokenType,
    );

    await _storage.write(
      key: StorageKeys.rememberMe,
      value: rememberMe.toString(),
    );
  }

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  @override
  Future<String?> readRefreshToken() {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  @override
  Future<String?> readTokenType() {
    return _storage.read(key: StorageKeys.tokenType);
  }

  @override
  Future<bool> readRememberMe() async {
    final value = await _storage.read(key: StorageKeys.rememberMe);
    return value == 'true';
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.tokenType);
    await _storage.delete(key: StorageKeys.rememberMe);
  }
}
