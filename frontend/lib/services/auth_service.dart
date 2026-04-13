import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _keyToken = 'access_token';
  static const _keyUserId = 'user_id';
  static const _keyPhone = 'phone';
  static Future<void> saveLoginResult(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    final token = json['accessToken'] ?? json['access_token'];
    final tokenStr = token is String ? token : token?.toString();
    if (tokenStr != null && tokenStr.isNotEmpty) {
      prefs.setString(_keyToken, tokenStr);
      ApiService.setToken(tokenStr);
    }
    final rawUser = json['userInfo'] ?? json['user_info'];
    Map<String, dynamic>? user;
    if (rawUser is Map<String, dynamic>) {
      user = rawUser;
    } else if (rawUser is Map) {
      user = Map<String, dynamic>.from(rawUser);
    }
    if (user != null) {
      final id = user['id'];
      if (id != null) prefs.setInt(_keyUserId, id is int ? id : int.tryParse(id.toString()) ?? 0);
      final phone = user['phone'] as String?;
      if (phone != null) prefs.setString(_keyPhone, phone);
    }
  }

  static Future<bool> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token != null && token.isNotEmpty) {
      if (_isJwtExpired(token)) {
        await prefs.remove(_keyToken);
        await prefs.remove(_keyUserId);
        await prefs.remove(_keyPhone);
        ApiService.setToken(null);
        return false;
      }
      ApiService.setToken(token);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPhone);
    ApiService.setToken(null);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return false;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return false;
      final exp = json['exp'];
      final expSec = exp is int ? exp : int.tryParse('$exp');
      if (expSec == null) return false;
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return nowSec >= expSec;
    } catch (_) {
      return false;
    }
  }
}
