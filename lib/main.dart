import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mobile_project_fitquest/presentation/screens/home_screen.dart';
import 'package:mobile_project_fitquest/presentation/viewmodels/interval_training_view_model.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'domain/repository/tracking_repository.dart';
import 'presentation/viewmodels/map_view_model.dart';
import 'presentation/viewmodels/analytics_view_model.dart';
import 'domain/usecases/location_tracking_use_case.dart';
import 'data/datasources/local/location_service.dart';
import 'data/datasources/local/tracking_local_data_source.dart';

void main() {
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

        // ViewModels
        ChangeNotifierProvider<MapViewModel>(
          create: (context) {
            final locationTrackingUseCase = Provider.of<LocationTrackingUseCase>(context, listen: false);
            final trackingRepository = Provider.of<TrackingRepository>(context, listen: false);
            final locationService = Provider.of<LocationService>(context, listen: false);
            return MapViewModel(
              locationTrackingUseCase,
              trackingRepository,
              locationService,
              MapController()
            );
          },
        ),

        // Analytics ViewModel
        ChangeNotifierProvider<AnalyticsViewModel>(
          create: (context) {
            final trackingRepository = Provider.of<TrackingRepository>(context, listen: false);
            return AnalyticsViewModel(trackingRepository);
          },
        ),

        ChangeNotifierProvider(
          create: (_) => IntervalTrainingViewModel(),
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
      title: 'GPS Tracker',
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
      home: MainScreen(),
    );
  }
}