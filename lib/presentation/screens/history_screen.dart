import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/tracking/route_replay_view_model.dart';
import '../widgets/route_replay_widget.dart';


class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MapViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking History"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _showClearHistoryDialog(context, viewModel),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: viewModel.loadTrackingHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error loading history: ${snapshot.error}"));
          }

          if (viewModel.history.isEmpty) {
            return Center(child: Text("No tracking history available."));
          }

          return ListView.builder(
            itemCount: viewModel.history.length,
            itemBuilder: (context, index) {
              final item = viewModel.history[index];
              final timestamp = item['timestamp'];
              final duration = item['duration'];
              final totalDistance = item['totalDistance'];
              final avgPace = item['avgPace'];
              final route = item['route'] as List<LatLng>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text("Session ${index + 1}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Date: ${_formatTimestamp(timestamp)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text("Duration: ${_formatDuration(duration)}"),
                      Text("Distance: ${totalDistance} km"),
                      Text("Avg Pace: $avgPace min/km"),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.play_circle_outline),
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
          child: Scaffold(
            appBar: AppBar(
              title: Text("Route Replay"),
              //subtitle: Text(_formatTimestamp(timestamp)),
            ),
            body: RouteReplayWidget(),
          ),
        ),
      ),
    );
  }

  // Your existing helper methods remain the same
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
          title: Text("Clear History"),
          content: Text("Are you sure you want to clear your entire tracking history?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Clear"),
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