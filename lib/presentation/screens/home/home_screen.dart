import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/database/providers/database_provider.dart';
import '../../../theme/app_colors.dart';
import '../../viewmodels/achievements/achievements_view_model.dart';
import '../../viewmodels/analytics/analytics_view_model.dart';
import '../../viewmodels/auth/auth_view_model.dart';
import '../../viewmodels/goals/goals_view_model.dart';
import '../achievements/achievements_screen.dart';
import '../analytics/analytics_screen.dart';
import '../goals/goals_screen.dart';
import '../history_screen.dart';
import 'components/achievements_card.dart';
import 'components/goals_card.dart';
import 'components/interval_training_card.dart';
import 'components/personal_records_card.dart';
import 'components/recent_activities_card.dart';
import 'components/statistics_card.dart';

class HomeScreen extends StatelessWidget {

  final DatabaseProvider databaseProvider;

  const HomeScreen({
    super.key,
    required this.databaseProvider,
  });

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthViewModel>().currentUser!.id;
    final databaseProvider = context.read<DatabaseProvider>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AnalyticsViewModel(
            databaseProvider.trackingRepository, // ITrackingRepository
            databaseProvider,
          )..loadAnalytics(userId),
        ),
        ChangeNotifierProvider(
          create: (_) => GoalsViewModel(
            databaseProvider.goalsRepository, // IGoalsRepository
            databaseProvider,
            userId,
          )..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => AchievementsViewModel(
            databaseProvider.achievementsRepository, // IAchievementsRepository
            databaseProvider,
            userId,
          )..initialize(),
        ),
      ],
      child: const HomeScreenContent(),
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initializeViewModels();
  }

  Future<void> _initializeViewModels() async {
    final goalsVM = context.read<GoalsViewModel>();
    final achievementsVM = context.read<AchievementsViewModel>();
    final analyticsVM = context.read<AnalyticsViewModel>();
    final userId = context.read<AuthViewModel>().currentUser!.id;

    try {
      await Future.wait([
        goalsVM.initialize(),
        achievementsVM.initialize(),
        analyticsVM.loadAnalytics(userId),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    final databaseProvider = context.read<DatabaseProvider>();
    final userId = context.read<AuthViewModel>().currentUser!.id;

    try {
      // First sync all data
      await databaseProvider.syncService.syncAll();

      // Then refresh view models
      await Future.wait([
        context.read<AnalyticsViewModel>().loadAnalytics(userId),
        context.read<GoalsViewModel>().refreshGoals(),
        context.read<AchievementsViewModel>().refreshAchievements(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
      child: SafeArea(
        child: FutureBuilder(
          future: _initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: 16,
                ),
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
          },
        ),
      ),
    );
  }
}