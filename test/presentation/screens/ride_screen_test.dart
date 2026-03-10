import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/presentation/providers/athlete_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ble_connection_provider.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/screens/ride_screen.dart';

import '../fixtures/fake_athlete_repository.dart';
import '../fixtures/fake_ble_service.dart';
import '../fixtures/fake_repository.dart';
import '../fixtures/pump_app.dart';

class _ErrorNotifier extends RideSessionNotifier {
  @override
  RideState build() => RideStateError(message: 'sensor crashed');
}

void main() {
  setUpAll(setUpWidgetTestMocks);

  group('RideScreen', () {
    testWidgets('idle + disconnected shows connect prompt', (tester) async {
      await pumpApp(tester, const RideScreen());
      await tester.pump(); // let StreamProvider emit first value

      expect(
        find.text('Connect a sensor to start'),
        findsOneWidget,
      );
    });

    testWidgets('idle + connected shows Start Ride button', (tester) async {
      final container = ProviderContainer(
        overrides: [
          rideRepositoryProvider.overrideWithValue(FakeRepository()),
          bleServiceProvider.overrideWithValue(FakeBleService()),
          athleteRepositoryProvider.overrideWithValue(
            FakeAthleteRepository(),
          ),
          bleConnectionProvider.overrideWith(
            (ref) => Stream.value(BleConnectionState.connected),
          ),
        ],
      );
      await pumpApp(tester, const RideScreen(), container: container);
      await tester.pump();

      expect(find.text('Start Ride'), findsOneWidget);
    });

    testWidgets('error state shows error message', (tester) async {
      final container = ProviderContainer(
        overrides: [
          rideRepositoryProvider.overrideWithValue(FakeRepository()),
          bleServiceProvider.overrideWithValue(FakeBleService()),
          athleteRepositoryProvider.overrideWithValue(
            FakeAthleteRepository(),
          ),
          rideSessionProvider.overrideWith(_ErrorNotifier.new),
        ],
      );
      await pumpApp(tester, const RideScreen(), container: container);
      await tester.pump();

      expect(find.text('sensor crashed'), findsOneWidget);
    });
  });
}
