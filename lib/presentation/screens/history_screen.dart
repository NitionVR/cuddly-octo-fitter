import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_colors.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/tracking/route_replay_view_model.dart';
import '../widgets/route_replay_widget.dart';
import 'package:mobile_project_fitquest/theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MapViewModel>(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundStart,
            AppColors.backgroundEnd,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Running History",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _showClearHistoryDialog(context, viewModel),
            ),
          ],
        ),
        body: FutureBuilder<void>(
          future: viewModel.loadTrackingHistory(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (viewModel.history.isEmpty) {
              return _buildEmptyState();
            }

            return _buildHistoryList(context, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, MapViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.history.length,
      itemBuilder: (context, index) {
        final item = viewModel.history[index];
        return _buildHistoryCard(context, item, index);
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item, int index) {
    final timestamp = item['timestamp'] as DateTime;
    final duration = item['duration'] as int;
    final totalDistanceMeters = item['total_distance'] ?? 0.0;
    final totalDistanceKm = totalDistanceMeters / 1000;
    final avgPace = item['avg_pace'];
    final route = item['route'] as List<LatLng>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and time
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(timestamp),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                _buildTimeAgo(timestamp),
              ],
            ),
          ),

          // Stats Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatItem(
                  context,
                  'Distance',
                  '${totalDistanceKm.toStringAsFixed(2)} km',
                  Icons.straighten,
                ),
                _buildStatItem(
                  context,
                  'Duration',
                  _formatDuration(duration),
                  Icons.timer,
                ),
                _buildStatItem(
                  context,
                  'Avg Pace',
                  '$avgPace/km',
                  Icons.speed,
                ),
              ],
            ),
          ),

          // Route Preview (if you want to add a small map preview)
          // _buildRoutePreview(route),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _navigateToReplay(
                    context,
                    route,
                    Duration(seconds: duration),
                    timestamp,
                  ),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Replay'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.buttonPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.cardHoverBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeAgo(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    String timeAgo;

    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours}h ago';
    } else {
      timeAgo = '${difference.inMinutes}m ago';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardHoverBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        timeAgo,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_run,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No runs yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first run to see it here',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
              child: const Text("Clear", style: TextStyle(color: Colors.red)),
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