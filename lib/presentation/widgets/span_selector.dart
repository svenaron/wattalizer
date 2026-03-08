import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';
import 'package:wattalizer/presentation/utils/period_utils.dart';

class SpanSelector extends ConsumerWidget {
  const SpanSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(spanSelectionProvider);
    final showNav = selection.span != HistorySpan.allTime;
    final period =
        computePeriod(selection.span, selection.offset, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SegmentedButton<HistorySpan>(
            segments: const [
              ButtonSegment(value: HistorySpan.week, label: Text('Week')),
              ButtonSegment(value: HistorySpan.month, label: Text('Month')),
              ButtonSegment(value: HistorySpan.year, label: Text('Year')),
              ButtonSegment(value: HistorySpan.allTime, label: Text('All')),
            ],
            selected: {selection.span},
            onSelectionChanged: (s) =>
                ref.read(spanSelectionProvider.notifier).setSpan(s.first),
          ),
          if (showNav)
            _PeriodNav(
              label: period.label,
              offset: selection.offset,
              onBack: ref.read(spanSelectionProvider.notifier).stepBack,
              onForward: ref.read(spanSelectionProvider.notifier).stepForward,
            ),
        ],
      ),
    );
  }
}

class _PeriodNav extends StatelessWidget {
  const _PeriodNav({
    required this.label,
    required this.offset,
    required this.onBack,
    required this.onForward,
  });

  final String label;
  final int offset;
  final VoidCallback onBack;
  final VoidCallback onForward;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onBack,
          tooltip: 'Previous period',
        ),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: offset < 0 ? onForward : null,
          tooltip: 'Next period',
        ),
      ],
    );
  }
}
