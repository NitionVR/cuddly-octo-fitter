

import 'analytics/analytics_view_model.dart';

extension AnalyticsViewModelExtension on AnalyticsViewModel {
  String? get averagePace => stats?.averagePace;
  String? get bestPace => stats?.fastestPace;
  double get totalDistance => stats?.totalDistance ?? 0.0;
  int get totalRuns => stats?.totalRuns ?? 0;

  // Optional: Add more convenience getters
  Duration get totalDuration => stats?.totalDuration ?? Duration.zero;
  double get longestRun => stats?.longestRun ?? 0.0;
  Duration get longestDuration => stats?.longestDuration ?? Duration.zero;
}