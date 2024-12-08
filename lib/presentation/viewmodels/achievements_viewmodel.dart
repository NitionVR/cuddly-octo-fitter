import 'package:flutter/foundation.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/repository/achievements_repository.dart';

class AchievementsViewModel extends ChangeNotifier {
  final AchievementsRepository _achievementsRepository;
  final String userId;

  List<Achievement> _achievements = [];
  List<Achievement> _unlockedAchievements = [];
  bool _isLoading = false;
  String? _error;

  AchievementsViewModel(this._achievementsRepository, this.userId) {
    _initializeAchievements();
  }

  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _unlockedAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalAchievements => _achievements.length;
  int get unlockedCount => _unlockedAchievements.length;
  double get completionPercentage =>
      totalAchievements > 0 ? (unlockedCount / totalAchievements) * 100 : 0;

  Future<void> _initializeAchievements() async {
    _isLoading = true;
    notifyListeners();

    try {
      _achievements = await _achievementsRepository.getUserAchievements(userId);
      _unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load achievements: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkAndUnlockAchievement(String achievementId) async {
    try {
      await _achievementsRepository.unlockAchievement(userId, achievementId);
      await _initializeAchievements();
    } catch (e) {
      _error = 'Failed to unlock achievement: $e';
      notifyListeners();
    }
  }

  List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievements.where((a) => a.type == type).toList();
  }

  Achievement? getMostRecentUnlock() {
    if (_unlockedAchievements.isEmpty) return null;
    return _unlockedAchievements.reduce((a, b) =>
    a.unlockedAt!.isAfter(b.unlockedAt!) ? a : b);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}