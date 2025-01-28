import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/tracking/route_replay_view_model.dart';
import '../widgets/route_replay_widget.dart';
import 'package:mobile_project_fitquest/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MapViewModel>(context);

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Tracking History", style: TextStyle(color: AppColors.textPrimary)),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.textSecondary),
              onPressed: () => _showClearHistoryDialog(context, viewModel),
            ),
          ],
        ),
        body: FutureBuilder<void>(
          future: viewModel.loadTrackingHistory(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error loading history: ${snapshot.error}", style: const TextStyle(color: AppColors.textPrimary)));
            }

            if (viewModel.history.isEmpty) {
              return const Center(child: Text("No tracking history available.", style: TextStyle(color: AppColors.textPrimary)));
            }

            return ListView.builder(
              itemCount: viewModel.history.length,
              itemBuilder: (context, index) {
                final item = viewModel.history[index];
                final timestamp = item['timestamp'];
                final duration = item['duration'];
                final totalDistance = item['total_distance'] ?? 0.0; // Handle null totalDistance
                final avgPace = item['avg_pace'];
                final route = item['route'] as List<LatLng>;

                return Card(
                  color: AppColors.cardDark,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text("Session ${index + 1}", style: const TextStyle(color: AppColors.textPrimary)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Date: ${_formatTimestamp(timestamp)}",
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text("Duration: ${_formatDuration(duration)}", style: const TextStyle(color: AppColors.textPrimary)),
                        Text("Distance: ${totalDistance.toStringAsFixed(2)} km", style: const TextStyle(color: AppColors.textPrimary)),
                        Text("Avg Pace: $avgPace min/km", style: const TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_circle_outline, color: AppColors.accentGreen),
                      onPressed: () => _navigateToReplay(
                        context,
                        route,
                        Duration(seconds: duration),
                        timestamp,
                      ),
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _navigateToReplay(
      BuildContext context,
      List<LatLng> route,
      Duration duration,
      DateTime timestamp,
      ) {
    final mapController = MapController();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => RouteReplayViewModel(
            route: route,
            duration: duration,
            mapController: mapController,
          ),
          child: Theme(
            data: AppTheme.darkTheme,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("Route Replay", style: TextStyle(color: AppColors.textPrimary)),
                //subtitle: Text(_formatTimestamp(timestamp)),
              ),
              body: const RouteReplayWidget(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final dateFormat = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
    final timeFormat = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    return '$dateFormat at $timeFormat';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes min ${remainingSeconds.toString().padLeft(2, '0')} sec';
  }

  void _showClearHistoryDialog(BuildContext context, MapViewModel viewModel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Clear History", style: TextStyle(color: AppColors.textPrimary)),
          content: const Text("Are you sure you want to clear your entire tracking history?", style: TextStyle(color: AppColors.textPrimary)),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Clear", style: TextStyle(color: AppColors.errorRed)),
              onPressed: () async {
                await viewModel.clearTrackingHistory();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}