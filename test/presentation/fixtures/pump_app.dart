import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wattalizer/presentation/providers/athlete_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

import 'fake_athlete_repository.dart';
import 'fake_ble_service.dart';
import 'fake_repository.dart';

// wakelock_plus v1.x uses a Pigeon-generated BasicMessageChannel.
// Returning encoded [null] (StandardMessageCodec success envelope) silences it.
const _wakelockChannel = 'dev.flutter.pigeon'
    '.wakelock_plus_platform_interface.WakelockPlusApi.toggle';

/// Call once per widget test file in [setUpAll].
void setUpWidgetTestMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler(_wakelockChannel, (_) async {
    const codec = StandardMessageCodec();
    return codec.encodeMessage(<Object?>[null]);
  });
  SharedPreferences.setMockInitialValues({});
}

/// Builds a [ProviderContainer] with the three standard test overrides.
///
/// Tests that need additional provider overrides should build a
/// [ProviderContainer] directly — Dart infers the element type from the
/// override objects so the unexported `Override` type never needs to be named.
///
/// Example:
/// ```dart
/// final container = ProviderContainer(
///   overrides: [
///     rideRepositoryProvider.overrideWithValue(FakeRepository()),
///     bleServiceProvider.overrideWithValue(FakeBleService()),
///     athleteRepositoryProvider.overrideWithValue(FakeAthleteRepository()),
///     bleConnectionProvider.overrideWith(
///       (ref) => Stream.value(BleConnectionState.connected),
///     ),
///   ],
/// );
/// await pumpApp(tester, const MyScreen(), container: container);
/// ```
ProviderContainer buildTestContainer({
  FakeRepository? repository,
  FakeBleService? bleService,
  FakeAthleteRepository? athleteRepository,
}) {
  return ProviderContainer(
    overrides: [
      rideRepositoryProvider.overrideWithValue(
        repository ?? FakeRepository(),
      ),
      bleServiceProvider.overrideWithValue(bleService ?? FakeBleService()),
      athleteRepositoryProvider.overrideWithValue(
        athleteRepository ?? FakeAthleteRepository(),
      ),
    ],
  );
}

/// Pumps [widget] inside a [MaterialApp] wrapped in an
/// [UncontrolledProviderScope]. Returns the [ProviderContainer] so tests can
/// inspect provider state after interactions.
///
/// Pass [container] to supply a pre-configured container (e.g. with extra
/// provider overrides). When omitted, [buildTestContainer] is called with the
/// optional [repository], [bleService], and [athleteRepository] fakes.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Widget widget, {
  FakeRepository? repository,
  FakeBleService? bleService,
  FakeAthleteRepository? athleteRepository,
  ProviderContainer? container,
  Size surfaceSize = const Size(390, 844),
}) async {
  final c = container ??
      buildTestContainer(
        repository: repository,
        bleService: bleService,
        athleteRepository: athleteRepository,
      );

  await tester.binding.setSurfaceSize(surfaceSize);
  // Pump pending frames before disposing to avoid "dirty widget in wrong
  // build scope" errors from async providers that complete after the test.
  addTearDown(() async {
    await tester.pumpAndSettle();
    c.dispose();
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(useMaterial3: true),
        home: widget,
      ),
    ),
  );

  return c;
}
