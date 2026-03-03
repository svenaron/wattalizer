import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';

class ActiveEffortState {
  const ActiveEffortState({
    required this.phase,
    this.liveCurve,
    this.startOffset,
    this.baseline = 0,
  });

  const ActiveEffortState.idle()
      : phase = AutoLapState.idle,
        liveCurve = null,
        startOffset = null,
        baseline = 0;

  final AutoLapState phase;
  final MapCurve? liveCurve;
  final int? startOffset;
  final double baseline;
}

/// Derived provider: extracts active effort state from [rideSessionProvider].
/// Avoids rebuilding all ride-watching widgets when only effort state changes.
/// keepAlive — same lifecycle as [rideSessionProvider].
final Provider<ActiveEffortState> activeEffortProvider =
    Provider<ActiveEffortState>((ref) {
  final rideState = ref.watch(rideSessionProvider);
  return switch (rideState) {
    RideStateActive(
      :final autoLapState,
      :final liveEffortCurve,
      :final activeEffortStartOffset,
      :final currentBaseline,
    ) =>
      ActiveEffortState(
        phase: autoLapState,
        liveCurve: liveEffortCurve,
        startOffset: activeEffortStartOffset,
        baseline: currentBaseline,
      ),
    _ => const ActiveEffortState.idle(),
  };
});
