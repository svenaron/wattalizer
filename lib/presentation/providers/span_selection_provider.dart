import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/history_span.dart';

typedef PeriodSelection = ({HistorySpan span, int offset});

/// Single source of truth for the selected history span and period offset.
/// keepAlive — historicalRangeProvider and rideListProvider watch this.
// (brackets omitted: importing those providers here would be circular)
final spanSelectionProvider =
    NotifierProvider<SpanSelectionNotifier, PeriodSelection>(
  SpanSelectionNotifier.new,
);

class SpanSelectionNotifier extends Notifier<PeriodSelection> {
  @override
  PeriodSelection build() => (span: HistorySpan.allTime, offset: 0);

  /// Switches to [span] and resets offset to current period.
  void setSpan(HistorySpan span) => state = (span: span, offset: 0);

  /// Steps back one period.
  void stepBack() => state = (span: state.span, offset: state.offset - 1);

  /// Steps forward one period. No-op when already at current period.
  void stepForward() {
    if (state.offset < 0) {
      state = (span: state.span, offset: state.offset + 1);
    }
  }
}
