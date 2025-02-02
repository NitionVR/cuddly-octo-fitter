// lib/data/database/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/user.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final DateTime createdAt;
  final DateTime lastLogin;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    required this.createdAt,
    required this.lastLogin,
  });

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt,
      lastLogin: user.lastLogin,
    );
  }

  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return UserModel(
      id: documentId,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      createdAt: parseDateTime(map['createdAt']),
      lastLogin: parseDateTime(map['lastLogin']),
    );
  }
}