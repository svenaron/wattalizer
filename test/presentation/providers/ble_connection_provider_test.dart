import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/presentation/providers/ble_connection_provider.dart';
import 'package:wattalizer/presentation/providers/connected_device_provider.dart';

import '../fixtures/fake_ble_service.dart';
import '../fixtures/test_container.dart';

void main() {
  group('bleConnectionProvider', () {
    test('no device → emits disconnected', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      // Use listen instead of .future — StreamProvider.future can hang if
      // stream emits synchronously before Riverpod subscribes.
      final received = <BleConnectionState>[];
      final sub = container.listen(
        bleConnectionProvider,
        (_, next) => next.whenData(received.add),
      );

      await Future<void>.delayed(Duration.zero);

      expect(received, contains(BleConnectionState.disconnected));
      sub.close();
    });

    test('device connected → streams connection state from BLE service',
        () async {
      final ble = FakeBleService();
      final container = createTestContainer(bleService: ble);
      addTearDown(container.dispose);

      await container
          .read(connectedDeviceProvider.notifier)
          .connect('device-1');

      final received = <BleConnectionState>[];
      final sub = container.listen(
        bleConnectionProvider,
        (_, next) => next.whenData(received.add),
      );

      ble.connectionController('device-1').add(BleConnectionState.connecting);
      ble.connectionController('device-1').add(BleConnectionState.connected);

      await Future<void>.delayed(Duration.zero);

      expect(received, contains(BleConnectionState.connecting));
      expect(received, contains(BleConnectionState.connected));

      sub.close();
    });
  });
}
