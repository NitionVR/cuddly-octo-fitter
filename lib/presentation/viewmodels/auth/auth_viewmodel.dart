import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repository/auth/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  User? _currentUser;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<User?>? _authStateSubscription;

  AuthViewModel(this._authRepository) {
    _init();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  void _init() async {
    _authStateSubscription = _authRepository.authStateChanges.listen(
          (user) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print('Auth state error: $error');
        }
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );

    try {
      _currentUser = await _authRepository.getCurrentUser();
    } catch (e) {
      if (kDebugMode) {
        print('Init current user error: $e');
      }
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInWithEmail(email, password);
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('Sign in error: $e');
      }
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signUpWithEmail(email, password);
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('Sign up error: $e');
      }
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.resetPassword(email);
    } catch (e) {
      if (kDebugMode) {
        print('Reset password error: $e');
      }
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}