// lib/data/services/sync/training_plans_sync_handler.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../data/database/dao/training_plan_dao.dart';
import '../../../data/database/models/training_plan_model.dart';
import 'base_sync_handler.dart';

class TrainingPlansSyncHandler extends BaseSyncHandler {
  final TrainingPlanDao _trainingPlanDao;

  TrainingPlansSyncHandler(super.firestore, this._trainingPlanDao);

  @override
  Future<void> sync(String userId) async {
    try {
      // Get local plans
      final localPlans = await _trainingPlanDao.getAvailablePlans(userId);

      // Get global templates and user-specific plans
      final globalPlans = await firestore
          .collection('training_plans')
          .where('isTemplate', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      final userPlans = await firestore
          .collection('users')
          .doc(userId)
          .collection('training_plans')
          .get();

      // Combine cloud plans
      final cloudPlans = [
        ...globalPlans.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return TrainingPlanModel.fromMap(data);
        }),
        ...userPlans.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return TrainingPlanModel.fromMap(data);
        }),
      ];

      await _handleSync(localPlans, cloudPlans);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing training plans: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleSync(
      List<TrainingPlanModel> localPlans,
      List<TrainingPlanModel> cloudPlans,
      ) async {
    final localPlansMap = {for (var plan in localPlans) plan.id: plan};
    final cloudPlansMap = {for (var plan in cloudPlans) plan.id: plan};
    final batch = firestore.batch();
    bool hasBatchOperations = false;

    // Handle local plans that need to be synced to cloud
    for (var localPlan in localPlans) {
      // Skip templates as they should be read-only
      if (localPlan.isTemplate) continue;

      final cloudPlan = cloudPlansMap[localPlan.id];

      if (cloudPlan == null) {
        // Plan exists locally but not in cloud - upload it
        batch.set(
          _getPlanRef(localPlan.userId, localPlan.id),
          localPlan.toMap(),
        );
        hasBatchOperations = true;
      } else if (localPlan.lastUpdated.isAfter(cloudPlan.lastUpdated)) {
        // Local plan is newer - update cloud
        batch.update(
          _getPlanRef(localPlan.userId, localPlan.id),
          localPlan.toMap(),
        );
        hasBatchOperations = true;
      } else {
        // Cloud plan is newer - update local
        await _trainingPlanDao.updatePlan(cloudPlan);
      }
    }

    // Handle cloud plans that don't exist locally
    for (var cloudPlan in cloudPlans) {
      if (!localPlansMap.containsKey(cloudPlan.id)) {
        await _trainingPlanDao.insertPlan(cloudPlan);
      }
    }

    if (hasBatchOperations) {
      await batch.commit();
    }
  }

  DocumentReference<Map<String, dynamic>> _getPlanRef(
      String userId,
      String planId,
      ) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('training_plans')
        .doc(planId);
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
        print('Error resolving training plan conflicts: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getConflicts(String userId) async {
    final localPlans = await _trainingPlanDao.getAvailablePlans(userId);
    final conflicts = <Map<String, dynamic>>[];

    for (var localPlan in localPlans) {
      // Skip templates as they should be read-only
      if (localPlan.isTemplate) continue;

      final cloudDoc = await _getPlanRef(userId, localPlan.id).get();

      if (cloudDoc.exists) {
        final cloudPlan = TrainingPlanModel.fromMap({
          ...cloudDoc.data()!,
          'id': cloudDoc.id,
        });

        if (_hasConflict(localPlan, cloudPlan)) {
          conflicts.add({
            'local': localPlan,
            'cloud': cloudPlan,
          });
        }
      }
    }

    return conflicts;
  }

  bool _hasConflict(TrainingPlanModel local, TrainingPlanModel cloud) {
    // No conflict if last update times are the same
    if (local.lastUpdated == cloud.lastUpdated) return false;

    // Check for specific conflict conditions
    return local.isActive != cloud.isActive ||
        local.completedDate != cloud.completedDate ||
        local.weeks != cloud.weeks;  // Compare serialized weeks data
  }

  Future<void> _resolveConflict(Map<String, dynamic> conflict) async {
    final localPlan = conflict['local'] as TrainingPlanModel;
    final cloudPlan = conflict['cloud'] as TrainingPlanModel;

    // Skip templates
    if (localPlan.isTemplate || cloudPlan.isTemplate) return;

    // Resolution strategy:
    // 1. If one is completed and the other isn't, prefer the completed version
    // 2. If completion status is the same, use the most recently updated version
    final localCompleted = localPlan.completedDate != null;
    final cloudCompleted = cloudPlan.completedDate != null;

    if (localCompleted != cloudCompleted) {
      // Prefer the completed version
      if (localCompleted) {
        await _uploadPlanToCloud(localPlan);
      } else {
        await _trainingPlanDao.updatePlan(cloudPlan);
      }
    } else {
      // Use the most recently updated version
      final keepLocal = localPlan.lastUpdated.isAfter(cloudPlan.lastUpdated);

      if (keepLocal) {
        await _uploadPlanToCloud(localPlan);
      } else {
        await _trainingPlanDao.updatePlan(cloudPlan);
      }
    }
  }

  Future<void> _uploadPlanToCloud(TrainingPlanModel plan) async {
    // Skip templates
    if (plan.isTemplate) return;

    await _getPlanRef(plan.userId, plan.id).set(plan.toMap());
  }
}