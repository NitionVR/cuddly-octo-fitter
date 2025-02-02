import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/database/providers/database_provider.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repository/auth/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final DatabaseProvider _databaseProvider;
  User? _currentUser;
  bool _isLoading = true;
  String? _error;
  StreamSubscription<User?>? _authStateSubscription;
  bool _isInitialized = false;

  AuthViewModel(this._authRepository, this._databaseProvider) {
    _initialize();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _currentUser = await _authRepository.getCurrentUser();

      _authStateSubscription = _authRepository.authStateChanges.listen(
            (user) async {
          final previousUser = _currentUser;
          _currentUser = user;

          // Handle user state changes
          if (previousUser?.id != user?.id) {
            if (user != null) {
              // New user logged in - start sync
              await _handleUserLogin(user);
            } else {
              // User logged out - clean up
              await _handleUserLogout(previousUser?.id);
            }
          }

          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = _getReadableError(error.toString());
          _isLoading = false;
          notifyListeners();
        },
      );

    } catch (e) {
      _error = _getReadableError(e.toString());
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _handleUserLogin(User user) async {
    try {
      // Start sync service
      await _databaseProvider.syncService.syncAll();
    } catch (e) {
      if (kDebugMode) {
        print('Error during login sync: $e');
      }
    }
  }

  Future<void> _handleUserLogout(String? userId) async {
    try {
      if (userId != null) {
        // Clean up local data
        await _databaseProvider.clearAllData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout cleanup: $e');
      }
    }
  }


  Future<void> signInWithEmail(String email, String password) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _authRepository.signInWithEmail(email, password);

      // Verify authentication state
      await Future.delayed(const Duration(milliseconds: 300));
      final verifiedUser = await _authRepository.getCurrentUser();

      if (verifiedUser == null) {
        throw Exception('Authentication failed');
      }

      _currentUser = verifiedUser;

      // Initial sync after login
      await _handleUserLogin(verifiedUser);

    } catch (e) {
      _error = _getReadableError(e.toString());
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getReadableError(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email';
    }
    if (error.contains('wrong-password')) {
      return 'Incorrect password';
    }
    if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }
    return 'Unable to sign in. Please try again';
  }

  Future<void> signUpWithEmail(String email, String password) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _currentUser = await _authRepository.signUpWithEmail(email, password);

      // Verify authentication state
      await Future.delayed(const Duration(milliseconds: 300));
      final verifiedUser = await _authRepository.getCurrentUser();

      if (verifiedUser == null) {
        throw Exception('Registration failed');
      }

      _currentUser = verifiedUser;

    } catch (e) {
      _error = _getSignUpError(e.toString());
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Add this method for signup-specific error messages
  String _getSignUpError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    }
    if (error.contains('invalid-email')) {
      return 'Please enter a valid email address';
    }
    if (error.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password';
    }
    if (error.contains('operation-not-allowed')) {
      return 'Unable to register at this time. Please try again later';
    }
    if (error.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later';
    }
    if (error.contains('network-request-failed')) {
      return 'Network error. Please check your connection and try again';
    }
    return 'Unable to create account. Please try again';
  }


  Future<void> signOut() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _currentUser?.id;
      await _authRepository.signOut();

      // Clean up after sign out
      await _handleUserLogout(userId);

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