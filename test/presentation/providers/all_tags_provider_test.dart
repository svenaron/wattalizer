import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/presentation/providers/all_tags_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

void main() {
  group('allTagsProvider', () {
    test('returns empty list when no tags', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      final tags = await container.read(allTagsProvider.future);

      expect(tags, isEmpty);
    });

    test('returns sorted tags from repository', () async {
      final repo = FakeRepository()
        ..tagsToReturn = ['track', 'indoor', 'sprint'];
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final tags = await container.read(allTagsProvider.future);

      expect(tags, ['track', 'indoor', 'sprint']);
    });
  });
}
