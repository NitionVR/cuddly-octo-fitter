// lib/data/database/models/completed_workout_model.dart
class CompletedWorkoutModel {
  final String userId;
  final String weekId;
  final String workoutId;
  final bool completed;
  final DateTime? completedAt;

  const CompletedWorkoutModel({
    required this.userId,
    required this.weekId,
    required this.workoutId,
    required this.completed,
    this.completedAt,
  });

  factory CompletedWorkoutModel.fromMap(Map<String, dynamic> map) {
    return CompletedWorkoutModel(
      userId: map['userId'] as String,
      weekId: map['weekId'] as String,
      workoutId: map['workoutId'] as String,
      completed: (map['completed'] as int) == 1,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'weekId': weekId,
      'workoutId': workoutId,
      'completed': completed ? 1 : 0,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}