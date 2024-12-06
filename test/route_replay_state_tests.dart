/*
* Tests for RouteReplayState
*
* Purpose: Verify the state management for workout route replay functionality:
* - Initial state creation
* - State updates via copyWith
* - Validation of workout replay parameters
*/

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_project_fitquest/data/models/route_replay_state.dart';

void main() {
  group('RouteReplayState Creation', () {
    test('creates with default values', () {
      final route = [LatLng(0, 0), LatLng(1, 1)];
      final state = RouteReplayState(
        route: route,
        duration: Duration(minutes: 10),
      );

      expect(state.currentPointIndex, 0);
      expect(state.totalDistance, 0.0);
      expect(state.pace, "0:00 min/km");
      expect(state.isPlaying, false);
      expect(state.playbackSpeed, 1.0);
    });

    test('creates with custom values', () {
      final route = [LatLng(0, 0), LatLng(1, 1)];
      final state = RouteReplayState(
        route: route,
        currentPointIndex: 1,
        totalDistance: 100.0,
        pace: "5:30 min/km",
        duration: Duration(minutes: 10),
        isPlaying: true,
        playbackSpeed: 2.0,
      );

      expect(state.currentPointIndex, 1);
      expect(state.totalDistance, 100.0);
      expect(state.pace, "5:30 min/km");
      expect(state.isPlaying, true);
      expect(state.playbackSpeed, 2.0);
    });
  });

  group('State Updates', () {
    test('updates partial state via copyWith', () {
      final route = [LatLng(0, 0), LatLng(1, 1)];
      final initialState = RouteReplayState(
        route: route,
        duration: Duration(minutes: 10),
      );

      final updatedState = initialState.copyWith(
        currentPointIndex: 1,
        isPlaying: true,
      );

      expect(updatedState.currentPointIndex, 1);
      expect(updatedState.isPlaying, true);
      expect(updatedState.route, route); // Unchanged
      expect(updatedState.playbackSpeed, 1.0); // Unchanged
    });
  });
}