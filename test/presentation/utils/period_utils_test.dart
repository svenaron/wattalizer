import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/presentation/utils/period_utils.dart';

void main() {
  // Wednesday, 5 March 2025, 14:00
  final wednesday = DateTime(2025, 3, 5, 14);
  // Monday, 3 March 2025
  final thisMondayMidnight = DateTime(2025, 3, 3);

  group('computePeriod – allTime', () {
    test('returns null bounds and All label', () {
      final p = computePeriod(HistorySpan.allTime, 0, wednesday);
      expect(p.from, isNull);
      expect(p.to, isNull);
      expect(p.label, 'All');
    });

    test('offset ignored for allTime', () {
      final p = computePeriod(HistorySpan.allTime, -5, wednesday);
      expect(p.from, isNull);
      expect(p.to, isNull);
    });
  });

  group('computePeriod – week', () {
    test('offset 0: from is Monday of current week, to is now', () {
      final p = computePeriod(HistorySpan.week, 0, wednesday);
      expect(p.from, thisMondayMidnight);
      expect(p.to, wednesday);
    });

    test('offset 0: label shows full week range', () {
      final p = computePeriod(HistorySpan.week, 0, wednesday);
      expect(p.label, '3–9 Mar');
    });

    test('offset -1: previous week Mon–Sun', () {
      final p = computePeriod(HistorySpan.week, -1, wednesday);
      expect(p.from, DateTime(2025, 2, 24));
      expect(p.to, DateTime(2025, 3, 3));
      expect(p.label, '24 Feb–2 Mar');
    });

    test('offset -2: two weeks ago', () {
      final p = computePeriod(HistorySpan.week, -2, wednesday);
      expect(p.from, DateTime(2025, 2, 17));
      expect(p.to, DateTime(2025, 2, 24));
      expect(p.label, '17–23 Feb');
    });

    test('week spanning months uses abbreviated month names for both', () {
      final p = computePeriod(HistorySpan.week, -1, wednesday);
      expect(p.label, contains('Feb'));
      expect(p.label, contains('Mar'));
    });
  });

  group('computePeriod – month', () {
    test('offset 0: from is 1st of month, to is now', () {
      final p = computePeriod(HistorySpan.month, 0, wednesday);
      expect(p.from, DateTime(2025, 3));
      expect(p.to, wednesday);
      expect(p.label, 'March 2025');
    });

    test('offset -1: previous full month', () {
      final p = computePeriod(HistorySpan.month, -1, wednesday);
      expect(p.from, DateTime(2025, 2));
      expect(p.to, DateTime(2025, 3));
      expect(p.label, 'February 2025');
    });

    test('offset -13: crosses year boundary', () {
      final p = computePeriod(HistorySpan.month, -13, wednesday);
      expect(p.from, DateTime(2024, 2));
      expect(p.to, DateTime(2024, 3));
      expect(p.label, 'February 2024');
    });
  });

  group('computePeriod – year', () {
    test('offset 0: from Jan 1, to now', () {
      final p = computePeriod(HistorySpan.year, 0, wednesday);
      expect(p.from, DateTime(2025));
      expect(p.to, wednesday);
      expect(p.label, '2025');
    });

    test('offset -1: previous full year', () {
      final p = computePeriod(HistorySpan.year, -1, wednesday);
      expect(p.from, DateTime(2024));
      expect(p.to, DateTime(2025));
      expect(p.label, '2024');
    });
  });
}
