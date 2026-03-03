import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/history_span.dart';

/// Single source of truth for the selected history span.
/// keepAlive — historicalRangeProvider and rideListProvider watch this.
// (brackets omitted: importing those providers here would be circular)
final spanSelectionProvider =
    NotifierProvider<SpanSelectionNotifier, HistorySpan>(
  SpanSelectionNotifier.new,
);

class SpanSelectionNotifier extends Notifier<HistorySpan> {
  @override
  HistorySpan build() => HistorySpan.allTime;

  HistorySpan get span => state;
  set span(HistorySpan value) => state = value;
}
