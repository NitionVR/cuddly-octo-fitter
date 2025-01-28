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
  bool _isInitialized = false;

  AuthViewModel(this._authRepository) {
    _initialize();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      // First check current user
      _currentUser = await _authRepository.getCurrentUser();

      // Then set up auth state listener
      _authStateSubscription = _authRepository.authStateChanges.listen(
            (user) {
          if (kDebugMode) {
            print('Auth state changed: ${user?.id}');
          }
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

    } catch (e) {
      if (kDebugMode) {
        print('Initialization error: $e');
      }
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('Attempting sign in with email: $email');
      }

      _currentUser = await _authRepository.signInWithEmail(email, password);

      if (kDebugMode) {
        print('Sign in successful. User: ${_currentUser?.id}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Sign in error in ViewModel: $e');
      }
      _error = e.toString();
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('Attempting sign up with email: $email');
      }

      _currentUser = await _authRepository.signUpWithEmail(email, password);

      if (kDebugMode) {
        print('Sign up successful. User: ${_currentUser?.id}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Sign up error in ViewModel: $e');
      }
      _error = e.toString();
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authRepository.signOut();
      _currentUser = null;

      if (kDebugMode) {
        print('Sign out successful');
      }

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
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authRepository.resetPassword(email);

      if (kDebugMode) {
        print('Password reset email sent to: $email');
      }

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

  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Refresh user error: $e');
      }
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}