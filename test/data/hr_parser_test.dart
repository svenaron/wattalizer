import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/data/ble/hr_parser.dart';

void main() {
  group('HrParser', () {
    test('8-bit HR, no RR', () {
      // Flags: 0x00 (8-bit HR, no extras)
      // HR: 165
      final data = HrParser.parse([0x00, 0xA5]);
      expect(data!.heartRate, 165);
      expect(data.rrIntervals, isNull);
    });

    test('16-bit HR with RR intervals', () {
      // Flags: 0x11 (16-bit HR + RR present)
      // HR: 172 (0x00AC)
      // RR: 727 in 1/1024s → (727 * 1000 / 1024).round() = 710ms
      // RR: 707 in 1/1024s → (707 * 1000 / 1024).round() = 690ms
      final data = HrParser.parse([0x11, 0xAC, 0x00, 0xD7, 0x02, 0xC3, 0x02]);
      expect(data!.heartRate, 172);
      expect(data.rrIntervals, hasLength(2));
      expect(data.rrIntervals![0], closeTo(710, 2));
      expect(data.rrIntervals![1], closeTo(690, 2));
    });

    test('too short (< 2 bytes) returns null', () {
      expect(HrParser.parse([]), isNull);
      expect(HrParser.parse([0x00]), isNull);
    });
  });
}
