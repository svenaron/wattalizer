import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';

void main() {
  group('RideSource', () {
    test('has recorded and importedTcx values', () {
      expect(
        RideSource.values,
        containsAll([RideSource.recorded, RideSource.importedTcx]),
      );
    });
  });

  group('Ride', () {
    final summary = _emptySummary();

    test('constructs with required fields and defaults', () {
      final ride = Ride(
        id: 'r1',
        startTime: DateTime(2026, 3),
        source: RideSource.recorded,
        summary: summary,
      );
      expect(ride.id, 'r1');
      expect(ride.tags, isEmpty);
      expect(ride.efforts, isEmpty);
      expect(ride.notes, isNull);
      expect(ride.endTime, isNull);
      expect(ride.autoLapConfigId, isNull);
    });

    group('copyWith', () {
      late Ride base;

      setUp(() {
        base = Ride(
          id: 'r1',
          startTime: DateTime(2026, 3),
          source: RideSource.recorded,
          tags: const ['track', 'morning'],
          summary: summary,
        );
      });

      test('unchanged when no arguments given', () {
        final copy = base.copyWith();
        expect(copy.id, base.id);
        expect(copy.tags, base.tags);
        expect(copy.source, base.source);
      });

      test('updates tags', () {
        final copy = base.copyWith(tags: ['evening']);
        expect(copy.tags, ['evening']);
        expect(copy.id, base.id);
      });

      test('updates notes', () {
        final copy = base.copyWith(notes: 'great session');
        expect(copy.notes, 'great session');
      });

      test('updates autoLapConfigId', () {
        final copy = base.copyWith(autoLapConfigId: 'cfg1');
        expect(copy.autoLapConfigId, 'cfg1');
      });
    });
  });
}

RideSummary _emptySummary() => const RideSummary(
      durationSeconds: 0,
      activeDurationSeconds: 0,
      avgPower: 0,
      maxPower: 0,
      readingCount: 0,
      effortCount: 0,
    );
