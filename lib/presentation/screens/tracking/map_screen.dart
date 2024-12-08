import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodels/tracking/map_view_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();

}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    // Call initializeLocation to set up location tracking
    final viewModel = Provider.of<MapViewModel>(context, listen: false);
    viewModel.initializeLocation(viewModel.locationService);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MapViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStat("Pace", viewModel.pace),
            _buildStat("Distance", "${(viewModel.totalDistance / 1000).toStringAsFixed(2)} km"),
            _buildStat("Time", viewModel.getElapsedTime()),
          ],
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: viewModel.mapController,
            options: MapOptions(
              center: viewModel.route.isNotEmpty
                  ? viewModel.route.last
                  : const LatLng(0, 0),
              zoom: 16.0,
              maxZoom: 18.0,
              minZoom: 3.0,
              interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: viewModel.route.isEmpty ? [] : viewModel.polylines,
              ),
              MarkerLayer(
                markers: viewModel.markers,
              ),
            ],
          ),

          // GPS Signal Indicator on left side
          Positioned(
            top: 16,
            left: 16,
            child: _buildGpsSignalBars(viewModel),
          ),

          // Current Location and Simulation buttons on right side
          Positioned(
            bottom: 100,  // Above the tracking button
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // if (kDebugMode)
                //   FloatingActionButton(
                //     heroTag: 'simulate',
                //     mini: true,
                //     onPressed: viewModel.toggleSimulation,
                //     child: Icon(
                //       viewModel.isSimulating ? Icons.stop : Icons.play_arrow,
                //     ),
                //     backgroundColor: viewModel.isSimulating ? Colors.red : Colors.blue,
                //   ),
                // SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'centerLocation',
                  mini: true,
                  onPressed: viewModel.centerOnCurrentLocation,
                  child: Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Tracking button at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                if (viewModel.isTracking && !viewModel.isPaused) {
                  // If tracking is active and not paused, show pause dialog
                  _showPauseDialog(context, viewModel);
                } else {
                  // Otherwise just toggle tracking
                  viewModel.toggleTracking();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getTrackingButtonColor(viewModel),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _getTrackingButtonText(viewModel),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }


  Widget _buildGpsSignalBars(MapViewModel viewModel) {
    if (!viewModel.showGpsSignal) return SizedBox.shrink();

    final int signalStrength = _getSignalBars(viewModel.gpsAccuracy);
    final color = _getGpsColor(viewModel.gpsAccuracy);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(4, (index) {
                  final bool isActive = index < signalStrength;
                  return Container(
                    width: 4,
                    height: 5 + (index * 4), // Progressively taller bars
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isActive ? color : Colors.grey[300],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(1),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'GPS',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getSignalBars(int accuracy) {
    if (accuracy <= 5) return 4;      // Excellent signal (4 bars)
    if (accuracy <= 10) return 3;     // Good signal (3 bars)
    if (accuracy <= 20) return 2;     // Fair signal (2 bars)
    if (accuracy <= 30) return 1;     // Poor signal (1 bar)
    return 0;                         // Very poor signal (no bars)
  }

  Color _getGpsColor(int accuracy) {
    if (accuracy <= 5) return Colors.green;       // Excellent
    if (accuracy <= 10) return const Color(0xFF90EE90); // Light green
    if (accuracy <= 20) return Colors.orange;     // Fair
    if (accuracy <= 30) return Colors.deepOrange; // Poor
    return Colors.red;                           // Very poor
  }

  void _showPauseDialog(BuildContext context, MapViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Run Paused'),
          content: const Text('What would you like to do?'),
          actions: [
            TextButton(
              child: const Text('Continue Run'),
              onPressed: () {
                viewModel.resumeTracking();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('End Run'),
              onPressed: () {
                viewModel.endTracking();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getTrackingButtonText(MapViewModel viewModel) {
    if (!viewModel.isTracking) return 'Start Tracking';
    if (viewModel.isPaused) return 'Resume Tracking';
    return 'Pause Tracking';
  }

  Color _getTrackingButtonColor(MapViewModel viewModel) {
    if (!viewModel.isTracking) return Colors.green;
    if (viewModel.isPaused) return Colors.orange;
    return Colors.red;
  }
}
