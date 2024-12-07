import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repository/tracking/tracking_repository.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/tracking/map_view_model.dart';
import '../viewmodels/analytics_view_model.dart';
import 'tracking/map_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authModel =  Provider.of<AuthViewModel>(context);
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
                )..loadAnalytics(authModel.currentUser!.id),
              ),
            ],
            child: AnalyticsScreen(),
          ),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Add this to show all items
        items: const [
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}