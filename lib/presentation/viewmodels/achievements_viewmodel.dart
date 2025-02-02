// import 'package:flutter/foundation.dart';
// import '../../domain/entities/achievement.dart';
// import '../../domain/repository/achievements_repository.dart';
//
// class AchievementsViewModel extends ChangeNotifier {
//   final AchievementsRepository? _achievementsRepository;
//   final String _userId;
//
//   List<Achievement> _achievements = [];
//   List<Achievement> _unlockedAchievements = [];
//   bool _isLoading = false;
//   String? _error;
//   bool _isInitialized = false;
//
//   AchievementsViewModel(this._achievementsRepository, this._userId);
//
//   // Getters
//   List<Achievement> get achievements => _achievements;
//   List<Achievement> get unlockedAchievements => _unlockedAchievements;
//   bool get isLoading => _isLoading;
//   String? get error => _error;
//   bool get isInitialized => _isInitialized && _achievementsRepository != null;
//
//   int get totalAchievements => _achievements.length;
//   int get unlockedCount => _unlockedAchievements.length;
//   double get completionPercentage =>
//       totalAchievements > 0 ? (unlockedCount / totalAchievements) * 100 : 0;
//
//   Future<void> initialize() async {
//     if (_achievementsRepository == null || _userId.isEmpty) return;
//     await _loadAchievements();
//     _isInitialized = true;
//     notifyListeners();
//   }
//
//   void clear() {
//     _achievements = [];
//     _unlockedAchievements = [];
//     _error = null;
//     _isLoading = false;
//     _isInitialized = false;
//     notifyListeners();
//   }
//
//   Future<void> _loadAchievements() async {
//     if (_achievementsRepository == null) return;
//
//     _isLoading = true;
//     notifyListeners();
//
//     try {
//       _achievements = await _achievementsRepository!.getUserAchievements(_userId);
//       _unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
//       _error = null;
//     } catch (e) {
//       _error = 'Failed to load achievements: $e';
//       _achievements = [];
//       _unlockedAchievements = [];
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   Future<void> checkAndUnlockAchievement(String achievementId) async {
//     if (_achievementsRepository == null) {
//       _error = 'Service not initialized';
//       notifyListeners();
//       return;
//     }
//
//     try {
//       await _achievementsRepository!.unlockAchievement(_userId, achievementId);
//       await _loadAchievements();
//     } catch (e) {
//       _error = 'Failed to unlock achievement: $e';
//       notifyListeners();
//     }
//   }
//
//   List<Achievement> getAchievementsByType(AchievementType type) {
//     return _achievements.where((a) => a.type == type).toList();
//   }
//
//   Achievement? getMostRecentUnlock() {
//     if (_unlockedAchievements.isEmpty) return null;
//     return _unlockedAchievements.reduce((a, b) =>
//     a.unlockedAt!.isAfter(b.unlockedAt!) ? a : b);
//   }
//
//   Future<void> refreshAchievements() async {
//     if (!isInitialized) {
//       await initialize();
//     } else {
//       await _loadAchievements();
//     }
//   }
//
//   void clearError() {
//     _error = null;
//     notifyListeners();
//   }
//
//   // Helper method to check if specific achievement types are unlocked
//   bool isAchievementTypeUnlocked(AchievementType type) {
//     return _unlockedAchievements.any((a) => a.type == type);
//   }
//
//   // Get progress towards next achievement of a specific type
//   double getProgressTowardsNextAchievement(AchievementType type) {
//     final typeAchievements = getAchievementsByType(type);
//     if (typeAchievements.isEmpty) return 0.0;
//
//     final unlockedCount = typeAchievements.where((a) => a.isUnlocked).length;
//     return unlockedCount / typeAchievements.length;
//   }
// }