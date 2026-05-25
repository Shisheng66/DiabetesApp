import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

enum BackendConnectionState { checking, online, offline }

class ConnectionProvider extends ChangeNotifier {
  BackendConnectionState _state = BackendConnectionState.checking;
  String _message = '正在连接服务...';
  String? _apiBase;

  BackendConnectionState get state => _state;
  String get message => _message;
  String? get apiBase => _apiBase;
  bool get online => _state == BackendConnectionState.online;

  Future<void> check({bool forceResolve = false}) async {
    _state = BackendConnectionState.checking;
    _message = '正在连接服务...';
    notifyListeners();

    try {
      final health = await ApiService.checkHealth(forceResolve: forceResolve);
      _state = BackendConnectionState.online;
      _apiBase = health.apiBase;
      _message = '服务已连接';
    } on ApiException catch (e) {
      _state = BackendConnectionState.offline;
      _apiBase = ApiService.resolvedApiBase;
      _message = e.message;
    } catch (_) {
      _state = BackendConnectionState.offline;
      _apiBase = ApiService.resolvedApiBase;
      _message = '服务连接失败，请检查网络或稍后重试';
    }
    notifyListeners();
  }
}
