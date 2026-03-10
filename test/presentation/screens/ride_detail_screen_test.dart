import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/presentation/screens/ride_detail_screen.dart';
import 'package:wattalizer/presentation/widgets/effort_card.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/pump_app.dart';

Ride _makeRide({List<Effort> efforts = const []}) => Ride(
      id: 'r1',
      startTime: DateTime(2025, 3, 10, 14),
      source: RideSource.recorded,
      efforts: efforts,
      summary: RideSummary(
        durationSeconds: 600,
        activeDurationSeconds: 300,
        avgPower: 300,
        maxPower: 500,
        readingCount: 600,
        effortCount: efforts.length,
      ),
    );

Effort _makeEffort(int number) => Effort(
      id: 'e$number',
      rideId: 'r1',
      effortNumber: number,
      startOffset: (number - 1) * 60,
      endOffset: number * 60,
      type: EffortType.auto,
      summary: const EffortSummary(
        durationSeconds: 60,
        avgPower: 350,
        peakPower: 450,
      ),
      mapCurve: MapCurve(
        entityId: 'e$number',
        values: List.filled(90, 350),
        flags: List.generate(90, (_) => const MapCurveFlags()),
        computedAt: DateTime(2025),
      ),
    );

void main() {
  setUpAll(setUpWidgetTestMocks);

  group('RideDetailScreen', () {
    testWidgets('delete ride via popup calls deleteRide', (tester) async {
      final repo = FakeRepository()..ridesById = {'r1': _makeRide()};
      await pumpApp(
        tester,
        const RideDetailScreen(rideId: 'r1'),
        repository: repo,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete ride?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repo.deleteRideCalls, contains('r1'));
    });

    testWidgets('delete effort shows SnackBar and updates repository',
        (tester) async {
      final effort1 = _makeEffort(1);
      final effort2 = _makeEffort(2);
      final repo = FakeRepository()
        ..ridesById = {
          'r1': _makeRide(efforts: [effort1, effort2]),
        };
      await pumpApp(
        tester,
        const RideDetailScreen(rideId: 'r1'),
        repository: repo,
      );
      await tester.pumpAndSettle();

      // Expand effort card 1 to reveal the delete button.
      await tester.tap(find.byType(EffortCard).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Remove Effort 1?'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Effort 1 removed'), findsOneWidget);
      expect(repo.savedEffortsByRide['r1']?.length, 1);
    });

    testWidgets('cancel delete ride does not call deleteRide', (tester) async {
      final repo = FakeRepository()..ridesById = {'r1': _makeRide()};
      await pumpApp(
        tester,
        const RideDetailScreen(rideId: 'r1'),
        repository: repo,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete ride?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.deleteRideCalls, isEmpty);
    });
  });
}
