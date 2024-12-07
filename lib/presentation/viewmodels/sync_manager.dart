// lib/presentation/viewmodels/sync_manager.dart
import 'package:flutter/foundation.dart';
import '../../domain/services/sync_service.dart';

class SyncManager extends ChangeNotifier {
  final SyncService _syncService;
  SyncStatus _status = SyncStatus.idle;
  String? _error;

  SyncManager(this._syncService) {
    _syncService.syncStatus.listen((status) {
      _status = status;
      notifyListeners();
    });
  }

  SyncStatus get status => _status;
  String? get error => _error;
  bool get isSyncing => _status == SyncStatus.syncing;

  Future<void> syncNow() async {
    try {
      await _syncService.syncAll();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> resolveConflicts() async {
    try {
      await _syncService.resolveConflicts();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }
}