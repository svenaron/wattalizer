import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

// Type is inferred by Riverpod's autoDispose.family chain.
// ignore: specify_nonobvious_property_types
final effortReadingsProvider = FutureProvider.autoDispose.family<
    List<SensorReading>,
    ({String rideId, int startOffset, int endOffset})>((ref, p) async {
  final repo = ref.read(rideRepositoryProvider);
  return repo.getReadings(
    p.rideId,
    startOffset: p.startOffset,
    endOffset: p.endOffset,
  );
});
