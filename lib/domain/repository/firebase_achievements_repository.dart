import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/achievement.dart';
import 'achievements_repository.dart';

class FirebaseAchievementsRepository implements AchievementsRepository {
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;

  FirebaseAchievementsRepository({
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseHelper = databaseHelper ?? DatabaseHelper();

  // Updated to use subcollection
  CollectionReference<Map<String, dynamic>> _achievementsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('achievements');

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _achievementsCollection(userId).get();

      final achievements = snapshot.docs
          .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Save to local database for offline access
      for (var achievement in achievements) {
        await _saveAchievementLocally(achievement);
      }

      return achievements;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching achievements: $e');
      }
      return _getLocalAchievements(userId);
    }
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      final now = DateTime.now();
      await _achievementsCollection(userId).doc(achievementId).update({
        'unlockedAt': now.toIso8601String(),
      });

      // Update local database
      await _updateLocalAchievement(achievementId, now);
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking achievement: $e');
      }
      // Handle offline case
      await _updateLocalAchievement(achievementId, DateTime.now());
    }
  }

  @override
  Future<void> createAchievement(Achievement achievement) async {
    try {
      await _achievementsCollection(achievement.userId)
          .doc(achievement.id)
          .set(achievement.toMap());
      await _saveAchievementLocally(achievement);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating achievement: $e');
      }
      // Save locally even if cloud sync fails
      await _saveAchievementLocally(achievement);
    }
  }

  @override
  Stream<List<Achievement>> achievementsStream(String userId) {
    return _achievementsCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  @override
  Future<List<Achievement>> getUnlockedAchievements(String userId) async {
    try {
      final snapshot = await _achievementsCollection(userId)
          .where('unlockedAt', isNull: false)
          .get();

      return snapshot.docs
          .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching unlocked achievements: $e');
      }
      // Return locally stored unlocked achievements
      return _getLocalUnlockedAchievements(userId);
    }
  }

  // Local database methods
  Future<List<Achievement>> _getLocalAchievements(String userId) async {
    try {
      final db = await _databaseHelper.database;
      final achievements = await db.query(
        'achievements',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      return achievements.map((achievement) => Achievement.fromMap(achievement)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local achievements: $e');
      }
      return [];
    }
  }

  Future<List<Achievement>> _getLocalUnlockedAchievements(String userId) async {
    try {
      final db = await _databaseHelper.database;
      final achievements = await db.query(
        'achievements',
        where: 'userId = ? AND unlockedAt IS NOT NULL',
        whereArgs: [userId],
      );

      return achievements.map((achievement) => Achievement.fromMap(achievement)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local unlocked achievements: $e');
      }
      return [];
    }
  }

  Future<void> _saveAchievementLocally(Achievement achievement) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert(
        'achievements',
        achievement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving achievement locally: $e');
      }
    }
  }

  Future<void> _updateLocalAchievement(String achievementId, DateTime unlockedAt) async {
    try {
      final db = await _databaseHelper.database;
      await db.update(
        'achievements',
        {'unlockedAt': unlockedAt.toIso8601String()},
        where: 'id = ?',
        whereArgs: [achievementId],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating local achievement: $e');
      }
    }
  }

  // Helper method to sync achievements
  Future<void> syncAchievements(String userId) async {
    try {
      final localAchievements = await _getLocalAchievements(userId);
      final remoteSnapshot = await _achievementsCollection(userId).get();
      final remoteAchievements = remoteSnapshot.docs
          .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Sync local achievements to remote
      for (var localAchievement in localAchievements) {
        if (!remoteAchievements.any((remote) => remote.id == localAchievement.id)) {
          await _achievementsCollection(userId)
              .doc(localAchievement.id)
              .set(localAchievement.toMap());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing achievements: $e');
      }
    }
  }
}