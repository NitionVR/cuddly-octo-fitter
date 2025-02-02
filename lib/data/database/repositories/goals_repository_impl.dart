// lib/data/repositories/goals_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/goals/fitness_goal.dart';
import '../../../domain/repository/goals/goals_repository.dart';
import '../dao/goals_dao.dart';
import '../models/goals_model.dart';

class GoalsRepositoryImpl implements IGoalsRepository {
  final GoalsDao _goalsDao;
  final FirebaseFirestore _firestore;

  GoalsRepositoryImpl(this._goalsDao, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _goalsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  @override
  Future<List<FitnessGoal>> getUserGoals(String userId) async {
    try {
      // Try to fetch from Firestore first
      final snapshot = await _goalsCollection(userId)
          .where('isActive', isEqualTo: true)
          .get();

      final goals = snapshot.docs
          .map((doc) => FitnessGoal.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Save to local database
      await _goalsDao.insertMultipleGoals(
        goals.map((goal) => GoalsModel.fromEntity(goal)).toList(),
      );

      return goals;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching goals from Firestore: $e');
      }
      // Fallback to local data
      final localGoals = await _goalsDao.getUserGoals(userId);
      return localGoals.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<FitnessGoal> createGoal(FitnessGoal goal) async {
    try {
      // Create in Firestore
      final docRef = await _goalsCollection(goal.userId).add(goal.toMap());
      final newGoal = goal.copyWith(id: docRef.id);

      // Save to local database
      await _goalsDao.insertGoal(GoalsModel.fromEntity(newGoal));

      return newGoal;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating goal: $e');
      }
      throw Exception('Failed to create goal');
    }
  }

  @override
  Future<void> updateGoal(FitnessGoal goal) async {
    try {
      // Update in Firestore
      await _goalsCollection(goal.userId).doc(goal.id).update(goal.toMap());

      // Update local database
      await _goalsDao.updateGoal(GoalsModel.fromEntity(goal));
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal: $e');
      }
      // Still update locally even if Firestore fails
      await _goalsDao.updateGoal(GoalsModel.fromEntity(goal));
    }
  }

  @override
  Future<void> updateGoalProgress(
      String userId,
      String goalId,
      double progress,
      ) async {
    try {
      final updateData = {
        'currentProgress': progress,
        'lastUpdated': DateTime.now().toIso8601String(),
        'isCompleted': progress >= 100,
      };

      // Update Firestore
      await _goalsCollection(userId).doc(goalId).update(updateData);

      // Update local database
      await _goalsDao.updateGoalProgress(userId, goalId, progress);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal progress: $e');
      }
      // Still update locally even if Firestore fails
      await _goalsDao.updateGoalProgress(userId, goalId, progress);
    }
  }

  @override
  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      // Delete from Firestore
      await _goalsCollection(userId).doc(goalId).delete();

      // Delete from local database
      await _goalsDao.deleteGoal(userId, goalId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting goal: $e');
      }
      throw Exception('Failed to delete goal');
    }
  }

  @override
  Stream<List<FitnessGoal>> activeGoalsStream(String userId) {
    return _goalsCollection(userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FitnessGoal.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  @override
  Future<void> syncGoals(String userId) async {
    try {
      // Get local goals
      final localGoals = await _goalsDao.getUserGoals(userId);

      // Get Firestore goals
      final snapshot = await _goalsCollection(userId).get();
      final remoteGoals = snapshot.docs
          .map((doc) => FitnessGoal.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Update remote goals that exist locally
      for (var localGoal in localGoals) {
        if (!remoteGoals.any((remote) => remote.id == localGoal.id)) {
          await _goalsCollection(userId)
              .doc(localGoal.id)
              .set(localGoal.toMap());
        }
      }

      // Update local database with remote goals
      await _goalsDao.insertMultipleGoals(
        remoteGoals.map((goal) => GoalsModel.fromEntity(goal)).toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing goals: $e');
      }
    }
  }
}