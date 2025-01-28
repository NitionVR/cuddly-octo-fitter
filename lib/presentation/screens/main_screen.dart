import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/achievements_repository.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../../domain/repository/goals/goals_repository.dart';
import 'home_screen.dart';
import 'tracking/map_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'training/training_plan_screens.dart';
import 'package:mobile_project_fitquest/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

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
            const TrainingPlansScreen(),
            const MapScreen(),
            const AnalyticsScreen(),
            const SettingsScreen(),
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
      icon: const Icon(Icons.play_arrow),
      label: const Text('START RUN'),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildBottomNavBar() {
    return BottomAppBar(
      color: AppColors.cardDark,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
          _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Plan'),
          const SizedBox(width: 80), // Space for FAB
          _buildNavItem(3, Icons.analytics_outlined, Icons.analytics, 'Analytics'),
          _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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