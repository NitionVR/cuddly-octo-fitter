// lib/viewmodels/analytics_view_model.dart
import 'package:flutter/foundation.dart';
import '../../data/models/personal_record.dart';
import '../../data/models/running_stats.dart';
import '../../domain/repository/tracking_repository.dart';
import '../../data/models/weekly_summary.dart';


class AnalyticsViewModel extends ChangeNotifier {
  final TrackingRepository _trackingRepository;

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

  AnalyticsViewModel(this._trackingRepository);

  Future<void> loadAnalytics() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all analytics data
      final history = await _trackingRepository.fetchTrackingHistory();

      // Calculate running stats
      _stats = _calculateRunningStats(history);

      // Calculate weekly summaries
      _weeklySummaries = _calculateWeeklySummaries(history);

      // Calculate personal records
      _personalRecords = _calculatePersonalRecords(history);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading analytics: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateTimeFrame(String timeFrame) {
    _selectedTimeFrame = timeFrame;
    loadAnalytics();
  }

  RunningStats _calculateRunningStats(List<Map<String, dynamic>> history) {
    double totalDistance = 0;
    Duration totalDuration = Duration.zero;
    double longestRun = 0;
    String fastestPace = "0:00";
    Duration longestDuration = Duration.zero;

    for (var run in history) {
      final distance = run['total_distance'] as double;
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
        totalDistance += run['total_distance'] as double;
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

  List<PersonalRecord> _calculatePersonalRecords(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return [];

    var records = <PersonalRecord>[];

    // Find records
    try {
      // Longest run
      var longestRun = history.reduce((a, b) =>
      (a['total_distance'] as double) > (b['total_distance'] as double) ? a : b);

      records.add(PersonalRecord(
        category: 'Longest Run',
        value: longestRun['total_distance'] as double,
        achievedDate: longestRun['timestamp'] as DateTime,
        displayValue: '${(longestRun['total_distance'] as double).toStringAsFixed(2)} km',
      ));

      // Fastest 5K
      var fiveKRuns = history.where((run) => (run['total_distance'] as double) >= 5.0).toList();
      if (fiveKRuns.isNotEmpty) {
        var fastest5K = fiveKRuns.reduce((a, b) {
          final paceA = a['avg_pace'] as String? ?? '0:00 min/km';
          final paceB = b['avg_pace'] as String? ?? '0:00 min/km';
          return _comparePaces(paceA, paceB) < 0 ? a : b;
        });

        records.add(PersonalRecord(
          category: '5K',
          value: _convertPaceToMinutes(fastest5K['avg_pace'] as String? ?? '0:00 min/km'),
          achievedDate: fastest5K['timestamp'] as DateTime,
          displayValue: fastest5K['avg_pace'] as String? ?? '0:00 min/km',
        ));
      }
    } catch (e) {
      print('Error calculating personal records: $e');
    }

    return records;
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