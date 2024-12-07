import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../viewmodels/tracking/route_replay_view_model.dart';

class RouteReplayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<RouteReplayViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: viewModel.mapController,
                options: MapOptions(
                  center: viewModel.route.isNotEmpty
                      ? viewModel.route[0]
                      : LatLng(0, 0),
                  zoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  PolylineLayer(polylines: viewModel.polylines),
                  MarkerLayer(markers: viewModel.markers),
                ],
              ),
            ),
            _buildControls(context, viewModel),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, RouteReplayViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          Slider(
            value: viewModel.currentIndex / (viewModel.route.length - 1),
            onChanged: viewModel.seekToPosition,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Playback speed control
              DropdownButton<double>(
                value: viewModel.state.playbackSpeed,
                items: [0.5, 1.0, 1.5, 2.0, 3.0].map((speed) {
                  return DropdownMenuItem(
                    value: speed,
                    child: Text('${speed}x'),
                  );
                }).toList(),
                onChanged: (speed) {
                  if (speed != null) viewModel.setPlaybackSpeed(speed);
                },
              ),

              // Play/Pause button
              IconButton(
                icon: Icon(
                  viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                iconSize: 32,
                onPressed: viewModel.togglePlayPause,
              ),

              // Reset button
              IconButton(
                icon: const Icon(Icons.restart_alt),
                onPressed: () => viewModel.seekToPosition(0),
              ),
            ],
          ),

          // Stats display
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Distance: ${(viewModel.state.totalDistance / 1000).toStringAsFixed(2)} km'),
                Text('Pace: ${viewModel.state.pace}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}