import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_api_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/local_captcha_service.dart';
import '../services/notification_service.dart';
import 'main_shell.dart';
import 'register_screen.dart';

enum _LoginMode { password, sms }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _smsCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();

  _LoginMode _mode = _LoginMode.password;
  bool _loading = false;
  bool _sendingSms = false;
  int _smsCountdown = 0;
  Timer? _smsTimer;
  String? _error;
  LocalCaptcha? _captcha;

  @override
  void initState() {
    super.initState();
    _refreshCaptcha();
  }

  void _refreshCaptcha() {
    setState(() {
      _captcha = LocalCaptchaService.generate();
      _captchaCtrl.clear();
    });
  }

  Future<void> _sendLoginSmsCode() async {
    final phone = _phoneCtrl.text.trim();
    final captcha = _captchaCtrl.text.trim();
    if (!_isPhoneValid(phone)) {
      setState(() => _error = '请输入正确的 11 位手机号');
      return;
    }
    if (_captcha == null || captcha.isEmpty) {
      setState(() => _error = '请输入图形验证码');
      return;
    }
    if (!LocalCaptchaService.verify(captcha: _captcha!, input: captcha)) {
      setState(() => _error = '图形验证码错误，请重新输入');
      _refreshCaptcha();
      return;
    }

    setState(() {
      _sendingSms = true;
      _error = null;
    });

    try {
      final res = await AuthApiService.post('/auth/sms/send', {
        'phone': phone,
        'scene': 'LOGIN',
      });
      final debugCode = res['debugCode']?.toString();
      if (debugCode != null && debugCode.isNotEmpty) {
        _smsCtrl.text = debugCode;
      }
      _startSmsCountdown(_readInt(res['cooldownSeconds']) ?? 60);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            debugCode != null && debugCode.isNotEmpty
                ? '验证码已发送，当前开发验证码：$debugCode'
                : '验证码已发送，请注意查收短信',
          ),
        ),
      );
      _refreshCaptcha();
      if (!mounted) return;
      setState(() {
        _sendingSms = false;
      });
    } on ApiException catch (e) {
      _refreshCaptcha();
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sendingSms = false;
      });
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '网络连接失败：${e.message}';
        _sendingSms = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = '连接超时，请稍后重试';
        _sendingSms = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '发送验证码失败：$e';
        _sendingSms = false;
      });
    }
  }

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    final smsCode = _smsCtrl.text.trim();
    final captcha = _captchaCtrl.text.trim();

    if (!_isPhoneValid(phone)) {
      setState(() => _error = '请输入正确的 11 位手机号');
      return;
    }
    if (_mode == _LoginMode.password) {
      if (pwd.isEmpty) {
        setState(() => _error = '请输入登录密码');
        return;
      }
      if (_captcha == null || captcha.isEmpty) {
        setState(() => _error = '请输入图形验证码');
        return;
      }
      if (!LocalCaptchaService.verify(captcha: _captcha!, input: captcha)) {
        setState(() => _error = '图形验证码错误，请重新输入');
        _refreshCaptcha();
        return;
      }
    } else if (smsCode.isEmpty) {
      setState(() => _error = '请输入短信验证码');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthApiService.post('/auth/login', {
        'phone': phone,
        'password': pwd,
        'smsCode': smsCode,
        'loginType': _mode == _LoginMode.password ? 'PASSWORD' : 'SMS',
      });
      await AuthService.saveLoginResult(res);
      await NotificationService.syncFromBackend();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } on ApiException catch (e) {
      if (_mode == _LoginMode.password) {
        _refreshCaptcha();
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '网络连接失败：${e.message}';
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = '连接超时，请稍后重试';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '登录失败：$e';
        _loading = false;
      });
    }
  }

  void _startSmsCountdown(int seconds) {
    _smsTimer?.cancel();
    setState(() {
      _smsCountdown = seconds;
    });
    _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _smsCountdown <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _smsCountdown = 0;
          });
        }
        return;
      }
      setState(() {
        _smsCountdown -= 1;
      });
    });
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  bool _isPhoneValid(String phone) => RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);

  @override
  void dispose() {
    _smsTimer?.cancel();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _smsCtrl.dispose();
    _captchaCtrl.dispose();
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '支持密码登录和短信验证码登录',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF5A7673)),
                        ),
                        const SizedBox(height: 24),
                        _LoginModeSwitcher(
                          mode: _mode,
                          onChanged: (mode) {
                            setState(() {
                              _mode = mode;
                              _error = null;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('手机号'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '请输入 11 位手机号',
                          ),
                        ),
                        if (_mode == _LoginMode.password) ...[
                          const SizedBox(height: 14),
                          const _FieldLabel('密码'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _pwdCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: '请输入登录密码',
                            ),
                            onSubmitted: (_) {
                              if (!_loading) _login();
                            },
                          ),
                          const SizedBox(height: 14),
                          const _FieldLabel('图形验证码'),
                          const SizedBox(height: 8),
                          _CaptchaRow(
                            controller: _captchaCtrl,
                            code: _captcha?.code,
                            onRefresh: _refreshCaptcha,
                          ),
                        ] else ...[
                          const SizedBox(height: 14),
                          const _FieldLabel('短信验证码'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _smsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '请输入 6 位短信验证码',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 132,
                                child: FilledButton.tonal(
                                  onPressed: (_sendingSms || _smsCountdown > 0)
                                      ? null
                                      : _sendLoginSmsCode,
                                  child: Text(
                                    _smsCountdown > 0
                                        ? '${_smsCountdown}s 后重发'
                                        : '获取验证码',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _FieldLabel('图形验证码'),
                          const SizedBox(height: 8),
                          _CaptchaRow(
                            controller: _captchaCtrl,
                            code: _captcha?.code,
                            onRefresh: _refreshCaptcha,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '发送短信前需先通过图形验证码校验',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF6B7C79)),
                          ),
                        ],
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
                              : Text(
                                  _mode == _LoginMode.password
                                      ? '立即登录'
                                      : '短信验证码登录',
                                ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
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

class _LoginModeSwitcher extends StatelessWidget {
  const _LoginModeSwitcher({required this.mode, required this.onChanged});

  final _LoginMode mode;
  final ValueChanged<_LoginMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1EF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              selected: mode == _LoginMode.password,
              label: '密码登录',
              onTap: () => onChanged(_LoginMode.password),
            ),
          ),
          Expanded(
            child: _ModeButton(
              selected: mode == _LoginMode.sms,
              label: '短信登录',
              onTap: () => onChanged(_LoginMode.sms),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFF103E38)
                  : const Color(0xFF65807C),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptchaRow extends StatelessWidget {
  const _CaptchaRow({
    required this.controller,
    required this.code,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final String? code;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: '请输入右侧验证码'),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 128,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F8F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9E8E4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  code ?? '----',
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0E4B43),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefresh,
                tooltip: '刷新验证码',
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
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
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
