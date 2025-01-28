import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../entities/user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<User> signInWithEmail(String email, String password) async {
    try {
      print('Starting sign in process for: $email');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('No user found');
      }

      print('Firebase Auth successful. UID: ${credential.user!.uid}');

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        final now = DateTime.now();
        final nowStr = now.toIso8601String();

        if (!userDoc.exists) {
          print('Creating new user document');
          final newUserData = {
            'email': email,
            'displayName': null,
            'createdAt': nowStr,
            'lastLogin': nowStr,
          };

          await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .set(newUserData);

          return User(
            id: credential.user!.uid,
            email: email,
            displayName: null,
            createdAt: now,
            lastLogin: now,
          );
        }

        print('Updating existing user');
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .update({'lastLogin': nowStr});

        final userData = userDoc.data()!;
        return User(
          id: credential.user!.uid,
          email: email,
          displayName: userData['displayName'] as String?,
          createdAt: DateTime.parse(userData['createdAt'] as String),
          lastLogin: now,
        );

      } on FirebaseException catch (e) {
        print('Firestore error: ${e.code} - ${e.message}');
        // Return basic user if Firestore fails
        return User(
          id: credential.user!.uid,
          email: email,
          displayName: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }

    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('General Exception: $e');
      throw Exception('Authentication failed');
    }
  }

  @override
  Future<User> signUpWithEmail(String email, String password) async {
    try {
      print('Starting sign up process for: $email');

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      final now = DateTime.now();
      final nowStr = now.toIso8601String();

      final userData = {
        'email': email,
        'displayName': null,
        'createdAt': nowStr,
        'lastLogin': nowStr,
      };

      try {
        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData);

        print('User document created successfully');

        return User(
          id: credential.user!.uid,
          email: email,
          displayName: null,
          createdAt: now,
          lastLogin: now,
        );
      } on FirebaseException catch (e) {
        print('Firestore error during signup: ${e.code} - ${e.message}');
        // Return basic user if Firestore fails
        return User(
          id: credential.user!.uid,
          email: email,
          displayName: null,
          createdAt: now,
          lastLogin: now,
        );
      }
    } catch (e) {
      print('Sign up error: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) {
        print('Auth state change: No user');
        return null;
      }

      print('Auth state change: User authenticated ${firebaseUser.uid}');

      // Return basic user information without Firestore access
      return User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: null,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        print('No current user');
        return null;
      }

      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) {
          print('No user document found');
          return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: null,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );
        }

        final userData = userDoc.data()!;
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: userData['displayName'] as String?,
          createdAt: DateTime.parse(userData['createdAt'] as String),
          lastLogin: DateTime.parse(userData['lastLogin'] as String),
        );
      } on FirebaseException catch (e) {
        print('Firestore error: ${e.code} - ${e.message}');
        // Return basic user if Firestore fails
        return User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
      }
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Failed to sign out');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset password error: $e');
      throw _handleAuthError(e);
    }
  }

  Exception _handleAuthError(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return Exception('No user found with this email');
        case 'wrong-password':
          return Exception('Wrong password');
        case 'email-already-in-use':
          return Exception('Email is already registered');
        case 'invalid-email':
          return Exception('Invalid email address');
        case 'weak-password':
          return Exception('Password is too weak');
        case 'operation-not-allowed':
          return Exception('Email/password accounts are not enabled');
        case 'too-many-requests':
          return Exception('Too many attempts. Please try again later');
        default:
          return Exception(e.message ?? 'Authentication failed');
      }
    }
    return Exception('Authentication failed');
  }
}