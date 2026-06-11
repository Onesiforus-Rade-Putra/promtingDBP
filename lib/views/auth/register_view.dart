import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../viewmodels/register_view_model.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _selectBirthDate(RegisterViewModel viewModel) async {
    final DateTime today = DateTime.now();

    final DateTime initialDate = viewModel.selectedBirthDate ??
        DateTime(
          today.year - 18,
          today.month,
          today.day,
        );

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (selectedDate != null) {
      viewModel.setBirthDate(selectedDate);
    }
  }

  Future<void> _submitRegister(RegisterViewModel viewModel) async {
    FocusScope.of(context).unfocus();

    final bool isFormValid = _formKey.currentState?.validate() ?? false;

    if (!isFormValid) {
      return;
    }

    final bool isSuccess = await viewModel.register();

    if (!mounted) {
      return;
    }

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.successMessage ?? 'Registrasi berhasil. Silakan login.',
          ),
          backgroundColor: const Color(0xFF15803D),
          behavior: SnackBarBehavior.floating,
        ),
      );

      _navigateToLogin();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.errorMessage ?? 'Terjadi kesalahan. Silakan coba lagi.',
        ),
        backgroundColor: const Color(0xFFD62828),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RegisterViewModel viewModel = context.watch<RegisterViewModel>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF3B3B),
              Color(0xFFD71920),
              Color(0xFF980D16),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const _BackgroundDecoration(),
              Column(
                children: [
                  _Header(
                    onBackPressed: _navigateToLogin,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildLoginRedirect(),
                          const SizedBox(height: 22),
                          _buildRegisterCard(viewModel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Sudah punya akun? ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        InkWell(
          onTap: _navigateToLogin,
          child: const Text(
            'Login',
            style: TextStyle(
              color: Color(0xFF8CD5FF),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard(RegisterViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Account',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Daftar untuk mulai belajar dan berkompetisi.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 22),
            _RegisterInputField(
              label: 'Nama Lengkap',
              hintText: 'Masukkan nama lengkap',
              controller: viewModel.fullNameController,
              validator: viewModel.validateFullName,
              prefixIcon: Icons.person_outline_rounded,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _RegisterInputField(
              label: 'Username',
              hintText: 'Masukkan username',
              controller: viewModel.usernameController,
              validator: viewModel.validateUsername,
              prefixIcon: Icons.alternate_email_rounded,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _RegisterInputField(
              label: 'Email',
              hintText: 'contoh@email.com',
              controller: viewModel.emailController,
              validator: viewModel.validateEmail,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _RegisterInputField(
              label: 'Tanggal Lahir',
              hintText: 'dd/mm/yyyy',
              controller: viewModel.birthDateController,
              readOnly: true,
              onTap: viewModel.isLoading
                  ? null
                  : () => _selectBirthDate(viewModel),
              prefixIcon: Icons.calendar_today_outlined,
              suffixIcon: IconButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () => _selectBirthDate(viewModel),
                icon: const Icon(
                  Icons.calendar_month_outlined,
                  color: Color(0xFF6B7280),
                ),
              ),
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _RegisterInputField(
              label: 'Nomor Telepon',
              hintText: '08xxxxxxxxxx',
              controller: viewModel.phoneNumberController,
              validator: viewModel.validatePhoneNumber,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              prefixIcon: Icons.phone_outlined,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _RegisterInputField(
              label: 'NIM (Opsional)',
              hintText: 'Masukkan NIM',
              controller: viewModel.nimController,
              validator: viewModel.validateNim,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              prefixIcon: Icons.badge_outlined,
              enabled: !viewModel.isLoading,
            ),
            const SizedBox(height: 14),
            _RegisterInputField(
              label: 'Password',
              hintText: 'Minimal 8 karakter',
              controller: viewModel.passwordController,
              validator: viewModel.validatePassword,
              obscureText: viewModel.obscurePassword,
              prefixIcon: Icons.lock_outline_rounded,
              enabled: !viewModel.isLoading,
              suffixIcon: IconButton(
                onPressed: viewModel.isLoading
                    ? null
                    : viewModel.togglePasswordVisibility,
                icon: Icon(
                  viewModel.obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () => _submitRegister(viewModel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD71920),
                  disabledBackgroundColor: const Color(0xFFEFA3A6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: viewModel.isLoading
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBackPressed,
  });

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Expanded(
            child: Text(
              'Sign up',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _RegisterInputField extends StatelessWidget {
  const _RegisterInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    required this.enabled,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData prefixIcon;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: const Color(0xFF6B7280),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFD71920),
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFD71920),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFD71920),
                width: 1.4,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -80,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 220,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          Positioned(
            top: 145,
            left: -45,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 180,
                height: 1,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
          Positioned(
            bottom: 90,
            right: -40,
            child: Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 190,
                height: 1,
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
