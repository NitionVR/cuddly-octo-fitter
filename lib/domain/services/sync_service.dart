// lib/domain/services/sync_service.dart
abstract class SyncService {
  Future<void> syncWorkouts();
  Future<void> syncGoals();
  Future<void> syncAchievements();
  Future<void> syncAll();
  Future<void> resolveConflicts();
  Stream<SyncStatus> get syncStatus;
}

enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
  offline
}

class SyncResult {
  final bool success;
  final String? error;
  final int itemsSynced;
  final List<String> conflicts;

  SyncResult({
    required this.success,
    this.error,
    this.itemsSynced = 0,
    this.conflicts = const [],
  });
}