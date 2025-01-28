import 'package:flutter/foundation.dart';
import '../../../domain/entities/training/training_plan.dart';
import '../../../domain/enums/difficulty_level.dart';
import '../../../domain/enums/workout_type.dart';
import '../../../domain/repository/training/training_plan_repository.dart';

class TrainingPlanViewModel extends ChangeNotifier {
  final TrainingPlanRepository? _repository;
  final String _userId;

  List<TrainingPlan> _availablePlans = [];
  TrainingPlan? _activePlan;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  TrainingPlanViewModel(this._repository, this._userId);

  List<TrainingPlan> get availablePlans => _availablePlans;
  TrainingPlan? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized && _repository != null;

  Future<void> initialize() async {
    if (_repository == null || _userId.isEmpty) return;
    await _loadPlans();
    _isInitialized = true;
    notifyListeners();
  }

  void clear() {
    _availablePlans = [];
    _activePlan = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> _loadPlans() async {
    if (_repository == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _availablePlans = await _repository!.getAvailablePlans();
      _activePlan = await _repository!.getActivePlan(_userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load training plans: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startPlan(String planId) async {
    if (_repository == null) return;

    try {
      _activePlan = await _repository!.startPlan(_userId, planId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start plan: $e';
      notifyListeners();
    }
  }

  Future<void> completePlan() async {
    if (_repository == null || _activePlan == null) return;

    try {
      await _repository!.completePlan(_userId, _activePlan!.id);
      _activePlan = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to complete plan: $e';
      notifyListeners();
    }
  }

  Future<void> updateWorkoutStatus(String weekId, String workoutId, bool completed) async {
    if (_repository == null) return;

    try {
      await _repository!.updateWorkoutStatus(_userId, weekId, workoutId, completed);
      await _loadPlans();
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