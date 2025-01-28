import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';

// Import your local files
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/viewmodels/achievements_viewmodel.dart';
import 'presentation/viewmodels/auth/auth_viewmodel.dart';
import 'presentation/viewmodels/goals/goals_view_model.dart';
import 'presentation/viewmodels/training/training_plan_view_model.dart';
import 'domain/repository/achievements_repository.dart';
import 'domain/repository/auth/firebase_auth_repository.dart';
import 'domain/repository/firebase_achievements_repository.dart';
import 'domain/repository/goals/firebase_goals_repository.dart';
import 'domain/repository/goals/goals_repository.dart';
import 'domain/repository/training/firebase_training_plan_repository.dart';
import 'domain/services/firestore_tracking_service.dart';
import 'firebase_options.dart';
import 'domain/repository/tracking/tracking_repository.dart';
import 'domain/repository/auth/auth_repository.dart';
import 'presentation/viewmodels/tracking/map_view_model.dart';
import 'presentation/viewmodels/analytics_view_model.dart';
import 'presentation/viewmodels/training/interval_training_view_model.dart';
import 'domain/usecases/location_tracking_use_case.dart';
import 'data/datasources/local/location_service.dart';
import 'data/datasources/local/tracking_local_data_source.dart';

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Base Services
        Provider<Location>(
          create: (_) => Location(),
        ),
        Provider<LocationService>(
          create: (context) => LocationService(context.read<Location>()),
        ),
        Provider<TrackingLocalDataSource>(
          create: (_) => TrackingLocalDataSource(),
        ),

        // Auth
        Provider<AuthRepository>(
          create: (_) => FirebaseAuthRepository(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(context.read<AuthRepository>()),
          lazy: false,
        ),

        // Tracking Services
        Provider<FirestoreTrackingService>(
          create: (_) => FirestoreTrackingService(),
        ),
        ProxyProvider2<TrackingLocalDataSource, FirestoreTrackingService, TrackingRepository>(
          update: (_, localDataSource, firestoreService, __) =>
              TrackingRepository(localDataSource, firestoreService),
        ),

        // Location Tracking
        ProxyProvider<LocationService, LocationTrackingUseCase>(
          update: (_, locationService, __) =>
              LocationTrackingUseCase(locationService.locationStream),
        ),

        // Repositories
        ProxyProvider<AuthViewModel, GoalsRepository?>(
          update: (_, authViewModel, __) => authViewModel.isAuthenticated
              ? FirebaseGoalsRepository()
              : null,
        ),
        ProxyProvider<AuthViewModel, AchievementsRepository?>(
          update: (_, authViewModel, __) => authViewModel.isAuthenticated
              ? FirebaseAchievementsRepository()
              : null,
        ),
        Provider<FirebaseTrainingPlanRepository>(
          create: (_) => FirebaseTrainingPlanRepository(),
        ),

        // ViewModels
        ChangeNotifierProxyProvider2<GoalsRepository?, AuthViewModel, GoalsViewModel>(
          create: (_) => GoalsViewModel(null, ''),
          update: (_, goalsRepository, authViewModel, previous) {
            return (authViewModel.isAuthenticated && goalsRepository != null)
                ? GoalsViewModel(goalsRepository, authViewModel.currentUser!.id)
                : previous!..clear();
          },
        ),

        ChangeNotifierProxyProvider2<AchievementsRepository?, AuthViewModel, AchievementsViewModel>(
          create: (_) => AchievementsViewModel(null, ''),
          update: (_, achievementsRepository, authViewModel, previous) {
            return (authViewModel.isAuthenticated && achievementsRepository != null)
                ? AchievementsViewModel(achievementsRepository, authViewModel.currentUser!.id)
                : previous!..clear();
          },
        ),

        ChangeNotifierProxyProvider3<AuthViewModel, TrackingRepository, LocationTrackingUseCase, MapViewModel>(
          create: (_) => MapViewModel(
            null,
            null,
            null,
            MapController(),
            null,
          ),
          update: (context, authViewModel, trackingRepository, locationTrackingUseCase, previous) {
            return (authViewModel.isAuthenticated)
                ? MapViewModel(
              locationTrackingUseCase,
              trackingRepository,
              context.read<LocationService>(),
              previous?.mapController ?? MapController(),
              authViewModel,
            )
                : previous!..clear();
          },
        ),

        ChangeNotifierProvider<AnalyticsViewModel>(
          create: (context) => AnalyticsViewModel(context.read<TrackingRepository>()),
        ),

        ChangeNotifierProvider<IntervalTrainingViewModel>(
          create: (_) => IntervalTrainingViewModel(),
        ),

        ChangeNotifierProxyProvider2<AuthViewModel, FirebaseTrainingPlanRepository, TrainingPlanViewModel>(
          create: (_) => TrainingPlanViewModel(null, ''),
          update: (_, authViewModel, trainingPlanRepo, previous) {
            return (authViewModel.isAuthenticated)
                ? TrainingPlanViewModel(trainingPlanRepo, authViewModel.currentUser!.id)
                : previous!..clear();
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
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const AuthenticationWrapper(),
      ),
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({super.key});

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  bool _isInitializing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // Show loading while auth is being checked
        if (authViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show login screen if not authenticated
        if (!authViewModel.isAuthenticated) {
          return const LoginScreen();
        }

        // Initialize ViewModels if authenticated
        return FutureBuilder(
          future: _initializeViewModels(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Check if all ViewModels are initialized
            return Consumer4<GoalsViewModel, AchievementsViewModel, MapViewModel, TrainingPlanViewModel>(
              builder: (context, goalsVM, achievementsVM, mapVM, trainingPlanVM, _) {
                final allInitialized = goalsVM.isInitialized &&
                    achievementsVM.isInitialized &&
                    mapVM.isInitialized &&
                    trainingPlanVM.isInitialized;

                if (!allInitialized) {
                  print('Not all ViewModels initialized:');
                  print('Goals: ${goalsVM.isInitialized}');
                  print('Achievements: ${achievementsVM.isInitialized}');
                  print('Map: ${mapVM.isInitialized}');
                  print('Training: ${trainingPlanVM.isInitialized}');
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                return const MainScreen();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _initializeViewModels(BuildContext context) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final goalsVM = context.read<GoalsViewModel>();
      final achievementsVM = context.read<AchievementsViewModel>();
      final mapVM = context.read<MapViewModel>();
      final trainingPlanVM = context.read<TrainingPlanViewModel>();

      // Initialize each ViewModel sequentially to avoid race conditions
      await goalsVM.initialize();
      print('Goals initialized');

      await achievementsVM.initialize();
      print('Achievements initialized');

      await mapVM.initialize();
      print('Map initialized');

      await trainingPlanVM.initialize();
      print('Training initialized');

    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      _isInitializing = false;
    }
  }
}
