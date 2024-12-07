// // lib/presentation/widgets/social/workout_map.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
//
// class WorkoutMap extends StatelessWidget {
//   final List<LatLng> route;
//
//   const WorkoutMap({
//     Key? key,
//     required this.route,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 200,
//       child: FlutterMap(
//         options: MapOptions(
//           bounds: LatLngBounds.fromPoints(route),
//           boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(50)),
//         ),
//         children: [
//           TileLayer(
//             urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//             subdomains: ['a', 'b', 'c'],
//           ),
//           PolylineLayer(
//             polylines: [
//               Polyline(
//                 points: route,
//                 color: Colors.blue,
//                 strokeWidth: 4,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }