import 'package:wattalizer/domain/interfaces/ble_service.dart';

class CscParser {
  int? _prevRevs;
  int? _prevTime;

  /// Parse CSC Measurement (0x2A5B). Returns null on first call
  /// or when delta cannot be computed.
  CadenceData? parse(List<int> bytes) {
    if (bytes.isEmpty) return null;

    final flags = bytes[0];
    var offset = 1;

    // Bit 0: Wheel Revolution Data present (skip)
    if (flags & 0x01 != 0) {
      offset += 6; // u32 wheel revs + u16 wheel event time
    }

    // Bit 1: Crank Revolution Data present
    if (flags & 0x02 == 0) return null; // no crank data
    if (offset + 3 >= bytes.length) return null;

    final revs = bytes[offset] | (bytes[offset + 1] << 8);
    offset += 2;
    final time = bytes[offset] | (bytes[offset + 1] << 8);

    if (_prevRevs == null || _prevTime == null) {
      _prevRevs = revs;
      _prevTime = time;
      return null; // first reading, no delta
    }

    // Handle 16-bit rollover
    final deltaRevs = (revs - _prevRevs!) & 0xFFFF;
    final deltaTime = (time - _prevTime!) & 0xFFFF;

    _prevRevs = revs;
    _prevTime = time;

    if (deltaTime == 0) return null; // avoid div by zero

    // deltaTime is in 1/1024 seconds
    final rpm = (deltaRevs / (deltaTime / 1024.0)) * 60.0;

    // Sanity check: cadence > 250 RPM is likely a glitch
    if (rpm > 250) return null;

    return CadenceData(rpm: rpm);
  }

  /// Call on reconnection to avoid bogus delta from stale previous values.
  void reset() {
    _prevRevs = null;
    _prevTime = null;
  }
}
