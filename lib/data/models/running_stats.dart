class RunningStats {
  final double totalDistance;
  final Duration totalDuration;
  final String averagePace;
  final int totalRuns;
  final double longestRun;
  final String fastestPace;
  final Duration longestDuration;

  RunningStats({
    required this.totalDistance,
    required this.totalDuration,
    required this.averagePace,
    required this.totalRuns,
    required this.longestRun,
    required this.fastestPace,
    required this.longestDuration,
  });
}