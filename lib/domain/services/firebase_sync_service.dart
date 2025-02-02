// lib/data/services/firebase_sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/services/sync_service.dart';
import 'sync/base_sync_handler.dart';
import 'sync/goals_sync_handler.dart';
import 'sync/achievements_sync_handler.dart';
import 'sync/training_plans_sync_handler.dart';
import 'sync/workouts_sync_handler.dart';

class FirebaseSyncService implements SyncService {
  static const Duration _syncInterval = Duration(minutes: 15);
  static const Duration _retryDelay = Duration(seconds: 30);
  static const int _maxRetries = 3;

  final FirebaseFirestore _firestore;
  final GoalsSyncHandler _goalsSyncHandler;
  final AchievementsSyncHandler _achievementsSyncHandler;
  final TrainingPlansSyncHandler _trainingPlansSyncHandler;
  final WorkoutsSyncHandler _workoutsSyncHandler;
  final StreamController<SyncStatus> _syncStatusController;

  Timer? _syncTimer;
  bool _isSyncing = false;
  int _currentRetry = 0;

  FirebaseSyncService({
    required GoalsSyncHandler goalsSyncHandler,
    required AchievementsSyncHandler achievementsSyncHandler,
    required TrainingPlansSyncHandler trainingPlansSyncHandler,
    required WorkoutsSyncHandler workoutsSyncHandler,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _goalsSyncHandler = goalsSyncHandler,
        _achievementsSyncHandler = achievementsSyncHandler,
        _trainingPlansSyncHandler = trainingPlansSyncHandler,
        _workoutsSyncHandler = workoutsSyncHandler,
        _syncStatusController = StreamController<SyncStatus>.broadcast() {
    _initializeSync();
  }

  void _initializeSync() {
    _syncTimer = Timer.periodic(_syncInterval, (_) => syncAll());
    _syncStatusController.add(SyncStatus.idle);

    Connectivity().onConnectivityChanged.listen((update) async {
      if (update != ConnectivityResult.none && !_isSyncing) {
        await syncAll();
      }
    });
  }

  String? _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  @override
  Future<void> syncAll() async {
    if (_isSyncing) return;

    final userId = _getCurrentUserId();
    if (userId == null) {
      _syncStatusController.add(SyncStatus.error);
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncStatusController.add(SyncStatus.offline);
        return;
      }

      await Future.wait([
        syncGoals(),
        syncAchievements(),
        syncWorkouts(),
        syncTrainingPlans(), // Add this
      ]);

      _syncStatusController.add(SyncStatus.completed);
      _currentRetry = 0;
    } catch (e) {
      if (kDebugMode) {
        print('Sync error: $e');
      }
      if (_currentRetry < _maxRetries) {
        _currentRetry++;
        await Future.delayed(_retryDelay * _currentRetry);
        await syncAll();
      } else {
        _syncStatusController.add(SyncStatus.error);
      }
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> syncGoals() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _goalsSyncHandler.sync(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing goals: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> syncAchievements() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _achievementsSyncHandler.sync(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing achievements: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> syncWorkouts() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _workoutsSyncHandler.sync(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing workouts: $e');
      }
      rethrow;
    }
  }

  @override // Add this override
  Future<void> syncTrainingPlans() async {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _trainingPlansSyncHandler.sync(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing training plans: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> resolveConflicts() async {
    final userId = _getCurrentUserId();
    if (userId == null) return;

    try {
      _syncStatusController.add(SyncStatus.syncing);

      await Future.wait([
        _goalsSyncHandler.resolveConflicts(userId),
        _achievementsSyncHandler.resolveConflicts(userId),
        _workoutsSyncHandler.resolveConflicts(userId),
        _trainingPlansSyncHandler.resolveConflicts(userId),
      ]);

      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving conflicts: $e');
      }
      _syncStatusController.add(SyncStatus.error);
    }
  }

  Future<SyncResult> syncWithResult(Future<void> Function() syncOperation) async {
    try {
      final startTime = DateTime.now();
      await syncOperation();
      final endTime = DateTime.now();

      return SyncResult(
        success: true,
        itemsSynced: 1, // This should be updated with actual count
        conflicts: [], // This should be populated with actual conflicts
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
        itemsSynced: 0,
        conflicts: [],
      );
    }
  }



  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}