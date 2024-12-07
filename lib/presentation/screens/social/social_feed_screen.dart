// lib/presentation/screens/social/social_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/social_view_model.dart';
import '../../widgets/shared_workout_card.dart';

class SocialFeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feed'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/social/search'),
          ),
        ],
      ),
      body: Consumer<SocialViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(viewModel.error!),
                  ElevatedButton(
                    onPressed: viewModel.clearError,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.feed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_run, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No workouts in your feed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text('Follow friends to see their workouts here'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh functionality will be handled by the stream
            },
            child: ListView.builder(
              itemCount: viewModel.feed.length,
              itemBuilder: (context, index) {
                final workout = viewModel.feed[index];
                return SharedWorkoutCard(
                  workout: workout,
                  currentUserId: viewModel.userId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}