// lib/domain/entities/fitness_goal.dart
class FitnessGoal {
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

  FitnessGoal({
    required this.id,
    required this.userId,
    required this.type,
    required this.period,
    required this.target,
    this.currentProgress = 0.0,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    required this.lastUpdated,
    this.isActive = true,
  });

  double get progressPercentage =>
      (currentProgress / target * 100).clamp(0, 100);

  bool get isExpired => endDate.isBefore(DateTime.now());

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
      'isCompleted': isCompleted,
      'lastUpdated': lastUpdated.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory FitnessGoal.fromMap(Map<String, dynamic> map) {
    return FitnessGoal(
      id: map['id'],
      userId: map['userId'],
      type: GoalType.values.firstWhere(
            (e) => e.toString() == map['type'],
      ),
      period: GoalPeriod.values.firstWhere(
            (e) => e.toString() == map['period'],
      ),
      target: map['target'],
      currentProgress: map['currentProgress'] ?? 0.0,
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isCompleted: map['isCompleted'] ?? false,
      lastUpdated: DateTime.parse(map['lastUpdated']),
      isActive: map['isActive'] ?? true,
    );
  }

  FitnessGoal copyWith({
    String? id, // Added id parameter
    String? userId, // Added userId parameter
    GoalType? type, // Added type parameter
    GoalPeriod? period, // Added period parameter
    double? target, // Added target parameter
    double? currentProgress,
    DateTime? startDate, // Added startDate parameter
    DateTime? endDate, // Added endDate parameter
    bool? isCompleted,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return FitnessGoal(
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
}

enum GoalType {
  distance,    // Total distance (km)
  duration,    // Total time (minutes)
  frequency,   // Number of workouts
  calories,    // Calories burned
  pace        // Target pace (min/km)
}

enum GoalPeriod {
  daily,
  weekly,
  monthly,
  custom
}