import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:study_deck/models/admin_user_model.dart';
import 'package:study_deck/services/auth_service.dart';

/// Central state holder for administrator session.
/// Allows dynamic elevation of privileges across the shared UI without page redirects.
class AdminSession extends ChangeNotifier {
  AdminSession({
    AuthService? authService,
  }) : _authService = authService ?? AuthService() {
    _init();
  }

  static AdminSession? _instance;
  static AdminSession get instance => _instance ??= AdminSession();

  final AuthService _authService;
  AdminUserModel? _currentAdmin;
  bool _isLoading = true;

  AdminUserModel? get currentAdmin => _currentAdmin;
  bool get isAdmin => _currentAdmin != null && _currentAdmin!.isAdmin;
  bool get isLoading => _isLoading;

  Future<void> _init() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final profile = await _authService.checkAdminStatus(user.uid);
        _currentAdmin = profile;
      } else {
        _currentAdmin = null;
      }
    } catch (e, st) {
      developer.log('Error initializing AdminSession', error: e, stackTrace: st);
      _currentAdmin = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes the admin status for the current Firebase user.
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    await _init();
  }

  /// Signs in an administrator and updates the session in-place.
  Future<AdminUserModel> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final adminUser = await _authService.signInAdmin(
        email: email,
        password: password,
      );
      _currentAdmin = adminUser;
      _isLoading = false;
      notifyListeners();
      return adminUser;
    } catch (e) {
      _currentAdmin = null;
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sets an explicit admin profile (used when login screen succeeds).
  void setAdmin(AdminUserModel? adminUser) {
    _currentAdmin = adminUser;
    _isLoading = false;
    notifyListeners();
  }

  /// Signs out the administrator and returns the application to student mode.
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (e, st) {
      developer.log('Error during signOut in AdminSession', error: e, stackTrace: st);
    } finally {
      _currentAdmin = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Inherited notifier to give the widget tree access to [AdminSession].
class AdminSessionScope extends InheritedNotifier<AdminSession> {
  const AdminSessionScope({
    super.key,
    required AdminSession session,
    required super.child,
  }) : super(notifier: session);

  static AdminSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdminSessionScope>();
    return scope?.notifier ?? AdminSession.instance;
  }
}
