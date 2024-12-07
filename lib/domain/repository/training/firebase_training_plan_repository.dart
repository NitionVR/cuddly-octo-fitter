// lib/data/repositories/training/firebase_training_plan_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_project_fitquest/domain/repository/training/training_plan_repository.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../../domain/entities/training/training_plan.dart';


class FirebaseTrainingPlanRepository implements TrainingPlanRepository {
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;

  FirebaseTrainingPlanRepository({
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  CollectionReference<Map<String, dynamic>> get _plansCollection =>
      _firestore.collection('training_plans');

  CollectionReference<Map<String, dynamic>> get _userPlansCollection =>
      _firestore.collection('user_training_plans');

  @override
  Future<List<TrainingPlan>> getAvailablePlans() async {
    try {
      final snapshot = await _plansCollection
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => TrainingPlan.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error fetching available plans: $e');
      // Fallback to local data
      return _getLocalPlans();
    }
  }

  @override
  Future<TrainingPlan?> getActivePlan(String userId) async {
    try {
      final snapshot = await _userPlansCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final userPlan = snapshot.docs.first;
      final planId = userPlan.data()['planId'] as String;

      final planDoc = await _plansCollection.doc(planId).get();
      if (!planDoc.exists) return null;

      return TrainingPlan.fromMap({
        ...planDoc.data()!,
        'id': planDoc.id,
        ...userPlan.data(),
      });
    } catch (e) {
      print('Error fetching active plan: $e');
      return null;
    }
  }

  @override
  Future<TrainingPlan> startPlan(String userId, String planId) async {
    try {
      // Get the plan
      final planDoc = await _plansCollection.doc(planId).get();
      if (!planDoc.exists) {
        throw Exception('Plan not found');
      }

      // Create user plan record
      final userPlanRef = await _userPlansCollection.add({
        'userId': userId,
        'planId': planId,
        'isActive': true,
        'startDate': DateTime.now().toIso8601String(),
        'completedWorkouts': [],
      });

      // Save to local database
      final plan = TrainingPlan.fromMap({
        ...planDoc.data()!,
        'id': planId,
        'userPlanId': userPlanRef.id,
      });
      await _saveLocalPlan(plan, userId);

      return plan;
    } catch (e) {
      print('Error starting plan: $e');
      throw Exception('Failed to start plan');
    }
  }

  @override
  Future<void> completePlan(String userId, String planId) async {
    try {
      final snapshot = await _userPlansCollection
          .where('userId', isEqualTo: userId)
          .where('planId', isEqualTo: planId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      final userPlanRef = snapshot.docs.first.reference;
      await userPlanRef.update({
        'isActive': false,
        'completedDate': DateTime.now().toIso8601String(),
      });

      // Update local database
      await _updateLocalPlanStatus(planId, userId, false);
    } catch (e) {
      print('Error completing plan: $e');
      throw Exception('Failed to complete plan');
    }
  }

  @override
  Future<void> updateWorkoutStatus(
      String userId,
      String weekId,
      String workoutId,
      bool completed,
      ) async {
    try {
      final snapshot = await _userPlansCollection
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      final userPlanRef = snapshot.docs.first.reference;
      final completedWorkouts = List<String>.from(
        snapshot.docs.first.data()['completedWorkouts'] ?? [],
      );

      if (completed) {
        completedWorkouts.add(workoutId);
      } else {
        completedWorkouts.remove(workoutId);
      }

      await userPlanRef.update({
        'completedWorkouts': completedWorkouts,
      });

      // Update local database
      await _updateLocalWorkoutStatus(userId, weekId, workoutId, completed);
    } catch (e) {
      print('Error updating workout status: $e');
      throw Exception('Failed to update workout status');
    }
  }

  // Local database methods
  Future<List<TrainingPlan>> _getLocalPlans() async {
    final db = await _databaseHelper.database;
    final plans = await db.query('training_plans');
    return plans.map((plan) => TrainingPlan.fromMap(plan)).toList();
  }

  Future<void> _saveLocalPlan(TrainingPlan plan, String userId) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'training_plans',
      {
        ...plan.toMap(),
        'userId': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _updateLocalPlanStatus(String planId, String userId, bool isActive) async {
    final db = await _databaseHelper.database;
    await db.update(
      'training_plans',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [planId, userId],
    );
  }

  Future<void> _updateLocalWorkoutStatus(
      String userId,
      String weekId,
      String workoutId,
      bool completed,
      ) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'completed_workouts',
      {
        'userId': userId,
        'weekId': weekId,
        'workoutId': workoutId,
        'completed': completed ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}