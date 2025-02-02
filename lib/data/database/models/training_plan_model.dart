// lib/data/database/models/training_plan_model.dart
import 'dart:convert';
import '../../../domain/entities/training/training_plan.dart';
import '../../../domain/entities/training/training_week.dart';
import '../../../domain/enums/difficulty_level.dart';
import '../../../domain/enums/workout_type.dart';

class TrainingPlanModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final int durationWeeks;
  final DifficultyLevel difficulty;
  final WorkoutType type;
  final String weeks; // JSON string
  final String? imageUrl;
  final String? metadata; // JSON string
  final bool isCustom;
  final bool isTemplate;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? completedDate;
  final String? createdBy;
  final DateTime lastUpdated;

  const TrainingPlanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.durationWeeks,
    required this.difficulty,
    required this.type,
    required this.weeks,
    this.imageUrl,
    this.metadata,
    this.isCustom = false,
    this.isTemplate = false,
    this.isActive = true,
    this.startDate,
    this.completedDate,
    this.createdBy,
    required this.lastUpdated,
  });

  factory TrainingPlanModel.fromMap(Map<String, dynamic> map) {
    return TrainingPlanModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      durationWeeks: map['durationWeeks'] as int,
      difficulty: DifficultyLevel.values.firstWhere(
            (e) => e.toString() == map['difficulty'],
      ),
      type: WorkoutType.values.firstWhere(
            (e) => e.toString() == map['type'],
      ),
      weeks: map['weeks'] as String,
      imageUrl: map['imageUrl'] as String?,
      metadata: map['metadata'] as String?,
      isCustom: (map['isCustom'] as int) == 1,
      isTemplate: (map['isTemplate'] as int) == 1,
      isActive: (map['isActive'] as int) == 1,
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'] as String)
          : null,
      completedDate: map['completedDate'] != null
          ? DateTime.parse(map['completedDate'] as String)
          : null,
      createdBy: map['createdBy'] as String?,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'durationWeeks': durationWeeks,
      'difficulty': difficulty.toString(),
      'type': type.toString(),
      'weeks': weeks,
      'imageUrl': imageUrl,
      'metadata': metadata,
      'isCustom': isCustom ? 1 : 0,
      'isTemplate': isTemplate ? 1 : 0,
      'isActive': isActive ? 1 : 0,
      'startDate': startDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'createdBy': createdBy,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  TrainingPlan toEntity() {
    final weeksList = (jsonDecode(weeks) as List)
        .map((w) => TrainingWeek.fromMap(w))
        .toList();

    return TrainingPlan(
      id: id,
      title: title,
      description: description,
      durationWeeks: durationWeeks,
      difficulty: difficulty,
      weeks: weeksList,
      type: type,
      imageUrl: imageUrl,
      metadata: metadata != null ? jsonDecode(metadata!) : null,
      isCustom: isCustom,
      createdBy: createdBy,
    );
  }

  factory TrainingPlanModel.fromEntity(TrainingPlan entity, String userId) {
    return TrainingPlanModel(
      id: entity.id,
      userId: userId,
      title: entity.title,
      description: entity.description,
      durationWeeks: entity.durationWeeks,
      difficulty: entity.difficulty,
      type: entity.type,
      weeks: jsonEncode(entity.weeks.map((w) => w.toMap()).toList()),
      imageUrl: entity.imageUrl,
      metadata: entity.metadata != null ? jsonEncode(entity.metadata) : null,
      isCustom: entity.isCustom,
      createdBy: entity.createdBy,
      lastUpdated: DateTime.now(),
    );
  }
}

