import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/display_text.dart';

class DietProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _mealPlans = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get records => _records;
  List<Map<String, dynamic>> get foods => _foods;
  List<Map<String, dynamic>> get mealPlans => _mealPlans;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.get('/diet/records');
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

  Future<void> loadFoods() async {
    try {
      final resp = await ApiService.get('/diet/foods');
      final data = resp['data'];
      if (data is List) {
        _foods = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        notifyListeners();
      }
    } catch (_) {
      // Silently ignore — foods list is auxiliary
    }
  }

  Future<void> loadMealPlans() async {
    try {
      final resp = await ApiService.get('/diet/meal-plans');
      final data = resp['data'];
      if (data is List) {
        _mealPlans = data
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        notifyListeners();
      }
    } catch (_) {
      // Silently ignore — meal plans list is auxiliary
    }
  }

  Future<void> addRecord(Map<String, dynamic> body) async {
    try {
      await ApiService.post('/diet/records', body);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await ApiService.delete('/diet/records/$id');
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addFood(Map<String, dynamic> body) async {
    try {
      await ApiService.post('/diet/foods', body);
      await loadFoods();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMealPlan(Map<String, dynamic> body) async {
    try {
      await ApiService.post('/diet/meal-plans', body);
      await loadMealPlans();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMealPlan(int id) async {
    try {
      await ApiService.delete('/diet/meal-plans/$id');
      await loadMealPlans();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
