import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class FirestoreTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncTrackingHistory({
    required String userId,
    required Map<String, dynamic> trackingData,
  }) async {
    try {
      // Convert LatLng list to a format Firestore can store
      final routeData = (trackingData['route'] as List<LatLng>).map((point) => {
        'lat': point.latitude,
        'lng': point.longitude,
      }).toList();

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tracking_history')
          .doc(trackingData['id'].toString())
          .set({
        'timestamp': trackingData['timestamp'],
        'route': routeData,
        'total_distance': trackingData['total_distance'],
        'duration': trackingData['duration'],
        'avg_pace': trackingData['avg_pace'],
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
        // Convert Firestore route data back to LatLng
        final routeData = (data['route'] as List).map((point) =>
            LatLng(point['lat'], point['lng'])
        ).toList();

        return {
          'id': doc.id,
          'timestamp': (data['timestamp'] as Timestamp).toDate(),
          'route': routeData,
          'total_distance': data['total_distance'],
          'duration': data['duration'],
          'avg_pace': data['avg_pace'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching from Firestore: $e');
      rethrow;
    }
  }
}