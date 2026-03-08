import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

void main() {
  group('autoLapConfigProvider', () {
    test('returns default config from repository', () async {
      final repo = FakeRepository();
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final config = await container.read(autoLapConfigProvider.future);

      expect(config.id, 1);
      expect(config.name, 'Default');
      expect(config.startDeltaWatts, 200);
    });

    test('returns custom config when repository is overridden', () async {
      final repo = FakeRepository()
        ..defaultConfigToReturn = const AutoLapConfig(
          id: 2,
          name: 'Flying Start',
          startDeltaWatts: 150,
          endDeltaWatts: 150,
        );
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final config = await container.read(autoLapConfigProvider.future);

      expect(config.id, 2);
      expect(config.startDeltaWatts, 150);
    });
  });
}
