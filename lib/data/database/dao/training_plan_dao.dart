// lib/data/database/dao/training_plan_dao.dart
import 'package:flutter/foundation.dart';
import '../database_config.dart';
import '../models/training_plan_model.dart';
import 'base_dao.dart';

class TrainingPlanDao extends BaseDao {
  TrainingPlanDao(super.db);

  Future<void> insertPlan(TrainingPlanModel plan) async {
    try {
      await insert(DatabaseConfig.tableTrainingPlans, plan.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting training plan: $e');
      }
      rethrow;
    }
  }

  Future<void> updatePlan(TrainingPlanModel plan) async {
    try {
      await update(
        DatabaseConfig.tableTrainingPlans,
        plan.toMap(),
        where: 'id = ? AND userId = ?',
        whereArgs: [plan.id, plan.userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating training plan: $e');
      }
      rethrow;
    }
  }

  Future<List<TrainingPlanModel>> getAvailablePlans(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableTrainingPlans,
        where: 'userId = ? AND isActive = ?',
        whereArgs: [userId, 1],
        orderBy: 'lastUpdated DESC',
      );
      return results.map(TrainingPlanModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available plans: $e');
      }
      return [];
    }
  }

  Future<TrainingPlanModel?> getActivePlan(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableTrainingPlans,
        where: 'userId = ? AND isActive = ? AND isTemplate = ?',
        whereArgs: [userId, 1, 0],
        limit: 1,
      );
      return results.isEmpty ? null : TrainingPlanModel.fromMap(results.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active plan: $e');
      }
      return null;
    }
  }

  Future<void> completePlan(String userId, String planId) async {
    try {
      await update(
        DatabaseConfig.tableTrainingPlans,
        {
          'isActive': 0,
          'completedDate': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND userId = ?',
        whereArgs: [planId, userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error completing plan: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteUserPlans(String userId) async {
    try {
      await delete(
        DatabaseConfig.tableTrainingPlans,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user plans: $e');
      }
      rethrow;
    }
  }
}