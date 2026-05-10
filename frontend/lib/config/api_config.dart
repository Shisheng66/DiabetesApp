import 'dart:io';
import 'package:flutter/foundation.dart';

/// Backend API base address configuration.
class ApiConfig {
  static const String apiPrefix = '/api';
  static const String buildTimeBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String devLanBaseUrls = String.fromEnvironment(
    'DEV_LAN_BASE_URLS',
  );

  static List<String> get baseUrlCandidates {
    if (kReleaseMode) {
      if (buildTimeBaseUrl.isEmpty) return const [];
      if (!buildTimeBaseUrl.startsWith('https://')) {
        assert(false, 'API_BASE_URL must use HTTPS in release mode: $buildTimeBaseUrl');
        return const [];
      }
      return [buildTimeBaseUrl];
    }

    final candidates = <String>[];

    if (buildTimeBaseUrl.isNotEmpty) {
      candidates.add(buildTimeBaseUrl);
    }

    if (Platform.isAndroid) {
      // Real-device USB debugging usually relies on adb reverse.
      candidates.add('http://127.0.0.1:8080');
      // Emulator host access fallback.
      candidates.add('http://10.0.2.2:8080');
    } else if (Platform.isIOS) {
      // iOS Simulator can reach the Mac host via loopback. Real devices should
      // use DEV_LAN_BASE_URLS or the LAN scan fallback below.
      candidates.add('http://127.0.0.1:8080');
      candidates.add('http://localhost:8080');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      candidates.add('http://127.0.0.1:8080');
      candidates.add('http://localhost:8080');
    }

    candidates.addAll(
      devLanBaseUrls
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    );
    return candidates.toSet().toList(growable: false);
  }

  static String apiBaseFor(String baseUrl) => '$baseUrl$apiPrefix';
}
