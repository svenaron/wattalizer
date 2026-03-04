import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/domain/models/ride_state.dart';
import 'package:wattalizer/domain/services/ride_session_manager.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/sensor_stream_provider.dart';

export 'package:wattalizer/domain/models/ride_state.dart';

/// The main orchestration provider. keepAlive — survives navigation.
final NotifierProvider<RideSessionNotifier, RideState> rideSessionProvider =
    NotifierProvider<RideSessionNotifier, RideState>(RideSessionNotifier.new);

class RideSessionNotifier extends Notifier<RideState> {
  RideSessionManager? _manager; // null when idle

  @override
  RideState build() => RideStateIdle();

  Future<void> startRide() async {
    final repo = ref.read(rideRepositoryProvider);
    final config = await ref.read(autoLapConfigProvider.future);

    _manager = RideSessionManager(
      repository: repo,
      config: config,
      onStateChanged: (s) => state = s,
    );
    _manager!.start(ref.read(sensorStreamProvider));
  }

  void manualLap() => _manager?.manualLap();

  Future<void> endRide() async {
    try {
      final ride = await _manager?.end();
      _manager = null;
      state = RideStateIdle(lastRide: ride)
        ..toString(); // silence unused warning
      ref
        ..invalidate(historicalRangeProvider)
        ..invalidate(maxPowerProvider)
        ..invalidate(rideListProvider);
    } on AppError catch (e) {
      _manager = null;
      state = RideStateError(message: 'Failed to save ride: $e');
    }
  }
}
