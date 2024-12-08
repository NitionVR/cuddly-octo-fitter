enum IntervalType {
  running,
  recovery,
  warmup,
  cooldown
}

class IntervalSegment {
  final IntervalType type;
  final Duration duration;
  final double targetPace; // in minutes per km
  final String description;

  IntervalSegment({
    required this.type,
    required this.duration,
    this.targetPace = 0.0,
    String? description,
  }) : description = description ?? _getDefaultDescription(type);

  static String _getDefaultDescription(IntervalType type) {
    switch (type) {
      case IntervalType.running:
        return 'Run Fast';
      case IntervalType.recovery:
        return 'Recovery';
      case IntervalType.warmup:
        return 'Warm Up';
      case IntervalType.cooldown:
        return 'Cool Down';
    }
  }
}

class IntervalWorkout {
  final String name;
  final List<IntervalSegment> segments;
  final int repetitions;
  final String description;

  IntervalWorkout({
    required this.name,
    required this.segments,
    this.repetitions = 1,
    this.description = '',
  });

  Duration get totalDuration {
    final segmentsDuration = segments.fold<Duration>(
      Duration.zero,
          (total, segment) => total + segment.duration,
    );
    return segmentsDuration * repetitions;
  }

  // Predefined workout templates
  static IntervalWorkout basic() {
    return IntervalWorkout(
      name: 'Basic Intervals',
      description: '8 rounds of 1-minute running intervals with 1-minute recovery',
      segments: [
        IntervalSegment(
          type: IntervalType.running,
          duration: const Duration(minutes: 1),
        ),
        IntervalSegment(
          type: IntervalType.recovery,
          duration: const Duration(minutes: 1),
        ),
      ],
      repetitions: 8,
    );
  }

  static IntervalWorkout pyramid() {
    return IntervalWorkout(
      name: 'Pyramid',
      description: 'Progressive intervals building up then down',
      segments: [
        IntervalSegment(
          type: IntervalType.running,
          duration: const Duration(minutes: 1),
        ),
        IntervalSegment(
          type: IntervalType.recovery,
          duration: const Duration(minutes: 1),
        ),
        IntervalSegment(
          type: IntervalType.running,
          duration: const Duration(minutes: 2),
        ),
        IntervalSegment(
          type: IntervalType.recovery,
          duration: const Duration(minutes: 1),
        ),
        IntervalSegment(
          type: IntervalType.running,
          duration: const Duration(minutes: 3),
        ),
        IntervalSegment(
          type: IntervalType.recovery,
          duration: const Duration(minutes: 1),
        ),
        IntervalSegment(
          type: IntervalType.running,
          duration: const Duration(minutes: 2),
        ),
        IntervalSegment(
          type: IntervalType.recovery,
          duration: const Duration(minutes: 1),
        ),
        IntervalSegment(
          type: IntervalType.running,
          duration: const Duration(minutes: 1),
        ),
      ],
    );
  }
}