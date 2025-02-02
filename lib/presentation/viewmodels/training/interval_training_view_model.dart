
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../data/database/providers/database_provider.dart';
import '../../../domain/entities/interval_workout.dart';

class IntervalTrainingViewModel extends ChangeNotifier {
  final DatabaseProvider _databaseProvider;

  IntervalWorkout? _currentWorkout;
  bool _isRunning = false;
  int _currentSegmentIndex = 0;
  int _currentRepetition = 1;
  Duration _segmentTimeRemaining = Duration.zero;
  Timer? _timer;
  String? _error;
  final String _userId;

  IntervalTrainingViewModel(this._databaseProvider, this._userId);

  // Existing getters
  IntervalWorkout? get currentWorkout => _currentWorkout;
  bool get isRunning => _isRunning;
  int get currentSegmentIndex => _currentSegmentIndex;
  int get currentRepetition => _currentRepetition;
  Duration get segmentTimeRemaining => _segmentTimeRemaining;
  String? get error => _error;

  IntervalSegment? get currentSegment {
    if (_currentWorkout == null ||
        _currentSegmentIndex >= _currentWorkout!.segments.length) {
      return null;
    }
    return _currentWorkout!.segments[_currentSegmentIndex];
  }


  // Workout control methods
  Future<void> startWorkout(IntervalWorkout workout) async {
    try {
      _currentWorkout = workout;
      _currentSegmentIndex = 0;
      _currentRepetition = 1;
      _segmentTimeRemaining = workout.segments.first.duration;
      _isRunning = true;
      _error = null;
      _startTimer();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start workout: $e';
      notifyListeners();
    }
  }


  void pauseWorkout() {
    _isRunning = false;
    _timer?.cancel();
    notifyListeners();
  }

  void resumeWorkout() {
    if (_currentWorkout != null) {
      _isRunning = true;
      _startTimer();
      notifyListeners();
    }
  }

  void stopWorkout() {
    _isRunning = false;
    _timer?.cancel();
    _currentWorkout = null;
    _currentSegmentIndex = 0;
    _currentRepetition = 1;
    _segmentTimeRemaining = Duration.zero;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segmentTimeRemaining <= Duration.zero) {
        _moveToNextSegment();
      } else {
        _segmentTimeRemaining -= const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void _moveToNextSegment() {
    if (_currentWorkout == null) return;

    _currentSegmentIndex++;

    // Check if we've completed all segments in the current repetition
    if (_currentSegmentIndex >= _currentWorkout!.segments.length) {
      _currentSegmentIndex = 0;
      _currentRepetition++;

      // Check if we've completed all repetitions
      if (_currentRepetition > _currentWorkout!.repetitions) {
        _completeWorkout();
        return;
      }
    }

    // Start next segment
    _segmentTimeRemaining = _currentWorkout!.segments[_currentSegmentIndex].duration;
    //_playIntervalChangeSound();
    notifyListeners();
  }

  Future<void> _completeWorkout() async {
    try {
      _isRunning = false;
      _timer?.cancel();

      if (_currentWorkout != null) {
        // Save workout data

        await _databaseProvider.trackingRepository.saveTrackingData(
          userId: _userId,
          timestamp: DateTime.now(),
          route: [], // No route for interval workouts
          totalDistance: 0, // Calculate if needed
          duration: _calculateTotalDuration().inSeconds,
          paceSeconds: 0, // Calculate if needed
        );

        // Sync after saving
        await _databaseProvider.syncService.syncWorkouts();
            }
    } catch (e) {
      _error = 'Failed to save workout: $e';
    } finally {
      notifyListeners();
    }
  }

  Duration _calculateTotalDuration() {
    if (_currentWorkout == null) return Duration.zero;

    // Calculate duration of completed full repetitions
    final durationPerRepetition = _currentWorkout!.segments
        .fold<Duration>(Duration.zero, (total, segment) => total + segment.duration);

    final completedRepetitionsDuration = durationPerRepetition * (_currentRepetition - 1);

    // Calculate duration of segments in current repetition
    final currentRepetitionDuration = _currentWorkout!.segments
        .take(_currentSegmentIndex)
        .fold<Duration>(Duration.zero, (total, segment) => total + segment.duration);

    // Add the time spent in current segment
    final currentSegmentDuration = _currentWorkout!.segments[_currentSegmentIndex].duration - _segmentTimeRemaining;

    // Total duration is sum of:
    // 1. Completed full repetitions
    // 2. Completed segments in current repetition
    // 3. Time spent in current segment
    return completedRepetitionsDuration + currentRepetitionDuration + currentSegmentDuration;
  }


  // Format time remaining for display
  String formatTimeRemaining() {
    return '${_segmentTimeRemaining.inMinutes}:${(_segmentTimeRemaining.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    // _audioPlayer.dispose();
    super.dispose();
  }
}