import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../config/server_url_prefs.dart';

class ApiService {
  static String? _token;
  static String? _resolvedApiBase;
  static Future<String>? _resolvingApiBaseFuture;
  static DateTime? _lastSubnetScanAt;
  static const Duration _subnetScanCooldown = Duration(minutes: 5);

  /// Call after backend/network changes to force rediscovery.
  static void clearResolvedApiBase() {
    _resolvedApiBase = null;
    _resolvingApiBaseFuture = null;
  }

  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final map = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      map['Authorization'] = 'Bearer $_token';
    }
    return map;
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    var uri = await _buildUri(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    final resp = await _send(() => http.get(uri, headers: _headers));
    return _handleResponse(resp);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic>? body,
  ) async {
    final uri = await _buildUri(path);
    final resp = await _send(
      () => http.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handleResponse(resp);
  }

  static Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic>? body,
  ) async {
    final uri = await _buildUri(path);
    final resp = await _send(
      () => http.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handleResponse(resp);
  }

  static Future<void> delete(String path) async {
    final uri = await _buildUri(path);
    final resp = await _send(() => http.delete(uri, headers: _headers));
    if (resp.statusCode >= 400) {
      final parsed = _tryParseJson(resp.body);
      final message = parsed is Map
          ? (parsed['message'] ??
                parsed['errors']?.toString() ??
                'Request failed')
          : 'Request failed';
      throw ApiException(resp.statusCode, '$message', parsed);
    }
  }

  static Future<Uri> _buildUri(String path) async {
    final apiBase = await _resolveApiBase();
    return Uri.parse('$apiBase$path');
  }

  static bool _isOurBackendHealthy(http.Response resp) {
    if (resp.statusCode == 401 || resp.statusCode == 403) {
      return true;
    }
    if (resp.statusCode < 200 || resp.statusCode >= 300) return false;

    final parsed = _tryParseJson(resp.body);
    if (parsed == null) return true;
    if (parsed is! Map) return true;

    final status = parsed['status']?.toString().toUpperCase();
    return status == null || status == 'UP';
  }

  static Future<String> _resolveApiBase() async {
    if (_resolvedApiBase != null) return _resolvedApiBase!;
    if (_resolvingApiBaseFuture != null) return _resolvingApiBaseFuture!;

    _resolvingApiBaseFuture = _doResolveApiBase();
    try {
      final resolved = await _resolvingApiBaseFuture!;
      _resolvedApiBase = resolved;
      return resolved;
    } finally {
      _resolvingApiBaseFuture = null;
    }
  }

  static Future<String> _doResolveApiBase() async {
    final override = await ServerUrlPrefs.getBaseUrlOverride();
    final firstRound =
        <String>[
              if (override != null && override.isNotEmpty) override,
              ...ApiConfig.baseUrlCandidates,
            ]
            .map(_normalizeBase)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList(growable: false);

    final directFound = await _findHealthyBase(
      firstRound,
      timeout: const Duration(seconds: 4),
    );
    if (directFound != null) {
      await _persistResolvedBase(override, directFound);
      return ApiConfig.apiBaseFor(directFound);
    }

    // Stale manual override is common after router/IP changes.
    if (override != null && override.isNotEmpty) {
      await ServerUrlPrefs.setBaseUrlOverride(null);
    }

    final now = DateTime.now();
    final canRescan = _lastSubnetScanAt == null ||
        now.difference(_lastSubnetScanAt!) >= _subnetScanCooldown;
    if (canRescan) {
      _lastSubnetScanAt = now;
      final scanRound = _expandSubnetCandidates(firstRound);
      final scannedFound = await _findHealthyBase(
        scanRound,
        timeout: const Duration(milliseconds: 900),
      );
      if (scannedFound != null) {
        await _persistResolvedBase(override, scannedFound);
        return ApiConfig.apiBaseFor(scannedFound);
      }
    }

    final hint = firstRound.take(6).join(', ');
    throw ApiException(
      0,
      canRescan
          ? 'Unable to connect backend. Make sure phone and backend are on the same LAN. Tried: $hint'
          : 'Backend is still unreachable. To avoid repeated LAN scanning, retry after a few minutes or use adb reverse.',
      null,
    );
  }

  static Future<void> _persistResolvedBase(
    String? oldOverride,
    String newBase,
  ) async {
    if (_isEphemeralDeviceOnlyBase(newBase)) {
      // Do not persist adb-reverse/emulator loopback addresses.
      if (oldOverride != null && oldOverride.isNotEmpty) {
        await ServerUrlPrefs.setBaseUrlOverride(null);
      }
      return;
    }
    if (oldOverride == newBase) return;
    await ServerUrlPrefs.setBaseUrlOverride(newBase);
  }

  static bool _isEphemeralDeviceOnlyBase(String base) {
    final host = Uri.tryParse(base)?.host ?? '';
    return host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2';
  }

  static Future<String?> _findHealthyBase(
    List<String> baseUrls, {
    required Duration timeout,
  }) async {
    if (baseUrls.isEmpty) return null;

    final checks = <Future<(String, bool)>>[];
    for (final base in baseUrls) {
      checks.add(_probeBase(base, timeout));
    }

    final results = await Future.wait(checks);
    final healthy = <String>{};
    for (final item in results) {
      if (item.$2) healthy.add(item.$1);
    }

    for (final base in baseUrls) {
      if (healthy.contains(base)) return base;
    }
    return null;
  }

  static Future<(String, bool)> _probeBase(
    String base,
    Duration timeout,
  ) async {
    final normalized = _normalizeBase(base);
    final probes = <Uri>[
      Uri.parse('${ApiConfig.apiBaseFor(normalized)}/health'),
      Uri.parse('$normalized/api/health'),
      Uri.parse('$normalized/health'),
    ].toSet().toList(growable: false);

    for (final uri in probes) {
      try {
        final resp = await http
            .get(uri, headers: const {'Accept': 'application/json'})
            .timeout(timeout);
        if (_isOurBackendHealthy(resp)) {
          return (normalized, true);
        }
      } on SocketException {
        // Try next probe.
      } on TimeoutException {
        // Try next probe.
      } on HttpException {
        // Try next probe.
      } on http.ClientException {
        // Try next probe.
      } catch (_) {
        // Try next probe.
      }
    }
    return (normalized, false);
  }

  static List<String> _expandSubnetCandidates(List<String> seedBases) {
    final result = <String>{};
    final prefixes = <String>{};

    for (final base in seedBases) {
      final host = Uri.tryParse(base)?.host ?? '';
      final parts = host.split('.');
      if (parts.length == 4 && parts.every((e) => int.tryParse(e) != null)) {
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        final c = int.parse(parts[2]);
        if (_isPrivateIpv4(a, b)) {
          prefixes.add('$a.$b.$c');
        }
      }
    }

    prefixes.addAll(const [
      '192.168.17',
      '192.168.190',
      '192.168.1',
      '192.168.0',
      '10.0.2',
    ]);

    const suffixes = <int>[
      2,
      8,
      10,
      11,
      12,
      20,
      30,
      50,
      100,
      101,
      102,
      103,
      108,
      109,
      110,
      120,
      130,
      138,
      150,
      186,
      200,
      201,
    ];

    for (final prefix in prefixes) {
      for (final s in suffixes) {
        result.add('http://$prefix.$s:8080');
      }
    }

    return result.toList(growable: false);
  }

  static bool _isPrivateIpv4(int a, int b) {
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }

  static String _normalizeBase(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return raw;

    var withScheme = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : 'http://$raw';
    withScheme = withScheme.replaceAll(RegExp(r'/+$'), '');

    // Accept values like http://x.x.x.x:8080/api from older manual settings.
    if (withScheme.toLowerCase().endsWith('/api')) {
      withScheme = withScheme.substring(0, withScheme.length - 4);
    }
    return withScheme.replaceAll(RegExp(r'/+$'), '');
  }

  static dynamic _tryParseJson(String body) {
    if (body.isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(const Duration(seconds: 10));
    } on SocketException {
      _resolvedApiBase = null;
      throw ApiException(
        0,
        'Network error. Check backend is running and phone is on the same LAN.',
      );
    } on TimeoutException {
      _resolvedApiBase = null;
      throw ApiException(0, 'Request timeout. Please retry.');
    } on HttpException {
      _resolvedApiBase = null;
      throw ApiException(0, 'HTTP error. Please retry later.');
    } on http.ClientException {
      _resolvedApiBase = null;
      throw ApiException(0, 'Client network error. Please retry later.');
    }
  }

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response resp,
  ) async {
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
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  ApiException(this.statusCode, this.message, [this.body]);

  @override
  String toString() => message;
}
