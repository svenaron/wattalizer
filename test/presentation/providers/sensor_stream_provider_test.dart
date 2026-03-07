import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/presentation/providers/connected_device_provider.dart';
import 'package:wattalizer/presentation/providers/sensor_stream_provider.dart';

import '../fixtures/fake_ble_service.dart';
import '../fixtures/test_container.dart';

void main() {
  group('sensorStreamProvider', () {
    test('no device → returns empty stream', () async {
      final container = createTestContainer();
      addTearDown(container.dispose);

      final stream = container.read(sensorStreamProvider);

      // Empty stream emits no events and closes immediately
      expect(await stream.isEmpty, isTrue);
    });

    test('device connected → returns sensor stream for that device', () async {
      final ble = FakeBleService();
      final container = createTestContainer(bleService: ble);
      addTearDown(container.dispose);

      await container
          .read(connectedDeviceProvider.notifier)
          .connect('device-1');
      final stream = container.read(sensorStreamProvider);

      // Emit a sensor reading via the fake
      final received = <RawSensorData>[];
      final sub = stream.listen(received.add);

      final reading = RawSensorData(receivedAt: DateTime(2025));
      ble.sensorController('device-1').add(reading);

      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      expect(received.first, same(reading));

      await sub.cancel();
    });
  });
}
