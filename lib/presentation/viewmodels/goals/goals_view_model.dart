import 'package:flutter/foundation.dart';
import '../../../domain/entities/goals/fitness_goal.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/goal_type.dart';
import '../../../domain/repository/goals/goals_repository.dart';

class GoalsViewModel extends ChangeNotifier {
  final GoalsRepository? _goalsRepository;
  final String _userId;

  List<FitnessGoal> _activeGoals = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  Stream<List<FitnessGoal>>? _goalsStream;

  GoalsViewModel(this._goalsRepository, this._userId);

  // Getters
  List<FitnessGoal> get activeGoals => _activeGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized && _goalsRepository != null;
  Stream<List<FitnessGoal>>? get goalsStream => _goalsStream;

  Future<void> initialize() async {
    if (_goalsRepository == null || _userId.isEmpty) {
      print('Goals: Cannot initialize - missing dependencies');
      return;
    }

    if (_isInitialized) {
      print('Goals: Already initialized');
      return;
    }

    print('Goals: Starting initialization');
    _setLoading(true);

    try {
      await _loadGoals();
      _setupGoalsStream();
      _isInitialized = true;
      print('Goals: Initialization complete');
    } catch (e) {
      print('Goals: Initialization failed - $e');
      _error = 'Initialization failed: $e';
    } finally {
      _setLoading(false);
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

  void _setupGoalsStream() {
    if (_goalsRepository == null) return;
    _goalsStream = _goalsRepository!.activeGoalsStream(_userId);
  }

  Future<void> _loadGoals() async {
    if (_goalsRepository == null) return;

    try {
      _activeGoals = await _goalsRepository!.getUserGoals(_userId);
      _error = null;
    } catch (e) {
      print('Error loading goals: $e');
      _error = 'Failed to load goals: $e';
      _activeGoals = [];
    }
  }

  Future<void> createGoal({
    required GoalType type,
    required GoalPeriod period,
    required double target,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_goalsRepository == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return;
    }

    _setLoading(true);

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

      await _goalsRepository!.createGoal(goal);
      await _loadGoals();
    } catch (e) {
      _error = 'Failed to create goal: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateGoalProgress(String goalId, double progress) async {
    if (_goalsRepository == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      await _goalsRepository!.updateGoalProgress(_userId, goalId, progress);
      await _loadGoals();
    } catch (e) {
      _error = 'Failed to update goal progress: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    if (_goalsRepository == null) {
      _error = 'Service not initialized';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      await _goalsRepository!.deleteGoal(_userId, goalId);
      _activeGoals.removeWhere((goal) => goal.id == goalId);
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
    if (_goalsRepository == null) return;

    final now = DateTime.now();
    for (var goal in _activeGoals) {
      // Check if goal is expired
      if (goal.endDate.isBefore(now) && !goal.isCompleted) {
        await _goalsRepository!.updateGoal(
          goal.copyWith(
            isActive: false,
            lastUpdated: now,
          ),
        );
        continue;
      }

      // Check if goal is completed
      if (goal.currentProgress >= goal.target && !goal.isCompleted) {
        await _goalsRepository!.updateGoal(
          goal.copyWith(
            isCompleted: true,
            lastUpdated: now,
          ),
        );

        // Trigger achievement if needed
        // You can add achievement logic here
      }
    }

    // Reload goals after updates
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