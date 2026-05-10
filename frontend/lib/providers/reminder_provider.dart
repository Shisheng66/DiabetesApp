import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/display_text.dart';

class ReminderProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _reminders = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get reminders => _reminders;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.get('/reminders');
      final data = resp['data'];
      if (data is List) {
        _reminders = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (data is Map && data['records'] is List) {
        _reminders = (data['records'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (data is Map && data['content'] is List) {
        _reminders = (data['content'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
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

  Future<void> createReminder(Map<String, dynamic> body) async {
    try {
      await ApiService.post('/reminders', body);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateReminder(int id, Map<String, dynamic> body) async {
    try {
      await ApiService.put('/reminders/$id', body);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await ApiService.delete('/reminders/$id');
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
