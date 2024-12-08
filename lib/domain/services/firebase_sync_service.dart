import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/services/sync_service.dart';


class FirebaseSyncService implements SyncService {
  final FirebaseFirestore _firestore;
  final DatabaseHelper _databaseHelper;
  final StreamController<SyncStatus> _syncStatusController;
  Timer? _syncTimer;
  bool _isSyncing = false;

  FirebaseSyncService({
    FirebaseFirestore? firestore,
    DatabaseHelper? databaseHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
        _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _syncStatusController = StreamController<SyncStatus>.broadcast() {
    _initializeSync();
  }

  void _initializeSync() {
    // Set up periodic sync (every 15 minutes)
    _syncTimer = Timer.periodic(Duration(minutes: 15), (_) => syncAll());

    // Initialize connectivity subscription
    final subscription = Connectivity().onConnectivityChanged;
    subscription.listen((update) async {
      if (update != ConnectivityResult.none) {
        await syncAll();
      }
    });
  }


  @override
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  @override
  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _syncStatusController.add(SyncStatus.offline);
        return;
      }

      await Future.wait([
        syncWorkouts(),
        syncGoals(),
        syncAchievements(),
      ]);

      _syncStatusController.add(SyncStatus.completed);
    } catch (e) {
      print('Sync error: $e');
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> syncWorkouts() async {
    final db = await _databaseHelper.database;

    // Get local workouts that haven't been synced
    final unsynced = await db.query(
      'workouts',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    // Upload unsynced workouts to Firestore
    for (final workout in unsynced) {
      try {
        final docRef = _firestore.collection('workouts').doc(workout['id'] as String);
        final cloudWorkout = await docRef.get();

        if (cloudWorkout.exists) {
          // Handle conflict
          final localLastModified = DateTime.parse(workout['lastModified'] as String);
          final cloudLastModified = cloudWorkout.data()?['lastModified'] as Timestamp;

          if (cloudLastModified.toDate().isAfter(localLastModified)) {
            // Cloud version is newer, update local
            await _updateLocalWorkout(workout['id'] as String, cloudWorkout.data()!);
          } else {
            // Local version is newer, update cloud
            await docRef.set(workout);
          }
        } else {
          // No conflict, just upload
          await docRef.set(workout);
        }

        // Mark as synced in local DB
        await db.update(
          'workouts',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [workout['id']],
        );
      } catch (e) {
        print('Error syncing workout ${workout['id']}: $e');
      }
    }

    // Download new workouts from Firestore
    final lastSync = await _getLastSyncTime();
    final newWorkouts = await _firestore
        .collection('workouts')
        .where('lastModified', isGreaterThan: lastSync)
        .get();

    for (final doc in newWorkouts.docs) {
      await _updateLocalWorkout(doc.id, doc.data());
    }

    await _updateLastSyncTime();
  }

  Future<void> _updateLocalWorkout(String id, Map<String, dynamic> data) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'workouts',
      {...data, 'id': id, 'isSynced': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> syncGoals() async {
    final db = await _databaseHelper.database;

    // Sync unsynced local goals
    final unsynced = await db.query(
      'goals',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    for (final goal in unsynced) {
      try {
        final docRef = _firestore.collection('goals').doc(goal['id'] as String);
        final cloudGoal = await docRef.get();

        if (cloudGoal.exists) {
          final localLastModified = DateTime.parse(goal['lastUpdated'] as String);
          final cloudLastModified = cloudGoal.data()?['lastUpdated'] as Timestamp;

          if (cloudLastModified.toDate().isAfter(localLastModified)) {
            await _updateLocalGoal(goal['id'] as String, cloudGoal.data()!);
          } else {
            await docRef.set(goal);
          }
        } else {
          await docRef.set(goal);
        }

        await db.update(
          'goals',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [goal['id']],
        );
      } catch (e) {
        print('Error syncing goal ${goal['id']}: $e');
      }
    }

    // Get new goals from cloud
    final lastSync = await _getLastSyncTime();
    final newGoals = await _firestore
        .collection('goals')
        .where('lastUpdated', isGreaterThan: lastSync)
        .get();

    for (final doc in newGoals.docs) {
      await _updateLocalGoal(doc.id, doc.data());
    }
  }

  Future<void> _updateLocalGoal(String id, Map<String, dynamic> data) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'goals',
      {...data, 'id': id, 'isSynced': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  @override
  Future<void> syncAchievements() async {
    final db = await _databaseHelper.database;

    // Sync unsynced local achievements
    final unsynced = await db.query(
      'achievements',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    for (final achievement in unsynced) {
      try {
        final docRef = _firestore.collection('achievements').doc(achievement['id'] as String);
        final cloudAchievement = await docRef.get();

        if (cloudAchievement.exists) {
          final localLastModified = DateTime.parse(achievement['lastModified'] as String);
          final cloudLastModified = cloudAchievement.data()?['lastModified'] as Timestamp;

          if (cloudLastModified.toDate().isAfter(localLastModified)) {
            await _updateLocalAchievement(achievement['id'] as String, cloudAchievement.data()!);
          } else {
            await docRef.set(achievement);
          }
        } else {
          await docRef.set(achievement);
        }

        await db.update(
          'achievements',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [achievement['id']],
        );
      } catch (e) {
        print('Error syncing achievement ${achievement['id']}: $e');
      }
    }

    // Get new achievements from cloud
    final lastSync = await _getLastSyncTime();
    final newAchievements = await _firestore
        .collection('achievements')
        .where('lastModified', isGreaterThan: lastSync)
        .get();

    for (final doc in newAchievements.docs) {
      await _updateLocalAchievement(doc.id, doc.data());
    }
  }

  Future<void> _updateLocalAchievement(String id, Map<String, dynamic> data) async {
    final db = await _databaseHelper.database;
    await db.insert(
      'achievements',
      {...data, 'id': id, 'isSynced': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  @override
  Future<void> resolveConflicts() async {
    final db = await _databaseHelper.database;

    // Get all data with sync conflicts
    final conflicts = await Future.wait([
      _getConflicts('workouts'),
      _getConflicts('goals'),
      _getConflicts('achievements'),
    ]);

    for (var conflictList in conflicts) {
      for (var conflict in conflictList) {
        try {
          // Default resolution: newest version wins
          final localData = conflict['local'];
          final cloudData = conflict['cloud'];

          final localTime = DateTime.parse(localData['lastModified'] as String);
          final cloudTime = (cloudData['lastModified'] as Timestamp).toDate();

          if (cloudTime.isAfter(localTime)) {
            await _updateLocalData(
              conflict['table'] as String,
              conflict['id'] as String,
              cloudData,
            );
          } else {
            await _updateCloudData(
              conflict['table'] as String,
              conflict['id'] as String,
              localData,
            );
          }
        } catch (e) {
          print('Error resolving conflict: $e');
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getConflicts(String table) async {
    final db = await _databaseHelper.database;
    final localData = await db.query(table);
    final conflicts = <Map<String, dynamic>>[];

    for (var local in localData) {
      final docRef = _firestore.collection(table).doc(local['id'] as String);
      final cloud = await docRef.get();

      if (cloud.exists && cloud.data() != local) {
        conflicts.add({
          'table': table,
          'id': local['id'],
          'local': local,
          'cloud': cloud.data()!,
        });
      }
    }

    return conflicts;
  }

  Future<void> _updateLocalData(String table, String id, Map<String, dynamic> data) async {
    final db = await _databaseHelper.database;
    await db.insert(
      table,
      {...data, 'id': id, 'isSynced': 1},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _updateCloudData(String table, String id, Map<String, dynamic> data) async {
    await _firestore.collection(table).doc(id).set(data);
  }

  Future<DateTime> _getLastSyncTime() async {
    final db = await _databaseHelper.database;
    final result = await db.query('sync_info');
    if (result.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.parse(result.first['last_sync'] as String);
  }

  Future<void> _updateLastSyncTime() async {
    final db = await _databaseHelper.database;
    await db.insert(
      'sync_info',
      {'last_sync': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}