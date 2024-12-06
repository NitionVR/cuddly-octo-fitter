// lib/data/repositories/firebase_auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
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
      // First sign in with Firebase Auth
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('No user found');
      }

      // Check if user document exists in Firestore
      final userDoc = await _firestore.collection('users').doc(credential.user!.uid).get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final newUser = User(
          id: credential.user!.uid,
          email: email,
          displayName: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );

        await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
        return newUser;
      }

      // Update last login time
      await _updateLastLogin(credential.user!.uid);

      // Return existing user data
      return User.fromMap({
        ...userDoc.data()!,
        'id': credential.user!.uid,
      });
    } catch (e) {
      print('Sign in error: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Future<User> signUpWithEmail(String email, String password) async {
    try {
      // Create auth account
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user data
      final user = User(
        id: credential.user!.uid,
        email: email,
        displayName: null,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      // Create Firestore document
      await _firestore.collection('users').doc(user.id).set(user.toMap());

      print('User document created successfully: ${user.id}');
      return user;
    } catch (e) {
      print('Sign up error: $e');
      throw _handleAuthError(e);
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (!userDoc.exists) {
          // Create user document if it doesn't exist
          final newUser = User(
            id: firebaseUser.uid,
            email: firebaseUser.email!,
            displayName: null,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
          return newUser;
        }

        return User.fromMap({
          ...userDoc.data()!,
          'id': firebaseUser.uid,
        });
      } catch (e) {
        print('Auth state change error: $e');
        return null;
      }
    });
  }

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        return null;
      }

      return User.fromMap({
        ...userDoc.data()!,
        'id': firebaseUser.uid,
      });
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }


  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }


  Future<User> _getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        throw Exception('User document not found');
      }

      final data = doc.data()!;
      // Convert Timestamp to DateTime
      return User.fromMap({
        ...data,
        'id': uid,
      });
    } catch (e) {
      print('Error in _getUser: $e');
      throw Exception('Failed to get user data');
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({'lastLogin': DateTime.now().toIso8601String()});
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
        default:
          return Exception(e.message ?? 'Authentication failed');
      }
    }
    return Exception('Authentication failed');
  }
}