// lib/domain/usecases/tracking_usecases.dart
import 'package:latlong2/latlong.dart';

import '../repository/tracking/tracking_repository.dart';

class SaveTrackingUseCase {
  final ITrackingRepository _repository;

  SaveTrackingUseCase(this._repository);

  Future<void> call({
    required String userId,
    required DateTime timestamp,
    required List<LatLng> route,
    double? totalDistance,
    int? duration,
    int? paceSeconds,
  }) async {
    await _repository.saveTrackingData(
      userId: userId,
      timestamp: timestamp,
      route: route,
      totalDistance: totalDistance,
      duration: duration,
      paceSeconds: paceSeconds,
    );
  }
}