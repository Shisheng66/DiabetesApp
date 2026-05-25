import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _loading = true;
  bool _signedIn = false;
  String? _error;

  bool get loading => _loading;
  bool get signedIn => _signedIn;
  String? get error => _error;

  Future<void> bootstrap() async {
    try {
      _signedIn = await AuthService.loadSavedToken().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
    } catch (e) {
      _signedIn = false;
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> login(Map<String, dynamic> json) async {
    await AuthService.saveLoginResult(json);
    _signedIn = true;
    _error = null;
    notifyListeners();
    return true;
  }

  Future<void> logout({bool revokeRemote = true}) async {
    await AuthService.logout(revokeRemote: revokeRemote);
    _signedIn = false;
    notifyListeners();
  }

  void setSignedIn(bool value) {
    _signedIn = value;
    notifyListeners();
  }
}
