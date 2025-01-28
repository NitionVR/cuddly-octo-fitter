import 'analytics_view_model.dart';

extension AnalyticsViewModelExtension on AnalyticsViewModel {
  String? get averagePace => stats?.averagePace;

  String? get bestPace => stats?.fastestPace;

  double get totalDistance => stats?.totalDistance ?? 0.0;

  int get totalRuns => stats?.totalRuns ?? 0;
}