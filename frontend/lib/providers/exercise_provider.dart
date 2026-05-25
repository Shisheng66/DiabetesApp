import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/display_text.dart';

class ExerciseProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _exerciseTypes = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get records => _records;
  List<Map<String, dynamic>> get exerciseTypes => _exerciseTypes;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.get('/exercise/records');
      final data = resp['data'];
      if (data is List) {
        _records = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (data is Map && data['records'] is List) {
        _records = (data['records'] as List)
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

  Future<void> loadExerciseTypes() async {
    try {
      final resp = await ApiService.get('/exercise/types');
      final data = resp['data'];
      if (data is List) {
        _exerciseTypes = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Silently ignore — exercise types list is auxiliary
    }
  }

  Future<void> addRecord(Map<String, dynamic> body) async {
    try {
      await ApiService.post('/exercise/records', body);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await ApiService.delete('/exercise/records/$id');
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
