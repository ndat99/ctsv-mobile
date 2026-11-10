import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_service.dart';
import '../data/auth_user.dart';

enum AuthStatus { restoring, signedOut, signedIn, restoreFailed }

class AuthController extends ChangeNotifier {
  AuthController(this.service) {
    service.onSessionExpired = () {
      user = null;
      status = AuthStatus.signedOut;
      message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
      _notify();
    };
  }

  final AuthService service;
  AuthStatus status = AuthStatus.restoring;
  AuthUser? user;
  bool busy = false;
  String? message;
  bool _disposed = false;

  Future<void> restore() async {
    if (busy) return;
    busy = true;
    status = AuthStatus.restoring;
    message = null;
    _notify();
    try {
      user = await service.restore();
      status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    } catch (error) {
      status = AuthStatus.restoreFailed;
      message = authErrorMessage(error);
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> login(String username, String password) async {
    if (busy) return false;
    busy = true;
    message = null;
    _notify();
    try {
      user = await service.login(username, password);
      status = AuthStatus.signedIn;
      return true;
    } catch (error) {
      user = null;
      status = AuthStatus.signedOut;
      message = authErrorMessage(error);
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> logout() async {
    if (busy) return;
    busy = true;
    message = null;
    _notify();
    try {
      final warning = await service.logout();
      user = null;
      status = AuthStatus.signedOut;
      message = warning;
    } catch (error) {
      message = authErrorMessage(error);
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    service.onSessionExpired = null;
    service.close();
    super.dispose();
  }
}
