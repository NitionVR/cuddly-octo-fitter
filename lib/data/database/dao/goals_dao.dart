import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database_config.dart';
import '../models/goals_model.dart';
import 'base_dao.dart';

class GoalsDao extends BaseDao {
  GoalsDao(super.db);

  Future<void> insertGoal(GoalsModel goal) async {
    try {
      await insert(DatabaseConfig.tableFitnessGoals, goal.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting goal: $e');
      }
      rethrow;
    }
  }

  Future<void> insertMultipleGoals(List<GoalsModel> goals) async {
    try {
      await db.transaction((txn) async {
        for (var goal in goals) {
          await txn.insert(
            DatabaseConfig.tableFitnessGoals,
            goal.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting multiple goals: $e');
      }
      rethrow;
    }
  }

  Future<List<GoalsModel>> getUserGoals(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        where: 'userId = ? AND isActive = ?',
        whereArgs: [userId, 1],
        orderBy: 'lastUpdated DESC',
      );
      return results.map(GoalsModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user goals: $e');
      }
      return [];
    }
  }

  Future<GoalsModel?> getGoalById(String userId, String goalId) async {
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        where: 'id = ? AND userId = ?',
        whereArgs: [goalId, userId],
        limit: 1,
      );
      return results.isEmpty ? null : GoalsModel.fromMap(results.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting goal by id: $e');
      }
      return null;
    }
  }

  Future<void> updateGoal(GoalsModel goal) async {
    try {
      await update(
        DatabaseConfig.tableFitnessGoals,
        goal.toMap(),
        where: 'id = ? AND userId = ?',
        whereArgs: [goal.id, goal.userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal: $e');
      }
      rethrow;
    }
  }

  Future<void> updateGoalProgress(
      String userId,
      String goalId,
      double progress,
      ) async {
    try {
      await update(
        DatabaseConfig.tableFitnessGoals,
        {
          'currentProgress': progress,
          'lastUpdated': DateTime.now().toIso8601String(),
          'isCompleted': progress >= 100 ? 1 : 0,
        },
        where: 'id = ? AND userId = ?',
        whereArgs: [goalId, userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goal progress: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    try {
      await delete(
        DatabaseConfig.tableFitnessGoals,
        where: 'id = ? AND userId = ?',
        whereArgs: [goalId, userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting goal: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteAllUserGoals(String userId) async {
    try {
      await delete(
        DatabaseConfig.tableFitnessGoals,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting all user goals: $e');
      }
      rethrow;
    }
  }

  Future<void> deactivateGoal(String userId, String goalId) async {
    try {
      await update(
        DatabaseConfig.tableFitnessGoals,
        {
          'isActive': 0,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND userId = ?',
        whereArgs: [goalId, userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deactivating goal: $e');
      }
      rethrow;
    }
  }

  Future<List<GoalsModel>> getActiveGoals(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        where: 'userId = ? AND isActive = ? AND isCompleted = ?',
        whereArgs: [userId, 1, 0],
        orderBy: 'lastUpdated DESC',
      );
      return results.map(GoalsModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active goals: $e');
      }
      return [];
    }
  }

  Future<List<GoalsModel>> getCompletedGoals(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        where: 'userId = ? AND isCompleted = ?',
        whereArgs: [userId, 1],
        orderBy: 'lastUpdated DESC',
      );
      return results.map(GoalsModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting completed goals: $e');
      }
      return [];
    }
  }

  Future<List<GoalsModel>> getGoalsByType(String userId, String type) async {
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        where: 'userId = ? AND type = ? AND isActive = ?',
        whereArgs: [userId, type, 1],
        orderBy: 'lastUpdated DESC',
      );
      return results.map(GoalsModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting goals by type: $e');
      }
      return [];
    }
  }

  Future<List<GoalsModel>> getExpiredGoals(String userId) async {
    final now = DateTime.now().toIso8601String();
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        where: 'userId = ? AND endDate < ? AND isActive = ?',
        whereArgs: [userId, now, 1],
        orderBy: 'endDate DESC',
      );
      return results.map(GoalsModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting expired goals: $e');
      }
      return [];
    }
  }

  Future<bool> hasActiveGoals(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        where: 'userId = ? AND isActive = ? AND isCompleted = ?',
        whereArgs: [userId, 1, 0],
        limit: 1,
      );
      return results.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking active goals: $e');
      }
      return false;
    }
  }

  Future<int> getActiveGoalsCount(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableFitnessGoals,
        columns: ['COUNT(*) as count'],
        where: 'userId = ? AND isActive = ? AND isCompleted = ?',
        whereArgs: [userId, 1, 0],
      );
      return Sqflite.firstIntValue(results) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active goals count: $e');
      }
      return 0;
    }
  }
}