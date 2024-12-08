import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../../theme/app_theme.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import 'tracking/map_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'achievements_screen.dart';
import 'goals/goals_screen.dart';
import 'training/active_plan_screen.dart';
import 'training/interval_training_screen.dart';
import 'training/plan_details_screen.dart';
import 'training/training_plan_screens.dart';




class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRecentActivitiesCard(context),
            SizedBox(height: 16),
            _buildGoalsCard(context),
            SizedBox(height: 16),
            _buildPersonalRecordsCard(context),
            SizedBox(height: 16),
            _buildQuickStatsRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Recent Activities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryScreen()),
              ),
              child: Text('More', style: TextStyle(color: AppColors.accentGreen)),
            ),
          ),
          Divider(color: AppColors.textSecondary),
          ...List.generate(3, (index) => _buildActivityItem()).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem() {
    return ListTile(
      leading: Icon(Icons.directions_run, color: AppColors.accentGreen),
      title: Text('Morning Run', style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text('5.2 km • 32:14 • 6:12/km', style: TextStyle(color: AppColors.textSecondary)),
      trailing: Text('2h ago', style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildGoalsCard(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('Goals Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GoalsScreen()),
              ),
              child: Text('More', style: TextStyle(color: AppColors.accentGreen)),
            ),
          ),
          Divider(color: AppColors.textSecondary),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildGoalProgress('Weekly Distance', 0.7, '35/50 km'),
                SizedBox(height: 12),
                _buildGoalProgress('Monthly Runs', 0.5, '6/12 runs'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress(String label, double progress, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppColors.textPrimary)),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.progressBackground,
          color: AppColors.progressBar,
        ),
        SizedBox(height: 4),
        Text(status, style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildPersonalRecordsCard(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text('Personal Records',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Divider(color: AppColors.textSecondary),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            padding: EdgeInsets.all(16),
            children: [
              _buildRecordItem('Longest Run', '15.3 km'),
              _buildRecordItem('Fastest 5K', '25:30'),
              _buildRecordItem('Longest Streak', '7 days'),
              _buildRecordItem('Best Pace', '5:30/km'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildQuickStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard('This Week', '23.4 km'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatCard('Active Streak', '3 days'),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatCard('Next Plan', 'Tomorrow'),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String label, String value) {
    return Card(
      color: AppColors.cardDark,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}