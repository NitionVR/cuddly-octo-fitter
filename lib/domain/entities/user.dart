import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime lastLogin;

  User({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
    required this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  factory User.fromMap(Map<String, dynamic> map, String documentId) {
    try {
      // Handle createdAt
      DateTime createdAtDate;
      if (map['createdAt'] is Timestamp) {
        createdAtDate = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        createdAtDate = DateTime.parse(map['createdAt'] as String);
      } else {
        createdAtDate = DateTime.now();
      }

      // Handle lastLogin
      DateTime lastLoginDate;
      if (map['lastLogin'] is Timestamp) {
        lastLoginDate = (map['lastLogin'] as Timestamp).toDate();
      } else if (map['lastLogin'] is String) {
        lastLoginDate = DateTime.parse(map['lastLogin'] as String);
      } else {
        lastLoginDate = DateTime.now();
      }

      return User(
        id: documentId,
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String?,
        createdAt: createdAtDate,
        lastLogin: lastLoginDate,
      );
    } catch (e) {
      print('Error creating User from map: $e');
      print('Problematic map: $map');
      rethrow;
    }
  }

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, createdAt: $createdAt, lastLogin: $lastLogin)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.createdAt == createdAt &&
        other.lastLogin == lastLogin;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    email.hashCode ^
    displayName.hashCode ^
    createdAt.hashCode ^
    lastLogin.hashCode;
  }
}