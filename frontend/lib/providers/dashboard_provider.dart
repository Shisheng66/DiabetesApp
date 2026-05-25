import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/display_text.dart';

class DashboardProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  Map<String, dynamic> _data = {};

  bool get loading => _loading;
  String? get error => _error;
  Map<String, dynamic> get data => _data;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await ApiService.get('/dashboard/today');
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
}
