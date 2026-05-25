import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/display_text.dart';

class GlucoseProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _records = [];
  int _page = 1;
  bool _hasMore = true;
  static const int _pageSize = 20;

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get records => _records;
  bool get hasMore => _hasMore;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _records = [];
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.get(
        '/glucose/records',
        query: {'page': '$_page', 'size': '$_pageSize'},
      );
      final data = resp['data'];
      final List<dynamic> items;
      if (data is List) {
        items = data;
      } else if (data is Map && data['records'] is List) {
        items = data['records'] as List<dynamic>;
      } else if (data is Map && data['content'] is List) {
        items = data['content'] as List<dynamic>;
      } else {
        items = [];
      }
      final parsed = items
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (refresh) {
        _records = parsed;
      } else {
        _records = [..._records, ...parsed];
      }
      _hasMore = parsed.length >= _pageSize;
      _page++;
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

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    await load();
  }

  Future<void> addRecord(Map<String, dynamic> body) async {
    try {
      await ApiService.post('/glucose/records', body);
      await load(refresh: true);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteRecord(int id) async {
    try {
      await ApiService.delete('/glucose/records/$id');
      await load(refresh: true);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
