import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';

/// Derived provider: extracts completed efforts from [rideSessionProvider].
/// Returns an empty list when idle. keepAlive.
final Provider<List<Effort>> sessionEffortsProvider = Provider<List<Effort>>((
  ref,
) {
  final rideState = ref.watch(rideSessionProvider);
  return switch (rideState) {
    RideStateActive(:final completedEfforts) => completedEfforts,
    _ => const [],
  };
});
