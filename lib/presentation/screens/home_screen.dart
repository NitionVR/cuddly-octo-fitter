import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/tracking_repository.dart';
import '../viewmodels/map_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MapScreen(),
          HistoryScreen(),
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (context) => AnalyticsViewModel(
                  Provider.of<TrackingRepository>(context, listen: false),
                )..loadAnalytics(),
              ),
            ],
            child: AnalyticsScreen(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}