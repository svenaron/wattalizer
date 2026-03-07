import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';

import '../fixtures/test_container.dart';

void main() {
  group('spanSelectionProvider', () {
    test('default state is HistorySpan.allTime', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      expect(container.read(spanSelectionProvider), HistorySpan.allTime);
    });

    test('setter changes state', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier).span = HistorySpan.week;

      expect(container.read(spanSelectionProvider), HistorySpan.week);
    });

    test('accepts each enum value', () {
      for (final span in HistorySpan.values) {
        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(spanSelectionProvider.notifier).span = span;

        expect(container.read(spanSelectionProvider), span);
      }
    });
  });
}
