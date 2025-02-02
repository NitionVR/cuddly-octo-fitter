import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../data/database/dao/goals_dao.dart';
import '../../../data/database/models/goals_model.dart';
import 'base_sync_handler.dart';

class GoalsSyncHandler extends BaseSyncHandler {
  final GoalsDao _goalsDao;

  GoalsSyncHandler(FirebaseFirestore firestore, this._goalsDao) : super(firestore);

  @override
  Future<void> sync(String userId) async {
    try {
      final localGoals = await _goalsDao.getUserGoals(userId);
      print(localGoals);
      final cloudSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('goals')
          .get();

      final cloudGoals = cloudSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GoalsModel.fromMap(data);
      }).toList();

      await _handleSync(localGoals, cloudGoals);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing goals: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleSync(List<GoalsModel> localGoals, List<GoalsModel> cloudGoals) async {
    final localGoalsMap = {for (var goal in localGoals) goal.id: goal};
    final cloudGoalsMap = {for (var goal in cloudGoals) goal.id: goal};
    final batch = firestore.batch();
    bool hasBatchOperations = false;

    // Handle local goals that need to be synced to cloud
    for (var localGoal in localGoals) {
      final cloudGoal = cloudGoalsMap[localGoal.id];

      if (cloudGoal == null) {
        // Goal exists locally but not in cloud - upload it
        batch.set(
          _getGoalRef(localGoal.userId, localGoal.id),
          _convertToFirestore(localGoal), // Convert to Firestore format
        );
        hasBatchOperations = true;
      } else {
        // Goal exists in both places - check which is newer
        if (localGoal.lastUpdated.isAfter(cloudGoal.lastUpdated)) {
          batch.update(
            _getGoalRef(localGoal.userId, localGoal.id),
            _convertToFirestore(localGoal), // Convert to Firestore format
          );
          hasBatchOperations = true;
        } else {
          await _goalsDao.updateGoal(cloudGoal);
        }
      }
    }

    // Handle cloud goals that don't exist locally
    for (var cloudGoal in cloudGoals) {
      if (!localGoalsMap.containsKey(cloudGoal.id)) {
        await _goalsDao.insertGoal(cloudGoal);
      }
    }

    if (hasBatchOperations) {
      await batch.commit();
    }
  }

  DocumentReference<Map<String, dynamic>> _getGoalRef(String userId, String goalId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('goals')
        .doc(goalId);
  }

  Map<String, dynamic> _convertToFirestore(GoalsModel goal) {
    return {
      'id': goal.id,
      'userId': goal.userId,
      'type': goal.type.toString(),
      'period': goal.period.toString(),
      'target': goal.target,
      'currentProgress': goal.currentProgress,
      'startDate': goal.startDate.toIso8601String(),
      'endDate': goal.endDate.toIso8601String(),
      'isCompleted': goal.isCompleted, // Keep as boolean for Firestore
      'lastUpdated': goal.lastUpdated.toIso8601String(),
      'isActive': goal.isActive, // Keep as boolean for Firestore
    };
  }

  Future<void> _uploadGoalToCloud(GoalsModel goal) async {
    await _getGoalRef(goal.userId, goal.id).set(_convertToFirestore(goal));
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
        print('Error resolving goal conflicts: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getConflicts(String userId) async {
    final localGoals = await _goalsDao.getUserGoals(userId);
    final conflicts = <Map<String, dynamic>>[];

    for (var localGoal in localGoals) {
      final cloudDoc = await _getGoalRef(userId, localGoal.id).get();

      if (cloudDoc.exists) {
        final cloudGoal = GoalsModel.fromMap({
          ...cloudDoc.data()!,
          'id': cloudDoc.id,
        });

        if (_hasConflict(localGoal, cloudGoal)) {
          conflicts.add({
            'local': localGoal,
            'cloud': cloudGoal,
          });
        }
      }
    }

    return conflicts;
  }

  bool _hasConflict(GoalsModel local, GoalsModel cloud) {
    // Define what constitutes a conflict
    if (local.lastUpdated == cloud.lastUpdated) return false;

    // Check for specific conflict conditions
    return local.currentProgress != cloud.currentProgress ||
        local.isCompleted != cloud.isCompleted ||
        local.isActive != cloud.isActive;
  }

  Future<void> _resolveConflict(Map<String, dynamic> conflict) async {
    final localGoal = conflict['local'] as GoalsModel;
    final cloudGoal = conflict['cloud'] as GoalsModel;

    // Resolution strategy: Keep the most recently updated version
    final keepLocal = localGoal.lastUpdated.isAfter(cloudGoal.lastUpdated);

    if (keepLocal) {
      // Update cloud with local version
      await _getGoalRef(localGoal.userId, localGoal.id)
          .update(localGoal.toMap());
    } else {
      // Update local with cloud version
      await _goalsDao.updateGoal(cloudGoal);
    }
  }

}