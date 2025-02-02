// lib/data/database/models/goals_model.dart
import '../../../domain/entities/goals/fitness_goal.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/goal_type.dart';

class GoalsModel {
  final String id;
  final String userId;
  final GoalType type;
  final GoalPeriod period;
  final double target;
  final double currentProgress;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final DateTime lastUpdated;
  final bool isActive;

  const GoalsModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.period,
    required this.target,
    required this.currentProgress,
    required this.startDate,
    required this.endDate,
    required this.isCompleted,
    required this.lastUpdated,
    required this.isActive,
  });

  // Create from database map
  factory GoalsModel.fromMap(Map<String, dynamic> map) {
    return GoalsModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      type: GoalType.values.firstWhere(
            (e) => e.toString() == map['type'],
      ),
      period: GoalPeriod.values.firstWhere(
            (e) => e.toString() == map['period'],
      ),
      target: map['target'] as double,
      currentProgress: map['currentProgress'] as double? ?? 0.0,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      isCompleted: (map['isCompleted'] as int) == 1,
      lastUpdated: DateTime.parse(map['lastUpdated'] as String),
      isActive: (map['isActive'] as int) == 1,
    );
  }

  // Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString(),
      'period': period.toString(),
      'target': target,
      'currentProgress': currentProgress,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  // Convert to domain entity
  FitnessGoal toEntity() {
    return FitnessGoal(
      id: id,
      userId: userId,
      type: type,
      period: period,
      target: target,
      currentProgress: currentProgress,
      startDate: startDate,
      endDate: endDate,
      isCompleted: isCompleted,
      lastUpdated: lastUpdated,
      isActive: isActive,
    );
  }

  // Create from domain entity
  factory GoalsModel.fromEntity(FitnessGoal entity) {
    return GoalsModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      period: entity.period,
      target: entity.target,
      currentProgress: entity.currentProgress,
      startDate: entity.startDate,
      endDate: entity.endDate,
      isCompleted: entity.isCompleted,
      lastUpdated: entity.lastUpdated,
      isActive: entity.isActive,
    );
  }

  GoalsModel copyWith({
    String? id,
    String? userId,
    GoalType? type,
    GoalPeriod? period,
    double? target,
    double? currentProgress,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return GoalsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      period: period ?? this.period,
      target: target ?? this.target,
      currentProgress: currentProgress ?? this.currentProgress,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GoalsModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              userId == other.userId &&
              type == other.type &&
              period == other.period &&
              target == target &&
              currentProgress == currentProgress &&
              startDate == startDate &&
              endDate == endDate &&
              isCompleted == isCompleted &&
              lastUpdated == lastUpdated &&
              isActive == isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      type.hashCode ^
      period.hashCode ^
      target.hashCode ^
      currentProgress.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      isCompleted.hashCode ^
      lastUpdated.hashCode ^
      isActive.hashCode;

  @override
  String toString() {
    return 'GoalsModel('
        'id: $id, '
        'userId: $userId, '
        'type: $type, '
        'period: $period, '
        'target: $target, '
        'currentProgress: $currentProgress, '
        'startDate: $startDate, '
        'endDate: $endDate, '
        'isCompleted: $isCompleted, '
        'lastUpdated: $lastUpdated, '
        'isActive: $isActive)';
  }
}