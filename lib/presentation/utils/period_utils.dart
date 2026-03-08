import 'package:wattalizer/domain/models/history_span.dart';

typedef PeriodBounds = ({DateTime? from, DateTime? to, String label});

/// Converts a [HistorySpan] + [offset] into a date range and display label.
///
/// [offset] of 0 means "current period" (always ends at [now]).
/// Negative offsets step backwards: -1 = previous period, -2 = two periods ago.
/// Forward navigation is clamped at 0 (can't go into the future).
PeriodBounds computePeriod(
  HistorySpan span,
  int offset,
  DateTime now,
) {
  switch (span) {
    case HistorySpan.allTime:
      return (from: null, to: null, label: 'All');
    case HistorySpan.week:
      final monday = _isoWeekMonday(now);
      final targetMonday = DateTime(
        monday.year,
        monday.month,
        monday.day + 7 * offset,
      );
      final label = _weekLabel(targetMonday);
      if (offset == 0) {
        return (from: targetMonday, to: now, label: label);
      }
      final endExclusive = DateTime(
        targetMonday.year,
        targetMonday.month,
        targetMonday.day + 7,
      );
      return (from: targetMonday, to: endExclusive, label: label);
    case HistorySpan.month:
      final targetMonth = DateTime(now.year, now.month + offset);
      final from = DateTime(targetMonth.year, targetMonth.month);
      final label = _monthLabel(targetMonth);
      if (offset == 0) {
        return (from: from, to: now, label: label);
      }
      final endExclusive = DateTime(targetMonth.year, targetMonth.month + 1);
      return (from: from, to: endExclusive, label: label);
    case HistorySpan.year:
      final year = now.year + offset;
      final from = DateTime(year);
      if (offset == 0) {
        return (from: from, to: now, label: '$year');
      }
      return (from: from, to: DateTime(year + 1), label: '$year');
  }
}

DateTime _isoWeekMonday(DateTime date) {
  final d = date.subtract(Duration(days: date.weekday - 1));
  return DateTime(d.year, d.month, d.day);
}

String _weekLabel(DateTime monday) {
  final sunday = monday.add(const Duration(days: 6));
  const m = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (monday.month == sunday.month) {
    return '${monday.day}–${sunday.day} ${m[monday.month]}';
  }
  return '${monday.day} ${m[monday.month]}–${sunday.day} ${m[sunday.month]}';
}

String _monthLabel(DateTime date) {
  const months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month]} ${date.year}';
}
