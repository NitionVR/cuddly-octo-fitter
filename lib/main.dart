import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_project_fitquest/presentation/screens/auth/login_screen.dart';
import 'package:mobile_project_fitquest/presentation/screens/loading_screen.dart';
import 'package:mobile_project_fitquest/presentation/screens/splash_screen.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/achievements/achievements_view_model.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/analytics/analytics_view_model.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/auth/auth_view_model.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/goals/goals_view_model.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/tracking/map_view_model.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/training/interval_training_view_model.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/training/training_plan_view_model.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';

// Import your local files
import 'data/database/providers/database_provider.dart';
import 'presentation/screens/main_screen.dart';
import 'firebase_options.dart';
import 'domain/usecases/location_tracking_use_case.dart';
import 'data/datasources/local/location_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Consider showing an error screen or terminating the app
  }

  if (kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && !message.contains('gralloc4')) {
        print(message+"lol");
      }
    };
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initializeDatabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }

          final databaseProvider = snapshot.data as DatabaseProvider;

          return MultiProvider(
            providers: [
              // Core Services
              Provider<Location>(
                create: (_) => Location(),
              ),
              Provider<LocationService>(
                create: (context) => LocationService(context.read<Location>()),
              ),

              // Database Provider
              Provider<DatabaseProvider>.value(
                value: databaseProvider,
              ),

              // Auth ViewModel
              ChangeNotifierProvider<AuthViewModel>(
                create: (context) =>
                    AuthViewModel(
                      context
                          .read<DatabaseProvider>()
                          .authRepository,
                      context.read<DatabaseProvider>(),
                    ),
                lazy: false,
              ),

              // Goals ViewModel
              ChangeNotifierProxyProvider<AuthViewModel, GoalsViewModel>(
                create: (context) =>
                    GoalsViewModel(
                      context
                          .read<DatabaseProvider>()
                          .goalsRepository,
                      context.read<DatabaseProvider>(),
                      '',
                    ),
                update: (_, authViewModel, previous) {
                  return authViewModel.isAuthenticated
                      ? GoalsViewModel(
                    _
                        .read<DatabaseProvider>()
                        .goalsRepository,
                    _.read<DatabaseProvider>(),
                    authViewModel.currentUser!.id,
                  )
                      : previous!
                    ..clear();
                },
              ),

              // Achievements ViewModel
              ChangeNotifierProxyProvider<AuthViewModel, AchievementsViewModel>(
                create: (context) =>
                    AchievementsViewModel(
                      context
                          .read<DatabaseProvider>()
                          .achievementsRepository,
                      context.read<DatabaseProvider>(),
                      '',
                    ),
                update: (_, authViewModel, previous) {
                  return authViewModel.isAuthenticated
                      ? AchievementsViewModel(
                    _
                        .read<DatabaseProvider>()
                        .achievementsRepository,
                    _.read<DatabaseProvider>(),
                    authViewModel.currentUser!.id,
                  )
                      : previous!
                    ..clear();
                },
              ),

              // Map ViewModel
              ChangeNotifierProxyProvider<AuthViewModel, MapViewModel>(
                create: (context) =>
                    MapViewModel(
                      trackingRepository: context
                          .read<DatabaseProvider>()
                          .trackingRepository,
                      locationTrackingUseCase: LocationTrackingUseCase(
                        context
                            .read<LocationService>()
                            .locationStream,
                      ),
                      locationService: context.read<LocationService>(),
                      databaseProvider: context.read<DatabaseProvider>(),
                      authViewModel: context.read<AuthViewModel>(),
                      goalsViewModel: context.read<GoalsViewModel>(),
                      mapController: MapController(),
                    ),
                update: (_, authViewModel, previous) {
                  return authViewModel.isAuthenticated
                      ? MapViewModel(
                    trackingRepository: _
                        .read<DatabaseProvider>()
                        .trackingRepository,
                    locationTrackingUseCase: LocationTrackingUseCase(
                      _
                          .read<LocationService>()
                          .locationStream,
                    ),
                    locationService: _.read<LocationService>(),
                    databaseProvider: _.read<DatabaseProvider>(),
                    authViewModel: authViewModel,
                    goalsViewModel: _.read<GoalsViewModel>(),
                    mapController: previous?.mapController ?? MapController(),
                  )
                      : previous!
                    ..clear();
                },
              ),

              // Analytics ViewModel
              ChangeNotifierProxyProvider<AuthViewModel, AnalyticsViewModel>(
                create: (context) =>
                    AnalyticsViewModel(
                      context
                          .read<DatabaseProvider>()
                          .trackingRepository,
                      context.read<DatabaseProvider>(),
                    ),
                update: (_, authViewModel, previous) {
                  return authViewModel.isAuthenticated
                      ? AnalyticsViewModel(
                    _
                        .read<DatabaseProvider>()
                        .trackingRepository,
                    _.read<DatabaseProvider>(),
                  )
                      : previous!;
                },
              ),

              // Interval Training ViewModel
              ChangeNotifierProxyProvider<
                  AuthViewModel,
                  IntervalTrainingViewModel>(
                create: (context) =>
                    IntervalTrainingViewModel(
                      context.read<DatabaseProvider>(),
                      '',
                    ),
                update: (_, authViewModel, previous) {
                  return authViewModel.isAuthenticated
                      ? IntervalTrainingViewModel(
                    _.read<DatabaseProvider>(),
                    authViewModel.currentUser!.id,
                  )
                      : previous!;
                },
              ),

              // Training Plan ViewModel
              ChangeNotifierProxyProvider<AuthViewModel, TrainingPlanViewModel>(
                create: (context) =>
                    TrainingPlanViewModel(
                      context
                          .read<DatabaseProvider>()
                          .trainingPlanRepository,
                      context.read<DatabaseProvider>(),
                      '',
                    ),
                update: (_, authViewModel, previous) {
                  return authViewModel.isAuthenticated
                      ? TrainingPlanViewModel(
                    _
                        .read<DatabaseProvider>()
                        .trainingPlanRepository,
                    _.read<DatabaseProvider>(),
                    authViewModel.currentUser!.id,
                  )
                      : previous!
                    ..clear();
                },
              ),

            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'FitQuest',
              theme: ThemeData(
                primarySwatch: Colors.teal,
                scaffoldBackgroundColor: Colors.grey[100],
                cardTheme: CardTheme(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              home: const AuthenticationWrapper(),
            ),
          );
        });
      }

  Future<DatabaseProvider> _initializeDatabase() async {
    final provider = DatabaseProvider();
    await provider.initialize();
    return provider;
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();


}


class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _showSplash = true;
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _removeSplashAfterDelay();
  }

  Future<void> _removeSplashAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  Future<void> _initializeViewModels(BuildContext context) async {
    final goalsVM = context.read<GoalsViewModel>();
    final achievementsVM = context.read<AchievementsViewModel>();
    final mapVM = context.read<MapViewModel>();
    final trainingPlanVM = context.read<TrainingPlanViewModel>();

    // Initialize all view models concurrently
    await Future.wait([
      goalsVM.initialize(),
      achievementsVM.initialize(),
      mapVM.initialize(),
      trainingPlanVM.initialize(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        if (authViewModel.isLoading) {
          return const LoadingScreen(message: 'Checking authentication...');
        }

        if (!authViewModel.isAuthenticated) {
          return const LoginScreen();
        }

        // Use FutureBuilder for initialization
        return FutureBuilder(
          future: _initializeViewModels(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingScreen(message: 'Initializing services...');
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error initializing: ${snapshot.error}'),
              );
            }

            return const MainScreen();
          },
        );
      },
    );
  }
}