// lib/data/database/dao/completed_workouts_dao.dart
import 'package:flutter/foundation.dart';
import '../database_config.dart';
import '../models/completed_workout_model.dart';
import 'base_dao.dart';

class CompletedWorkoutsDao extends BaseDao {
  CompletedWorkoutsDao(super.db);

  Future<void> updateWorkoutStatus(CompletedWorkoutModel workout) async {
    try {
      await insert(
        DatabaseConfig.tableCompletedWorkouts,
        workout.toMap(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating workout status: $e');
      }
      rethrow;
    }
  }

  Future<List<CompletedWorkoutModel>> getCompletedWorkouts(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableCompletedWorkouts,
        where: 'userId = ? AND completed = ?',
        whereArgs: [userId, 1],
      );
      return results.map(CompletedWorkoutModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting completed workouts: $e');
      }
      return [];
    }
  }

  Future<List<CompletedWorkoutModel>> getCompletedWorkoutsForPlan(
      String userId,
      String planId,
      ) async {
    try {
      final results = await query(
        DatabaseConfig.tableCompletedWorkouts,
        where: 'userId = ? AND completed = ? AND planId = ?',
        whereArgs: [userId, 1, planId],
      );
      return results.map(CompletedWorkoutModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting completed workouts for plan: $e');
      }
      return [];
    }
  }

  Future<void> deleteCompletedWorkouts(String userId) async {
    try {
      await delete(
        DatabaseConfig.tableCompletedWorkouts,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting completed workouts: $e');
      }
      rethrow;
    }
  }
}