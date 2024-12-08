// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart';
// import '../../../domain/entities/social/shared_workout.dart';
// import '../../viewmodels/social/social_view_models.dart';
// import 'workout_header.dart';
// import 'workout_map.dart';
// import 'workout_details.dart';
//
// class SharedWorkoutCard extends StatelessWidget {
//   final SharedWorkout workout;
//   final String currentUserId;
//
//   const SharedWorkoutCard({
//     Key? key,
//     required this.workout,
//     required this.currentUserId,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           WorkoutHeader(
//             userId: workout.userId,
//             currentUserId: currentUserId,
//             userName: workout.userName,
//             userProfileImage: workout.userProfileImage,
//             title: workout.title,
//             timestamp: workout.timestamp,
//             onProfileTap: () => _navigateToProfile(context),
//             onActionSelected: (value) => _handleMenuAction(context, value),
//           ),
//           WorkoutMap(route: workout.route),
//           WorkoutDetails(
//             distance: workout.distance,
//             duration: workout.duration,
//             pace: workout.pace,
//           ),
//           _buildInteractions(context),
//           if (workout.comments.isNotEmpty)
//             _buildComments(context),
//         ],
//       ),
//     );
//   }
//
//   // ... Keep the interaction and comments building methods ...
//   // [Previous methods like _buildInteractions, _buildComments remain the same]
//
//   void _navigateToProfile(BuildContext context) {
//     if (workout.userId != currentUserId) {
//       Navigator.pushNamed(context, '/profile/${workout.userId}');
//     }
//   }
//
//   void _handleMenuAction(BuildContext context, String value) {
//     switch (value) {
//       case 'delete':
//         _confirmDelete(context);
//         break;
//       case 'share':
//         _shareWorkout(context);
//         break;
//       case 'report':
//         _showReportDialog(context);
//         break;
//     }
//   }
//
// // ... Keep the utility methods ...
// // [Previous methods for delete confirmation, sharing, reporting remain the same]
//   void _shareWorkout(BuildContext context) {
//     final shareText = '''
//       Check out my ${workout.distance.toStringAsFixed(2)}km workout!
//       Time: ${_formatDuration(workout.duration)}
//       Pace: ${workout.pace}
//       ''';
//
//     Share.share(
//       shareText,
//       subject: workout.title,
//     );
//   }
//
//   void _showComments(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CommentsScreen(workout: workout),
//       ),
//     );
//   }
//
//   void _showReportDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Report Workout'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text('Why are you reporting this workout?'),
//             SizedBox(height: 16),
//             ListTile(
//               title: Text('Inappropriate content'),
//               onTap: () => _submitReport(context, 'inappropriate'),
//             ),
//             ListTile(
//               title: Text('Spam'),
//               onTap: () => _submitReport(context, 'spam'),
//             ),
//             ListTile(
//               title: Text('Other'),
//               onTap: () => _submitReport(context, 'other'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   void _submitReport(BuildContext context, String reason) {
//     context.read<SocialViewModel>().reportWorkout(workout.id, reason);
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Thank you for your report. We\'ll review it shortly.'),
//       ),
//     );
//   }
//
//   void _confirmDelete(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Delete Workout'),
//         content: Text('Are you sure you want to delete this workout?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               context.read<SocialViewModel>().deleteWorkout(workout.id);
//               Navigator.pop(context);
//             },
//             child: Text('Delete', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
// }
//
// class _buildInteractions {
//   _buildInteractions(BuildContext context);
// }
//
// class _buildComments {
//   _buildComments(BuildContext context);
// }
//
// class _formatDuration {
//   _formatDuration(Duration duration);
// }