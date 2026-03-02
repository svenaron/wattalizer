import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/ble/power_parser.dart';

void main() {
  group('PowerParser', () {
    test('minimal: power only, no optional fields', () {
      // Flags: 0x0000 (no optional fields)
      // Power: 350W (0x015E little-endian)
      final bytes = [0x00, 0x00, 0x5E, 0x01];
      final data = PowerParser.parse(bytes);

      expect(data, isNotNull);
      expect(data!.instantaneousPower, 350);
      expect(data.pedalBalance, isNull);
      expect(data.crankRevolutions, isNull);
    });

    test('power + pedal balance', () {
      // Flags: 0x0001 (bit 0 set = balance present)
      // Power: 420W (0x01A4)
      // Balance: 104 → 52.0% left
      final bytes = [0x01, 0x00, 0xA4, 0x01, 0x68];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 420);
      expect(data.pedalBalance, 52.0);
    });

    test('power + balance + crank revolution data', () {
      // Flags: 0x0021 (bit 0 + bit 5)
      // Power: 800W (0x0320)
      // Balance: 98 → 49.0%
      // Crank revolutions: 1234 (0x04D2)
      // Last crank event: 5678 (0x162E)
      final bytes = [
        0x21, 0x00, // flags
        0x20, 0x03, // power 800
        0x62, // balance 49.0%
        0xD2, 0x04, // crank revs 1234
        0x2E, 0x16, // crank event time 5678
      ];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 800);
      expect(data.pedalBalance, 49.0);
      expect(data.crankRevolutions, 1234);
      expect(data.lastCrankEventTime, 5678);
    });

    test('negative power (braking/error)', () {
      // Flags: 0x0000
      // Power: -10 (0xFFF6 as unsigned = 65526, signed = -10)
      final bytes = [0x00, 0x00, 0xF6, 0xFF];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, -10);
    });

    test('zero power (coasting)', () {
      final bytes = [0x00, 0x00, 0x00, 0x00];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 0);
    });

    test('too short (< 4 bytes) returns null', () {
      expect(PowerParser.parse([0x00, 0x00, 0x5E]), isNull);
      expect(PowerParser.parse([]), isNull);
    });

    test('all optional fields present', () {
      // Flags: 0x0FE5 = bits 0,2,5,6,7,8,9,10,11
      final bytes = [
        0xE5, 0x0F, // flags
        0xE8, 0x03, // power: 1000W
        0x64, // balance: 50.0%
        0x10, 0x27, // acc torque: 10000
        0xD2, 0x04, // crank revs: 1234
        0x00, 0x04, // crank time: 1024
        0xF4, 0x01, // max force: 500N
        0x96, 0x00, // min force: 150N
        0xC8, 0x00, // max torque: 200
        0x64, 0x00, // min torque: 100
        0x00, 0x5A, 0xB4, // extreme angles (3 bytes packed, skipped)
        0x0A, 0x00, // top dead spot: 10°
        0xB4, 0x00, // bottom dead spot: 180°
        0x05, 0x00, // acc energy: 5 kJ
      ];
      final data = PowerParser.parse(bytes);

      expect(data!.instantaneousPower, 1000);
      expect(data.pedalBalance, 50.0);
      expect(data.accumulatedTorque, 10000);
      expect(data.crankRevolutions, 1234);
      expect(data.lastCrankEventTime, 1024);
      expect(data.maxForceMagnitude, 500);
      expect(data.minForceMagnitude, 150);
      expect(data.maxTorqueMagnitude, 200);
      expect(data.minTorqueMagnitude, 100);
      expect(data.topDeadSpotAngle, 10);
      expect(data.bottomDeadSpotAngle, 180);
      expect(data.accumulatedEnergy, 5);
    });
  });
}
