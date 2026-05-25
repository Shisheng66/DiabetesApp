import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/display_text.dart';

class ProfileProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  Map<String, dynamic> _profile = {};

  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic> get profile => _profile;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.get('/users/me');
      _profile = resp['data'] is Map<String, dynamic>
          ? resp['data'] as Map<String, dynamic>
          : resp;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = DisplayText.userError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    try {
      final resp = await ApiService.put('/users/me', body);
      _profile = resp['data'] is Map<String, dynamic>
          ? resp['data'] as Map<String, dynamic>
          : resp;
      _error = null;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateHealthProfile(Map<String, dynamic> body) async {
    try {
      final resp = await ApiService.put('/users/me/health', body);
      _profile = resp['data'] is Map<String, dynamic>
          ? resp['data'] as Map<String, dynamic>
          : resp;
      _error = null;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changePassword(Map<String, dynamic> body) async {
    try {
      await ApiService.put('/users/me/password', body);
      _error = null;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
