import 'package:flutter/foundation.dart';

import '../../../data/database/models/tracking_model.dart';
import '../../../data/database/providers/database_provider.dart';
import '../../../data/models/personal_record.dart';
import '../../../data/models/running_stats.dart';
import '../../../data/models/weekly_summary.dart';
import '../../../domain/repository/tracking/tracking_repository.dart';




class AnalyticsViewModel extends ChangeNotifier {
  final ITrackingRepository _trackingRepository;
  final DatabaseProvider _databaseProvider;

  RunningStats? _stats;
  List<WeeklySummary> _weeklySummaries = [];
  List<PersonalRecord> _personalRecords = [];
  bool _isLoading = false;
  String _selectedTimeFrame = 'Last 4 Weeks';

  // Getters
  RunningStats? get stats => _stats;
  List<WeeklySummary> get weeklySummaries => _weeklySummaries;
  List<PersonalRecord> get personalRecords => _personalRecords;
  bool get isLoading => _isLoading;
  String get selectedTimeFrame => _selectedTimeFrame;

  AnalyticsViewModel(this._trackingRepository, this._databaseProvider);

  Future<void> loadAnalytics(String userId) async {
    // Set loading state without notifying
    _isLoading = true;

    try {
      // Load all data first
      await _loadAnalyticsInternal(userId);

      // Update state and notify once at the end
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading analytics: $e');
      }
      // Reset state
      _stats = await RunningStats.empty();
      _weeklySummaries = [];
      _personalRecords = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAnalyticsInternal(String userId) async {
    // Sync with cloud first
    await _databaseProvider.syncService.syncWorkouts();

    // Load stats directly from repository
    _stats = await _trackingRepository.getRunningStats(userId);

    // Load weekly summaries
    _weeklySummaries = await _trackingRepository.getWeeklySummaries(userId);

    // Calculate personal records from tracking history
    final history = await _trackingRepository.fetchTrackingHistory(
      userId: userId,
      limit: 100,
    );
    _personalRecords = _calculatePersonalRecords(history);
  }

  void updateTimeFrame(String timeFrame, String userId) async {
    _selectedTimeFrame = timeFrame;
    await loadAnalytics(userId);
  }

  RunningStats _calculateRunningStats(List<Map<String, dynamic>> history) {
    double totalDistance = 0;
    Duration totalDuration = Duration.zero;
    double longestRun = 0;
    String fastestPace = "0:00";
    Duration longestDuration = Duration.zero;

    for (var run in history) {
      final distance = (run['total_distance'] as double)/1000;
      final duration = Duration(seconds: run['duration'] as int);

      totalDistance += distance;
      totalDuration += duration;

      if (distance > longestRun) longestRun = distance;
      if (duration > longestDuration) longestDuration = duration;

      // Update fastest pace
      final currentPace = run['avg_pace'] as String;
      if (fastestPace == "0:00" || _comparePaces(currentPace, fastestPace) < 0) {
        fastestPace = currentPace;
      }
    }

    final avgPace = _calculateAveragePace(totalDistance, totalDuration);

    return RunningStats(
      totalDistance: totalDistance,
      totalDuration: totalDuration,
      averagePace: avgPace,
      totalRuns: history.length,
      longestRun: longestRun,
      fastestPace: fastestPace,
      longestDuration: longestDuration,
    );
  }

  List<WeeklySummary> _calculateWeeklySummaries(List<Map<String, dynamic>> history) {
    // Group runs by week
    final Map<String, List<Map<String, dynamic>>> weeklyRuns = {};

    for (var run in history) {
      final date = run['timestamp'] as DateTime;
      final weekStart = _getWeekStart(date);
      final weekKey = weekStart.toString();

      weeklyRuns.putIfAbsent(weekKey, () => []);
      weeklyRuns[weekKey]!.add(run);
    }

    // Calculate summary for each week
    return weeklyRuns.entries.map((entry) {
      final runs = entry.value;
      final weekStart = DateTime.parse(entry.key);

      double totalDistance = 0;
      Duration totalDuration = Duration.zero;

      for (var run in runs) {
        totalDistance += (run['total_distance'] as double)/1000;
        totalDuration += Duration(seconds: run['duration'] as int);
      }

      return WeeklySummary(
        weekStart: weekStart,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        numberOfRuns: runs.length,
        averagePace: _calculateAveragePace(totalDistance, totalDuration),
      );
    }).toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));
  }

  List<PersonalRecord> _calculatePersonalRecords(List<TrackingModel> history) {
    if (history.isEmpty) return [];

    var records = <PersonalRecord>[];

    try {
      // Longest run
      var longestRun = history.reduce((a, b) =>
      (a.totalDistance ?? 0) > (b.totalDistance ?? 0) ? a : b);

      if (longestRun.totalDistance != null) {
        records.add(PersonalRecord(
          category: 'Longest Run',
          value: longestRun.totalDistance!,
          achievedDate: longestRun.timestamp,
          displayValue: '${(longestRun.totalDistance! / 1000).toStringAsFixed(2)} km',
        ));
      }

      // Fastest 5K
      var fiveKRuns = history
          .where((run) => (run.totalDistance ?? 0) >= 5000) // 5000 meters
          .toList();

      if (fiveKRuns.isNotEmpty) {
        var fastest5K = fiveKRuns.reduce((a, b) {
          final paceA = a.paceSeconds ?? double.infinity;
          final paceB = b.paceSeconds ?? double.infinity;
          return paceA < paceB ? a : b;
        });

        if (fastest5K.paceSeconds != null) {
          records.add(PersonalRecord(
            category: '5K',
            value: fastest5K.paceSeconds!.toDouble(),
            achievedDate: fastest5K.timestamp,
            displayValue: _formatPace(fastest5K.paceSeconds!),
          ));
        }
      }

      // Add more records as needed

    } catch (e) {
      print('Error calculating personal records: $e');
    }

    return records;
  }

  String _formatPace(int paceSeconds) {
    if (paceSeconds <= 0) return "0:00 min/km";
    final minutes = paceSeconds ~/ 60;
    final seconds = paceSeconds % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')} min/km";
  }

  DateTime _getTimeFrameStart() {
    final now = DateTime.now();
    switch (_selectedTimeFrame) {
      case 'Last Week':
        return now.subtract(const Duration(days: 7));
      case 'Last Month':
        return now.subtract(const Duration(days: 30));
      case 'Last 3 Months':
        return now.subtract(const Duration(days: 90));
      case 'Last 4 Weeks':
      default:
        return now.subtract(const Duration(days: 28));
    }
  }


