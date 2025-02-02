import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../../../domain/repository/tracking/tracking_repository.dart';
import '../../../domain/services/firestore_tracking_service.dart';
import '../../../utils/pace_utils.dart';
import '../../models/running_stats.dart';
import '../../models/weekly_summary.dart';
import '../dao/tracking_dao.dart';
import '../models/tracking_model.dart';


class TrackingRepositoryImpl implements ITrackingRepository {
  final TrackingDao _trackingDao;
  final FirestoreTrackingService _firestoreService;

  TrackingRepositoryImpl(this._trackingDao, this._firestoreService);

  @override
  Future<void> saveTrackingData({
    required String userId,
    required DateTime timestamp,
    required List<LatLng> route,
    double? totalDistance,
    int? duration,
    int? paceSeconds,
  }) async {
    if (kDebugMode) {
      print("=== Repository Saving Data ===");
      print("Total Distance received: $totalDistance");
      print("Route points: ${route.length}");
    }

    if (route.isEmpty) {
      throw ArgumentError('Route cannot be empty');
    }

    final trackingModel = TrackingModel(
      userId: userId,
      timestamp: timestamp,
      route: route,
      totalDistance: totalDistance,
      duration: duration,
      paceSeconds: paceSeconds,
      lastSync: DateTime.now(),
    );

    await _trackingDao.saveTracking(trackingModel);
  }

  @override
  Future<List<TrackingModel>> fetchTrackingHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _trackingDao.getTrackingHistory(
        userId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tracking history: $e');
      }
      return [];
    }
  }

  @override
  Future<List<TrackingModel>> fetchTrackingHistoryByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      return await _trackingDao.getTrackingHistoryByDateRange(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tracking history by date range: $e');
      }
      return [];
    }
  }

  @override
  Future<TrackingModel?> fetchSingleTrackingHistory({
    required String userId,
    required int id,
  }) async {
    try {
      return await _trackingDao.getTrackingHistoryById(userId, id);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching single tracking history: $e');
      }
      return null;
    }
  }

  @override
  Future<void> clearTrackingHistory(String userId) async {
    try {
      await _trackingDao.clearTrackingHistory(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing tracking history: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteSpecificTrackingHistory({
    required String userId,
    required int id,
  }) async {
    try {
      await _trackingDao.deleteSpecificHistory(userId, id);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting specific tracking history: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> syncWithFirestore(String userId) async {
    try {
      final unsyncedRecords = await _trackingDao.getUnsyncedRecords(userId);

      for (var record in unsyncedRecords) {
        await _firestoreService.syncTrackingHistory(
          userId: userId,
          trackingData: record.toMap(),
        );

        await _trackingDao.updateSyncStatus(record);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during sync: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> mergeFirestoreData(String userId) async {
    try {
      final firestoreData = await _firestoreService.fetchFirestoreHistory(userId);
      await _trackingDao.mergeFirestoreData(userId, firestoreData);
    } catch (e) {
      if (kDebugMode) {
        print('Error merging Firestore data: $e');
      }
      rethrow;
    }
  }

  @override
  Future<RunningStats> getRunningStats(String userId) async {
    try {
      final history = await fetchTrackingHistory(userId: userId);
      double totalDistance = 0;
      Duration totalDuration = Duration.zero;
      double longestRun = 0;
      int? fastestPaceSeconds;
      Duration longestDuration = Duration.zero;

      for (var run in history) {
        final distance = run.totalDistance ?? 0.0;
        final duration = Duration(seconds: run.duration ?? 0);
        final paceSeconds = run.paceSeconds;

        totalDistance += distance;
        totalDuration += duration;

        if (distance > longestRun) longestRun = distance;
        if (duration > longestDuration) longestDuration = duration;

        if (paceSeconds != null && (fastestPaceSeconds == null || paceSeconds < fastestPaceSeconds)) {
          fastestPaceSeconds = paceSeconds;
        }
        print(fastestPaceSeconds);
      }

      return RunningStats(
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        averagePace: PaceUtils.formatPace(
          PaceUtils.calculatePaceSeconds(totalDistance, totalDuration.inSeconds),
        ),
        totalRuns: history.length,
        longestRun: longestRun,
        fastestPace: PaceUtils.formatPace(fastestPaceSeconds ?? 0),
        longestDuration: longestDuration,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in getRunningStats: $e');
      }
      return RunningStats.empty();
    }
  }

  @override
  Future<Map<String, dynamic>> getTrackingAnalytics(String userId) async {
    try {
      final history = await fetchTrackingHistory(userId: userId);

      if (history.isEmpty) {
        return {
          'totalRuns': 0,
          'totalDistance': 0.0,
          'totalDuration': 0,
          'averagePace': '0:00 min/km',
        };
      }

      double totalDistance = 0.0;
      int totalDuration = 0;
      List<int> paceSeconds = [];

      for (var run in history) {
        totalDistance += run.totalDistance ?? 0.0;
        totalDuration += run.duration ?? 0;

        if (run.paceSeconds != null && run.paceSeconds! > 0) {
          paceSeconds.add(run.paceSeconds!);
        }
      }

      return {
        'totalRuns': history.length,
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'averagePace': PaceUtils.formatPace(
          PaceUtils.calculateAveragePaceSeconds(paceSeconds),
        ),
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in getTrackingAnalytics: $e');
      }
      return {
        'totalRuns': 0,
        'totalDistance': 0.0,
        'totalDuration': 0,
        'averagePace': '0:00 min/km',
      };
    }
  }

  @override
  Future<List<WeeklySummary>> getWeeklySummaries(String userId) async {
    final history = await fetchTrackingHistory(userId: userId);
    final Map<String, List<TrackingModel>> weeklyRuns = {};

    for (var run in history) {
      final weekStart = _getWeekStart(run.timestamp);
      final weekKey = weekStart.toString();

      weeklyRuns.putIfAbsent(weekKey, () => []);
      weeklyRuns[weekKey]!.add(run);
    }

    return weeklyRuns.entries.map((entry) {
      final runs = entry.value;
      double totalDistance = 0;
      Duration totalDuration = Duration.zero;

      for (var run in runs) {
        totalDistance += run.totalDistance ?? 0;
        totalDuration += Duration(seconds: run.duration ?? 0);
      }

      return WeeklySummary(
        weekStart: DateTime.parse(entry.key),
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        numberOfRuns: runs.length,
        averagePace: PaceUtils.formatPace(
          PaceUtils.calculatePaceSeconds(totalDistance, totalDuration.inSeconds),
          includeUnits: false,
        ),
      );
    }).toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - date.weekday + 1);
  }
}