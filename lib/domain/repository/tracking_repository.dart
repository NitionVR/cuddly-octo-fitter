import 'package:latlong2/latlong.dart';
import '../../data/datasources/local/tracking_local_data_source.dart';
import '../../data/models/running_stats.dart';
import '../../data/models/weekly_summary.dart';

class TrackingRepository {
  final TrackingLocalDataSource localDataSource;

  TrackingRepository(this.localDataSource);

  Future<void> saveTrackingData({
    required DateTime timestamp,
    required List<LatLng> route,
    double? totalDistance,
    int? duration,
    String? avgPace,
  }) async {
    // Additional validation if needed
    if (route.isEmpty) {
      throw ArgumentError('Route cannot be empty');
    }

    await localDataSource.saveTrackingHistory(
      timestamp: timestamp,
      route: route,
      totalDistance: totalDistance,
      duration: duration,
      avgPace: avgPace,
    );
  }

  Future<List<Map<String, dynamic>>> fetchTrackingHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final history = await localDataSource.getTrackingHistory(
        limit: limit,
        offset: offset,
      );
      return history;
    } catch (e) {
      print('Error fetching tracking history: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchTrackingHistoryByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      final history = await localDataSource.getTrackingHistoryByDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
      return history;
    } catch (e) {
      print('Error fetching tracking history by date range: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchSingleTrackingHistory(int id) async {
    try {
      return await localDataSource.getTrackingHistoryById(id);
    } catch (e) {
      print('Error fetching single tracking history: $e');
      return null;
    }
  }

  Future<void> clearTrackingHistory() async {
    try {
      await localDataSource.clearTrackingHistory();
    } catch (e) {
      print('Error clearing tracking history: $e');
    }
  }

  Future<void> deleteSpecificTrackingHistory(int id) async {
    try {
      await localDataSource.deleteSpecificHistory(id);
    } catch (e) {
      print('Error deleting specific tracking history: $e');
    }
  }

  Future<String> exportTrackingHistory() async {
    try {
      return await localDataSource.exportTrackingHistoryToJson();
    } catch (e) {
      print('Error exporting tracking history: $e');
      return '[]';
    }
  }

  // Analytics methods
  Future<Map<String, dynamic>> getTrackingAnalytics() async {
    try {
      final history = await fetchTrackingHistory();

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
      List<String> paces = [];

      for (var entry in history) {
        // Handle distance
        totalDistance += (entry['total_distance'] as num?)?.toDouble() ?? 0.0;

        // Handle duration
        totalDuration += (entry['duration'] as num?)?.toInt() ?? 0;

        // Handle pace
        final pace = entry['avg_pace'] as String?;
        if (pace != null && pace.contains(':')) {
          // Only add valid pace formats (containing ':')
          paces.add(pace);
        }
      }

      return {
        'totalRuns': history.length,
        'totalDistance': totalDistance,
        'totalDuration': totalDuration,
        'averagePace': paces.isNotEmpty
            ? _calculateAveragePace(paces)
            : '0:00 min/km',
      };
    } catch (e) {
      print('Error in getTrackingAnalytics: $e');
      return {
        'totalRuns': 0,
        'totalDistance': 0.0,
        'totalDuration': 0,
        'averagePace': '0:00 min/km',
      };
    }
  }

  String _calculateAveragePace(List<String> paces) {
    try {
      // Convert all paces to total seconds
      final List<int> secondsList = paces.map((pace) {
        final parts = pace.split(':');
        final minutes = int.parse(parts[0]);
        final seconds = parts.length > 1 ? int.parse(parts[1]) : 0;
        return minutes * 60 + seconds;
      }).toList();

      // Calculate average seconds
      final averageSeconds = secondsList.reduce((a, b) => a + b) / secondsList.length;

      // Convert back to min:sec format
      final minutes = (averageSeconds ~/ 60);
      final seconds = (averageSeconds % 60).round();

      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error calculating average pace: $e');
      return '0:00';
    }
  }

  Future<RunningStats> getRunningStats() async {
    try {
      final history = await fetchTrackingHistory();
      double totalDistance = 0;
      Duration totalDuration = Duration.zero;
      double longestRun = 0;
      String fastestPace = "0:00 min/km";
      Duration longestDuration = Duration.zero;

      for (var run in history) {
        // Safely handle distance
        final distance = (run['total_distance'] as num?)?.toDouble() ?? 0.0;
        // Safely handle duration
        final duration = Duration(seconds: (run['duration'] as num?)?.toInt() ?? 0);

        totalDistance += distance;
        totalDuration += duration;

        if (distance > longestRun) longestRun = distance;
        if (duration > longestDuration) longestDuration = duration;

        // Safely handle pace comparison
        final currentPace = run['avg_pace'] as String? ?? "0:00 min/km";
        if (fastestPace == "0:00 min/km" || _comparePaceSafely(currentPace, fastestPace) < 0) {
          fastestPace = currentPace;
        }
      }

      return RunningStats(
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        averagePace: _calculateAveragePaceFromDistanceAndDuration(totalDistance, totalDuration),
        totalRuns: history.length,
        longestRun: longestRun,
        fastestPace: fastestPace,
        longestDuration: longestDuration,
      );
    } catch (e) {
      print('Error in getRunningStats: $e');
      // Return default stats if calculation fails
      return RunningStats(
        totalDistance: 0,
        totalDuration: Duration.zero,
        averagePace: "0:00 min/km",
        totalRuns: 0,
        longestRun: 0,
        fastestPace: "0:00 min/km",
        longestDuration: Duration.zero,
      );
    }
  }

  int _comparePaceSafely(String pace1, String pace2) {
    try {
      final parts1 = pace1.split(':');
      final parts2 = pace2.split(':');

      // Convert to seconds for comparison
      final seconds1 = int.parse(parts1[0]) * 60 + (parts1.length > 1 ? int.parse(parts1[1]) : 0);
      final seconds2 = int.parse(parts2[0]) * 60 + (parts2.length > 1 ? int.parse(parts2[1]) : 0);

      return seconds1 - seconds2;
    } catch (e) {
      print('Error comparing paces: $e');
      return 0;
    }
  }

  String _calculateAveragePaceFromDistanceAndDuration(double totalDistance, Duration totalDuration) {
    if (totalDistance <= 0) return "0:00 min/km";

    try {
      final totalMinutes = totalDuration.inSeconds / 60;
      final paceMinutes = totalMinutes / totalDistance;
      final wholeMinutes = paceMinutes.floor();
      final seconds = ((paceMinutes - wholeMinutes) * 60).round();

      return "$wholeMinutes:${seconds.toString().padLeft(2, '0')} min/km";
    } catch (e) {
      print('Error calculating average pace: $e');
      return "0:00 min/km";
    }
  }

  Future<List<WeeklySummary>> getWeeklySummaries() async {
    final history = await fetchTrackingHistory();
    final Map<String, List<Map<String, dynamic>>> weeklyRuns = {};

    for (var run in history) {
      final date = run['timestamp'] as DateTime;
      final weekStart = _getWeekStart(date);
      final weekKey = weekStart.toString();

      weeklyRuns.putIfAbsent(weekKey, () => []);
      weeklyRuns[weekKey]!.add(run);
    }

    return weeklyRuns.entries.map((entry) {
      final runs = entry.value;
      double totalDistance = 0;
      Duration totalDuration = Duration.zero;

      for (var run in runs) {
        totalDistance += run['total_distance'] as double;
        totalDuration += Duration(seconds: run['duration'] as int);
      }

      return WeeklySummary(
        weekStart: DateTime.parse(entry.key),
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        numberOfRuns: runs.length,
        averagePace: _calculateAveragePace1(totalDistance, totalDuration),
      );
    }).toList();
  }

  // Helper methods
  String _calculateAveragePace1(double totalDistance, Duration totalDuration) {
    if (totalDistance == 0) return "0:00";
    final paceMinutes = totalDuration.inMinutes / totalDistance;
    return "${paceMinutes.floor()}:${((paceMinutes % 1) * 60).round().toString().padLeft(2, '0')}";
  }

  int _comparePaces(String pace1, String pace2) {
    try {
      // Extract just the numbers from pace strings (e.g., "15 min/km" -> "15")
      final parts1 = pace1.split(' ')[0].split(':');
      final parts2 = pace2.split(' ')[0].split(':');

      // Convert to total seconds for comparison
      final seconds1 = int.parse(parts1[0]) * 60 + (parts1.length > 1 ? int.parse(parts1[1]) : 0);
      final seconds2 = int.parse(parts2[0]) * 60 + (parts2.length > 1 ? int.parse(parts2[1]) : 0);

      return seconds1 - seconds2;
    } catch (e) {
      print('Error comparing paces: $e');
      return 0; // Return 0 if comparison fails
    }
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - date.weekday + 1);
  }


}
