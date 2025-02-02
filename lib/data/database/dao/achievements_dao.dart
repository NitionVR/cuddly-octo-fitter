// lib/data/database/dao/achievements_dao.dart
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../domain/entities/achievement.dart';
import '../database_config.dart';
import '../models/achievement_model.dart';
import 'base_dao.dart';

class AchievementsDao extends BaseDao {
  AchievementsDao(super.db);

  Future<void> insertAchievement(AchievementModel achievement) async {
    try {
      await insert(DatabaseConfig.tableAchievements, achievement.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting achievement: $e');
      }
      rethrow;
    }
  }

  Future<void> insertMultipleAchievements(List<AchievementModel> achievements) async {
    try {
      await db.transaction((txn) async {
        for (var achievement in achievements) {
          await txn.insert(
            DatabaseConfig.tableAchievements,
            achievement.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting multiple achievements: $e');
      }
      rethrow;
    }
  }

  Future<List<AchievementModel>> getUserAchievements(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableAchievements,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'unlockedAt DESC',
      );
      return results.map(AchievementModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user achievements: $e');
      }
      return [];
    }
  }

  Future<List<AchievementModel>> getUnlockedAchievements(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableAchievements,
        where: 'userId = ? AND unlockedAt IS NOT NULL',
        whereArgs: [userId],
        orderBy: 'unlockedAt DESC',
      );
      return results.map(AchievementModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unlocked achievements: $e');
      }
      return [];
    }
  }

  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      await update(
        DatabaseConfig.tableAchievements,
        {
          'unlockedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND userId = ?',
        whereArgs: [achievementId, userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking achievement: $e');
      }
      rethrow;
    }
  }

  Future<List<AchievementModel>> getAchievementsByType(
      String userId,
      AchievementType type,
      ) async {
    try {
      final results = await query(
        DatabaseConfig.tableAchievements,
        where: 'userId = ? AND type = ?',
        whereArgs: [userId, type.toString()],
        orderBy: 'threshold ASC',
      );
      return results.map(AchievementModel.fromMap).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting achievements by type: $e');
      }
      return [];
    }
  }

  Future<AchievementModel?> getAchievementById(
      String userId,
      String achievementId,
      ) async {
    try {
      final results = await query(
        DatabaseConfig.tableAchievements,
        where: 'id = ? AND userId = ?',
        whereArgs: [achievementId, userId],
        limit: 1,
      );
      return results.isEmpty ? null : AchievementModel.fromMap(results.first);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting achievement by id: $e');
      }
      return null;
    }
  }

  Future<void> deleteUserAchievements(String userId) async {
    try {
      await delete(
        DatabaseConfig.tableAchievements,
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user achievements: $e');
      }
      rethrow;
    }
  }

  Future<int> getUnlockedAchievementsCount(String userId) async {
    try {
      final results = await query(
        DatabaseConfig.tableAchievements,
        columns: ['COUNT(*) as count'],
        where: 'userId = ? AND unlockedAt IS NOT NULL',
        whereArgs: [userId],
      );
      return Sqflite.firstIntValue(results) ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting unlocked achievements count: $e');
      }
      return 0;
    }
  }
}