import '../entities/achievement.dart';

abstract class AchievementsRepository {
  Future<List<Achievement>> getUserAchievements(String userId);
  Future<void> unlockAchievement(String userId, String achievementId);
  Future<List<Achievement>> getUnlockedAchievements(String userId);
  Future<void> createAchievement(Achievement achievement);
  Stream<List<Achievement>> achievementsStream(String userId);
}