import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/datasources/local/database_helper.dart';
import '../../entities/goals/fitness_goal.dart';
import 'goals_repository.dart';

class FirebaseGoalsRepository implements GoalsRepository {
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;

  FirebaseGoalsRepository({
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  // Updated to use subcollection
  CollectionReference<Map<String, dynamic>> _goalsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  @override
  Future<List<FitnessGoal>> getUserGoals(String userId) async {
    try {
      final snapshot = await _goalsCollection(userId)
          .where('isActive', isEqualTo: true)
          .get();

      final goals = snapshot.docs
          .map((doc) => FitnessGoal.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Save to local database for offline access
      for (var goal in goals) {
        await _saveGoalLocally(goal);
      }

      return goals;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching goals: $e');
      }
      // Fallback to local data if offline
      return _getLocalGoals(userId);
    }
  }

  @override
  Future<FitnessGoal> createGoal(FitnessGoal goal) async {
    try {
      final docRef = await _goalsCollection(goal.userId).add(goal.toMap());
      final newGoal = goal.copyWith(id: docRef.id);

      // Save to local database
      await _saveGoalLocally(newGoal);

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
      await _goalsCollection(goal.userId).doc(goal.id).update(goal.toMap());
      await _saveGoalLocally(goal);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal: $e');
      }
      // Save locally even if cloud sync fails
      await _saveGoalLocally(goal);
    }
  }

  @override
  Future<void> updateGoalProgress(String userId, String goalId, double progress) async {
    try {
      await _goalsCollection(userId).doc(goalId).update({
        'currentProgress': progress,
        'lastUpdated': DateTime.now().toIso8601String(),
        'isCompleted': progress >= 100,
      });

      // Update local database
      final db = await _databaseHelper.database;
      await db.update(
        'fitness_goals',
        {
          'currentProgress': progress,
          'lastUpdated': DateTime.now().toIso8601String(),
          'isCompleted': progress >= 100 ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [goalId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal progress: $e');
      }
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

  Future<List<FitnessGoal>> _getLocalGoals(String userId) async {
    final db = await _databaseHelper.database;
    final goals = await db.query(
      'fitness_goals',
      where: 'userId = ? AND isActive = ?',
      whereArgs: [userId, 1],
    );

    return goals.map((goal) => FitnessGoal.fromMap(goal)).toList();
  }

  Future<void> _saveGoalLocally(FitnessGoal goal) async {
    final db = await _databaseHelper.database;

    await db.insert(
      'fitness_goals',
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      // Delete from Firestore
      await _goalsCollection(userId).doc(goalId).delete();

      // Delete from local database
      final db = await _databaseHelper.database;
      await db.delete(
        'fitness_goals',
        where: 'id = ?',
        whereArgs: [goalId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting goal: $e');
      }
      throw Exception('Failed to delete goal');
    }
  }

  // Helper method to sync local goals with Firestore
  Future<void> syncGoals(String userId) async {
    try {
      final localGoals = await _getLocalGoals(userId);
      final snapshot = await _goalsCollection(userId).get();
      final remoteGoals = snapshot.docs
          .map((doc) => FitnessGoal.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Update remote goals that exist locally
      for (var localGoal in localGoals) {
        if (!remoteGoals.any((remote) => remote.id == localGoal.id)) {
          await _goalsCollection(userId).doc(localGoal.id).set(localGoal.toMap());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing goals: $e');
      }
    }
  }
}