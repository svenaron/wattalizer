import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/presentation/screens/history_screen.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/pump_app.dart';

void main() {
  setUpAll(setUpWidgetTestMocks);

  group('HistoryScreen', () {
    testWidgets('empty list shows No rides found', (tester) async {
      final repo = FakeRepository()..ridesToReturn = [];
      await pumpApp(tester, const HistoryScreen(), repository: repo);
      await tester.pump();

      expect(find.text('No rides found'), findsOneWidget);
    });

    testWidgets('non-empty list renders ride card with date', (tester) async {
      final repo = FakeRepository()
        ..ridesToReturn = [
          RideSummaryRow(
            id: 'r1',
            startTime: DateTime(2025, 3, 10, 14),
            tags: const [],
            summary: const RideSummary(
              durationSeconds: 3600,
              activeDurationSeconds: 1800,
              avgPower: 250,
              maxPower: 500,
              readingCount: 3600,
              effortCount: 3,
            ),
          ),
        ];
      await pumpApp(tester, const HistoryScreen(), repository: repo);
      await tester.pump();

      expect(find.text('10/3/2025 14:00'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('swipe to delete shows dialog then removes card',
        (tester) async {
      const rideId = 'r1';
      final repo = FakeRepository()
        ..ridesToReturn = [
          RideSummaryRow(
            id: rideId,
            startTime: DateTime(2025, 3, 10, 14),
            tags: const [],
            summary: const RideSummary(
              durationSeconds: 3600,
              activeDurationSeconds: 1800,
              avgPower: 250,
              maxPower: 500,
              readingCount: 3600,
              effortCount: 3,
            ),
          ),
        ];
      await pumpApp(tester, const HistoryScreen(), repository: repo);
      await tester.pump();

      await tester.fling(
        find.byKey(const ValueKey(rideId)),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete ride?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(repo.deleteRideCalls, contains(rideId));
      expect(find.byKey(const ValueKey(rideId)), findsNothing);
    });
  });
}
