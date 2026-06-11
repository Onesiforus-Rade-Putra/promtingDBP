import 'package:flutter/material.dart';
import '../core/errors/auth_exception.dart';
import '../models/register_request_model.dart';
import '../services/auth_service.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({
    required AuthService authService,
  }) : _authService = authService;

  final AuthService _authService;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;
  DateTime? _selectedBirthDate;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  DateTime? get selectedBirthDate => _selectedBirthDate;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setBirthDate(DateTime selectedDate) {
    _selectedBirthDate = selectedDate;
    birthDateController.text = _formatDisplayDate(selectedDate);
    notifyListeners();
  }

  void clearBirthDate() {
    _selectedBirthDate = null;
    birthDateController.clear();
    notifyListeners();
  }

  String _formatDisplayDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }

  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap wajib diisi.';
    }

    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username wajib diisi.';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final String email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }

    final RegExp emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Format email tidak valid.';
    }

    return null;
  }

  String? validatePhoneNumber(String? value) {
    final String phoneNumber = value?.trim() ?? '';

    if (phoneNumber.isEmpty) {
      return 'Nomor telepon wajib diisi.';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phoneNumber)) {
      return 'Nomor telepon hanya boleh berisi angka.';
    }

    return null;
  }

  String? validateNim(String? value) {
    final String nim = value?.trim() ?? '';

    if (nim.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(nim)) {
      return 'NIM hanya boleh berisi angka.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) {
      return 'Password wajib diisi.';
    }

    if (password.length < 8) {
      return 'Password minimal terdiri dari 8 karakter.';
    }

    return null;
  }

  String? validateAllFields() {
    return validateFullName(fullNameController.text) ??
        validateUsername(usernameController.text) ??
        validateEmail(emailController.text) ??
        validatePhoneNumber(phoneNumberController.text) ??
        validateNim(nimController.text) ??
        validatePassword(passwordController.text);
  }

  Future<bool> register() async {
    _errorMessage = null;
    _successMessage = null;

    final String? localValidationError = validateAllFields();

    if (localValidationError != null) {
      _errorMessage = localValidationError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    final RegisterRequestModel request = RegisterRequestModel(
      fullName: fullNameController.text.trim(),
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      phoneNumber: phoneNumberController.text.trim(),
      nim: nimController.text.trim().isEmpty ? null : nimController.text.trim(),
      birthDate: _selectedBirthDate,
      password: passwordController.text,
    );

    try {
      await _authService.register(request);

      _successMessage = 'Registrasi berhasil. Silakan login.';
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      return false;
    } finally {
      /*
       * Password dikosongkan setelah request selesai agar tidak tersimpan
       * di state aplikasi setelah proses register berhasil maupun gagal.
       */
      passwordController.clear();

      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    birthDateController.dispose();
    phoneNumberController.dispose();
    nimController.dispose();
    passwordController.dispose();

    _authService.dispose();

    super.dispose();
  }
}
