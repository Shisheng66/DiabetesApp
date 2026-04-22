import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class LocalCaptcha {
  const LocalCaptcha({
    required this.code,
    required this.salt,
    required this.hash,
  });

  final String code;
  final String salt;
  final String hash;
}

class LocalCaptchaService {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _random = Random.secure();

  static LocalCaptcha generate({int length = 4}) {
    final code = List.generate(
      length,
      (_) => _chars[_random.nextInt(_chars.length)],
    ).join();
    final salt =
        '${DateTime.now().microsecondsSinceEpoch}${_random.nextInt(99999)}';
    return LocalCaptcha(
      code: code,
      salt: salt,
      hash: _hash('${code.toUpperCase()}:$salt'),
    );
  }

  static bool verify({required LocalCaptcha captcha, required String input}) {
    final normalized = input.trim().toUpperCase();
    return _hash('$normalized:${captcha.salt}') == captcha.hash;
  }

  static String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
