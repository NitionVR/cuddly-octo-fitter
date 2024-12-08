class Achievement {
  final String id;
  final String userId;
  final String title;
  final String description;
  final AchievementType type;
  final double threshold;
  final DateTime? unlockedAt;
  final String? iconUrl;
  final Map<String, dynamic>? metadata;

  Achievement({
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

  bool get isUnlocked => unlockedAt != null;

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

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      type: AchievementType.values.firstWhere(
            (e) => e.toString() == map['type'],
      ),
      threshold: map['threshold'],
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'])
          : null,
      iconUrl: map['iconUrl'],
      metadata: map['metadata'],
    );
  }

  Achievement copyWith({
    DateTime? unlockedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id,
      userId: userId,
      title: title,
      description: description,
      type: type,
      threshold: threshold,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      iconUrl: iconUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to check if achievement should be unlocked
  bool checkUnlockCondition(double value) {
    return value >= threshold && !isUnlocked;
  }
}

enum AchievementType {
  totalDistance,      // Total distance covered
  totalWorkouts,      // Total number of workouts
  longestWorkout,     // Longest single workout
  fastestPace,        // Fastest pace achieved
  streakDays,         // Consecutive days with workouts
  elevationGain,      // Total elevation gained
  specialEvent,       // Special achievements (holidays, challenges)
  milestone          // Custom milestones
}

// Achievement Templates
class AchievementTemplates {
  static Achievement createDistanceAchievement({
    required String userId,
    required double distanceKm,
    String? customTitle,
    String? customDescription,
  }) {
    return Achievement(
      id: 'distance_${distanceKm.toInt()}',
      userId: userId,
      title: customTitle ?? '${distanceKm.toInt()}km Club',
      description: customDescription ??
          'Run a total of ${distanceKm.toInt()}km',
      type: AchievementType.totalDistance,
      threshold: distanceKm,
    );
  }

  static Achievement createStreakAchievement({
    required String userId,
    required int days,
    String? customTitle,
    String? customDescription,
  }) {
    return Achievement(
      id: 'streak_$days',
      userId: userId,
      title: customTitle ?? '$days Day Streak',
      description: customDescription ??
          'Complete workouts for $days consecutive days',
      type: AchievementType.streakDays,
      threshold: days.toDouble(),
    );
  }

}