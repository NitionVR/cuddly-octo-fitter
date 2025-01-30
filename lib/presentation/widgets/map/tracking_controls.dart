// lib/presentation/widgets/map/tracking_controls.dart
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../viewmodels/tracking/map_view_model.dart';

class TrackingControls extends StatelessWidget {
  final MapViewModel viewModel;
  final VoidCallback onPauseTap;

  const TrackingControls({
    super.key,
    required this.viewModel,
    required this.onPauseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCenterButton(viewModel),
        const SizedBox(height: 16),
        _buildMainButton(context),
      ],
    );
  }

  Widget _buildMainButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: _getButtonColor(),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (viewModel.isTracking && !viewModel.isPaused) {
              onPauseTap();
            } else {
              viewModel.toggleTracking();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getButtonIcon(),
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _getButtonText(),
                  style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(MapViewModel viewModel) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: viewModel.centerOnCurrentLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.my_location,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  if (viewModel.isTracking) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Center',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getButtonIcon() {
    if (!viewModel.isTracking) return Icons.play_arrow_rounded;
    if (viewModel.isPaused) return Icons.play_arrow_rounded;
    return Icons.pause_rounded;
  }

  String _getButtonText() {
    if (!viewModel.isTracking) return 'START RUN';
    if (viewModel.isPaused) return 'RESUME';
    return 'PAUSE';
  }

  Color _getButtonColor() {
    if (!viewModel.isTracking) return Colors.green;
    if (viewModel.isPaused) return Colors.orange;
    return Colors.red;
  }
}