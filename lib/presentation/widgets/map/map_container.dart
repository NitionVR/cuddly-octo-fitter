// lib/presentation/widgets/map/map_container.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/app_colors.dart';
import '../../viewmodels/tracking/map_view_model.dart';

class MapContainer extends StatelessWidget {
  final MapViewModel viewModel;

  const MapContainer({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            _buildMap(),
            _buildMapOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: viewModel.mapController,
      options: MapOptions(
        center: viewModel.route.isNotEmpty
            ? viewModel.route.last
            : const LatLng(0, 0),
        zoom: 16.0,
        maxZoom: 18.0,
        minZoom: 3.0,
        interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            // Optional: Handle map movement
          }
        },
      ),
      children: [
        _buildTileLayer(),
        _buildRouteLayer(),
        _buildMarkersLayer(),
      ],
    );
  }

  Widget _buildTileLayer() {
    return TileLayer(
      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
      subdomains: const ['a', 'b', 'c'],
      backgroundColor: AppColors.backgroundEnd.withOpacity(0.8),
      userAgentPackageName: 'com.example.mobile_project_fitquest',
      tileBuilder: (context, widget, tile) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: widget,
        );
      },
    );
  }

  Widget _buildRouteLayer() {
    if (viewModel.route.isEmpty) {
      return const PolylineLayer(polylines: []);
    }

    return PolylineLayer(
      polylines: [
        Polyline(
          points: viewModel.route,
          strokeWidth: 4.0,
          color: Colors.blue.withOpacity(0.8),
          borderColor: Colors.white.withOpacity(0.2),
          borderStrokeWidth: 2.0,
          isDotted: false,
          gradientColors: viewModel.isTracking ? [
            Colors.blue.withOpacity(0.8),
            Colors.blue.withOpacity(0.6),
          ] : null,
        ),
      ],
    );
  }

  Widget _buildMarkersLayer() {
    return MarkerLayer(
      markers: viewModel.markers.map((marker) {
        return Marker(
          point: marker.point,
          width: 20,
          height: 20,
          builder: (context) => _buildMarker(marker.point),
        );
      }).toList(),
    );
  }

  Widget _buildMarker(LatLng position) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.navigation,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  Widget _buildMapOverlay() {
    return Stack(
      children: [
        // Top gradient overlay
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom gradient overlay
        if (viewModel.isTracking)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

        // Optional: Add distance markers or mile markers
        if (viewModel.isTracking) _buildDistanceMarkers(),
      ],
    );
  }

  Widget _buildDistanceMarkers() {
    // Add distance markers every kilometer
    final markers = <Widget>[];
    final totalKm = (viewModel.totalDistance / 1000).floor();

    for (var i = 1; i <= totalKm; i++) {
      // Calculate position for each kilometer marker
      // This is a simplified version - you'll need to implement proper positioning
      markers.add(
        Positioned(
          // Position calculation needed
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              '${i}km',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: markers);
  }
}