// lib/data/services/sync/workouts_sync_handler.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../data/database/dao/completed_workouts_dao.dart';
import '../../../data/database/models/completed_workout_model.dart';
import 'base_sync_handler.dart';

class WorkoutsSyncHandler extends BaseSyncHandler {
  final CompletedWorkoutsDao _completedWorkoutsDao;

  WorkoutsSyncHandler(FirebaseFirestore firestore, this._completedWorkoutsDao)
      : super(firestore);

  @override
  Future<void> sync(String userId) async {
    try {
      // Get local completed workouts
      final localWorkouts = await _completedWorkoutsDao.getCompletedWorkouts(userId);

      // Get cloud completed workouts
      final cloudSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('completed_workouts')
          .get();

      final cloudWorkouts = cloudSnapshot.docs.map((doc) {
        final data = doc.data();
        data['workoutId'] = doc.id;
        return CompletedWorkoutModel.fromMap(data);
      }).toList();

      await _handleSync(localWorkouts, cloudWorkouts);
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing workouts: $e');
      }
      rethrow;
    }
  }

  Future<void> _handleSync(
      List<CompletedWorkoutModel> localWorkouts,
      List<CompletedWorkoutModel> cloudWorkouts,
      ) async {
    final localWorkoutsMap = {
      for (var workout in localWorkouts)
        '${workout.userId}_${workout.workoutId}': workout
    };
    final cloudWorkoutsMap = {
      for (var workout in cloudWorkouts)
        '${workout.userId}_${workout.workoutId}': workout
    };
    final batch = firestore.batch();
    bool hasBatchOperations = false;

    // Handle local workouts that need to be synced to cloud
    for (var localWorkout in localWorkouts) {
      final key = '${localWorkout.userId}_${localWorkout.workoutId}';
      final cloudWorkout = cloudWorkoutsMap[key];

      if (cloudWorkout == null) {
        // Workout exists locally but not in cloud - upload it
        batch.set(
          _getWorkoutRef(localWorkout.userId, localWorkout.workoutId),
          localWorkout.toMap(),
        );
        hasBatchOperations = true;
      } else {
        // Handle completion status
        final localCompleted = localWorkout.completed;
        final cloudCompleted = cloudWorkout.completed;
        final localCompletedAt = localWorkout.completedAt;
        final cloudCompletedAt = cloudWorkout.completedAt;

        if (localCompleted && !cloudCompleted) {
          // Local workout is completed but cloud isn't - update cloud
          batch.update(
            _getWorkoutRef(localWorkout.userId, localWorkout.workoutId),
            localWorkout.toMap(),
          );
          hasBatchOperations = true;
        } else if (!localCompleted && cloudCompleted) {
          // Cloud workout is completed but local isn't - update local
          await _completedWorkoutsDao.updateWorkoutStatus(cloudWorkout);
        } else if (localCompleted && cloudCompleted &&
            localCompletedAt != null && cloudCompletedAt != null) {
          // Both are completed - keep the earlier completion time
          final workoutToKeep = localCompletedAt.isBefore(cloudCompletedAt)
              ? localWorkout
              : cloudWorkout;

          if (workoutToKeep == localWorkout) {
            batch.update(
              _getWorkoutRef(localWorkout.userId, localWorkout.workoutId),
              localWorkout.toMap(),
            );
            hasBatchOperations = true;
          } else {
            await _completedWorkoutsDao.updateWorkoutStatus(cloudWorkout);
          }
        }
      }
    }

    // Handle cloud workouts that don't exist locally
    for (var cloudWorkout in cloudWorkouts) {
      final key = '${cloudWorkout.userId}_${cloudWorkout.workoutId}';
      if (!localWorkoutsMap.containsKey(key)) {
        await _completedWorkoutsDao.updateWorkoutStatus(cloudWorkout);
      }
    }

    if (hasBatchOperations) {
      await batch.commit();
    }
  }

  DocumentReference<Map<String, dynamic>> _getWorkoutRef(
      String userId,
      String workoutId,
      ) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('completed_workouts')
        .doc(workoutId);
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
        print('Error resolving workout conflicts: $e');
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getConflicts(String userId) async {
    final localWorkouts = await _completedWorkoutsDao.getCompletedWorkouts(userId);
    final conflicts = <Map<String, dynamic>>[];

    for (var localWorkout in localWorkouts) {
      final cloudDoc = await _getWorkoutRef(
        userId,
        localWorkout.workoutId,
      ).get();

      if (cloudDoc.exists) {
        final cloudWorkout = CompletedWorkoutModel.fromMap({
          ...cloudDoc.data()!,
          'workoutId': cloudDoc.id,
        });

        if (_hasConflict(localWorkout, cloudWorkout)) {
          conflicts.add({
            'local': localWorkout,
            'cloud': cloudWorkout,
          });
        }
      }
    }

    return conflicts;
  }

  bool _hasConflict(CompletedWorkoutModel local, CompletedWorkoutModel cloud) {
    // No conflict if completion status and time are the same
    if (local.completed == cloud.completed &&
        local.completedAt == cloud.completedAt) {
      return false;
    }

    // Conflict if completion status differs
    if (local.completed != cloud.completed) {
      return true;
    }

    // If both are completed, conflict if completion times differ
    if (local.completed && cloud.completed &&
        local.completedAt != cloud.completedAt) {
      return true;
    }

    return false;
  }

  Future<void> _resolveConflict(Map<String, dynamic> conflict) async {
    final localWorkout = conflict['local'] as CompletedWorkoutModel;
    final cloudWorkout = conflict['cloud'] as CompletedWorkoutModel;

    // If one is completed and the other isn't, prefer the completed version
    if (localWorkout.completed && !cloudWorkout.completed) {
      await _uploadWorkoutToCloud(localWorkout);
    } else if (!localWorkout.completed && cloudWorkout.completed) {
      await _completedWorkoutsDao.updateWorkoutStatus(cloudWorkout);
    } else if (localWorkout.completed && cloudWorkout.completed &&
        localWorkout.completedAt != null && cloudWorkout.completedAt != null) {
      // If both are completed, keep the earlier completion time
      final keepLocal = localWorkout.completedAt!.isBefore(cloudWorkout.completedAt!);

      if (keepLocal) {
        await _uploadWorkoutToCloud(localWorkout);
      } else {
        await _completedWorkoutsDao.updateWorkoutStatus(cloudWorkout);
      }
    }
  }

  Future<void> _uploadWorkoutToCloud(CompletedWorkoutModel workout) async {
    await _getWorkoutRef(workout.userId, workout.workoutId)
        .set(workout.toMap());
  }
}