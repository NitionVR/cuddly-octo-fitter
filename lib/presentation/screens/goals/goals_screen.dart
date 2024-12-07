// lib/presentation/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/goals/goals_view_model.dart';
import '../../../domain/entities/goals/fitness_goal.dart';

class GoalsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fitness Goals'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateGoalDialog(context),
          ),
        ],
      ),
      body: Consumer<GoalsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Text(viewModel.error!, style: TextStyle(color: Colors.red)),
            );
          }

          if (viewModel.activeGoals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No active goals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showCreateGoalDialog(context),
                    child: Text('Create a Goal'),
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
    );
  }

  void _showCreateGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateGoalDialog(),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final FitnessGoal goal;

  const _GoalCard({Key? key, required this.goal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                  icon: Icon(Icons.more_vert),
                  onPressed: () => _showGoalOptions(context),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal.progressPercentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${goal.progressPercentage.toStringAsFixed(1)}% Complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 4),
            Text(
              _getGoalPeriodText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
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
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Goal'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show edit dialog
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Goal', style: TextStyle(color: Colors.red)),
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
        title: Text('Delete Goal'),
        content: Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete', style: TextStyle(color: Colors.red)),
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
  @override
  _CreateGoalDialogState createState() => _CreateGoalDialogState();
}

class _CreateGoalDialogState extends State<CreateGoalDialog> {
  late GoalType _selectedType = GoalType.distance;
  late GoalPeriod _selectedPeriod = GoalPeriod.weekly;
  final _targetController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create New Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<GoalType>(
              value: _selectedType,
              items: GoalType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Goal Type'),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target',
                suffixText: _getTargetSuffix(),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<GoalPeriod>(
              value: _selectedPeriod,
              items: GoalPeriod.values.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(period.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                  _updateDates();
                });
              },
              decoration: InputDecoration(labelText: 'Period'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Create'),
          onPressed: () => _createGoal(context),
        ),
      ],
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
        _endDate = _startDate.add(Duration(days: 1));
        break;
      case GoalPeriod.weekly:
        _endDate = _startDate.add(Duration(days: 7));
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
        SnackBar(content: Text('Please enter a target value')),
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
        SnackBar(content: Text('Invalid target value')),
      );
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}