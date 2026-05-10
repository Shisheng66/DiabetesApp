import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/connection_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/glucose_provider.dart';
import 'providers/diet_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/community_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/connection_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Flutter error: ${details.exception}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Platform error: $error\n$stack');
    }
    return true;
  };
  await initializeDateFormatting();
  Intl.defaultLocale = 'zh_CN';
  runApp(const DiabetesApp());
  unawaited(_initBackgroundServices());
}

Future<void> _initBackgroundServices() async {
  try {
    await NotificationService.init();
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Notification init skipped: $error');
    }
  }
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()..check()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => GlucoseProvider()),
        ChangeNotifierProvider(create: (_) => DietProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '糖尿病健康管家',
        navigatorKey: navigatorKey,
        theme: AppTheme.light(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        locale: const Locale('zh', 'CN'),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<void>? _authExpiredSub;

  @override
  void initState() {
    super.initState();
    _authExpiredSub = ApiService.onAuthExpired.listen((_) async {
      await AuthService.logout(revokeRemote: false);
      if (!mounted) return;
      context.read<AuthProvider>().setSignedIn(false);
      DiabetesApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
    context.read<ConnectionProvider>().check();
    context.read<AuthProvider>().bootstrap();
  }

  @override
  void dispose() {
    _authExpiredSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) {
      return const _SplashScreen();
    }
    final child = auth.signedIn ? const MainShell() : const LoginScreen();
    return Stack(children: [child, const ConnectionBanner()]);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD6F0EC), Color(0xFFF4F8F7), Color(0xFFFFF2E9)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0B8A7D),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: Color(0xFF0B8A7D),
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '糖尿病健康管家',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
