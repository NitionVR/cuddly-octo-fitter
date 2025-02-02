// lib/data/providers/database_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/repository/achievements/achievements_repository.dart';
import '../../../domain/repository/auth/auth_repository.dart';
import '../../../domain/repository/auth/firebase_auth_repository.dart';
import '../../../domain/repository/goals/goals_repository.dart';
import '../../../domain/repository/tracking/tracking_repository.dart';
import '../../../domain/repository/training/training_plan_repository.dart';
import '../../../domain/services/firebase_sync_service.dart';
import '../../../domain/services/firestore_tracking_service.dart';
import '../../../domain/services/sync/achievements_sync_handler.dart';
import '../../../domain/services/sync/goals_sync_handler.dart';
import '../../../domain/services/sync/training_plans_sync_handler.dart';
import '../../../domain/services/sync/workouts_sync_handler.dart';
import '../../../domain/services/sync_service.dart';
import '../dao/achievements_dao.dart';
import '../dao/completed_workouts_dao.dart';
import '../dao/goals_dao.dart';
import '../dao/tracking_dao.dart';
import '../dao/training_plan_dao.dart';
import '../dao/workout_dao.dart';
import '../database_service.dart';
import '../repositories/achievements_repository_impl.dart';
import '../repositories/goals_repository_impl.dart';
import '../repositories/tracking_repository_impl.dart';
import '../repositories/training_plan_repository_impl.dart';

class DatabaseProvider {
  static final DatabaseProvider _instance = DatabaseProvider._internal();
  factory DatabaseProvider() => _instance;
  DatabaseProvider._internal();

  // Database service
  late final DatabaseService _databaseService;

  // DAOs
  late final TrackingDao _trackingDao;
  late final GoalsDao _goalsDao;
  late final AchievementsDao _achievementsDao;
  late final TrainingPlanDao _trainingPlanDao;
  late final CompletedWorkoutsDao _completedWorkoutsDao;
  late final WorkoutDao _workoutDao;

  // Repositories
  late final ITrackingRepository _trackingRepository;
  late final IGoalsRepository _goalsRepository;
  late final IAchievementsRepository _achievementsRepository;
  late final ITrainingPlanRepository _trainingPlanRepository;
  late final AuthRepository _authRepository;

  // Services
  late final FirestoreTrackingService _firestoreService;
  late final FirebaseFirestore _firestore;
  late final SyncService _syncService;

  // Sync Handlers
  late final GoalsSyncHandler _goalsSyncHandler;
  late final AchievementsSyncHandler _achievementsSyncHandler;
  late final TrainingPlansSyncHandler _trainingPlansSyncHandler;
  late final WorkoutsSyncHandler _workoutsSyncHandler;

  Future<void> initialize() async {
    _databaseService = DatabaseService();
    final db = await _databaseService.database;

    // Initialize DAOs
    _trackingDao = TrackingDao(db);
    _goalsDao = GoalsDao(db);
    _achievementsDao = AchievementsDao(db);
    _trainingPlanDao = TrainingPlanDao(db);
    _completedWorkoutsDao = CompletedWorkoutsDao(db);
    _workoutDao = WorkoutDao(db);

    // Initialize Firestore
    _firestore = FirebaseFirestore.instance;
    _firestoreService = FirestoreTrackingService();

    // Initialize Sync Handlers
    _goalsSyncHandler = GoalsSyncHandler(_firestore, _goalsDao);
    _achievementsSyncHandler = AchievementsSyncHandler(_firestore, _achievementsDao);
    _trainingPlansSyncHandler = TrainingPlansSyncHandler(_firestore, _trainingPlanDao);
    _workoutsSyncHandler = WorkoutsSyncHandler(_firestore, _completedWorkoutsDao);

    // Initialize Sync Service
    _syncService = FirebaseSyncService(
      goalsSyncHandler: _goalsSyncHandler,
      achievementsSyncHandler: _achievementsSyncHandler,
      trainingPlansSyncHandler: _trainingPlansSyncHandler,
      workoutsSyncHandler: _workoutsSyncHandler,
      firestore: _firestore,
    );

    // Initialize Repositories
    _trackingRepository = TrackingRepositoryImpl(_trackingDao, _firestoreService);
    _goalsRepository = GoalsRepositoryImpl(_goalsDao, firestore: _firestore);
    _achievementsRepository = AchievementsRepositoryImpl(_achievementsDao, firestore: _firestore);
    _trainingPlanRepository = TrainingPlanRepositoryImpl(
      _trainingPlanDao,
      _completedWorkoutsDao,
      firestore: _firestore,
    );

    _authRepository = FirebaseAuthRepository(
      firebaseAuth: FirebaseAuth.instance,
      firestore: _firestore,
    );
  }


  // Repository getters
  ITrackingRepository get trackingRepository => _trackingRepository;
  IGoalsRepository get goalsRepository => _goalsRepository;
  IAchievementsRepository get achievementsRepository => _achievementsRepository;
  ITrainingPlanRepository get trainingPlanRepository => _trainingPlanRepository;
  AuthRepository get authRepository => _authRepository;

  // Service getters
  SyncService get syncService => _syncService;
  FirestoreTrackingService get firestoreService => _firestoreService;

  // DAO getters (if still needed)
  TrainingPlanDao get trainingPlanDao => _trainingPlanDao;
  CompletedWorkoutsDao get completedWorkoutsDao => _completedWorkoutsDao;
  WorkoutDao get workoutDao => _workoutDao;

  Future<void> dispose() async {
    await _databaseService.close();
    (_syncService as FirebaseSyncService).dispose();
  }

  Future<void> clearAllData() async {
    final db = await _databaseService.database;
    await db.transaction((txn) async {
      await Future.wait([
        txn.delete('tracking_history'),
        txn.delete('fitness_goals'),
        txn.delete('achievements'),
        txn.delete('training_plans'),
        txn.delete('completed_workouts'),
        txn.delete('workouts'),
      ]);
    });
  }
}