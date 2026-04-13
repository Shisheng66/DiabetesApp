import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    final phone = _phoneCtrl.text.trim();
    final pwd = _pwdCtrl.text;

    if (phone.isEmpty || pwd.isEmpty) {
      setState(() => _error = '请输入手机号和密码');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _error = '密码至少需要 6 位');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.post('/auth/register', {
        'phone': phone,
        'password': pwd,
        'role': 'PATIENT',
      });
      await AuthService.saveLoginResult(res);
      await NotificationService.syncFromBackend();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
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
        _error = '注册失败：$e';
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
      appBar: AppBar(title: const Text('创建账号')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE2F3EF), Color(0xFFF4F8F7)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '注册后即可开始健康追踪',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 18),
                        const Text('手机号', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(hintText: '请输入 11 位手机号'),
                        ),
                        const SizedBox(height: 14),
                        const Text('密码', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(hintText: '请输入 6~32 位密码'),
                          onSubmitted: (_) {
                            if (!_loading) _register();
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
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loading ? null : _register,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('注册并登录'),
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
