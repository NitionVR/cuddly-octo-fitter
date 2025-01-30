import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/goal_type.dart';
import '../../../theme/app_colors.dart';
import '../../viewmodels/goals/goals_view_model.dart';
import '../../../domain/entities/goals/fitness_goal.dart';
import 'package:mobile_project_fitquest/theme/app_theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Goals',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () => _showCreateGoalDialog(context),
            ),
          ],
        ),
        body: Consumer<GoalsViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }

            if (viewModel.error != null) {
              return _buildErrorState(context, viewModel.error!);
            }

            if (viewModel.activeGoals.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildGoalsList(context, viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildGoalsList(BuildContext context, GoalsViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.activeGoals.length,
      itemBuilder: (context, index) {
        final goal = viewModel.activeGoals[index];
        return _GoalCard(goal: goal);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Goals',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set your first fitness goal',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateGoalDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withOpacity(0.8),
          ),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<GoalsViewModel>().refreshGoals(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGoalTypeChip(context),
                      const SizedBox(height: 8),
                      Text(
                        _getGoalTitle(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  onPressed: () => _showGoalOptions(context),
                ),
              ],
            ),
          ),

          // Progress Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${goal.progressPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildProgressBar(),
              ],
            ),
          ),

          // Stats Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatItem(
                  context,
                  'Current',
                  _formatValue(goal.currentProgress),
                ),
                _buildStatItem(
                  context,
                  'Target',
                  _formatValue(goal.target),
                ),
                _buildStatItem(
                  context,
                  'Remaining',
                  _getRemainingDays(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTypeChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardHoverBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getGoalTypeIcon(),
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            goal.period.toString().split('.').last,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Stack(
      children: [
        // Background
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.progressBackground,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        // Progress
        FractionallySizedBox(
          widthFactor: goal.progressPercentage / 100,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: _getProgressColor(),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGoalTypeIcon() {
    switch (goal.type) {
      case GoalType.distance:
        return Icons.straighten;
      case GoalType.duration:
        return Icons.timer;
      case GoalType.frequency:
        return Icons.repeat;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.pace:
        return Icons.speed;
    }
  }

  Color _getProgressColor() {
    if (goal.isCompleted) return Colors.green;
    if (goal.progressPercentage >= 90) return Colors.orange;
    return AppColors.buttonPrimary;
  }

  String _getGoalTitle() {
    switch (goal.type) {
      case GoalType.distance:
        return 'Run ${goal.target}km';
      case GoalType.duration:
        return 'Exercise for ${goal.target} minutes';
      case GoalType.frequency:
        return 'Complete ${goal.target.toInt()} workouts';
      case GoalType.calories:
        return 'Burn ${goal.target.toInt()} calories';
      case GoalType.pace:
        return 'Achieve ${goal.target}/km pace';
    }
  }

  String _formatValue(double value) {
    switch (goal.type) {
      case GoalType.distance:
        return '${value.toStringAsFixed(1)}km';
      case GoalType.duration:
        return '${value.toInt()}min';
      case GoalType.frequency:
        return '${value.toInt()}x';
      case GoalType.calories:
        return '${value.toInt()}cal';
      case GoalType.pace:
        return '$value/km';
    }
  }

  String _getRemainingDays() {
    final remaining = goal.endDate.difference(DateTime.now()).inDays;
    return '$remaining days';
  }

  void _showGoalOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: const Text(
                'Edit Goal',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show edit dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Goal',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Goal',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this goal?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<GoalsViewModel>().deleteGoal(goal.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
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
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundStart,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildContent(),
            const SizedBox(height: 24),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Create New Goal',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _currentStep,
      children: [
        _buildTypeSelection(),
        _buildTargetInput(),
        _buildPeriodSelection(),
      ],
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of goal?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...GoalType.values.map((type) => _buildTypeOption(type)),
      ],
    );
  }

  Widget _buildTypeOption(GoalType type) {
    final isSelected = type == _selectedType;
    return InkWell(
      onTap: () => setState(() {
        _selectedType = type;
        _currentStep = 1;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonPrimary.withOpacity(0.1) : AppColors.cardHoverBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.buttonPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getTypeIcon(type),
              color: isSelected ? AppColors.buttonPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTypeTitle(type),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    _getTypeDescription(type),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.buttonPrimary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your target',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _targetController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.3),
            ),
            suffixText: _getTargetSuffix(),
            suffixStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 24,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.textSecondary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.buttonPrimary),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              setState(() => _currentStep = 2);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPeriodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Over what period?',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        ...GoalPeriod.values.map((period) => _buildPeriodOption(period)),
      ],
    );
  }

  Widget _buildPeriodOption(GoalPeriod period) {
    final isSelected = period == _selectedPeriod;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _updateDates();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonPrimary.withOpacity(0.1) : AppColors.cardHoverBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.buttonPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(
              period.toString().split('.').last,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.buttonPrimary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          )
        else
          const SizedBox.shrink(),
        ElevatedButton(
          onPressed: _currentStep == 2 ? () => _createGoal(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Create Goal'),
        ),
      ],
    );
  }

  IconData _getTypeIcon(GoalType type) {
    switch (type) {
      case GoalType.distance:
        return Icons.straighten;
      case GoalType.duration:
        return Icons.timer;
      case GoalType.frequency:
        return Icons.repeat;
      case GoalType.calories:
        return Icons.local_fire_department;
      case GoalType.pace:
        return Icons.speed;
    }
  }

  String _getTypeTitle(GoalType type) {
    switch (type) {
      case GoalType.distance:
        return 'Distance Goal';
      case GoalType.duration:
        return 'Time Goal';
      case GoalType.frequency:
        return 'Frequency Goal';
      case GoalType.calories:
        return 'Calorie Goal';
      case GoalType.pace:
        return 'Pace Goal';
    }
  }

  String _getTypeDescription(GoalType type) {
    switch (type) {
      case GoalType.distance:
        return 'Set a target distance to cover';
      case GoalType.duration:
        return 'Set a target time to exercise';
      case GoalType.frequency:
        return 'Set a number of workouts to complete';
      case GoalType.calories:
        return 'Set a target calorie burn';
      case GoalType.pace:
        return 'Set a target pace to achieve';
    }
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
        return '/km';
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
      _showError('Please enter a target value');
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
      _showError('Invalid target value');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }
}