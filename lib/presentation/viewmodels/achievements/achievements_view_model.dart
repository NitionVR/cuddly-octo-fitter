import 'package:flutter/foundation.dart';

import '../../../data/database/providers/database_provider.dart';
import '../../../domain/entities/achievement.dart';
import '../../../domain/repository/achievements/achievements_repository.dart';

class AchievementsViewModel extends ChangeNotifier {
  final IAchievementsRepository _achievementsRepository;
  final DatabaseProvider _databaseProvider;
  final String _userId;

  List<Achievement> _achievements = [];
  List<Achievement> _unlockedAchievements = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  Stream<List<Achievement>>? _achievementsStream;

  AchievementsViewModel(
      this._achievementsRepository,
      this._databaseProvider,
      this._userId,
      );

  // Getters
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _unlockedAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  Stream<List<Achievement>>? get achievementsStream => _achievementsStream;

  int get totalAchievements => _achievements.length;
  int get unlockedCount => _unlockedAchievements.length;
  double get completionPercentage =>
      totalAchievements > 0 ? (unlockedCount / totalAchievements) * 100 : 0;

  Future<void> initialize() async {
    if (_userId.isEmpty) {
      _error = 'Cannot initialize - missing user ID';
      return;
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('Achievements: Already initialized');
      }
      return;
    }

    if (kDebugMode) {
      print('Achievements: Starting initialization');
    }

    _isLoading = true; // Don't notify yet

    try {
      // Perform all initialization steps
      await _initializeInternal();

      _isInitialized = true;
      _isLoading = false;
      _error = null;

      // Notify only once at the end
      notifyListeners();

      if (kDebugMode) {
        print('Achievements: Initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Achievements: Initialization failed - $e');
      }
      _error = 'Initialization failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeInternal() async {
    // Load achievements
    await _loadAchievements();

    // Setup stream without notifying
    _setupAchievementsStreamInternal();

    // Sync with cloud
    await _syncAchievements();
  }

  void _setupAchievementsStreamInternal() {
    _achievementsStream = _achievementsRepository.achievementsStream(_userId);
    _achievementsStream?.listen(
          (achievements) {
        _achievements = achievements;
        _unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
        notifyListeners();
      },
      onError: (error) {
        _error = 'Stream error: $error';
        notifyListeners();
      },
    );
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  Future<void> _syncAchievements() async {
    try {
      await _databaseProvider.syncService.syncAchievements();
    } catch (e) {
      print('Achievements sync failed: $e');
      // Don't throw - sync failure shouldn't stop initialization
    }
  }

  void _setupAchievementsStream() {
    _achievementsStream = _achievementsRepository.achievementsStream(_userId);
    _achievementsStream?.listen(
          (achievements) {
        _achievements = achievements;
        _unlockedAchievements = achievements.where((a) => a.isUnlocked).toList();
        notifyListeners();
      },
      onError: (error) {
        _error = 'Stream error: $error';
        notifyListeners();
      },
    );
  }

  void clear() {
    _achievements = [];
    _unlockedAchievements = [];
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> _loadAchievements() async {
    try {
      _achievements = await _achievementsRepository.getUserAchievements(_userId);
      _unlockedAchievements = _achievements.where((a) => a.isUnlocked).toList();
      _error = null;
    } catch (e) {
      print('Error loading achievements: $e');
      _error = 'Failed to load achievements: $e';
      _achievements = [];
      _unlockedAchievements = [];
    }
  }

  Future<void> checkAndUnlockAchievement(String achievementId) async {
    _setLoading(true);

    try {
      await _achievementsRepository.unlockAchievement(_userId, achievementId);
      await _syncAchievements(); // Sync after unlocking
      await _loadAchievements();
    } catch (e) {
      _error = 'Failed to unlock achievement: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createAchievement(Achievement achievement) async {
    _setLoading(true);

    try {
      await _achievementsRepository.createAchievement(achievement);
      await _syncAchievements(); // Sync after creation
      await _loadAchievements();
    } catch (e) {
      _error = 'Failed to create achievement: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshAchievements() async {
    if (!isInitialized) {
      await initialize();
    } else {
      _setLoading(true);
      try {
        await _loadAchievements();
        await _syncAchievements(); // Sync on refresh
      } finally {
        _setLoading(false);
      }
    }
  }

  // Helper methods
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _achievements.where((a) => a.type == type).toList();
  }

  Achievement? getMostRecentUnlock() {
    if (_unlockedAchievements.isEmpty) return null;
    return _unlockedAchievements.reduce((a, b) =>
    a.unlockedAt!.isAfter(b.unlockedAt!) ? a : b);
  }

  bool isAchievementTypeUnlocked(AchievementType type) {
    return _unlockedAchievements.any((a) => a.type == type);
  }

  double getProgressTowardsNextAchievement(AchievementType type) {
    final typeAchievements = getAchievementsByType(type);
    if (typeAchievements.isEmpty) return 0.0;

    final unlockedCount = typeAchievements.where((a) => a.isUnlocked).length;
    return unlockedCount / typeAchievements.length;
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}