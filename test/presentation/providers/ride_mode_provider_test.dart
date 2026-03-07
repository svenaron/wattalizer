import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/presentation/providers/ride_mode_provider.dart';

import '../fixtures/test_container.dart';

void main() {
  group('rideModeProvider', () {
    test('default state is RideMode.focus', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      expect(container.read(rideModeProvider), RideMode.focus);
    });

    test('toggle() switches focus → chart', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(rideModeProvider.notifier).toggle();

      expect(container.read(rideModeProvider), RideMode.chart);
    });

    test('toggle() switches chart → focus', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(rideModeProvider.notifier)
        ..toggle()
        ..toggle();

      expect(container.read(rideModeProvider), RideMode.focus);
    });

    test('setChart() sets chart mode', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(rideModeProvider.notifier).setChart();

      expect(container.read(rideModeProvider), RideMode.chart);
    });

    test('setFocus() sets focus mode', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(rideModeProvider.notifier)
        ..setChart()
        ..setFocus();

      expect(container.read(rideModeProvider), RideMode.focus);
    });
  });
}
