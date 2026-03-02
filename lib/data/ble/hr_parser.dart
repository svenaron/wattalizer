import 'package:wattalizer/domain/interfaces/ble_service.dart';

class HrParser {
  /// Parse Heart Rate Measurement (0x2A37) characteristic value.
  /// Returns null if data is too short (minimum 2 bytes).
  static HeartRateData? parse(List<int> bytes) {
    if (bytes.length < 2) return null;

    final flags = bytes[0];
    var offset = 1;

    // Bit 0: HR format. 0 = uint8, 1 = uint16
    int hr;
    if (flags & 0x01 != 0) {
      if (offset + 1 >= bytes.length) return null;
      hr = bytes[offset] | (bytes[offset + 1] << 8);
      offset += 2;
    } else {
      hr = bytes[offset];
      offset += 1;
    }

    // Bit 1: Sensor Contact Status (skip)
    // Bit 2: Sensor Contact Supported (skip)

    // Bit 3: Energy Expended present
    if (flags & 0x08 != 0) {
      offset += 2; // skip u16 energy
    }

    // Bit 4: RR-Interval present
    List<int>? rr;
    if (flags & 0x10 != 0) {
      rr = [];
      while (offset + 1 < bytes.length) {
        final raw = bytes[offset] | (bytes[offset + 1] << 8);
        // Convert from 1/1024 seconds to milliseconds
        rr.add((raw * 1000 / 1024).round());
        offset += 2;
      }
    }

    return HeartRateData(heartRate: hr, rrIntervals: rr);
  }
}
