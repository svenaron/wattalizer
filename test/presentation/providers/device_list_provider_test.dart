import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/presentation/providers/device_list_provider.dart';

import '../fixtures/fake_repository.dart';
import '../fixtures/test_container.dart';

void main() {
  group('deviceListProvider', () {
    test('returns empty list when no devices remembered', () async {
      final container = createTestContainer(repository: FakeRepository());
      addTearDown(container.dispose);

      final devices = await container.read(deviceListProvider.future);

      expect(devices, isEmpty);
    });

    test('returns remembered devices from repository', () async {
      final repo = FakeRepository()
        ..devicesToReturn = [
          DeviceInfo(
            deviceId: 'dev1',
            displayName: 'Garmin Vector',
            supportedServices: {SensorType.power},
            lastConnected: DateTime(2025),
          ),
          DeviceInfo(
            deviceId: 'dev2',
            displayName: 'Polar H10',
            supportedServices: {SensorType.heartRate},
            lastConnected: DateTime(2025),
          ),
        ];
      final container = createTestContainer(repository: repo);
      addTearDown(container.dispose);

      final devices = await container.read(deviceListProvider.future);

      expect(devices, hasLength(2));
      expect(devices[0].deviceId, 'dev1');
      expect(devices[1].deviceId, 'dev2');
    });
  });
}
