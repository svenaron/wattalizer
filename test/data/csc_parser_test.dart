import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/ble/csc_parser.dart';

void main() {
  group('CscParser', () {
    test('two readings produce cadence', () {
      final parser = CscParser();

      // First reading: 100 revs at time 10240 (10s in 1/1024)
      // Flags: 0x02 (crank data present, no wheel)
      final first = parser.parse([0x02, 0x64, 0x00, 0x00, 0x28]);
      expect(first, isNull); // first reading → null

      // Second reading: 102 revs at time 12288 (12s in 1/1024)
      // Delta: 2 revs / 2s = 1 rev/s = 60 RPM
      final second = parser.parse([0x02, 0x66, 0x00, 0x00, 0x30]);
      expect(second, isNotNull);
      expect(second!.rpm, closeTo(60.0, 0.1));
    });

    test('16-bit rollover handled', () {
      // First: revs=65534, time=65000
      // Second: revs=1 (rolled over), time=1048 (rolled over)
      // Delta revs: (1 - 65534) & 0xFFFF = 3
      // Delta time: (1048 - 65000) & 0xFFFF = 1584 → 1584/1024 = 1.547s
      // RPM: (3 / 1.547) * 60 ≈ 116.4
      final parser = CscParser()..parse([0x02, 0xFE, 0xFF, 0xE8, 0xFD]);
      final result = parser.parse([0x02, 0x01, 0x00, 0x18, 0x04]);
      expect(result, isNotNull);
      expect(result!.rpm, closeTo(116.4, 0.5));
    });

    test('reset clears state', () {
      final parser = CscParser()
        ..parse([0x02, 0x64, 0x00, 0x00, 0x28])
        ..reset();
      // After reset, next reading is treated as first → null
      final result = parser.parse([0x02, 0x66, 0x00, 0x00, 0x30]);
      expect(result, isNull);
    });
  });
}
