import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/server_url_prefs.dart';
import 'api_service.dart';

class AuthApiService {
  static String? _resolvedBase;

  static Future<Map<String, dynamic>> get(String path) async {
    final uri = await _buildUri(path);
    final resp = await http
        .get(
          uri,
          headers: const {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 8));
    return _handleResponse(resp);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic>? body,
  ) async {
    final uri = await _buildUri(path);
    final resp = await http
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(const Duration(seconds: 10));
    return _handleResponse(resp);
  }

  static Future<Uri> _buildUri(String path) async {
    final base = await _resolveBase();
    return Uri.parse('${ApiConfig.apiBaseFor(base)}$path');
  }

  static Future<String> _resolveBase() async {
    if (_resolvedBase != null) return _resolvedBase!;

    final override = await ServerUrlPrefs.getBaseUrlOverride();
    final candidates =
        <String>[
              if (override != null && override.isNotEmpty) override,
              ...ApiConfig.baseUrlCandidates,
            ]
            .map(_normalizeBase)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList(growable: false);

    final ordered = _prioritizeCandidates(candidates);
    for (final base in ordered) {
      final healthy = await _isHealthy(base);
      if (healthy) {
        _resolvedBase = base;
        return base;
      }
    }

    throw ApiException(
      0,
      '登录服务暂时不可用，请确认后端已启动，并在真机调试时执行 adb reverse tcp:8080 tcp:8080',
    );
  }

  static List<String> _prioritizeCandidates(List<String> bases) {
    final loopback = <String>[];
    final emulator = <String>[];
    final others = <String>[];
    final lan = <String>[];

    for (final base in bases) {
      final host = Uri.tryParse(base)?.host ?? '';
      if (host == '127.0.0.1' || host == 'localhost') {
        loopback.add(base);
      } else if (host == '10.0.2.2') {
        emulator.add(base);
      } else if (_looksLikeIpv4(host)) {
        lan.add(base);
      } else {
        others.add(base);
      }
    }

    return <String>[
      ...loopback,
      ...emulator,
      ...others,
      ...lan,
    ].toSet().toList(growable: false);
  }

  static Future<bool> _isHealthy(String base) async {
    final candidates = <Uri>[];
    for (final raw in <String>[
      '${ApiConfig.apiBaseFor(base)}/health',
      '$base/api/health',
      '$base/health',
    ]) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        candidates.add(uri);
      }
    }

    for (final uri in candidates) {
      try {
        final resp = await http
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 2));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          return true;
        }
      } on SocketException {
      } on TimeoutException {
      } on http.ClientException {
      } on HttpException {}
    }
    return false;
  }

  static String _normalizeBase(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;
    var withScheme = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'http://$raw';
    withScheme = withScheme.replaceAll(RegExp(r'/+$'), '');
    if (withScheme.toLowerCase().endsWith('/api')) {
      withScheme = withScheme.substring(0, withScheme.length - 4);
    }
    return withScheme.replaceAll(RegExp(r'/+$'), '');
  }

  static bool _looksLikeIpv4(String host) {
    final parts = host.split('.');
    return parts.length == 4 && parts.every((e) => int.tryParse(e) != null);
  }

  static Map<String, dynamic> _handleResponse(http.Response resp) {
    final body = _tryParseJson(resp.body);
    if (resp.statusCode >= 400) {
      final msg = body is Map
          ? (body['message'] ?? body['errors']?.toString() ?? 'Request failed')
          : 'Request failed';
      throw ApiException(resp.statusCode, '$msg', body);
    }
    if (body == null) return {};
    return body is Map<String, dynamic> ? body : {'data': body};
  }

  static dynamic _tryParseJson(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}
