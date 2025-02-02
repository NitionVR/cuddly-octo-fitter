import 'package:flutter/foundation.dart';
import '../../../data/database/providers/database_provider.dart';
import '../../../domain/entities/goals/fitness_goal.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/goal_type.dart';
import '../../../domain/repository/goals/goals_repository.dart';


class GoalsViewModel extends ChangeNotifier {
  final IGoalsRepository _goalsRepository;
  final DatabaseProvider _databaseProvider;
  final String _userId;

  List<FitnessGoal> _activeGoals = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  Stream<List<FitnessGoal>>? _goalsStream;

  GoalsViewModel(
      this._goalsRepository,
      this._databaseProvider,
      this._userId,
      );

  // Getters
  List<FitnessGoal> get activeGoals => _activeGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  Stream<List<FitnessGoal>>? get goalsStream => _goalsStream;

  Future<void> initialize() async {
    if (_userId.isEmpty) {
      _error = 'Cannot initialize - missing user ID';
      return;
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('Goals: Already initialized');
      }
      return;
    }

    if (kDebugMode) {
      print('Goals: Starting initialization');
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
        print('Goals: Initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Goals: Initialization failed - $e');
      }
      _error = 'Initialization failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeInternal() async {
    // Load goals first
    await _loadGoals();

    // Setup stream without notifying
    _setupGoalsStreamInternal();

    // Sync with cloud
    await _syncGoals();
  }

  void _setupGoalsStreamInternal() {
    _goalsStream = _goalsRepository.activeGoalsStream(_userId);
    _goalsStream?.listen(
          (goals) {
        _activeGoals = goals;
        notifyListeners();
      },
      onError: (error) {
        _error = 'Stream error: $error';
        notifyListeners();
      },
    );
  }


  Future<void> _syncGoals() async {
    try {
      await _databaseProvider.syncService.syncGoals();
    } catch (e) {
      if (kDebugMode) {
        print('Goals sync failed: $e');
      }
      // Don't throw - sync failure shouldn't stop initialization
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void clear() {
    _activeGoals = [];
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    _goalsStream = null;
    notifyListeners();
  }


  Future<void> _loadGoals() async {
    try {
      _activeGoals = await _goalsRepository.getUserGoals(_userId);
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading goals: $e');
      }
      _error = 'Failed to load goals: $e';
      _activeGoals = [];
      rethrow;
    }
  }

  Future<void> createGoal({
    required GoalType type,
    required GoalPeriod period,
    required double target,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final goal = FitnessGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId,
        type: type,
        period: period,
        target: target,
        startDate: startDate,
        endDate: endDate,
        lastUpdated: DateTime.now(),
      );

      await _goalsRepository.createGoal(goal);
      await _syncGoals();
      await _loadGoals(); // Reload goals after creation

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create goal: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGoalProgress(String goalId, double progress) async {
    _setLoading(true);

    try {
      await _goalsRepository.updateGoalProgress(_userId, goalId, progress);
      await _syncGoals(); // Sync after update
    } catch (e) {
      _error = 'Failed to update goal progress: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    _setLoading(true);

    try {
      await _goalsRepository.deleteGoal(_userId, goalId);
      _activeGoals.removeWhere((goal) => goal.id == goalId);
      await _syncGoals(); // Sync after deletion
    } catch (e) {
      _error = 'Failed to delete goal: $e';
    } finally {
      _setLoading(false);
    }
  }


  Future<void> refreshGoals() async {
    if (!isInitialized) {
      await initialize();
    } else {
      _setLoading(true);
      try {
        await _loadGoals();
        await _syncGoals(); // Sync on refresh
      } finally {
        _setLoading(false);
      }
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Helper methods
  List<FitnessGoal> getGoalsByType(GoalType type) {
    return _activeGoals.where((goal) => goal.type == type).toList();
  }

  List<FitnessGoal> getGoalsByPeriod(GoalPeriod period) {
    return _activeGoals.where((goal) => goal.period == period).toList();
  }

  double getCompletionRate() {
    if (_activeGoals.isEmpty) return 0.0;
    final completed = _activeGoals.where((goal) =>
    goal.currentProgress >= goal.target).length;
    return completed / _activeGoals.length;
  }

  Future<void> checkAndUpdateGoals() async {
    final now = DateTime.now();
    for (var goal in _activeGoals) {
      // Check if goal is expired
      if (goal.endDate.isBefore(now) && !goal.isCompleted) {
        await _goalsRepository.updateGoal(
          goal.copyWith(
            isActive: false,
            lastUpdated: now,
          ),
        );
        continue;
      }

      // Check if goal is completed
      if (goal.currentProgress >= goal.target && !goal.isCompleted) {
        await _goalsRepository.updateGoal(
          goal.copyWith(
            isCompleted: true,
            lastUpdated: now,
          ),
        );
      }
    }

    // Sync after batch updates
    await _syncGoals();
    await _loadGoals();
  }

  Map<String, double> getProgressSummary() {
    return {
      'distance': _getTypeProgress(GoalType.distance),
      'duration': _getTypeProgress(GoalType.duration),
      'frequency': _getTypeProgress(GoalType.frequency),
    };
  }

  double _getTypeProgress(GoalType type) {
    final goals = getGoalsByType(type);
    if (goals.isEmpty) return 0.0;

    return goals.map((g) => g.progressPercentage).reduce((a, b) => a + b) / goals.length;
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}