import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform error: $error\n$stack');
    return true;
  };
  await initializeDateFormatting();
  Intl.defaultLocale = 'zh_CN';
  await NotificationService.init();
  runApp(const DiabetesApp());
}

class DiabetesApp extends StatelessWidget {
  const DiabetesApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _signedIn = false;
  StreamSubscription<void>? _authExpiredSub;

  @override
  void initState() {
    super.initState();
    _authExpiredSub = ApiService.onAuthExpired.listen((_) async {
      await AuthService.logout(revokeRemote: false);
      if (!mounted) return;
      setState(() {
        _signedIn = false;
        _loading = false;
      });
      DiabetesApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    });
    _bootstrap();
  }

  @override
  void dispose() {
    _authExpiredSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final signedIn = await AuthService.loadSavedToken();
    if (signedIn) {
      await NotificationService.syncFromBackend();
    }
    if (!mounted) return;
    setState(() {
      _signedIn = signedIn;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _SplashScreen();
    }
    return _signedIn ? const MainShell() : const LoginScreen();
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
