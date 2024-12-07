import '../entities/achievement.dart';
import '../entities/workout.dart';

class AchievementService {
  final List<Achievement> _achievements = [];

  Future<void> checkWorkoutAchievements(Workout workout) async {
    // Check distance-based achievements
    _achievements
        .where((a) => a.type == AchievementType.totalDistance && !a.isUnlocked)
        .forEach((achievement) {
      if (achievement.checkUnlockCondition(workout.totalDistance)) {
        _unlockAchievement(achievement);
      }
    });

    // Check pace-based achievements
    if (workout.averageSpeed != null) {
      _achievements
          .where((a) => a.type == AchievementType.fastestPace && !a.isUnlocked)
          .forEach((achievement) {
        if (achievement.checkUnlockCondition(workout.averageSpeed!)) {
          _unlockAchievement(achievement);
        }
      });
    }

    // Additional achievement checks can be added here
  }

  Future<void> _unlockAchievement(Achievement achievement) async {
    // Update achievement in database
    final unlockedAchievement = achievement.copyWith(
      unlockedAt: DateTime.now(),
    );

    // TODO: Save to database
    // TODO: Show notification
    // TODO: Update user stats
  }

  Future<List<Achievement>> getUserAchievements(String userId) async {
    // TODO: Implement fetching from database
    return _achievements.where((a) => a.userId == userId).toList();
  }

  Future<List<Achievement>> getUnlockedAchievements(String userId) async {
    return (await getUserAchievements(userId))
        .where((a) => a.isUnlocked)
        .toList();
  }
}