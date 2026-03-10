import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/athlete_profile.dart';
import 'package:wattalizer/presentation/providers/athlete_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/screens/athlete_list_screen.dart';

import '../fixtures/fake_athlete_repository.dart';
import '../fixtures/fake_ble_service.dart';
import '../fixtures/fake_repository.dart';
import '../fixtures/pump_app.dart';

class _ActiveNotifier extends RideSessionNotifier {
  @override
  RideState build() => RideStateActive(
        rideId: 'r1',
        startTime: DateTime(2025, 3, 10),
        readings: const [],
        completedEfforts: const [],
        autoLapState: AutoLapState.idle,
        currentBaseline: 0,
      );
}

void main() {
  setUpAll(setUpWidgetTestMocks);

  group('AthleteListScreen', () {
    testWidgets('lists athletes with active marker', (tester) async {
      final athleteRepo = FakeAthleteRepository()
        ..athletes = [
          AthleteProfile(id: 'me', name: 'Me', createdAt: DateTime(2024)),
          AthleteProfile(id: 'a2', name: 'Alice', createdAt: DateTime(2024)),
        ];
      await pumpApp(
        tester,
        const AthleteListScreen(),
        athleteRepository: athleteRepo,
      );
      await tester.pump();

      expect(find.text('Me'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      // Exactly one active-marker check icon (for 'me').
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('create athlete dialog saves new athlete', (tester) async {
      final athleteRepo = FakeAthleteRepository();
      await pumpApp(
        tester,
        const AthleteListScreen(),
        athleteRepository: athleteRepo,
      );
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('New Athlete'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(athleteRepo.athletes.any((a) => a.name == 'Bob'), isTrue);
    });

    testWidgets('delete blocked during active ride shows SnackBar',
        (tester) async {
      final athleteRepo = FakeAthleteRepository()
        ..athletes = [
          AthleteProfile(id: 'me', name: 'Me', createdAt: DateTime(2024)),
        ];
      final container = ProviderContainer(
        overrides: [
          rideRepositoryProvider.overrideWithValue(FakeRepository()),
          bleServiceProvider.overrideWithValue(FakeBleService()),
          athleteRepositoryProvider.overrideWithValue(athleteRepo),
          rideSessionProvider.overrideWith(_ActiveNotifier.new),
        ],
      );
      await pumpApp(
        tester,
        const AthleteListScreen(),
        container: container,
      );
      await tester.pump();

      await tester.fling(
        find.byKey(const ValueKey('me')),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Cannot delete athlete during a ride'),
        findsOneWidget,
      );
      expect(athleteRepo.athletes.length, 1);
    });
  });
}
