// lib/presentation/screens/training/training_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/presentation/screens/training/plan_details_screen.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/training/training_plan.dart';
import '../../viewmodels/training/training_plan_view_model.dart';
import 'active_plan_screen.dart';

class TrainingPlansScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Training Plans'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Available Plans'),
              Tab(text: 'Active Plan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AvailablePlansTab(),
            _ActivePlanTab(),
          ],
        ),
      ),
    );
  }
}

class _AvailablePlansTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingPlanViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (viewModel.availablePlans.isEmpty) {
          return Center(
            child: Text('No training plans available'),
          );
        }

        return ListView.builder(
          itemCount: viewModel.availablePlans.length,
          itemBuilder: (context, index) {
            final plan = viewModel.availablePlans[index];
            return _TrainingPlanCard(plan: plan);
          },
        );
      },
    );
  }
}

class _TrainingPlanCard extends StatelessWidget {
  final TrainingPlan plan;

  const _TrainingPlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPlanDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.imageUrl != null)
              Image.network(
                plan.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(plan.description),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text('${plan.durationWeeks} weeks'),
                        backgroundColor: Colors.grey[200],
                      ),
                      SizedBox(width: 8),
                      Chip(
                        label: Text(plan.difficulty.toString().split('.').last),
                        backgroundColor: _getDifficultyColor(plan.difficulty),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _startPlan(context),
                    child: Text('Start Plan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.beginner:
        return Colors.green[100]!;
      case DifficultyLevel.intermediate:
        return Colors.blue[100]!;
      case DifficultyLevel.advanced:
        return Colors.orange[100]!;
      case DifficultyLevel.expert:
        return Colors.red[100]!;
    }
  }

  void _showPlanDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanDetailsScreen(plan: plan),
      ),
    );
  }

  void _startPlan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Training Plan'),
        content: Text('Are you ready to start ${plan.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TrainingPlanViewModel>().startPlan(plan.id);
              Navigator.pop(context);
            },
            child: Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _ActivePlanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingPlanViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        final activePlan = viewModel.activePlan;
        if (activePlan == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No active training plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8),
                Text('Start a plan to begin your training journey'),
              ],
            ),
          );
        }

        return ActivePlanScreen(plan: activePlan);
      },
    );
  }
}