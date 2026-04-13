import 'package:shared_preferences/shared_preferences.dart';

/// 持久化「后端根地址」，避免 api_service ↔ auth_service 循环依赖。
class ServerUrlPrefs {
  static const _keyApiBaseOverride = 'api_base_url_override';

  /// 例如 `http://192.168.1.8:8080`（不要带 `/api`）。
  static Future<String?> getBaseUrlOverride() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyApiBaseOverride);
    if (v == null || v.trim().isEmpty) return null;
    var normalized = v.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.toLowerCase().endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    return normalized.replaceAll(RegExp(r'/+$'), '');
  }

  static Future<void> setBaseUrlOverride(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(_keyApiBaseOverride);
      return;
    }
    var normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.toLowerCase().endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    await prefs.setString(
      _keyApiBaseOverride,
      normalized.replaceAll(RegExp(r'/+$'), ''),
    );
  }
}
