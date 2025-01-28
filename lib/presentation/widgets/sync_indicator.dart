import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/services/sync_service.dart';
import '../viewmodels/sync_manager.dart';

class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncManager>(
      builder: (context, syncManager, _) {
        if (syncManager.status == SyncStatus.syncing) {
          return const IconButton(
            icon: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            onPressed: null,
          );
        }

        return IconButton(
          icon: Icon(
            syncManager.status == SyncStatus.error
                ? Icons.sync_problem
                : Icons.sync,
            color: syncManager.status == SyncStatus.error
                ? Colors.red
                : Colors.white,
          ),
          onPressed: () => syncManager.syncNow(),
        );
      },
    );
  }
}