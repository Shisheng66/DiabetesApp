import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const _keyToken = 'access_token';
  static const _keyUserId = 'user_id';
  static const _keyPhone = 'phone';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveLoginResult(Map<String, dynamic> json) async {
    final token = json['accessToken'] ?? json['access_token'];
    final tokenStr = token is String ? token : token?.toString();
    if (tokenStr != null && tokenStr.isNotEmpty) {
      await _secureStorage.write(key: _keyToken, value: tokenStr);
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
      final prefs = await SharedPreferences.getInstance();
      final id = user['id'];
      if (id != null) {
        prefs.setInt(
          _keyUserId,
          id is int ? id : int.tryParse(id.toString()) ?? 0,
        );
      }
      final phone = user['phone'] as String?;
      if (phone != null) prefs.setString(_keyPhone, phone);
    }
  }

  static Future<bool> loadSavedToken() async {
    final token = await _secureStorage.read(key: _keyToken);
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
      try {
        await ApiService.get('/users/me');
        return true;
      } on ApiException catch (_) {
        // Server returned an error (e.g. 401) — token is invalid, clear it.
        await _clearSavedCredentials();
        ApiService.setToken(null);
        return false;
      }
      // Network errors (SocketException, TimeoutException, etc.) are NOT caught
      // here — they propagate up so the caller can distinguish "no connection"
      // from "invalid token". The token is preserved for retry.
    }
    return false;
  }

  static Future<void> logout({bool revokeRemote = true}) async {
    if (revokeRemote) {
      try {
        await ApiService.post('/auth/logout', null);
      } catch (_) {
        // Ignore network/logout endpoint failures and continue clearing local state.
      }
    }
    await _clearSavedCredentials();
    ApiService.setToken(null);
  }

  static Future<void> clearSavedCredentials() async {
    await _clearSavedCredentials();
  }

  static Future<String?> getToken() async {
    return _secureStorage.read(key: _keyToken);
  }

  static Future<bool> isAdmin() async {
    try {
      await ApiService.get('/admin/me');
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _clearSavedCredentials() async {
    await _secureStorage.delete(key: _keyToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPhone);
  }
}
