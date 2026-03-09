import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wattalizer/presentation/providers/max_power_override_provider.dart';

import '../fixtures/test_container.dart';

/// Allow unawaited(_load()) to complete.
/// Uses a real-timer delay so SharedPreferences async chains finish regardless
/// of how many microtask cycles they require internally.
Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  group('maxPowerOverrideProvider', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    // Pump before dispose so unawaited(_load()) can finish without throwing
    // "Cannot use Ref after disposed" into subsequent tests.
    tearDown(() async {
      await _pump();
      container.dispose();
    });

    test('initial synchronous state is null', () {
      container = createTestContainer();

      expect(container.read(maxPowerOverrideProvider), isNull);
    });

    test('loads persisted value from SharedPreferences', () async {
      container = createTestContainer();

      // Write a value so SharedPreferences has data to reload.
      await container.read(maxPowerOverrideProvider.notifier).set(750);

      // Invalidate forces a rebuild: build() returns null, then _load() fires.
      container
        ..invalidate(maxPowerOverrideProvider)
        ..read(maxPowerOverrideProvider); // trigger rebuild → starts _load()
      await _pump();

      expect(container.read(maxPowerOverrideProvider), 750);
    });

    test('set(value) updates state and persists to SharedPreferences',
        () async {
      container = createTestContainer();

      await container.read(maxPowerOverrideProvider.notifier).set(600);

      expect(container.read(maxPowerOverrideProvider), 600);
      final prefs = await SharedPreferences.getInstance();
      // Per-athlete key for the default athlete 'me'
      expect(prefs.getDouble('max_power_override_me'), 600);
    });

    test('set(null) clears state and removes from SharedPreferences', () async {
      container = createTestContainer();

      await container.read(maxPowerOverrideProvider.notifier).set(600);
      await container.read(maxPowerOverrideProvider.notifier).set(null);

      expect(container.read(maxPowerOverrideProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('max_power_override_me'), isNull);
    });
  });
}
