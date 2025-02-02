import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/database/models/tracking_model.dart';

class FirestoreTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncTrackingHistory({
    required String userId,
    required Map<String, dynamic> trackingData,
  }) async {
    try {

      final routeList = jsonDecode(trackingData['route'] as String);
      final routeData = (routeList as List).map((point) => {
        'lat': point['lat'],
        'lng': point['lng'],
      }).toList();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tracking_history')
          .doc(trackingData['id'].toString())
          .set({
        'timestamp': DateTime.parse(trackingData['timestamp']), // Convert ISO string to DateTime
        'route': routeData,
        'total_distance': trackingData['total_distance'],
        'duration': trackingData['duration'],
        'pace_seconds': trackingData['pace_seconds'],
        'synced_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error syncing to Firestore: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFirestoreHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tracking_history')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore route format to match TrackingModel's expected format
        final routeData = (data['route'] as List).map((point) => {
          'lat': point['lat'] as double,
          'lng': point['lng'] as double,
        }).toList();

        return {
          'id': int.tryParse(doc.id) ?? 0,
          'user_id': userId,
          'timestamp': (data['timestamp'] as Timestamp).toDate().toIso8601String(),
          'route': jsonEncode(routeData), // Encode as JSON string to match TrackingModel
          'total_distance': data['total_distance'] as double?,
          'duration': data['duration'] as int?,
          'pace_seconds': data['pace_seconds'] as int?,
          'last_sync': (data['synced_at'] as Timestamp?)?.toDate().toIso8601String(),
        };
      }).toList();
    } catch (e) {
      print('Error fetching from Firestore: $e');
      rethrow;
    }
  }

  // Helper method to convert TrackingModel to Firestore data
  Map<String, dynamic> _trackingModelToFirestore(TrackingModel model) {
    final routeData = model.route.map((point) => {
      'lat': point.latitude,
      'lng': point.longitude,
    }).toList();

    return {
      'timestamp': model.timestamp,
      'route': routeData,
      'total_distance': model.totalDistance,
      'duration': model.duration,
      'pace_seconds': model.paceSeconds,
      'synced_at': FieldValue.serverTimestamp(),
    };
  }
}