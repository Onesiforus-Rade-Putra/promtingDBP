import 'package:flutter/foundation.dart';

import '../core/errors/auth_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/token_storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final TokenStorageService _tokenStorageService;

  AuthViewModel({
    required AuthService authService,
    required TokenStorageService tokenStorageService,
  })  : _authService = authService,
        _tokenStorageService = tokenStorageService;

  bool _isLoading = false;
  bool _rememberMe = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  bool get rememberMe => _rememberMe;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String? validateEmailOrUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email atau username wajib diisi.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi.';
    }

    return null;
  }

  void setRememberMe(bool? value) {
    _rememberMe = value ?? false;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
  }) async {
    final identifierError = validateEmailOrUsername(emailOrUsername);
    final passwordError = validatePassword(password);

    if (identifierError != null || passwordError != null) {
      _errorMessage =
          'Email/username dan password wajib diisi atau data tidak valid.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _authService.login(
        emailOrUsername,
        password,
      );

      await _tokenStorageService.saveSession(
        loginResponse: response,
        rememberMe: _rememberMe,
      );

      _currentUser = response.user;
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _tokenStorageService.clearSession();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
