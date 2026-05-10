import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_api_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/json_helpers.dart';
import '../widgets/captcha_row.dart';
import '../widgets/field_label.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _smsCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();

  bool _loading = false;
  bool _sendingSms = false;
  int _smsCountdown = 0;
  Timer? _smsTimer;
  String? _error;
  String? _captchaChallengeId;
  String? _captchaCode;
  bool _captchaLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshCaptcha();
  }

  Future<void> _refreshCaptcha() async {
    setState(() {
      _captchaLoading = true;
      _captchaCtrl.clear();
    });
    try {
      final res = await AuthApiService.get('/auth/captcha');
      if (!mounted) return;
      setState(() {
        _captchaChallengeId = res['challengeId']?.toString();
        _captchaCode = (res['imageDataUri'] ?? res['displayCode'])?.toString();
        _captchaLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _captchaChallengeId = null;
        _captchaCode = null;
        _captchaLoading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _captchaChallengeId = null;
        _captchaCode = null;
        _captchaLoading = false;
        _error = '图形验证码加载失败，请稍后重试';
      });
    }
  }

  Future<void> _sendRegisterSmsCode() async {
    final phone = _phoneCtrl.text.trim();
    final captcha = _captchaCtrl.text.trim();
    if (!isPhoneValid(phone)) {
      setState(() => _error = '请输入正确的 11 位手机号');
      return;
    }
    if (_captchaChallengeId == null || captcha.isEmpty) {
      setState(() => _error = '请输入图形验证码');
      return;
    }

    setState(() {
      _sendingSms = true;
      _error = null;
    });

    try {
      final res = await AuthApiService.post('/auth/sms/send', {
        'phone': phone,
        'scene': 'REGISTER',
        'captchaChallengeId': _captchaChallengeId,
        'captchaCode': captcha,
      });
      _startSmsCountdown(readInt(res['cooldownSeconds']) ?? 60);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('验证码已发送，请注意查收短信')));
      await _refreshCaptcha();
      if (!mounted) return;
      setState(() {
        _sendingSms = false;
      });
    } on ApiException catch (e) {
      await _refreshCaptcha();
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _sendingSms = false;
      });
    } on http.ClientException {
      if (!mounted) return;
      setState(() {
        _error = '网络连接失败，请稍后重试';
        _sendingSms = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = '连接超时，请稍后重试';
        _sendingSms = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '发送验证码失败，请稍后重试';
        _sendingSms = false;
      });
    }
  }

  Future<void> _register() async {
    final phone = _phoneCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    final confirmPwd = _confirmPwdCtrl.text;
    final smsCode = _smsCtrl.text.trim();

    if (!isPhoneValid(phone)) {
      setState(() => _error = '请输入正确的 11 位手机号');
      return;
    }
    if (pwd.length < 8 ||
        !RegExp(r'^(?=.*[A-Za-z])(?=.*\d)\S+$').hasMatch(pwd)) {
      setState(() => _error = '密码至少 8 位，并需同时包含字母和数字');
      return;
    }
    if (pwd != confirmPwd) {
      setState(() => _error = '两次输入的密码不一致');
      return;
    }
    if (smsCode.isEmpty) {
      setState(() => _error = '请输入短信验证码');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthApiService.post('/auth/register', {
        'phone': phone,
        'password': pwd,
        'smsCode': smsCode,
      });
      await AuthService.saveLoginResult(res);
      await NotificationService.syncFromBackend();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on http.ClientException {
      if (!mounted) return;
      setState(() {
        _error = '网络连接失败，请稍后重试';
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = '连接超时，请稍后重试';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '注册失败，请稍后重试';
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

  @override
  void dispose() {
    _smsTimer?.cancel();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _smsCtrl.dispose();
    _captchaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手机号注册')),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '注册时需先完成图形验证码校验，再通过短信验证码完成手机号验证',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF667976)),
                        ),
                        const SizedBox(height: 18),
                        const FieldLabel('手机号'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '请输入 11 位手机号',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const FieldLabel('图形验证码'),
                        const SizedBox(height: 8),
                        CaptchaRow(
                          controller: _captchaCtrl,
                          imageDataUri: _captchaCode,
                          loading: _captchaLoading,
                          onRefresh: () => _refreshCaptcha(),
                        ),
                        const SizedBox(height: 14),
                        const FieldLabel('短信验证码'),
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
                                    : _sendRegisterSmsCode,
                                child: Text(
                                  _smsCountdown > 0
                                      ? '${_smsCountdown}s 后重发'
                                      : '获取验证码',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const FieldLabel('密码'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _pwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: '请输入 8~64 位，包含字母和数字',
                          ),
                        ),
                        const SizedBox(height: 14),
                        const FieldLabel('确认密码'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: '请再次输入密码',
                          ),
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
