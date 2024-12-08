import 'package:flutter/foundation.dart';
import '../../../domain/entities/training/training_plan.dart';
import '../../../domain/enums/workout_type.dart';
import '../../../domain/repository/training/training_plan_repository.dart';


class TrainingPlanViewModel extends ChangeNotifier {
  final TrainingPlanRepository _repository;
  final String userId;

  List<TrainingPlan> _availablePlans = [];
  TrainingPlan? _activePlan;
  bool _isLoading = false;
  String? _error;

  TrainingPlanViewModel(this._repository, this.userId) {
    _loadPlans();
  }

  List<TrainingPlan> get availablePlans => _availablePlans;
  TrainingPlan? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      _availablePlans = await _repository.getAvailablePlans();
      _activePlan = await _repository.getActivePlan(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load training plans: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startPlan(String planId) async {
    try {
      _activePlan = await _repository.startPlan(userId, planId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start plan: $e';
      notifyListeners();
    }
  }

  Future<void> completePlan() async {
    if (_activePlan == null) return;

    try {
      await _repository.completePlan(userId, _activePlan!.id);
      _activePlan = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to complete plan: $e';
      notifyListeners();
    }
  }

  Future<void> updateWorkoutStatus(String weekId, String workoutId, bool completed) async {
    try {
      await _repository.updateWorkoutStatus(userId, weekId, workoutId, completed);
      await _loadPlans(); // Reload to get updated status
    } catch (e) {
      _error = 'Failed to update workout status: $e';
      notifyListeners();
    }
  }

  List<TrainingPlan> filterPlansByDifficulty(DifficultyLevel difficulty) {
    return _availablePlans.where((plan) => plan.difficulty == difficulty).toList();
  }

  List<TrainingPlan> filterPlansByType(WorkoutType type) {
    return _availablePlans.where((plan) => plan.type == type).toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}