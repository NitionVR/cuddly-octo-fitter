import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/goal_type.dart';
import '../../viewmodels/goals/goals_view_model.dart';
import '../../../domain/entities/goals/fitness_goal.dart';
import 'package:mobile_project_fitquest/theme/app_theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Fitness Goals', style: TextStyle(color: AppColors.textPrimary)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.textSecondary),
              onPressed: () => _showCreateGoalDialog(context),
            ),
          ],
        ),
        body: Consumer<GoalsViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(
                child: Text(viewModel.error!, style: const TextStyle(color: AppColors.errorRed)),
              );
            }

            if (viewModel.activeGoals.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No active goals',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _showCreateGoalDialog(context),
                      child: const Text('Create a Goal'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: viewModel.activeGoals.length,
              itemBuilder: (context, index) {
                final goal = viewModel.activeGoals[index];
                return _GoalCard(goal: goal);
              },
            );
          },
        ),
      ),
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGoalDialog(),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final FitnessGoal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardDark,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getGoalTitle(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                  onPressed: () => _showGoalOptions(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progressPercentage / 100,
              backgroundColor: AppColors.progressBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? AppColors.successGreen : AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.progressPercentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _getGoalPeriodText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGoalTitle() {
    switch (goal.type) {
      case GoalType.distance:
        return '${goal.target}km ${goal.period.toString().split('.').last}';
      case GoalType.duration:
        return '${goal.target} minutes';
      case GoalType.frequency:
        return '${goal.target.toInt()} workouts';
      case GoalType.calories:
        return '${goal.target.toInt()} calories';
      case GoalType.pace:
        return '${goal.target}/km pace';
    }
  }

  String _getGoalPeriodText() {
    final remaining = goal.endDate.difference(DateTime.now()).inDays;
    return '$remaining days remaining';
  }

  void _showGoalOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.textSecondary),
            title: const Text('Edit Goal', style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show edit dialog
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.errorRed),
            title: const Text('Delete Goal', style: TextStyle(color: AppColors.errorRed)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Delete Goal', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to delete this goal?', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
            onPressed: () {
              context.read<GoalsViewModel>().deleteGoal(goal.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class CreateGoalDialog extends StatefulWidget {
  const CreateGoalDialog({super.key});

  @override
  _CreateGoalDialogState createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  late GoalType _selectedType = GoalType.distance;
  late GoalPeriod _selectedPeriod = GoalPeriod.weekly;
  final _targetController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text('Create New Goal', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<GoalType>(
                value: _selectedType,
                items: GoalType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last, style: const TextStyle(color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Goal Type',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Target',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  suffixText: _getTargetSuffix(),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GoalPeriod>(
                value: _selectedPeriod,
                items: GoalPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period.toString().split('.').last, style: const TextStyle(color: AppColors.textPrimary)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                    _updateDates();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Period',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.accentGreen),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Create'),
            onPressed: () => _createGoal(context),
          ),
        ],
      ),
    );
  }

  String _getTargetSuffix() {
    switch (_selectedType) {
      case GoalType.distance:
        return 'km';
      case GoalType.duration:
        return 'min';
      case GoalType.frequency:
        return 'times';
      case GoalType.calories:
        return 'cal';
      case GoalType.pace:
        return 'min/km';
    }
  }

  void _updateDates() {
    _startDate = DateTime.now();
    switch (_selectedPeriod) {
      case GoalPeriod.daily:
        _endDate = _startDate.add(const Duration(days: 1));
        break;
      case GoalPeriod.weekly:
        _endDate = _startDate.add(const Duration(days: 7));
        break;
      case GoalPeriod.monthly:
        _endDate = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
        break;
      case GoalPeriod.custom:
      // Show date picker
        break;
    }
  }

  void _createGoal(BuildContext context) {
    if (_targetController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target value', style: TextStyle(color: AppColors.textPrimary))),
      );
      return;
    }

    try {
      final target = double.parse(_targetController.text);
      context.read<GoalsViewModel>().createGoal(
        type: _selectedType,
        period: _selectedPeriod,
        target: target,
        startDate: _startDate,
        endDate: _endDate,
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid target value', style: TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}