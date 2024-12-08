import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_project_fitquest/presentation/screens/home_screen.dart';
import 'package:mobile_project_fitquest/presentation/screens/auth/login_screen.dart';
import 'package:mobile_project_fitquest/presentation/screens/main_screen.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/auth/auth_viewmodel.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/training/training_plan_view_model.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';

import 'domain/repository/auth/firebase_auth_repository.dart';
import 'domain/repository/training/firebase_training_plan_repository.dart';
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
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Base services
        Provider<Location>(
          create: (_) => Location(),
        ),
        Provider<LocationService>(
          create: (context) => LocationService(
              Provider.of<Location>(context, listen: false)
          ),
        ),
        Provider<TrackingLocalDataSource>(
          create: (_) => TrackingLocalDataSource(),
        ),


        Provider<AuthRepository>(
          create: (_) => FirebaseAuthRepository(),
          lazy: false,
        ),

        // ViewModels
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
          ),
        ),

        // Repository
        ProxyProvider<TrackingLocalDataSource, TrackingRepository>(
          update: (_, localDataSource, __) => TrackingRepository(localDataSource),
        ),

        // Use cases
        ProxyProvider<LocationService, LocationTrackingUseCase>(
          update: (_, locationService, __) => LocationTrackingUseCase(
              locationService.locationStream
          ),
        ),

        // Other ViewModels
        ChangeNotifierProvider<MapViewModel>(
          create: (context) {
            final locationTrackingUseCase = Provider.of<LocationTrackingUseCase>(context, listen: false);
            final trackingRepository = Provider.of<TrackingRepository>(context, listen: false);
            final locationService = Provider.of<LocationService>(context, listen: false);
            final authviewModel = Provider.of<AuthViewModel>(context, listen: false);
            return MapViewModel(
                locationTrackingUseCase,
                trackingRepository,
                locationService,
                MapController(),
                authviewModel
            );
          },
        ),

        ChangeNotifierProvider<AnalyticsViewModel>(
          create: (context) {
            final trackingRepository = Provider.of<TrackingRepository>(context, listen: false);
            return AnalyticsViewModel(trackingRepository);
          },
        ),

        ChangeNotifierProvider(
          create: (_) => IntervalTrainingViewModel(),
        ),

        ChangeNotifierProvider<TrainingPlanViewModel>(
          create: (context) => TrainingPlanViewModel(
            FirebaseTrainingPlanRepository(),
            context.read<AuthViewModel>().currentUser!.id,
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitQuest',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        cardTheme: CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (_, authViewModel, __) {
        if (authViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        print(authViewModel.isAuthenticated);
        return authViewModel.isAuthenticated ? MainScreen() : LoginScreen();
      },
    );
  }
}