// Helper method to convert pace string to minutes
  double _convertPaceToMinutes(String paceStr) {
    try {
      final parts = paceStr.split(' ')[0].split(':');
      final minutes = double.parse(parts[0]);
      final seconds = parts.length > 1 ? double.parse(parts[1]) / 60 : 0;
      return minutes + seconds;
    } catch (e) {
      print('Error converting pace to minutes: $e');
      return 0;
    }
  }

  // Helper methods
  DateTime _getWeekStart(DateTime date) {
    return DateTime(date.year, date.month, date.day - date.weekday + 1);
  }

  String _calculateAveragePace(double totalDistance, Duration totalDuration) {
    if (totalDistance == 0) return "0:00";

    final paceMinutes = totalDuration.inMinutes / totalDistance;
    return "${paceMinutes.floor()}:${((paceMinutes % 1) * 60).round().toString().padLeft(2, '0')}";
  }

  int _comparePaces(String pace1, String pace2) {
    final parts1 = pace1.split(':');
    final parts2 = pace2.split(':');

    final minutes1 = int.parse(parts1[0]);
    final seconds1 = int.parse(parts1[1]);
    final minutes2 = int.parse(parts2[0]);
    final seconds2 = int.parse(parts2[1]);

    return (minutes1 * 60 + seconds1) - (minutes2 * 60 + seconds2);
  }
}