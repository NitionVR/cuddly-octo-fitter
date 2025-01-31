import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/tracking/map_view_model.dart';
import '../../widgets/map/countdown_overlay.dart';
import '../../widgets/map/map_container.dart';
import '../../widgets/map/pause_summary_dialog.dart';
import '../../widgets/map/stats_dashboard.dart';
import '../../widgets/map/tracking_controls.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  bool _showingCountdown = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCenter();
  }

  Future<void> _initializeAndCenter() async {
    final viewModel = context.read<MapViewModel>();
    if (!viewModel.isInitialized) {
      await viewModel.initialize();
    }
    // Add a small delay to ensure the map is ready
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await viewModel.centerOnCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
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
      child: Consumer<MapViewModel>(
        builder: (context, viewModel, _) {
          if (!viewModel.isInitialized) {
            return const Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            );
          }

          return Stack(  // Wrap Scaffold in Stack to overlay countdown
            children: [
              Scaffold(
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Column(
                    children: [
                      // App Bar
                      _buildAppBar(),

                      // Stats Dashboard
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: StatsDashboard(viewModel: viewModel),
                      ),

                      // Map and Controls
                      Expanded(
                        child: Stack(
                          children: [
                            // Map Container
                            MapContainer(viewModel: viewModel),

                            // GPS Signal
                            if (viewModel.showGpsSignal)
                              Positioned(
                                top: 16,
                                left: 32,
                                child: _buildGpsSignalIndicator(viewModel),
                              ),


                            // Tracking Controls
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: TrackingControls(
                                viewModel: viewModel,
                                onPauseTap: () => _showPauseSummaryDialog(context, viewModel),
                                onStartTap: () => _handleStartTracking(viewModel),  // Add this
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Countdown Overlay
              if (_showingCountdown)
                CountdownOverlay(
                  onCountdownComplete: () {
                    setState(() {
                      _showingCountdown = false;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }

// Add this method to your class
  void _handleStartTracking(MapViewModel viewModel) {
    setState(() {
      _showingCountdown = true;
    });

    // Show the countdown overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownOverlay(
        onCountdownComplete: () {
          Navigator.of(context).pop();
          setState(() {
            _showingCountdown = false;
          });
          viewModel.startTracking();
        },
      ),
    );
  }


  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Run Tracking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              // Navigate to history
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton(MapViewModel viewModel) {
    return GlassmorphicContainer(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: viewModel.centerOnCurrentLocation,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGpsSignalIndicator(MapViewModel viewModel) {
    return GlassmorphicContainer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSignalBars(viewModel.gpsAccuracy),
            const SizedBox(width: 8),
            Text(
              _getGpsQualityText(viewModel.gpsAccuracy),
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: _getGpsColor(viewModel.gpsAccuracy),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalBars(int accuracy) {
    final int signalStrength = _getSignalBars(accuracy);
    final color = _getGpsColor(accuracy);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final bool isActive = index < signalStrength;
        return Container(
          width: 4,
          height: 6 + (index * 3),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(1),
            ),
          ),
        );
      }),
    );
  }

  String _getGpsQualityText(int accuracy) {
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 20) return 'Fair';
    return 'Poor';
  }

  int _getSignalBars(int accuracy) {
    if (accuracy <= 5) return 4;
    if (accuracy <= 10) return 3;
    if (accuracy <= 20) return 2;
    if (accuracy <= 30) return 1;
    return 0;
  }

  Color _getGpsColor(int accuracy) {
    if (accuracy <= 5) return Colors.green;
    if (accuracy <= 10) return const Color(0xFF90EE90);
    if (accuracy <= 20) return Colors.orange;
    if (accuracy <= 30) return Colors.deepOrange;
    return Colors.red;
  }

  void _showPauseSummaryDialog(BuildContext context, MapViewModel viewModel) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          PauseSummaryDialog(
            viewModel: viewModel,
            onResume: () {
              viewModel.resumeTracking();
              Navigator.pop(context);
            },
            onEnd: () {
              viewModel.endTracking();
              Navigator.pop(context);
              // Navigate to summary screen or perform end action
              Navigator.pushNamed(context, '/summary', arguments: {
                'distance': viewModel.totalDistance,
                'duration': viewModel.getElapsedTime(),
                'pace': viewModel.pace,
                'route': viewModel.route,
              });
            },
          ),
    );
  }
}

// GlassmorphicContainer widget (if not already in a separate file)
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final Color? backgroundColor;

  const GlassmorphicContainer({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.cardBackground,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}