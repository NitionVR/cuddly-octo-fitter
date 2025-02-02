import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/presentation/screens/tracking/map_screen.dart';
import 'package:provider/provider.dart';
import '../../data/database/providers/database_provider.dart';
import '../../theme/app_colors.dart';
import 'analytics/analytics_screen.dart';
import 'home/home_screen.dart';
import 'settings_screen.dart';
import 'training/training_plan_screens.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseProvider>(context);

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
              databaseProvider: databaseProvider,
            ),
            const TrainingPlansScreen(),
            const MapScreen(),
            const AnalyticsScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),

      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon,
      String label) {
    final isSelected = _currentIndex == index;

    return SizedBox(
      width: 70,
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunButton() {
    return SizedBox(
      width: 70,
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = 2),
          child: Center(
            child: Icon(
              Icons.directions_run,
              color: _currentIndex == 2 ? Colors.white : AppColors
                  .textSecondary,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 60,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(
                1, Icons.calendar_today_outlined, Icons.calendar_today, 'Plan'),
            _buildRunButton(),
            _buildNavItem(
                3, Icons.analytics_outlined, Icons.analytics, 'Analytics'),
            _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
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