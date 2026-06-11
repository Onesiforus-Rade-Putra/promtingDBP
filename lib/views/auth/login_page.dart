import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../viewmodels/auth_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _identifierFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final authViewModel = context.read<AuthViewModel>();

    authViewModel.clearError();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    final success = await authViewModel.login(
      emailOrUsername: _identifierController.text,
      password: _passwordController.text,
    );

    // Password dibersihkan setelah proses login selesai.
    _passwordController.clear();

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _LoginHeader(),
                        const SizedBox(height: 28),
                        _LoginCard(
                          formKey: _formKey,
                          identifierController: _identifierController,
                          passwordController: _passwordController,
                          identifierFocusNode: _identifierFocusNode,
                          passwordFocusNode: _passwordFocusNode,
                          obscurePassword: _obscurePassword,
                          isLoading: authViewModel.isLoading,
                          rememberMe: authViewModel.rememberMe,
                          errorMessage: authViewModel.errorMessage,
                          identifierValidator:
                              authViewModel.validateEmailOrUsername,
                          passwordValidator: authViewModel.validatePassword,
                          onRememberMeChanged: authViewModel.setRememberMe,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          onForgotPassword: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.resetPassword,
                            );
                          },
                          onLogin: _submitLogin,
                          onSignUp: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.signUp,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Color(0xFFD61F38),
            size: 40,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Mahasiswa Sukses',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Belajar Sambil Berkompetisi!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode identifierFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool isLoading;
  final bool rememberMe;
  final String? errorMessage;
  final String? Function(String?) identifierValidator;
  final String? Function(String?) passwordValidator;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;

  const _LoginCard({
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.identifierFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.isLoading,
    required this.rememberMe,
    required this.errorMessage,
    required this.identifierValidator,
    required this.passwordValidator,
    required this.onRememberMeChanged,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Selamat Datang',
                style: TextStyle(
                  color: Color(0xFF171A24),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Login untuk melanjutkan petualangan mu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF747985),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (errorMessage != null) ...[
              _ErrorBanner(message: errorMessage!),
              const SizedBox(height: 16),
            ],
            const Text(
              'Email atau Username',
              style: TextStyle(
                color: Color(0xFF252936),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: identifierController,
              focusNode: identifierFocusNode,
              enabled: !isLoading,
              validator: identifierValidator,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) {
                passwordFocusNode.requestFocus();
              },
              decoration: _inputDecoration(
                hintText: 'Masukkan email atau username',
                prefixIcon: Icons.person_outline_rounded,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Password',
              style: TextStyle(
                color: Color(0xFF252936),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              focusNode: passwordFocusNode,
              enabled: !isLoading,
              obscureText: obscurePassword,
              validator: passwordValidator,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!isLoading) {
                  onLogin();
                }
              },
              decoration: _inputDecoration(
                hintText: 'Masukkan password',
                prefixIcon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  onPressed: isLoading ? null : onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF7D8290),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: isLoading ? null : onRememberMeChanged,
                    activeColor: const Color(0xFFD61F38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(
                    color: Color(0xFF5C6270),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: isLoading ? null : onForgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Lupa password?',
                    style: TextStyle(
                      color: Color(0xFF2667D8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD61F38),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFD61F38).withValues(alpha: 0.65),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Belum punya akun? ',
                  style: TextStyle(
                    color: Color(0xFF737987),
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: isLoading ? null : onSignUp,
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF2667D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFFA3A8B3),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF818796),
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE6E8EE),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE6E8EE),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFD61F38),
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFD61F38),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFD61F38),
          width: 1.4,
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFF5B8C1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFD61F38),
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB71931),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF13B4F),
                Color(0xFFD61F38),
                Color(0xFFA70923),
              ],
              stops: [0.0, 0.48, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _DecorativeLinesPainter(),
          ),
        ),
      ],
    );
  }
}

class _DecorativeLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whiteLine = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final softShape = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final upperShape = Path()
      ..moveTo(size.width * 0.56, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.20)
      ..close();

    canvas.drawPath(upperShape, softShape);

    final lowerShape = Path()
      ..moveTo(0, size.height * 0.78)
      ..lineTo(size.width * 0.44, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(lowerShape, softShape);

    final lineOne = Path()
      ..moveTo(size.width * 0.65, 0)
      ..lineTo(size.width, size.height * 0.18);

    final lineTwo = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.36, size.height);

    final lineThree = Path()
      ..moveTo(size.width * 0.82, 0)
      ..lineTo(size.width, size.height * 0.10);

    canvas.drawPath(lineOne, whiteLine);
    canvas.drawPath(lineTwo, whiteLine);
    canvas.drawPath(lineThree, whiteLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
