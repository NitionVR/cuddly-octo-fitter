// lib/data/repositories/achievements_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/entities/achievement.dart';
import '../../../domain/repository/achievements/achievements_repository.dart';
import '../dao/achievements_dao.dart';
import '../models/achievement_model.dart';


class AchievementsRepositoryImpl implements IAchievementsRepository {
  final AchievementsDao _achievementsDao;
  final FirebaseFirestore _firestore;

  AchievementsRepositoryImpl(
      this._achievementsDao, {
        FirebaseFirestore? firestore,
      }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _achievementsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('achievements');

  @override
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      // Try to fetch from Firestore first
      final snapshot = await _achievementsCollection(userId).get();

      final achievements = snapshot.docs
          .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Save to local database
      await _achievementsDao.insertMultipleAchievements(
        achievements.map((achievement) => AchievementModel.fromEntity(achievement)).toList(),
      );

      return achievements;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching achievements from Firestore: $e');
      }
      // Fallback to local data
      final localAchievements = await _achievementsDao.getUserAchievements(userId);
      return localAchievements.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {
    try {
      final now = DateTime.now();

      // Update Firestore
      await _achievementsCollection(userId).doc(achievementId).update({
        'unlockedAt': now.toIso8601String(),
      });

      // Update local database
      await _achievementsDao.unlockAchievement(userId, achievementId);
    } catch (e) {
      if (kDebugMode) {
        print('Error unlocking achievement: $e');
      }
      // Still update locally even if Firestore fails
      await _achievementsDao.unlockAchievement(userId, achievementId);
    }
  }

  @override
  Future<void> createAchievement(Achievement achievement) async {
    try {
      // Create in Firestore
      await _achievementsCollection(achievement.userId)
          .doc(achievement.id)
          .set(achievement.toMap());

      // Save to local database
      await _achievementsDao.insertAchievement(
        AchievementModel.fromEntity(achievement),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating achievement: $e');
      }
      // Still save locally even if Firestore fails
      await _achievementsDao.insertAchievement(
        AchievementModel.fromEntity(achievement),
      );
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

      final achievements = snapshot.docs
          .map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Update local database
      await _achievementsDao.insertMultipleAchievements(
        achievements.map((achievement) => AchievementModel.fromEntity(achievement)).toList(),
      );

      return achievements;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching unlocked achievements: $e');
      }
      // Fallback to local data
      final localAchievements = await _achievementsDao.getUnlockedAchievements(userId);
      return localAchievements.map((model) => model.toEntity()).toList();
    }
  }

  @override
  Future<void> syncAchievements(String userId) async {
    try {
      // Get local achievements
      final localAchievements = await _achievementsDao.getUserAchievements(userId);

      // Get Firestore achievements
      final snapshot = await _achievementsCollection(userId).get();
      final remoteAchievements = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Achievement.fromMap(data);
      }).toList();

      // Update remote achievements that exist locally
      for (var localAchievement in localAchievements) {
        if (!remoteAchievements.any((remote) => remote.id == localAchievement.id)) {
          await _achievementsCollection(userId)
              .doc(localAchievement.id)
              .set(localAchievement.toMap());
        }
      }

      // Update local database with remote achievements
      await _achievementsDao.insertMultipleAchievements(
        remoteAchievements.map((achievement) =>
            AchievementModel.fromEntity(achievement)
        ).toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing achievements: $e');
      }
    }
  }
}