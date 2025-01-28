import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/achievements_repository.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../../domain/repository/goals/goals_repository.dart';
import '../../theme/app_colors.dart';
import 'home/home_screen.dart';
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
    final trackingRepository = Provider.of<TrackingRepository>(context);
    final goalsRepository = Provider.of<GoalsRepository>(context);
    final achievementsRepository = Provider.of<AchievementsRepository>(context);

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
        body: IndexedStack(
          index: _currentIndex,
          children: [
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
        setState(() => _currentIndex = 2);
      },
      icon: const Icon(Icons.play_arrow),
      label: const Text(
        'START RUN',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      backgroundColor: AppColors.buttonPrimary,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
        child: BottomAppBar(
          color: Colors.transparent,
          elevation: 0,
          notchMargin: 8,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Plan'),
                const SizedBox(width: 80),
                _buildNavItem(3, Icons.analytics_outlined, Icons.analytics, 'Analytics'),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.cardHoverBackground : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Optional: Add this animation for screen transitions
class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> {
  double _opacity = 1.0;

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      setState(() => _opacity = 0.0);
      Future.delayed(const Duration(milliseconds: 1), () {
        setState(() => _opacity = 1.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}