// // lib/presentation/widgets/social/workout_details.dart
// import 'package:flutter/material.dart';
//
// class WorkoutDetails extends StatelessWidget {
//   final double distance;
//   final Duration duration;
//   final String pace;
//
//   const WorkoutDetails({
//     Key? key,
//     required this.distance,
//     required this.duration,
//     required this.pace,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildDetailColumn('Distance', '${distance.toStringAsFixed(2)} km'),
//           _buildDetailColumn('Duration', _formatDuration(duration)),
//           _buildDetailColumn('Pace', pace),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetailColumn(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             color: Colors.grey,
//             fontSize: 12,
//           ),
//         ),
//         SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       ],
//     );
//   }
//
//   String _formatDuration(Duration duration) {
//     final hours = duration.inHours;
//     final minutes = duration.inMinutes.remainder(60);
//     return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
//   }
// }