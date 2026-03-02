import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/device_info.dart';

void main() {
  group('SensorType', () {
    test('has power, heartRate, and cadence values', () {
      expect(
        SensorType.values,
        containsAll([
          SensorType.power,
          SensorType.heartRate,
          SensorType.cadence,
        ]),
      );
    });
  });

  group('DeviceInfo', () {
    final now = DateTime(2026, 3);

    test('autoConnect defaults to true', () {
      final d = DeviceInfo(
        deviceId: 'dev1',
        displayName: 'Stages LR',
        supportedServices: {SensorType.power},
        lastConnected: now,
      );
      expect(d.autoConnect, isTrue);
    });

    test('can hold multiple sensor types', () {
      final d = DeviceInfo(
        deviceId: 'dev2',
        displayName: 'Wahoo TICKR',
        supportedServices: {SensorType.heartRate, SensorType.cadence},
        lastConnected: now,
      );
      expect(
        d.supportedServices,
        containsAll([SensorType.heartRate, SensorType.cadence]),
      );
    });

    group('copyWith', () {
      late DeviceInfo base;

      setUp(() {
        base = DeviceInfo(
          deviceId: 'dev1',
          displayName: 'Power Meter',
          supportedServices: {SensorType.power},
          lastConnected: now,
        );
      });

      test('updates displayName only', () {
        final copy = base.copyWith(displayName: 'Stages Left');
        expect(copy.displayName, 'Stages Left');
        expect(copy.deviceId, base.deviceId);
        expect(copy.autoConnect, base.autoConnect);
      });

      test('updates autoConnect only', () {
        final copy = base.copyWith(autoConnect: false);
        expect(copy.autoConnect, isFalse);
        expect(copy.displayName, base.displayName);
      });

      test('supportedServices is not changed by copyWith', () {
        final copy = base.copyWith(displayName: 'New Name');
        expect(copy.supportedServices, base.supportedServices);
      });
    });
  });
}
