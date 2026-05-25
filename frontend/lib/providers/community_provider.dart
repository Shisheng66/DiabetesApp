import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../utils/display_text.dart';

class CommunityProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _posts = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get posts => _posts;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final resp = await ApiService.get('/community/posts');
      final data = resp['data'];
      if (data is List) {
        _posts = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (data is Map && data['records'] is List) {
        _posts = (data['records'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (data is Map && data['content'] is List) {
        _posts = (data['content'] as List)
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

  Future<void> createPost(Map<String, dynamic> body) async {
    try {
      await ApiService.post('/community/posts', body);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleLike(int postId) async {
    try {
      await ApiService.post('/community/posts/$postId/like', null);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int postId) async {
    try {
      await ApiService.post('/community/posts/$postId/favorite', null);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  Future<void> addComment(int postId, Map<String, dynamic> body) async {
    try {
      await ApiService.post('/community/posts/$postId/comments', body);
      await load();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      rethrow;
    }
  }
}
