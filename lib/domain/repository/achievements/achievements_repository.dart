//
import '../../entities/achievement.dart';


abstract class IAchievementsRepository {
  Future<List<Achievement>> getUserAchievements(String userId);
  Future<void> unlockAchievement(String userId, String achievementId);
  Future<List<Achievement>> getUnlockedAchievements(String userId);
  Future<void> createAchievement(Achievement achievement);
  Stream<List<Achievement>> achievementsStream(String userId);
  Future<void> syncAchievements(String userId); // Optional: Add if you want sync functionality
}