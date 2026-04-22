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
      if (id != null)
        prefs.setInt(
          _keyUserId,
          id is int ? id : int.tryParse(id.toString()) ?? 0,
        );
      final phone = user['phone'] as String?;
      if (phone != null) prefs.setString(_keyPhone, phone);
    }
  }

  static Future<bool> loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token != null && token.isNotEmpty) {
      ApiService.setToken(token);
      try {
        await ApiService.get('/users/me');
        return true;
      } catch (_) {
        await _clearSavedCredentials(prefs);
        ApiService.setToken(null);
        return false;
      }
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
    await clearSavedCredentials();
    ApiService.setToken(null);
  }

  static Future<void> clearSavedCredentials([
    SharedPreferences? existing,
  ]) async {
    final prefs = existing ?? await SharedPreferences.getInstance();
    await _clearSavedCredentials(prefs);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> _clearSavedCredentials(SharedPreferences prefs) async {
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPhone);
  }
}
