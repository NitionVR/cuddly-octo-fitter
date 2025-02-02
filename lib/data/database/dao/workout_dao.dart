// lib/data/database/dao/workout_dao.dart
import 'package:flutter/foundation.dart';
import '../database_config.dart';
import '../models/workout_model.dart';
import '../models/completed_workout_model.dart';
import 'base_dao.dart';

class WorkoutDao extends BaseDao {
  WorkoutDao(super.db);

  Future<void> insertWorkout(WorkoutModel workout) async {
    try {
      await insert(DatabaseConfig.tableWorkouts, workout.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting workout: $e');
      }
      rethrow;
    }
  }

  Future<List<WorkoutModel>> getUserWorkouts(
      String userId, {
        int limit = 20,
        int offset = 0,
      }) async {
    try {
      final results = await query(
        DatabaseConfig.tableWorkouts,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit,
        offset: offset,
      );
      return results.map(WorkoutModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user workouts: $e');
      }
      return [];
    }
  }

  Future<void> markWorkoutCompleted(CompletedWorkoutModel workout) async {
    try {
      await insert(
        DatabaseConfig.tableCompletedWorkouts,
        workout.toMap(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error marking workout as completed: $e');
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

  Future<void> updateWorkoutSyncStatus(String workoutId, bool isSynced) async {
    try {
      await update(
        DatabaseConfig.tableWorkouts,
        {
          'isSynced': isSynced ? 1 : 0,
          'lastModified': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [workoutId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating workout sync status: $e');
      }
      rethrow;
    }
  }

  Future<List<WorkoutModel>> getUnsyncedWorkouts(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableWorkouts,
        where: 'userId = ? AND isSynced = ?',
        whereArgs: [userId, 0],
      );
      return results.map(WorkoutModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unsynced workouts: $e');
      }
      return [];
    }
  }

  Future<void> deleteUserWorkouts(String userId) async {
    try {
      await delete(
        DatabaseConfig.tableWorkouts,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user workouts: $e');
      }
      rethrow;
    }
  }
}