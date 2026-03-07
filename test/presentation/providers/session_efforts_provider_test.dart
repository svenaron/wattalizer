import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/providers/session_efforts_provider.dart';

import '../fixtures/fake_ble_service.dart';
import '../fixtures/fake_repository.dart';

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

Effort _makeEffort(String id) => Effort(
      id: id,
      rideId: 'r1',
      effortNumber: 1,
      startOffset: 0,
      endOffset: 10,
      type: EffortType.auto,
      mapCurve: MapCurve(
        entityId: id,
        values: List.generate(90, (_) => 400.0),
        flags: List.generate(90, (_) => const MapCurveFlags()),
        computedAt: DateTime(2025),
      ),
      summary: const EffortSummary(
        durationSeconds: 10,
        avgPower: 400,
        peakPower: 600,
      ),
    );

void main() {
  group('sessionEffortsProvider', () {
    test('when idle → returns empty list', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(sessionEffortsProvider), isEmpty);
    });

    test('when active with no efforts → returns empty list', () {
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

      expect(container.read(sessionEffortsProvider), isEmpty);
    });

    test('when active with efforts → returns completedEfforts', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      final effort = _makeEffort('e1');
      (container.read(rideSessionProvider.notifier) as _SetableRideSession)
          .forceState(
        RideStateActive(
          rideId: 'r1',
          startTime: DateTime(2025),
          readings: const [],
          completedEfforts: [effort],
          autoLapState: AutoLapState.idle,
          currentBaseline: 0,
        ),
      );

      final efforts = container.read(sessionEffortsProvider);
      expect(efforts, hasLength(1));
      expect(efforts.first.id, 'e1');
    });
  });
}
