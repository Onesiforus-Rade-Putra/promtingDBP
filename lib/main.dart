import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'config/api_config.dart';
import 'core/routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/progress_tracking_service.dart';
import 'services/quiz_service.dart';
import 'services/token_storage_service.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/progress_tracking_view_model.dart';
import 'viewmodels/quiz_view_model.dart';
import 'viewmodels/register_view_model.dart';
import 'views/auth/login_page.dart';
import 'views/auth/register_view.dart';
import 'views/auth/reset_password_page.dart';
import 'views/feature_placeholder_page.dart';
import 'views/forum_page.dart';
import 'views/home/dashboard_page.dart';
import 'views/leaderboard_page.dart';
import 'views/quiz/quiz_list_page.dart';
import 'views/settings_page.dart';
import 'views/target_task_page.dart';
import 'views/task_form_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahasiswaSuksesBootstrap());
}

class MahasiswaSuksesBootstrap extends StatelessWidget {
  const MahasiswaSuksesBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FlutterSecureStorage>(
          create: (_) => const FlutterSecureStorage(
            aOptions: AndroidOptions(),
          ),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(
            client: http.Client(),
            baseUrl: ApiConfig.baseUrl,
          ),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<TokenStorageService>(
          create: (context) => SecureTokenStorageService(
            context.read<FlutterSecureStorage>(),
          ),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
            tokenStorageService: context.read<TokenStorageService>(),
          ),
        ),
        ChangeNotifierProvider<DashboardViewModel>(
          create: (context) => DashboardViewModel(
            service: DashboardService(
              storage: context.read<FlutterSecureStorage>(),
            ),
          ),
        ),
        ChangeNotifierProvider<QuizViewModel>(
          create: (context) => QuizViewModel(
            quizService: QuizService(
              client: http.Client(),
              storage: context.read<FlutterSecureStorage>(),
            ),
          ),
        ),
        ChangeNotifierProvider<ProgressTrackingViewModel>(
          create: (context) => ProgressTrackingViewModel(
            service: ProgressTrackingService(
              baseUrl: ApiConfig.baseUrl,
              secureStorage: context.read<FlutterSecureStorage>(),
            ),
          ),
        ),
      ],
      child: const MahasiswaSuksesApp(),
    );
  }
}

class MahasiswaSuksesApp extends StatelessWidget {
  const MahasiswaSuksesApp({super.key});

  Widget _registerPage() {
    return ChangeNotifierProvider<RegisterViewModel>(
      create: (_) => RegisterViewModel(
        authService: AuthService(
          client: http.Client(),
          baseUrl: ApiConfig.baseUrl,
        ),
      ),
      child: const RegisterView(),
    );
  }

  void _navigateFromQuizBottomBar(BuildContext context, int index) {
    String route;

    switch (index) {
      case 0:
        route = AppRoutes.dashboard;
        break;
      case 1:
        route = AppRoutes.forum;
        break;
      case 3:
        route = AppRoutes.leaderboard;
        break;
      case 4:
        route = AppRoutes.settings;
        break;
      default:
        route = AppRoutes.quizList;
    }

    if (route == AppRoutes.dashboard) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (route) => false,
      );
    } else if (route != AppRoutes.quizList) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mahasiswa Sukses',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD61F38),
          primary: const Color(0xFFD61F38),
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.dashboard: (_) => const DashboardPage(),
        AppRoutes.signUp: (_) => _registerPage(),
        AppRoutes.register: (_) => _registerPage(),
        AppRoutes.resetPassword: (_) => const ResetPasswordPage(),
        AppRoutes.forum: (_) => const ForumPage(),
        AppRoutes.quizList: (context) => QuizListPage(
              onBottomNavigationTap: (index) {
                _navigateFromQuizBottomBar(context, index);
              },
            ),
        AppRoutes.leaderboard: (_) => const LeaderboardPage(),
        AppRoutes.settings: (_) => const SettingsPage(),
        AppRoutes.targetTask: (_) => const TargetTaskPage(),
        AppRoutes.addTargetTask: (_) => const TaskFormPage(),
        AppRoutes.profile: (_) => const FeaturePlaceholderPage(
              title: 'Profile',
              message:
                  'Halaman profile belum tersedia pada file lib yang digabungkan.',
            ),
        AppRoutes.achievement: (_) => const FeaturePlaceholderPage(
              title: 'Achievement',
              message:
                  'Ringkasan achievement sudah tampil pada dashboard. Halaman detail belum tersedia.',
            ),
        AppRoutes.quest: (_) => const FeaturePlaceholderPage(
              title: 'Quest',
              message:
                  'Ringkasan quest sudah tampil pada dashboard. Halaman detail belum tersedia.',
            ),
      },
    );
  }
}
