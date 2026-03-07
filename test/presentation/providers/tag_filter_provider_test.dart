import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';

import '../fixtures/test_container.dart';

void main() {
  group('tagFilterProvider', () {
    test('default state is empty set', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      expect(container.read(tagFilterProvider), isEmpty);
    });

    test('addTag() adds a tag', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(tagFilterProvider.notifier).addTag('track');

      expect(container.read(tagFilterProvider), {'track'});
    });

    test('addTag() is idempotent for duplicates', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(tagFilterProvider.notifier)
        ..addTag('track')
        ..addTag('track');

      expect(container.read(tagFilterProvider), {'track'});
    });

    test('removeTag() removes the tag', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(tagFilterProvider.notifier)
        ..addTag('track')
        ..addTag('sprint')
        ..removeTag('track');

      expect(container.read(tagFilterProvider), {'sprint'});
    });

    test('clear() empties the set', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      container.read(tagFilterProvider.notifier)
        ..addTag('track')
        ..addTag('sprint')
        ..clear();

      expect(container.read(tagFilterProvider), isEmpty);
    });
  });
}
