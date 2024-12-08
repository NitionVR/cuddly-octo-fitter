import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/achievements_repository.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../../domain/repository/goals/goals_repository.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import 'home_screen.dart';
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
import 'package:mobile_project_fitquest/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Access repositories from the root provider
    final trackingRepository = Provider.of<TrackingRepository>(context);
    final goalsRepository = Provider.of<GoalsRepository>(context);
    final achievementsRepository = Provider.of<AchievementsRepository>(context);

    return Theme(
      data: AppTheme.darkTheme,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Inject repositories into HomeScreen
            HomeScreen(
              trackingRepository: trackingRepository,
              goalsRepository: goalsRepository,
              achievementsRepository: achievementsRepository,
            ),
            TrainingPlansScreen(),
            MapScreen(),
            AnalyticsScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
        floatingActionButton: _buildFloatingActionButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 2) return null;

    return FloatingActionButton.extended(
      onPressed: () {
        setState(() => _currentIndex = 2);  // Switch to MapScreen
      },
      icon: Icon(Icons.play_arrow),
      label: Text('START RUN'),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: AppColors.cardDark,
      shape: CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
          _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Plan'),
          SizedBox(width: 80), // Space for FAB
          _buildNavItem(3, Icons.analytics_outlined, Icons.analytics, 'Analytics'),
          _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(
          _currentIndex == index ? activeIcon : icon,
          color: _currentIndex == index
              ? AppColors.accentGreen
              : AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _currentIndex = index),
      ),
    );
  }
}