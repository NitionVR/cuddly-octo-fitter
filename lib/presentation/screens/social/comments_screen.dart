// // lib/presentation/widgets/social/comments_screen.dart
// import 'package:flutter/material.dart';
// import '../../../domain/entities/social/shared_workout.dart';
// import '../../../domain/entities/social/comment.dart';
//
// class CommentsScreen extends StatefulWidget {
//   final SharedWorkout workout;
//
//   const CommentsScreen({
//     Key? key,
//     required this.workout,
//   }) : super(key: key);
//
//   @override
//   _CommentsScreenState createState() => _CommentsScreenState();
// }
//
// class _CommentsScreenState extends State<CommentsScreen> {
//   final TextEditingController _commentController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Comments'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: widget.workout.comments.length,
//               itemBuilder: (context, index) {
//                 final comment = widget.workout.comments[index];
//                 return _buildCommentTile(comment);
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _commentController,
//                     decoration: InputDecoration(
//                       hintText: 'Add a comment',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8.0),
//                 ElevatedButton(
//                   onPressed: _submitComment,
//                   child: Text('Post'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCommentTile(Comment comment) {
//     return ListTile(
//       leading: CircleAvatar(
//         backgroundImage: NetworkImage(comment.userProfileImage),
//       ),
//       title: Text(comment.userName),
//       subtitle: Text(comment.text),
//       trailing: Text(_formatDate(comment.timestamp)),
//     );
//   }
//
//   void _submitComment() {
//     final commentText = _commentController.text.trim();
//     if (commentText.isNotEmpty) {
//       // Implement the logic to add the comment to the workout
//       // and update the UI accordingly
//       _commentController.clear();
//     }
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }