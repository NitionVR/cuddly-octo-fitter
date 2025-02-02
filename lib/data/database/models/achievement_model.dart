import 'dart:convert';

import '../../../domain/entities/achievement.dart';

class AchievementModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final AchievementType type;
  final double threshold;
  final DateTime? unlockedAt;
  final String? iconUrl;
  final String? metadata; // Stored as JSON string in SQLite

  const AchievementModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.threshold,
    this.unlockedAt,
    this.iconUrl,
    this.metadata,
  });

  // Create from database map
  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      type: AchievementType.values.firstWhere(
            (e) => e.toString() == map['type'],
      ),
      threshold: map['threshold'] as double,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'] as String)
          : null,
      iconUrl: map['iconUrl'] as String?,
      metadata: map['metadata'] as String?,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString(),
      'threshold': threshold,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'iconUrl': iconUrl,
      'metadata': metadata,
    };
  }

  // Convert to domain entity
  Achievement toEntity() {
    return Achievement(
      id: id,
      userId: userId,
      title: title,
      description: description,
      type: type,
      threshold: threshold,
      unlockedAt: unlockedAt,
      iconUrl: iconUrl,
      metadata: metadata != null ? json.decode(metadata!) : null,
    );
  }

  // Create from domain entity
  factory AchievementModel.fromEntity(Achievement entity) {
    return AchievementModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      threshold: entity.threshold,
      unlockedAt: entity.unlockedAt,
      iconUrl: entity.iconUrl,
      metadata: entity.metadata != null ? json.encode(entity.metadata!) : null,
    );
  }

  AchievementModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    AchievementType? type,
    double? threshold,
    DateTime? unlockedAt,
    String? iconUrl,
    String? metadata,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconUrl: iconUrl ?? this.iconUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}