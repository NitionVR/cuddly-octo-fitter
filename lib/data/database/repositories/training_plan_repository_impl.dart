import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/training/training_plan.dart';
import '../../../domain/repository/training/training_plan_repository.dart';
import '../dao/completed_workouts_dao.dart';
import '../dao/training_plan_dao.dart';
import '../models/completed_workout_model.dart';
import '../models/training_plan_model.dart';


class TrainingPlanRepositoryImpl implements ITrainingPlanRepository {
  final TrainingPlanDao _trainingPlanDao;
  final CompletedWorkoutsDao _completedWorkoutsDao;
  final FirebaseFirestore _firestore;

  TrainingPlanRepositoryImpl(
      this._trainingPlanDao,
      this._completedWorkoutsDao, {
        FirebaseFirestore? firestore,
      }) : _firestore = firestore ?? FirebaseFirestore.instance;

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
        await _savePlanLocally(plan, userId);
      }

      return allPlans;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available plans: $e');
      }
      // Fallback to local data
      return _getLocalPlans();
    }
  }

  @override
  Future<TrainingPlan?> getActivePlan(String userId) async {
    try {
      final planModel = await _trainingPlanDao.getActivePlan(userId);
      if (planModel == null) return null;

      final completedWorkouts = await _completedWorkoutsDao.getCompletedWorkouts(userId);

      return _combinePlanWithWorkouts(planModel, completedWorkouts);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active plan: $e');
      }
      return null;
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

      final now = DateTime.now();
      final newPlanData = {
        ...templateDoc.data()!,
        'isTemplate': false,
        'isActive': true,
        'startDate': now.toIso8601String(),
        'lastUpdated': now.toIso8601String(),
      };

      final newPlanRef = await _userTrainingPlansCollection(userId).add(newPlanData);
      final plan = _convertToTrainingPlan(await newPlanRef.get());

      // Save to local database
      await _savePlanLocally(plan, userId);

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
      await _trainingPlanDao.completePlan(userId, planId);

      // Update Firestore
      await _userTrainingPlansCollection(userId)
          .doc(planId)
          .update({
        'isActive': false,
        'completedDate': DateTime.now().toIso8601String(),
      });
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
      final workoutModel = CompletedWorkoutModel(
        userId: userId,
        weekId: weekId,
        workoutId: workoutId,
        completed: completed,
        completedAt: completed ? DateTime.now() : null,
      );

      await _completedWorkoutsDao.updateWorkoutStatus(workoutModel);

      // Update Firestore
      await _userWorkoutsCollection(userId)
          .doc(workoutId)
          .set({
        'weekId': weekId,
        'completed': completed,
        'completedAt': completed ? DateTime.now().toIso8601String() : null,
        'lastUpdated': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

    } catch (e) {
      if (kDebugMode) {
        print('Error updating workout status: $e');
      }
      throw Exception('Failed to update workout status: ${e.toString()}');
    }
  }

  // Helper methods
  Future<List<TrainingPlan>> _getLocalPlans() async {
    final plans = await _trainingPlanDao.getAvailablePlans(_getCurrentUserId());
    final completedWorkouts = await _completedWorkoutsDao
        .getCompletedWorkouts(_getCurrentUserId());

    return plans.map((plan) =>
        _combinePlanWithWorkouts(plan, completedWorkouts)
    ).toList();
  }

  Future<void> _savePlanLocally(TrainingPlan plan, String userId) async {
    final planModel = TrainingPlanModel.fromEntity(plan, userId);
    await _trainingPlanDao.insertPlan(planModel);
  }

  TrainingPlan _convertToTrainingPlan(DocumentSnapshot<Map<String, dynamic>> doc) {
    return TrainingPlan.fromMap({
      ...doc.data()!,
      'id': doc.id,
    });
  }

  TrainingPlan _combinePlanWithWorkouts(
      TrainingPlanModel plan,
      List<CompletedWorkoutModel> completedWorkouts,
      ) {
    final planWorkouts = completedWorkouts
        .where((w) => w.completed)
        .map((w) => w.workoutId)
        .toList();

    return plan.toEntity().copyWith(
      completedWorkouts: planWorkouts,
    );
  }

  String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    return user.uid;
  }

  @override
  Future<void> clearUserData(String userId) async {
    try {
      // Clear local data
      await _trainingPlanDao.deleteUserPlans(userId);
      await _completedWorkoutsDao.deleteCompletedWorkouts(userId);

      // Clear Firestore data
      final batch = _firestore.batch();

      // Delete training plans
      final userPlans = await _userTrainingPlansCollection(userId).get();
      for (var doc in userPlans.docs) {
        batch.delete(doc.reference);
      }

      // Delete completed workouts
      final userWorkouts = await _userWorkoutsCollection(userId).get();
      for (var doc in userWorkouts.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user data: $e');
      }
      throw Exception('Failed to clear user data: ${e.toString()}');
    }
  }
}