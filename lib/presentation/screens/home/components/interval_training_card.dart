// lib/presentation/screens/home/components/interval_training_card.dart
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../screens/training/interval_training_screen.dart';
import '../../../widgets/dashboard_card.dart';

class IntervalTrainingCard extends StatelessWidget {
  const IntervalTrainingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      icon: const Icon(Icons.timer, color: Colors.white, size: 24),
      title: 'Interval Training',
      content: _IntervalTrainingContent(
        onStartWorkout: () => _navigateToTraining(context),
      ),
    );
  }

  void _navigateToTraining(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IntervalTrainingScreen(),
      ),
    );
  }
}

class _IntervalTrainingContent extends StatelessWidget {
  final VoidCallback onStartWorkout;

  const _IntervalTrainingContent({
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardHoverBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WorkoutPreview(),
          const SizedBox(height: 16),
          _StartWorkoutButton(onPressed: onStartWorkout),
        ],
      ),
    );
  }
}

class _WorkoutPreview extends StatelessWidget {
  const _WorkoutPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Session',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _WorkoutDetail(
          details: [
            '5x400m repeats',
            '2 min recovery between sets',
          ],
        ),
      ],
    );
  }
}

class _WorkoutDetail extends StatelessWidget {
  final List<String> details;

  const _WorkoutDetail({
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details.map((detail) =>
          Text(
            detail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
      ).toList(),
    );
  }
}

class _StartWorkoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _StartWorkoutButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _PulsingButton(
        onPressed: onPressed,
        child: const Text(
          'Start Workout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _PulsingButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _PulsingButton({
    required this.onPressed,
    required this.child,
  });

  @override
  _PulsingButtonState createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Optional: Add this for workout details
class WorkoutDetailsSheet extends StatelessWidget {
  const WorkoutDetailsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workout Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Warm Up',
            duration: '10 min',
            description: 'Light jog and dynamic stretches',
          ),
          _buildSection(
            title: 'Main Set',
            duration: '20 min',
            description: '5 x 400m at 5K pace\n2 min recovery between sets',
          ),
          _buildSection(
            title: 'Cool Down',
            duration: '5 min',
            description: 'Easy jog and stretching',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String duration,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardHoverBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              duration,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}