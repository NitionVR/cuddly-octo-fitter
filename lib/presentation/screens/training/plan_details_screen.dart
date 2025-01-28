import 'package:flutter/material.dart';
import '../../../domain/entities/training/training_plan.dart';
import '../../../domain/entities/training/training_week.dart';

class PlanDetailsScreen extends StatelessWidget {
  final TrainingPlan plan;

  const PlanDetailsScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(plan.title),
              background: plan.imageUrl != null
                  ? Image.network(
                plan.imageUrl!,
                fit: BoxFit.cover,
              )
                  : Container(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverview(),
                  const SizedBox(height: 24),
                  Text(
                    'Week by Week',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _WeekOverview(
                week: plan.weeks[index],
                isLastWeek: index == plan.weeks.length - 1,
              ),
              childCount: plan.weeks.length,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startPlan(context),
        label: const Text('Start Plan'),
        icon: const Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.description),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(Icons.calendar_today, '${plan.durationWeeks} weeks'),
            _buildStat(
              Icons.fitness_center,
              plan.type.toString().split('.').last,
            ),
            _buildStat(
              Icons.trending_up,
              plan.difficulty.toString().split('.').last,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(text),
      ],
    );
  }

  void _startPlan(BuildContext context) {
    // Navigate back and start plan
    Navigator.pop(context, true);
  }
}

class _WeekOverview extends StatelessWidget {
  final TrainingWeek week;
  final bool isLastWeek;

  const _WeekOverview({
    required this.week,
    this.isLastWeek = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Week ${week.weekNumber}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (week.notes != null) ...[
                const SizedBox(height: 8),
                Text(week.notes!),
              ],
            ],
          ),
        ),
        ...week.workouts.map((workout) => ListTile(
          leading: CircleAvatar(
            child: Text('Day ${workout.dayOfWeek}'),
          ),
          title: Text(workout.title),
          subtitle: Text(
            '${workout.targetDuration.inMinutes} min • '
                '${workout.intensity.toString().split('.').last}',
          ),
        )),
        if (!isLastWeek)
          const Divider(height: 32),
      ],
    );
  }
}