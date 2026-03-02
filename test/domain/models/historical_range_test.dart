import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/history_span.dart';

void main() {
  group('HistorySpan', () {
    test('has all four values', () {
      expect(
        HistorySpan.values,
        containsAll([
          HistorySpan.week,
          HistorySpan.month,
          HistorySpan.year,
          HistorySpan.allTime,
        ]),
      );
    });
  });

  group('DurationRecord', () {
    test('constructs and exposes all fields', () {
      final date = DateTime(2026, 2);
      final r = DurationRecord(
        durationSeconds: 5,
        power: 850,
        effortId: 'e1',
        rideId: 'r1',
        rideDate: date,
        effortNumber: 2,
      );
      expect(r.durationSeconds, 5);
      expect(r.power, 850.0);
      expect(r.effortId, 'e1');
      expect(r.rideId, 'r1');
      expect(r.rideDate, date);
      expect(r.effortNumber, 2);
    });
  });

  group('HistoricalRange', () {
    late HistoricalRange range;

    setUp(() {
      final record = DurationRecord(
        durationSeconds: 1,
        power: 900,
        effortId: 'e1',
        rideId: 'r1',
        rideDate: DateTime(2026, 3),
        effortNumber: 1,
      );
      range = HistoricalRange(
        span: HistorySpan.allTime,
        best: List.generate(
          90,
          (i) => DurationRecord(
            durationSeconds: i + 1,
            power: (900 - i * 5).toDouble(),
            effortId: 'e1',
            rideId: 'r1',
            rideDate: DateTime(2026, 3),
            effortNumber: 1,
          ),
        ),
        worst: List.filled(90, record),
        effortCount: 10,
      );
    });

    test('best has 90 entries', () {
      expect(range.best, hasLength(90));
    });

    test('worst has 90 entries', () {
      expect(range.worst, hasLength(90));
    });

    test('span is preserved', () {
      expect(range.span, HistorySpan.allTime);
    });

    test('effortCount is preserved', () {
      expect(range.effortCount, 10);
    });

    test('best[0] is 1-second best', () {
      expect(range.best[0].durationSeconds, 1);
    });
  });
}
