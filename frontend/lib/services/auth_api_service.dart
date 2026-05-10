import 'api_service.dart';

class AuthApiService {
  static Future<Map<String, dynamic>> get(String path) {
    return ApiService.getUnauth(path);
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic>? body,
  ) {
    return ApiService.postUnauth(path, body);
  }
}
