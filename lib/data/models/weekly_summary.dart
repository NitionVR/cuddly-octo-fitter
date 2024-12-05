class WeeklySummary {
  final DateTime weekStart;
  final double totalDistance;
  final Duration totalDuration;
  final int numberOfRuns;
  final String averagePace;

  WeeklySummary({
    required this.weekStart,
    required this.totalDistance,
    required this.totalDuration,
    required this.numberOfRuns,
    required this.averagePace,
  });
}