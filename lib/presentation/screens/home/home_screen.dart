import 'package:flutter/material.dart';
import 'package:mobile_project_fitquest/presentation/screens/achievements_screen.dart';
import 'package:mobile_project_fitquest/presentation/screens/analytics_screen.dart';
import 'package:mobile_project_fitquest/presentation/screens/goals/goals_screen.dart';
import 'package:provider/provider.dart';
import '../../../domain/repository/achievements_repository.dart';
import '../../../domain/repository/goals/goals_repository.dart';
import '../../../domain/repository/tracking/tracking_repository.dart';
import '../../../theme/app_colors.dart';
import '../../viewmodels/achievements_viewmodel.dart';
import '../../viewmodels/analytics_view_model.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/goals/goals_view_model.dart';
import '../history_screen.dart';
import 'components/achievements_card.dart';
import 'components/goals_card.dart';
import 'components/interval_training_card.dart';
import 'components/personal_records_card.dart';
import 'components/recent_activities_card.dart';
import 'components/statistics_card.dart';

class HomeScreen extends StatelessWidget {
  final TrackingRepository _trackingRepository;
  final GoalsRepository _goalsRepository;
  final AchievementsRepository _achievementsRepository;

  const HomeScreen({
    super.key,
    required TrackingRepository trackingRepository,
    required GoalsRepository goalsRepository,
    required AchievementsRepository achievementsRepository,
  })  : _trackingRepository = trackingRepository,
        _goalsRepository = goalsRepository,
        _achievementsRepository = achievementsRepository;

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser!.id;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalyticsViewModel(_trackingRepository)..loadAnalytics(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalsViewModel(_goalsRepository, userId),
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementsViewModel(_achievementsRepository, userId),
        ),
      ],
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecentActivitiesCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GoalsCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const PersonalRecordsCard(),
            const SizedBox(height: 16),
            StatisticsCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnalyticsScreen(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const IntervalTrainingCard(),
            const SizedBox(height: 16),
            AchievementsCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AchievementsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

