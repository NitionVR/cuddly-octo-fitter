import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  })
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _globalTrainingPlansCollection =>
      _firestore.collection('training_plans');

  CollectionReference<Map<String, dynamic>> _userTrainingPlansCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('training_plans');

  CollectionReference<Map<String, dynamic>> _userWorkoutsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('workouts');

  @override
  Future<List<TrainingPlan>> getAvailablePlans() async {
    try {
      final userId = _getCurrentUserId();

      // Get global templates first
      final globalPlans = await _globalTrainingPlansCollection
          .where('isActive', isEqualTo: true)
          .where('isTemplate', isEqualTo: true)
          .get();

      // Then get user-specific plans
      final userPlans = await _userTrainingPlansCollection(userId)
          .where('isActive', isEqualTo: true)
          .get();

      final allPlans = [
        ...globalPlans.docs.map((doc) => _convertToTrainingPlan(doc)),
        ...userPlans.docs.map((doc) => _convertToTrainingPlan(doc)),
      ];

      // Save to local database
      for (var plan in allPlans) {
        await _saveLocalPlan(plan, userId);
      }

      return allPlans;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available plans: $e');
      }
      return _getLocalPlans();
    }
  }

  @override
  Future<TrainingPlan?> getActivePlan(String userId) async {
    try {
      final snapshot = await _userTrainingPlansCollection(userId)
          .where('isActive', isEqualTo: true)
          .where('isTemplate', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return _convertToTrainingPlan(snapshot.docs.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching active plan: $e');
      }
      return _getLocalActivePlan(userId);
    }
  }


  @override
  Future<TrainingPlan> startPlan(String userId, String planId) async {
    try {
      // Try to get from global templates first
      var templateDoc = await _globalTrainingPlansCollection.doc(planId).get();

      // If not found, try user's collection
      if (!templateDoc.exists) {
        templateDoc = await _userTrainingPlansCollection(userId).doc(planId).get();
      }

      if (!templateDoc.exists) {
        throw Exception('Plan template not found');
      }

      final now = DateTime.now().toIso8601String();
      final newPlanData = {
        ...templateDoc.data()!,
        'isTemplate': false,
        'isActive': true,
        'startDate': now,
        'lastUpdated': now,
        'completedWorkouts': [],
      };

      final newPlanRef = await _userTrainingPlansCollection(userId).add(newPlanData);
      final plan = _convertToTrainingPlan(
        await newPlanRef.get(),
      );

      await _saveLocalPlan(plan, userId);
      return plan;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting plan: $e');
      }
      throw Exception('Failed to start plan: ${e.toString()}');
    }
  }

  @override
  Future<void> completePlan(String userId, String planId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _userTrainingPlansCollection(userId)
          .doc(planId)
          .update({
        'isActive': false,
        'completedDate': now,
        'lastUpdated': now,
      });

      await _updateLocalPlanStatus(planId, userId, false);
    } catch (e) {
      if (kDebugMode) {
        print('Error completing plan: $e');
      }
      throw Exception('Failed to complete plan: ${e.toString()}');
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
      final now = DateTime.now().toIso8601String();

      // Update workout status
      await _userWorkoutsCollection(userId)
          .doc(workoutId)
          .set({
        'weekId': weekId,
        'completed': completed,
        'completedAt': completed ? now : null,
        'lastUpdated': now,
      }, SetOptions(merge: true));

      // Update plan's completed workouts
      if (completed) {
        await _updatePlanCompletedWorkouts(userId, workoutId);
      }

      // Update local database
      await _updateLocalWorkoutStatus(userId, weekId, workoutId, completed);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating workout status: $e');
      }
      throw Exception('Failed to update workout status: ${e.toString()}');
    }
  }

  // Local database methods
  Future<List<TrainingPlan>> _getLocalPlans() async {
    try {
      final db = await _databaseHelper.database;
      final plans = await db.query('training_plans');

      // Get all completed workouts
      final completedWorkouts = await db.query('completed_workouts');

      return plans.map((plan) {
        final planWorkouts = completedWorkouts
            .where((w) => w['userId'] == plan['userId'])
            .where((w) => w['completed'] == 1)
            .map((w) => w['workoutId'] as String)
            .toList();

        return TrainingPlan.fromMap({
          ...plan,
          'completedWorkouts': planWorkouts,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local plans: $e');
      }
      return [];
    }
  }

  Future<void> _saveLocalPlan(TrainingPlan plan, String userId) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Save plan
      await txn.insert(
        'training_plans',
        {
          ...plan.toMap(),
          'userId': userId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Save completed workouts
      for (final workoutId in plan.completedWorkouts) {
        await txn.insert(
          'completed_workouts',
          {
            'userId': userId,
            'workoutId': workoutId,
            'weekId': '',
            'completed': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> _updateLocalPlanStatus(String planId, String userId,
      bool isActive) async {
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

  // Helper methods
  TrainingPlan _convertToTrainingPlan(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TrainingPlan.fromMap({
      ...doc.data()!,
      'id': doc.id,
    });
  }

  Future<void> _updatePlanCompletedWorkouts(String userId, String workoutId) async {
    final activePlanSnapshot = await _userTrainingPlansCollection(userId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (activePlanSnapshot.docs.isEmpty) return;

    final planDoc = activePlanSnapshot.docs.first;
    final completedWorkouts = List<String>.from(planDoc.data()['completedWorkouts'] ?? []);

    if (!completedWorkouts.contains(workoutId)) {
      completedWorkouts.add(workoutId);
      await planDoc.reference.update({
        'completedWorkouts': completedWorkouts,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    }
  }



  String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    return user.uid;
  }

  Future<TrainingPlan?> _getLocalActivePlan(String userId) async {
    try {
      final db = await _databaseHelper.database;
      final plans = await db.query(
        'training_plans',
        where: 'userId = ? AND isActive = ?',
        whereArgs: [userId, 1],
        limit: 1,
      );

      if (plans.isEmpty) return null;

      // Get completed workouts for this plan
      final completedWorkouts = await db.query(
        'completed_workouts',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      final plan = plans.first;
      return TrainingPlan.fromMap({
        ...plan,
        'completedWorkouts': completedWorkouts
            .where((w) => w['completed'] == 1)
            .map((w) => w['workoutId'] as String)
            .toList(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local active plan: $e');
      }
      return null;
    }
  }


  Future<void> clearLocalPlans(String userId) async {
    final db = await _databaseHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'training_plans',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      await txn.delete(
        'completed_workouts',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    });
  }


  Future<bool> hasLocalPlans(String userId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      'training_plans',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}