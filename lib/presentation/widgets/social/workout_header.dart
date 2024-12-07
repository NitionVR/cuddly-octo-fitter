// // lib/presentation/widgets/social/workout_header.dart
// import 'package:flutter/material.dart';
//
// class WorkoutHeader extends StatelessWidget {
//   final String userId;
//   final String currentUserId;
//   final String? userName;
//   final String? userProfileImage;
//   final String title;
//   final DateTime timestamp;
//   final Function() onProfileTap;
//   final Function(String) onActionSelected;
//
//   const WorkoutHeader({
//     Key? key,
//     required this.userId,
//     required this.currentUserId,
//     this.userName,
//     this.userProfileImage,
//     required this.title,
//     required this.timestamp,
//     required this.onProfileTap,
//     required this.onActionSelected,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: GestureDetector(
//         onTap: onProfileTap,
//         child: Hero(
//           tag: 'profile_$userId',
//           child: CircleAvatar(
//             backgroundImage: userProfileImage != null
//                 ? NetworkImage(userProfileImage!)
//                 : null,
//             child: userProfileImage == null
//                 ? Icon(Icons.person)
//                 : null,
//           ),
//         ),
//       ),
//       title: GestureDetector(
//         onTap: onProfileTap,
//         child: Text(userName ?? 'User'),
//       ),
//       subtitle: Text(DateFormatter.formatTimestamp(timestamp)),
//       trailing: PopupMenuButton<String>(
//         itemBuilder: (context) => [
//           if (userId == currentUserId)
//             PopupMenuItem(
//               value: 'delete',
//               child: Text('Delete'),
//             ),
//           PopupMenuItem(
//             value: 'share',
//             child: Text('Share'),
//           ),
//           PopupMenuItem(
//             value: 'report',
//             child: Text('Report'),
//           ),
//         ],
//         onSelected: onActionSelected,
//       ),
//     );
//   }
// }
//
// class DateFormatter {
//   static String formatTimestamp(DateTime timestamp) {
//     final dateFormat = '${timestamp.year}-${timestamp.month.toString().padLeft(
//         2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
//     final timeFormat = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp
//         .minute.toString().padLeft(2, '0')}';
//     return '$dateFormat at $timeFormat';
//   }
// }