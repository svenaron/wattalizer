import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/history_span.dart';
import 'package:wattalizer/presentation/providers/span_selection_provider.dart';

import '../fixtures/test_container.dart';

void main() {
  group('spanSelectionProvider', () {
    test('default state is allTime with offset 0', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final state = container.read(spanSelectionProvider);
      expect(state.span, HistorySpan.allTime);
      expect(state.offset, 0);
    });

    test('setSpan changes span and resets offset to 0', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier).setSpan(HistorySpan.week);

      final state = container.read(spanSelectionProvider);
      expect(state.span, HistorySpan.week);
      expect(state.offset, 0);
    });

    test('setSpan resets offset when switching spans', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier)
        ..setSpan(HistorySpan.week)
        ..stepBack()
        ..stepBack();
      container.read(spanSelectionProvider.notifier).setSpan(HistorySpan.month);

      final state = container.read(spanSelectionProvider);
      expect(state.span, HistorySpan.month);
      expect(state.offset, 0);
    });

    test('accepts each span value', () {
      for (final span in HistorySpan.values) {
        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(spanSelectionProvider.notifier).setSpan(span);

        expect(container.read(spanSelectionProvider).span, span);
      }
    });

    test('stepBack decrements offset', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier)
        ..setSpan(HistorySpan.week)
        ..stepBack();

      expect(container.read(spanSelectionProvider).offset, -1);
    });

    test('stepBack can go arbitrarily far back', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final notifier = container.read(spanSelectionProvider.notifier)
        ..setSpan(HistorySpan.month);
      for (var i = 0; i < 5; i++) {
        notifier.stepBack();
      }

      expect(container.read(spanSelectionProvider).offset, -5);
    });

    test('stepForward does nothing at offset 0', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier)
        ..setSpan(HistorySpan.week)
        ..stepForward();

      expect(container.read(spanSelectionProvider).offset, 0);
    });

    test('stepForward increments offset when negative', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier)
        ..setSpan(HistorySpan.week)
        ..stepBack()
        ..stepBack()
        ..stepForward();

      expect(container.read(spanSelectionProvider).offset, -1);
    });

    test('stepForward clamps at 0', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(spanSelectionProvider.notifier)
        ..setSpan(HistorySpan.week)
        ..stepBack()
        ..stepForward()
        ..stepForward();

      expect(container.read(spanSelectionProvider).offset, 0);
    });
  });
}
