// lib/presentation/viewmodels/interval_training_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
//import 'package:audioplayers/audioplayers.dart';
import '../../domain/entities/interval_workout.dart';

class IntervalTrainingViewModel extends ChangeNotifier {
  IntervalWorkout? _currentWorkout;
  bool _isRunning = false;
  int _currentSegmentIndex = 0;
  int _currentRepetition = 1;
  Duration _segmentTimeRemaining = Duration.zero;
  Timer? _timer;
  //final AudioPlayer _audioPlayer = AudioPlayer();

  // Getters
  IntervalWorkout? get currentWorkout => _currentWorkout;
  bool get isRunning => _isRunning;
  int get currentSegmentIndex => _currentSegmentIndex;
  int get currentRepetition => _currentRepetition;
  Duration get segmentTimeRemaining => _segmentTimeRemaining;

  IntervalSegment? get currentSegment {
    if (_currentWorkout == null ||
        _currentSegmentIndex >= _currentWorkout!.segments.length) {
      return null;
    }
    return _currentWorkout!.segments[_currentSegmentIndex];
  }

  // Workout control methods
  void startWorkout(IntervalWorkout workout) {
    _currentWorkout = workout;
    _currentSegmentIndex = 0;
    _currentRepetition = 1;
    _segmentTimeRemaining = workout.segments.first.duration;
    _isRunning = true;
    _startTimer();
    notifyListeners();
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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_segmentTimeRemaining <= Duration.zero) {
        _moveToNextSegment();
      } else {
        _segmentTimeRemaining -= Duration(seconds: 1);
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

  void _completeWorkout() {
    _isRunning = false;
    _timer?.cancel();
    // TODO: Save workout statistics
    notifyListeners();
  }

  // Future<void> _playIntervalChangeSound() async {
  //   try {
  //     await _audioPlayer.play(AssetSource('sounds/interval_change.mp3'));
  //   } catch (e) {
  //     print('Error playing sound: $e');
  //   }
  // }

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