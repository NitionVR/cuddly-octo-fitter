// lib/domain/repositories/tracking_repository.dart
import 'package:latlong2/latlong.dart';
import '../../../data/database/models/tracking_model.dart';
import '../../../data/models/running_stats.dart';
import '../../../data/models/weekly_summary.dart';

abstract class ITrackingRepository {
  Future<void> saveTrackingData({
    required String userId,
    required DateTime timestamp,
    required List<LatLng> route,
    double? totalDistance,
    int? duration,
    int? paceSeconds,
  });

  Future<List<TrackingModel>> fetchTrackingHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  });

  Future<List<TrackingModel>> fetchTrackingHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  });

  Future<TrackingModel?> fetchSingleTrackingHistory({
    required String userId,
    required int id,
  });

  Future<void> syncWithFirestore(String userId);

  Future<RunningStats> getRunningStats(String userId);

  Future<List<WeeklySummary>> getWeeklySummaries(String userId);

  Future<Map<String, dynamic>> getTrackingAnalytics(String userId);

  Future<void> clearTrackingHistory(String userId);

  Future<void> deleteSpecificTrackingHistory({
    required String userId,
    required int id,
  });

  Future<void> mergeFirestoreData(String userId);
}