import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/personal_record.dart';
import '../../../../theme/app_colors.dart';
import '../../../viewmodels/analytics_view_model.dart';
import '../../../widgets/dashboard_card.dart';

class PersonalRecordsCard extends StatelessWidget {
  const PersonalRecordsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsViewModel>();

    return DashboardCard(
      icon: const Icon(Icons.emoji_events_outlined, color: Colors.white, size: 24),
      title: 'Personal Records',
      content: analytics.isLoading
          ? const _LoadingState()
          : analytics.personalRecords.isEmpty
          ? const _EmptyState()
          : _RecordsGrid(records: analytics.personalRecords),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'No records yet',
        style: TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
      ),
    );
  }
}

class _RecordsGrid extends StatelessWidget {
  final List<PersonalRecord> records;

  const _RecordsGrid({required this.records});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      padding: const EdgeInsets.all(16),
      children: [
        _RecordItem(
          record: _findRecord(
            'Longest Run',
            defaultValue: '0.0 km',
          ),
          icon: Icons.straighten,
        ),
        _RecordItem(
          record: _findRecord(
            'Fastest Pace',
            defaultValue: '0:00 /km',
          ),
          icon: Icons.speed,
        ),
        _RecordItem(
          record: _findRecord(
            'Longest Duration',
            defaultValue: '0h 0m',
          ),
          icon: Icons.timer,
        ),
        _RecordItem(
          record: _findRecord(
            'Weekly Distance',
            defaultValue: '0.0 km',
          ),
          icon: Icons.calendar_today,
        ),
      ],
    );
  }

  PersonalRecord _findRecord(String category, {required String defaultValue}) {
    return records.firstWhere(
          (r) => r.category == category,
      orElse: () => PersonalRecord(
        category: category,
        value: 0,
        displayValue: defaultValue,
        achievedDate: DateTime.now(),
      ),
    );
  }
}

class _RecordItem extends StatelessWidget {
  final PersonalRecord record;
  final IconData icon;

  const _RecordItem({
    required this.record,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardHoverBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.category,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.displayValue,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (record.value > 0) ...[
            const SizedBox(height: 4),
            Text(
              _formatDate(record.achievedDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Optional: Add this for record animations
class AnimatedRecordValue extends StatelessWidget {
  final String value;
  final TextStyle? style;

  const AnimatedRecordValue({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Text(
        value,
        style: style,
      ),
    );
  }
}

// Optional: Add this for record details
class RecordDetails extends StatelessWidget {
  final PersonalRecord record;

  const RecordDetails({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            record.displayValue,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Achieved on ${_formatDate(record.achievedDate)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}