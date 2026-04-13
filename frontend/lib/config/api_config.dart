import 'dart:io';

/// Backend API base address configuration.
class ApiConfig {
  static const String apiPrefix = '/api';
  static const String buildTimeBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Add common LAN candidates that this project often runs on.
  static const List<String> lanBaseUrls = [
    'http://192.168.17.109:8080',
    'http://192.168.190.138:8080',
    'http://192.168.190.108:8080',
  ];

  static List<String> get baseUrlCandidates {
    final candidates = <String>[];

    if (buildTimeBaseUrl.isNotEmpty) {
      candidates.add(buildTimeBaseUrl);
    }

    if (Platform.isAndroid) {
      // Emulator host access; localhost works when adb reverse is active.
      candidates.add('http://10.0.2.2:8080');
      candidates.add('http://127.0.0.1:8080');
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      candidates.add('http://127.0.0.1:8080');
      candidates.add('http://localhost:8080');
    }

    candidates.addAll(lanBaseUrls);
    return candidates.toSet().toList(growable: false);
  }

  static String apiBaseFor(String baseUrl) => '$baseUrl$apiPrefix';
}
