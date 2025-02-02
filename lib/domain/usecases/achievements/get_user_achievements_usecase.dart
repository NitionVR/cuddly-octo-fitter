// lib/domain/usecases/achievements/get_user_achievements_usecase.dart
import '../../entities/achievement.dart';
import '../../repository/achievements/achievements_repository.dart';


class GetUserAchievementsUseCase {
  final IAchievementsRepository _repository;

  GetUserAchievementsUseCase(this._repository);

  Future<List<Achievement>> call(String userId) async {
    return await _repository.getUserAchievements(userId);
  }
}

// lib/domain/usecases/achievements/unlock_achievement_usecase.dart
class UnlockAchievementUseCase {
  final IAchievementsRepository _repository;

  UnlockAchievementUseCase(this._repository);

  Future<void> call(String userId, String achievementId) async {
    await _repository.unlockAchievement(userId, achievementId);
  }
}

// lib/domain/usecases/achievements/get_unlocked_achievements_usecase.dart
class GetUnlockedAchievementsUseCase {
  final IAchievementsRepository _repository;

  GetUnlockedAchievementsUseCase(this._repository);

  Future<List<Achievement>> call(String userId) async {
    return await _repository.getUnlockedAchievements(userId);
  }
}

// lib/domain/usecases/achievements/create_achievement_usecase.dart
class CreateAchievementUseCase {
  final IAchievementsRepository _repository;

  CreateAchievementUseCase(this._repository);

  Future<void> call(Achievement achievement) async {
    await _repository.createAchievement(achievement);
  }
}

// lib/domain/usecases/achievements/watch_achievements_usecase.dart
class WatchAchievementsUseCase {
  final IAchievementsRepository _repository;

  WatchAchievementsUseCase(this._repository);

  Stream<List<Achievement>> call(String userId) {
    return _repository.achievementsStream(userId);
  }
}

// lib/domain/usecases/achievements/sync_achievements_usecase.dart
class SyncAchievementsUseCase {
  final IAchievementsRepository _repository;

  SyncAchievementsUseCase(this._repository);

  Future<void> call(String userId) async {
    await _repository.syncAchievements(userId);
  }
}

// lib/domain/usecases/achievements/check_achievement_progress_usecase.dart
class CheckAchievementProgressUseCase {
  final IAchievementsRepository _repository;

  CheckAchievementProgressUseCase(this._repository);

  Future<void> call({
    required String userId,
    required AchievementType type,
    required double value,
  }) async {
    final achievements = await _repository.getUserAchievements(userId);

    final eligibleAchievements = achievements.where((achievement) =>
    achievement.type == type &&
        !achievement.isUnlocked &&
        achievement.checkUnlockCondition(value));

    for (var achievement in eligibleAchievements) {
      await _repository.unlockAchievement(userId, achievement.id);
    }
  }
}

// lib/domain/usecases/achievements/get_achievement_stats_usecase.dart
class GetAchievementStatsUseCase {
  final IAchievementsRepository _repository;

  GetAchievementStatsUseCase(this._repository);

  Future<AchievementStats> call(String userId) async {
    final allAchievements = await _repository.getUserAchievements(userId);
    final unlockedAchievements = allAchievements.where((a) => a.isUnlocked).toList();

    return AchievementStats(
      totalAchievements: allAchievements.length,
      unlockedAchievements: unlockedAchievements.length,
      completionPercentage: allAchievements.isEmpty
          ? 0
          : (unlockedAchievements.length / allAchievements.length) * 100,
      recentlyUnlocked: unlockedAchievements
          .where((a) => a.isNew)
          .toList(),
    );
  }
}

// lib/domain/models/achievement_stats.dart
class AchievementStats {
  final int totalAchievements;
  final int unlockedAchievements;
  final double completionPercentage;
  final List<Achievement> recentlyUnlocked;

  AchievementStats({
    required this.totalAchievements,
    required this.unlockedAchievements,
    required this.completionPercentage,
    required this.recentlyUnlocked,
  });
}