import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/presentation/providers/connected_device_provider.dart';

import '../fixtures/fake_ble_service.dart';
import '../fixtures/test_container.dart';

void main() {
  group('connectedDeviceProvider', () {
    test('default state is null', () {
      final container = createTestContainer();
      addTearDown(container.dispose);

      expect(container.read(connectedDeviceProvider), isNull);
    });

    test('connect() updates state to deviceId and calls BLE service', () async {
      final ble = FakeBleService();
      final container = createTestContainer(bleService: ble);
      addTearDown(container.dispose);

      await container
          .read(connectedDeviceProvider.notifier)
          .connect('device-1');

      expect(container.read(connectedDeviceProvider), 'device-1');
      expect(ble.connectCalls, ['device-1']);
    });

    test('disconnect() clears state and calls BLE service', () async {
      final ble = FakeBleService();
      final container = createTestContainer(bleService: ble);
      addTearDown(container.dispose);

      await container
          .read(connectedDeviceProvider.notifier)
          .connect('device-1');
      await container.read(connectedDeviceProvider.notifier).disconnect();

      expect(container.read(connectedDeviceProvider), isNull);
      expect(ble.disconnectCalls, ['device-1']);
    });

    test('disconnect() is a no-op when no device connected', () async {
      final ble = FakeBleService();
      final container = createTestContainer(bleService: ble);
      addTearDown(container.dispose);

      await container.read(connectedDeviceProvider.notifier).disconnect();

      expect(container.read(connectedDeviceProvider), isNull);
      expect(ble.disconnectCalls, isEmpty);
    });
  });
}
