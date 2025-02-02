// lib/data/services/sync/achievements_sync_handler.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../data/database/dao/achievements_dao.dart';
import '../../../data/database/models/achievement_model.dart';
import 'base_sync_handler.dart';

class AchievementsSyncHandler extends BaseSyncHandler {
  final AchievementsDao _achievementsDao;

  AchievementsSyncHandler(super.firestore, this._achievementsDao);

  @override
  Future<void> sync(String userId) async {
    try {
      final localAchievements = await _achievementsDao.getUserAchievements(userId);
      final cloudSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      final cloudAchievements = cloudSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AchievementModel.fromMap(data);
      }).toList();

      await _handleSync(localAchievements, cloudAchievements);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing achievements: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleSync(
      List<AchievementModel> localAchievements,
      List<AchievementModel> cloudAchievements,
      ) async {
    final localAchievementsMap = {
      for (var achievement in localAchievements) achievement.id: achievement
    };
    final cloudAchievementsMap = {
      for (var achievement in cloudAchievements) achievement.id: achievement
    };
    final batch = firestore.batch();
    bool hasBatchOperations = false;

    // Handle local achievements that need to be synced to cloud
    for (var localAchievement in localAchievements) {
      final cloudAchievement = cloudAchievementsMap[localAchievement.id];

      if (cloudAchievement == null) {
        // Achievement exists locally but not in cloud - upload it
        batch.set(
          _getAchievementRef(localAchievement.userId, localAchievement.id),
          localAchievement.toMap(),
        );
        hasBatchOperations = true;
      } else {
        // Handle unlock status
        final localUnlocked = localAchievement.unlockedAt != null;
        final cloudUnlocked = cloudAchievement.unlockedAt != null;

        if (localUnlocked && !cloudUnlocked) {
          // Local achievement is unlocked but cloud isn't - update cloud
          batch.update(
            _getAchievementRef(localAchievement.userId, localAchievement.id),
            localAchievement.toMap(),
          );
          hasBatchOperations = true;
        } else if (!localUnlocked && cloudUnlocked) {
          // Cloud achievement is unlocked but local isn't - update local
          await _achievementsDao.insertAchievement(cloudAchievement);
        } else if (localUnlocked && cloudUnlocked) {
          // Both are unlocked - keep the earlier unlock time
          final achievementToKeep = localAchievement.unlockedAt!
              .isBefore(cloudAchievement.unlockedAt!)
              ? localAchievement
              : cloudAchievement;

          if (achievementToKeep == localAchievement) {
            batch.update(
              _getAchievementRef(localAchievement.userId, localAchievement.id),
              localAchievement.toMap(),
            );
            hasBatchOperations = true;
          } else {
            await _achievementsDao.insertAchievement(cloudAchievement);
          }
        }
      }
    }

    // Handle cloud achievements that don't exist locally
    for (var cloudAchievement in cloudAchievements) {
      if (!localAchievementsMap.containsKey(cloudAchievement.id)) {
        await _achievementsDao.insertAchievement(cloudAchievement);
      }
    }

    if (hasBatchOperations) {
      await batch.commit();
    }
  }

  DocumentReference<Map<String, dynamic>> _getAchievementRef(
      String userId,
      String achievementId,
      ) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(achievementId);
  }

  @override
  Future<void> resolveConflicts(String userId) async {
    try {
      final conflicts = await _getConflicts(userId);

      for (var conflict in conflicts) {
        await _resolveConflict(conflict);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resolving achievement conflicts: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getConflicts(String userId) async {
    final localAchievements = await _achievementsDao.getUserAchievements(userId);
    final conflicts = <Map<String, dynamic>>[];

    for (var localAchievement in localAchievements) {
      final cloudDoc = await _getAchievementRef(
        userId,
        localAchievement.id,
      ).get();

      if (cloudDoc.exists) {
        final cloudAchievement = AchievementModel.fromMap({
          ...cloudDoc.data()!,
          'id': cloudDoc.id,
        });

        if (_hasConflict(localAchievement, cloudAchievement)) {
          conflicts.add({
            'local': localAchievement,
            'cloud': cloudAchievement,
          });
        }
      }
    }

    return conflicts;
  }

  bool _hasConflict(AchievementModel local, AchievementModel cloud) {
    // No conflict if neither is unlocked
    if (local.unlockedAt == null && cloud.unlockedAt == null) {
      return false;
    }

    // Conflict if one is unlocked and the other isn't
    if ((local.unlockedAt == null) != (cloud.unlockedAt == null)) {
      return true;
    }

    // If both are unlocked, check if unlock times are different
    if (local.unlockedAt != null && cloud.unlockedAt != null) {
      return local.unlockedAt != cloud.unlockedAt;
    }

    return false;
  }

  Future<void> _resolveConflict(Map<String, dynamic> conflict) async {
    final localAchievement = conflict['local'] as AchievementModel;
    final cloudAchievement = conflict['cloud'] as AchievementModel;

    // If one is unlocked and the other isn't, prefer the unlocked version
    if (localAchievement.unlockedAt != null && cloudAchievement.unlockedAt == null) {
      await _uploadAchievementToCloud(localAchievement);
    } else if (cloudAchievement.unlockedAt != null && localAchievement.unlockedAt == null) {
      await _achievementsDao.insertAchievement(cloudAchievement);
    } else if (localAchievement.unlockedAt != null && cloudAchievement.unlockedAt != null) {
      // If both are unlocked, keep the earlier unlock time
      final keepLocal = localAchievement.unlockedAt!
          .isBefore(cloudAchievement.unlockedAt!);

      if (keepLocal) {
        await _uploadAchievementToCloud(localAchievement);
      } else {
        await _achievementsDao.insertAchievement(cloudAchievement);
      }
    }
  }

  Future<void> _uploadAchievementToCloud(AchievementModel achievement) async {
    await _getAchievementRef(achievement.userId, achievement.id)
        .set(achievement.toMap());
  }
}