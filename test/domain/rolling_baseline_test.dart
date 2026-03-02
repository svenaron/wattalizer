import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/services/rolling_baseline.dart';

void main() {
  group('RollingBaseline', () {
    test('empty buffer returns 0.0 average', () {
      final rb = RollingBaseline(5);
      expect(rb.average, 0.0);
      expect(rb.isEmpty, true);
    });

    test('buffer fills below windowSize: average over all added values', () {
      final rb = RollingBaseline(5)
        ..add(100)
        ..add(200)
        ..add(300);

      expect(rb.average, closeTo(200.0, 0.001));
      expect(rb.isEmpty, false);
      expect(rb.isFull, false);
    });

    test('buffer fills to exactly windowSize: isFull true', () {
      final rb = RollingBaseline(3)
        ..add(10)
        ..add(20)
        ..add(30);

      expect(rb.isFull, true);
      expect(rb.average, closeTo(20.0, 0.001));
    });

    test('buffer overflows: oldest values replaced (circular)', () {
      final rb = RollingBaseline(3)
        ..add(10)
        ..add(20)
        ..add(30)
        // Add a 4th: 10 gets replaced
        ..add(40);

      // Window is now [40, 20, 30] → avg = 30
      expect(rb.average, closeTo(30.0, 0.001));

      // Add a 5th: 20 gets replaced
      rb.add(50);
      // Window is now [40, 50, 30] → avg = 40
      expect(rb.average, closeTo(40.0, 0.001));
    });

    test('null values are ignored (not added)', () {
      final rb = RollingBaseline(3)
        ..add(100)
        ..add(null)
        ..add(200);

      // Only 2 values in buffer
      expect(rb.average, closeTo(150.0, 0.001));
      expect(rb.isFull, false);
    });

    test('freeze stops updates, average stays constant', () {
      final rb = RollingBaseline(3)
        ..add(100)
        ..add(200)
        ..freeze();
      expect(rb.isFrozen, true);

      rb.add(9999); // should be ignored
      expect(rb.average, closeTo(150.0, 0.001));
    });

    test('unfreeze resumes accepting values', () {
      final rb = RollingBaseline(3)
        ..add(100)
        ..freeze()
        ..unfreeze();

      expect(rb.isFrozen, false);
      rb.add(200);
      expect(rb.average, closeTo(150.0, 0.001));
    });

    test('freeze also blocks null values', () {
      final rb = RollingBaseline(3)
        ..add(100)
        ..freeze()
        ..add(null); // ignored even though null-ignoring is separate

      expect(rb.average, closeTo(100.0, 0.001));
    });

    test('clear resets everything including frozen state', () {
      final rb = RollingBaseline(3)
        ..add(500)
        ..add(600)
        ..freeze()
        ..clear();

      expect(rb.isEmpty, true);
      expect(rb.isFrozen, false);
      expect(rb.average, 0.0);
      expect(rb.isFull, false);

      // Should accept new values after clear
      rb.add(100);
      expect(rb.average, closeTo(100.0, 0.001));
    });

    test('single-element window: average equals that element', () {
      final rb = RollingBaseline(1)..add(777);
      expect(rb.average, closeTo(777.0, 0.001));
      expect(rb.isFull, true);

      rb.add(888);
      expect(rb.average, closeTo(888.0, 0.001));
    });
  });
}
