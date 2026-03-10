import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/screens/redetect_preview_sheet.dart';

import '../fixtures/fake_repository.dart';

Ride _testRide() => Ride(
      id: 'r1',
      startTime: DateTime.utc(2024),
      source: RideSource.recorded,
      summary: const RideSummary(
        durationSeconds: 100,
        activeDurationSeconds: 50,
        avgPower: 0,
        maxPower: 0,
        readingCount: 0,
        effortCount: 0,
      ),
    );

void main() {
  late FakeRepository repo;

  setUp(() {
    repo = FakeRepository()
      ..autoLapConfigsToReturn = [
        const AutoLapConfig(
          id: 1,
          name: 'Standing Start',
          startDeltaWatts: 350,
          endDeltaWatts: 250,
          isDefault: true,
        ),
        const AutoLapConfig(
          id: 2,
          name: 'Flying Start',
          startDeltaWatts: 150,
          endDeltaWatts: 150,
        ),
      ];
  });

  Widget buildSheet() => ProviderScope(
        overrides: [rideRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: RedetectPreviewSheet(ride: _testRide(), readings: const []),
          ),
        ),
      );

  group('RedetectPreviewSheet', () {
    testWidgets('does not show Make Default button', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('Make Default'), findsNothing);
    });

    testWidgets('shows Apply and Cancel buttons', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('Apply'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('shows a chip for each available config', (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('Standing Start'), findsOneWidget);
      expect(find.text('Flying Start'), findsOneWidget);
    });

    testWidgets('selecting a chip populates the parameter fields',
        (tester) async {
      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flying Start'));
      await tester.pump();

      expect(find.widgetWithText(TextField, '150.0'), findsWidgets);
    });
  });
}
