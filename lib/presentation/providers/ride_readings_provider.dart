import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

// Type is inferred by Riverpod's autoDispose.family chain.
// ignore: specify_nonobvious_property_types
final rideReadingsProvider = FutureProvider.autoDispose
    .family<List<SensorReading>, String>((ref, rideId) async {
  final repo = ref.read(rideRepositoryProvider);
  return repo.getReadings(rideId);
});
