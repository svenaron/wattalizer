import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';

class SpanSelector extends ConsumerWidget {
  const SpanSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(spanSelectionProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<HistorySpan>(
        segments: const [
          ButtonSegment(value: HistorySpan.week, label: Text('Week')),
          ButtonSegment(value: HistorySpan.month, label: Text('Month')),
          ButtonSegment(value: HistorySpan.year, label: Text('Year')),
          ButtonSegment(value: HistorySpan.allTime, label: Text('All')),
        ],
        selected: {selected},
        onSelectionChanged: (s) =>
            ref.read(spanSelectionProvider.notifier).span = s.first,
      ),
    );
  }
}
