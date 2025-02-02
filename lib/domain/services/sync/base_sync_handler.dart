import 'package:cloud_firestore/cloud_firestore.dart';

abstract class BaseSyncHandler {
  final FirebaseFirestore firestore;

  BaseSyncHandler(this.firestore);

  Future<void> sync(String userId);
  Future<void> resolveConflicts(String userId);
}