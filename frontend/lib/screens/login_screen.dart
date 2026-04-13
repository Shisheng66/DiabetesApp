import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    if (phone.isEmpty || pwd.isEmpty) {
      setState(() => _error = '请输入手机号和密码');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.post('/auth/login', {
        'phone': phone,
        'password': pwd,
      });
      await AuthService.saveLoginResult(res);
      await NotificationService.syncFromBackend();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on http.ClientException catch (e) {
      setState(() {
        _error = '网络连接失败：${e.message}';
        _loading = false;
      });
    } on TimeoutException {
      setState(() {
        _error = '连接超时，请稍后重试';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '登录失败：$e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD7F0EB), Color(0xFFF4F8F7), Color(0xFFFFEFE2)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.monitor_heart_rounded,
                          size: 42,
                          color: Color(0xFF0B8A7D),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '欢迎回来',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '登录后继续管理每日血糖、饮食和运动',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF5A7673),
                              ),
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel('手机号'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(hintText: '请输入 11 位手机号'),
                        ),
                        const SizedBox(height: 14),
                        const _FieldLabel('密码'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(hintText: '请输入登录密码'),
                          onSubmitted: (_) {
                            if (!_loading) _login();
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Color(0xFFC53A2E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('登录'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: const Text('没有账号？立即注册'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
