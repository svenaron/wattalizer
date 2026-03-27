import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

// wakelock_plus v1.x uses a Pigeon-generated BasicMessageChannel.
// Returning encoded [null] (StandardMessageCodec success envelope) silences it.
const _wakelockChannel = 'dev.flutter.pigeon'
    '.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(_wakelockChannel, (_) async {
      const codec = StandardMessageCodec();
      return codec.encodeMessage(<Object?>[null]);
    });
    // maxPowerOverrideProvider calls SharedPreferences; mock it for all tests.
    SharedPreferences.setMockInitialValues({});
  });

  group('rideSessionProvider', () {
    test('initial state is RideStateIdle with no lastRide', () {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      final state = container.read(rideSessionProvider);

      expect(state, isA<RideStateIdle>());
      expect((state as RideStateIdle).lastRide, isNull);
    });

    test('startRide() transitions to RideStateActive', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      await container.read(rideSessionProvider.notifier).startRide();

      expect(container.read(rideSessionProvider), isA<RideStateActive>());
    });

    test('rapid double startRide() initializes only one session path',
        () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final notifier = container.read(rideSessionProvider.notifier);
      final firstStart = notifier.startRide();
      final secondStart = notifier.startRide();
      await Future.wait([firstStart, secondStart]);

      expect(container.read(rideSessionProvider), isA<RideStateActive>());

      await notifier.endRide();
      expect(repo.transactionCount, 1);
      expect(repo.savedRides.length, 1);
      expect(repo.insertedReadingsByRide.length, 1);
      expect(repo.savedEffortsByRide.length, 1);
    });

    test('endRide() after startRide() returns to RideStateIdle with lastRide',
        () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      await container.read(rideSessionProvider.notifier).startRide();
      await container.read(rideSessionProvider.notifier).endRide();

      final state = container.read(rideSessionProvider);
      expect(state, isA<RideStateIdle>());
      expect((state as RideStateIdle).lastRide, isNotNull);
    });

    test('endRide() when idle (no manager) returns RideStateIdle', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      await container.read(rideSessionProvider.notifier).endRide();

      final state = container.read(rideSessionProvider);
      expect(state, isA<RideStateIdle>());
      expect((state as RideStateIdle).lastRide, isNull);
    });

    test('endRide() invalidates dependent providers', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      await container.read(rideSessionProvider.notifier).startRide();

      final callsBefore = repo.getAllEffortCurvesCalls.length;

      // Prime maxPowerProvider so it can be invalidated
      await container.read(maxPowerProvider.future);
      final callsAfterRead = repo.getAllEffortCurvesCalls.length;
      expect(callsAfterRead, greaterThan(callsBefore));

      await container.read(rideSessionProvider.notifier).endRide();

      // After invalidation, reading maxPowerProvider again should re-query
      await container.read(maxPowerProvider.future);
      expect(
        repo.getAllEffortCurvesCalls.length,
        greaterThan(callsAfterRead),
      );
    });

    test('manualLap() does not throw when idle', () {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      expect(
        () => container.read(rideSessionProvider.notifier).manualLap(),
        returnsNormally,
      );
    });
  });
}
