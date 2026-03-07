import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/active_effort_provider.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';

import '../fixtures/fake_ble_service.dart';
import '../fixtures/fake_repository.dart';

// Minimal testable notifier — overrides build() to return a controlled state.
class _SetableRideSession extends RideSessionNotifier {
  @override
  RideState build() => RideStateIdle();

  // Method sets internal Notifier state; setter would conflict
  // with the inherited Notifier.state setter.
  // ignore: use_setters_to_change_properties
  void forceState(RideState s) => state = s;
}

ProviderContainer _makeContainer() {
  return ProviderContainer(
    overrides: [
      rideRepositoryProvider.overrideWithValue(FakeRepository()),
      bleServiceProvider.overrideWithValue(FakeBleService()),
      rideSessionProvider.overrideWith(_SetableRideSession.new),
    ],
  );
}

void main() {
  group('activeEffortProvider', () {
    test('when idle → returns ActiveEffortState.idle()', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final effort = container.read(activeEffortProvider);

      expect(effort.phase, AutoLapState.idle);
      expect(effort.liveCurve, isNull);
      expect(effort.startOffset, isNull);
      expect(effort.baseline, 0.0);
    });

    test('when active with no effort → phase is idle', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      (container.read(rideSessionProvider.notifier) as _SetableRideSession)
          .forceState(
        RideStateActive(
          rideId: 'r1',
          startTime: DateTime(2025),
          readings: const [],
          completedEfforts: const [],
          autoLapState: AutoLapState.idle,
          currentBaseline: 0,
        ),
      );

      final effort = container.read(activeEffortProvider);
      expect(effort.phase, AutoLapState.idle);
      expect(effort.liveCurve, isNull);
    });

    test('when active in effort → extracts curve, startOffset, and baseline',
        () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final curve = MapCurve(
        entityId: 'live',
        values: List.generate(90, (_) => 500.0),
        flags: List.generate(90, (_) => const MapCurveFlags()),
        computedAt: DateTime(2025),
      );

      (container.read(rideSessionProvider.notifier) as _SetableRideSession)
          .forceState(
        RideStateActive(
          rideId: 'r1',
          startTime: DateTime(2025),
          readings: const [],
          completedEfforts: const [],
          autoLapState: AutoLapState.inEffort,
          currentBaseline: 250,
          liveEffortCurve: curve,
          activeEffortStartOffset: 10,
        ),
      );

      final effort = container.read(activeEffortProvider);
      expect(effort.phase, AutoLapState.inEffort);
      expect(effort.liveCurve, same(curve));
      expect(effort.startOffset, 10);
      expect(effort.baseline, 250.0);
    });
  });
}
