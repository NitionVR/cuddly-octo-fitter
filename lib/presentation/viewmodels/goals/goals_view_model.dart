// lib/presentation/viewmodels/goals_view_model.dart
import 'package:flutter/foundation.dart';
import '../../domain/entities/goals/fitness_goal.dart';
import '../../domain/repository/goals_repository.dart';

class GoalsViewModel extends ChangeNotifier {
  final GoalsRepository _goalsRepository;
  final String userId;

  List<FitnessGoal> _activeGoals = [];
  bool _isLoading = false;
  String? _error;

  GoalsViewModel(this._goalsRepository, this.userId) {
    _initializeGoals();
  }

  List<FitnessGoal> get activeGoals => _activeGoals;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _initializeGoals() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeGoals = await _goalsRepository.getUserGoals(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load goals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createGoal({
    required GoalType type,
    required GoalPeriod period,
    required double target,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final goal = FitnessGoal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        period: period,
        target: target,
        startDate: startDate,
        endDate: endDate,
        lastUpdated: DateTime.now(),
      );

      await _goalsRepository.createGoal(goal);
      await _initializeGoals();
    } catch (e) {
      _error = 'Failed to create goal: $e';
      notifyListeners();
    }
  }

  Future<void> updateGoalProgress(String goalId, double progress) async {
    try {
      await _goalsRepository.updateGoalProgress(goalId, progress);
      await _initializeGoals();
    } catch (e) {
      _error = 'Failed to update goal progress: $e';
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _goalsRepository.deleteGoal(goalId);
      _activeGoals.removeWhere((goal) => goal.id == goalId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete goal: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}