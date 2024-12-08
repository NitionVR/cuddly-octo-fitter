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

  CollectionReference<Map<String, dynamic>> get _achievementsCollection =>
      _firestore.collection('achievements');

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final snapshot = await _achievementsCollection
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
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
      await _firestore.runTransaction((transaction) async {
        final docRef = _achievementsCollection.doc(achievementId);
        final achievement = await transaction.get(docRef);

        if (!achievement.exists) return;

        final data = achievement.data()!;
        if (data['unlockedAt'] != null) return; // Already unlocked

        transaction.update(docRef, {
          'unlockedAt': DateTime.now().toIso8601String(),
        });
      });

      // Update local database
      await _updateLocalAchievement(achievementId, DateTime.now());
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking achievement: $e');
      }
    }
  }

  @override
  Future<void> createAchievement(Achievement achievement) async {
    try {
      await _achievementsCollection.doc(achievement.id).set(achievement.toMap());
      await _saveAchievementLocally(achievement);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating achievement: $e');
      }
      await _saveAchievementLocally(achievement);
    }
  }

  @override
  Stream<List<Achievement>> achievementsStream(String userId) {
    return _achievementsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
        .toList());
  }

  Future<List<Achievement>> _getLocalAchievements(String userId) async {
    final db = await _databaseHelper.database;
    final achievements = await db.query(
      'achievements',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return achievements.map((achievement) => Achievement.fromMap(achievement)).toList();
  }

  Future<void> _saveAchievementLocally(Achievement achievement) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'achievements',
      achievement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _updateLocalAchievement(String achievementId, DateTime unlockedAt) async {
    final db = await _databaseHelper.database;
    await db.update(
      'achievements',
      {'unlockedAt': unlockedAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [achievementId],
    );
  }

  @override
  Future<List<Achievement>> getUnlockedAchievements(String userId) {
    // TODO: implement getUnlockedAchievements
    throw UnimplementedError();
  }
}