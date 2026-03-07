import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wattalizer/presentation/providers/theme_mode_provider.dart';

import '../fixtures/test_container.dart';

/// Allow unawaited(_load()) to complete.
Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  group('themeModeProvider', () {
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

    test('initial synchronous state is ThemeMode.system', () {
      container = createTestContainer();

      expect(container.read(themeModeProvider), ThemeMode.system);
    });

    test('loads persisted value from SharedPreferences', () async {
      container = createTestContainer();

      // Write a value so SharedPreferences has data to reload.
      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      // Invalidate forces a rebuild: build() returns system,
      // then _load() fires.
      container
        ..invalidate(themeModeProvider)
        ..read(themeModeProvider); // trigger rebuild → starts _load()
      await _pump();

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('setMode(dark) updates state and persists to SharedPreferences',
        () async {
      container = createTestContainer();

      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'dark');
    });

    test('setMode(light) persists light', () async {
      container = createTestContainer();

      await container.read(themeModeProvider.notifier).setMode(ThemeMode.light);

      expect(container.read(themeModeProvider), ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_mode'), 'light');
    });

    test('setMode(system) persists system', () async {
      container = createTestContainer();

      await container.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
      await container
          .read(themeModeProvider.notifier)
          .setMode(ThemeMode.system);

      expect(container.read(themeModeProvider), ThemeMode.system);
    });
  });
}
