import 'package:flutter/foundation.dart';
import '../../../data/database/providers/database_provider.dart';
import '../../../domain/entities/training/training_plan.dart';
import '../../../domain/enums/difficulty_level.dart';
import '../../../domain/enums/workout_type.dart';
import '../../../domain/repository/training/training_plan_repository.dart';


class TrainingPlanViewModel extends ChangeNotifier {
  final ITrainingPlanRepository _repository;
  final DatabaseProvider _databaseProvider;
  final String _userId;

  List<TrainingPlan> _availablePlans = [];
  TrainingPlan? _activePlan;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  TrainingPlanViewModel(
      this._repository,
      this._databaseProvider,
      this._userId,
      );

  // Getters
  List<TrainingPlan> get availablePlans => _availablePlans;
  TrainingPlan? get activePlan => _activePlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_userId.isEmpty) {
      _error = 'Cannot initialize - missing user ID';
      return;
    }

    if (_isInitialized) {
      if (kDebugMode) {
        print('Training Plans: Already initialized');
      }
      return;
    }

    if (kDebugMode) {
      print('Training Plans: Starting initialization');
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
        print('Training Plans: Initialization complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Training Plans: Initialization failed - $e');
      }
      _error = 'Initialization failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeInternal() async {
    // Load plans
    await _loadPlans();

    // Sync with cloud
    await _syncTrainingPlans();
  }

  Future<void> _syncTrainingPlans() async {
    try {
      await _databaseProvider.syncService.syncTrainingPlans();
    } catch (e) {
      if (kDebugMode) {
        print('Training plans sync failed: $e');
      }
      // Don't throw - sync failure shouldn't stop initialization
    }
  }

  Future<void> _loadPlans() async {
    try {
      final futures = await Future.wait([
        _repository.getAvailablePlans(),
        _repository.getActivePlan(_userId),
      ]);

      _availablePlans = futures[0] as List<TrainingPlan>;
      _activePlan = futures[1] as TrainingPlan?;
      _error = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading training plans: $e');
      }
      _error = 'Failed to load training plans: $e';
      _availablePlans = [];
      _activePlan = null;
      rethrow;
    }
  }

  void clear() {
    _availablePlans = [];
    _activePlan = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> startPlan(String planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _activePlan = await _repository.startPlan(_userId, planId);
      await _syncTrainingPlans();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start plan: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completePlan() async {
    if (_activePlan == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.completePlan(_userId, _activePlan!.id);
      await _syncTrainingPlans();
      _activePlan = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to complete plan: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWorkoutStatus(
      String weekId,
      String workoutId,
      bool completed,
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateWorkoutStatus(
        _userId,
        weekId,
        workoutId,
        completed,
      );
      await _syncTrainingPlans();
      await _loadPlans();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update workout status: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods remain the same
  List<TrainingPlan> filterPlansByDifficulty(DifficultyLevel difficulty) {
    return _availablePlans.where((plan) => plan.difficulty == difficulty).toList();
  }

  List<TrainingPlan> filterPlansByType(WorkoutType type) {
    return _availablePlans.where((plan) => plan.type == type).toList();
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