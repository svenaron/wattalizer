import 'package:wattalizer/domain/interfaces/ble_service.dart';

class PowerParser {
  /// Parse Cycling Power Measurement (0x2A63) characteristic value.
  /// Returns null if data is too short (minimum 4 bytes: 2 flags + 2 power).
  static PowerData? parse(List<int> bytes) {
    if (bytes.length < 4) return null;

    // Flags: 16-bit little-endian at offset 0
    final flags = bytes[0] | (bytes[1] << 8);
    var offset = 2;

    // Instantaneous Power: signed 16-bit LE, always present
    final power = _readS16(bytes, offset);
    offset += 2;

    // Bit 0: Pedal Power Balance present
    double? balance;
    if (flags & 0x0001 != 0) {
      if (offset >= bytes.length) return PowerData(instantaneousPower: power);
      balance = bytes[offset] / 2.0; // 0.5% resolution
      offset += 1;
    }

    // Bit 1: Pedal Power Balance Reference (no data, just a flag)

    // Bit 2: Accumulated Torque present
    int? accTorque;
    if (flags & 0x0004 != 0) {
      if (offset + 1 >= bytes.length) {
        return PowerData(instantaneousPower: power, pedalBalance: balance);
      }
      accTorque = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 3: Accumulated Torque Source (no data, just a flag)

    // Bit 4: Wheel Revolution Data present (u32 revs + u16 event time)
    if (flags & 0x0010 != 0) {
      offset += 6; // skip — not used, but must advance offset
    }

    // Bit 5: Crank Revolution Data present
    int? crankRevs;
    int? crankTime;
    if (flags & 0x0020 != 0) {
      if (offset + 3 >= bytes.length) {
        return PowerData(
          instantaneousPower: power,
          pedalBalance: balance,
          accumulatedTorque: accTorque,
        );
      }
      crankRevs = _readU16(bytes, offset);
      offset += 2;
      crankTime = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 6: Extreme Force Magnitudes present
    int? maxForce;
    int? minForce;
    if (flags & 0x0040 != 0) {
      if (offset + 3 >= bytes.length) {
        return PowerData(
          instantaneousPower: power,
          pedalBalance: balance,
          accumulatedTorque: accTorque,
          crankRevolutions: crankRevs,
          lastCrankEventTime: crankTime,
        );
      }
      maxForce = _readS16(bytes, offset);
      offset += 2;
      minForce = _readS16(bytes, offset);
      offset += 2;
    }

    // Bit 7: Extreme Torque Magnitudes present
    int? maxTorque;
    int? minTorque;
    if (flags & 0x0080 != 0) {
      if (offset + 3 >= bytes.length) {
        return PowerData(
          instantaneousPower: power,
          pedalBalance: balance,
          accumulatedTorque: accTorque,
          crankRevolutions: crankRevs,
          lastCrankEventTime: crankTime,
          maxForceMagnitude: maxForce,
          minForceMagnitude: minForce,
        );
      }
      maxTorque = _readS16(bytes, offset);
      offset += 2;
      minTorque = _readS16(bytes, offset);
      offset += 2;
    }

    // Bit 8: Extreme Angles present (3 bytes packed: 12-bit + 12-bit), skip
    if (flags & 0x0100 != 0) {
      offset += 3;
    }

    // Bit 9: Top Dead Spot Angle present
    int? topAngle;
    if (flags & 0x0200 != 0) {
      if (offset + 1 >= bytes.length) {
        return _buildPartial(
          power,
          balance,
          accTorque,
          crankRevs,
          crankTime,
          maxForce,
          minForce,
          maxTorque,
          minTorque,
        );
      }
      topAngle = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 10: Bottom Dead Spot Angle present
    int? bottomAngle;
    if (flags & 0x0400 != 0) {
      if (offset + 1 >= bytes.length) {
        return _buildPartial(
          power,
          balance,
          accTorque,
          crankRevs,
          crankTime,
          maxForce,
          minForce,
          maxTorque,
          minTorque,
          topAngle: topAngle,
        );
      }
      bottomAngle = _readU16(bytes, offset);
      offset += 2;
    }

    // Bit 11: Accumulated Energy present
    int? energy;
    if (flags & 0x0800 != 0) {
      if (offset + 1 >= bytes.length) {
        return _buildPartial(
          power,
          balance,
          accTorque,
          crankRevs,
          crankTime,
          maxForce,
          minForce,
          maxTorque,
          minTorque,
          topAngle: topAngle,
          bottomAngle: bottomAngle,
        );
      }
      energy = _readU16(bytes, offset);
    }

    return PowerData(
      instantaneousPower: power,
      pedalBalance: balance,
      accumulatedTorque: accTorque,
      crankRevolutions: crankRevs,
      lastCrankEventTime: crankTime,
      maxForceMagnitude: maxForce,
      minForceMagnitude: minForce,
      maxTorqueMagnitude: maxTorque,
      minTorqueMagnitude: minTorque,
      topDeadSpotAngle: topAngle,
      bottomDeadSpotAngle: bottomAngle,
      accumulatedEnergy: energy,
    );
  }

  static int _readU16(List<int> b, int o) => b[o] | (b[o + 1] << 8);

  static int _readS16(List<int> b, int o) {
    final v = b[o] | (b[o + 1] << 8);
    return v >= 0x8000 ? v - 0x10000 : v;
  }

  static PowerData _buildPartial(
    int power,
    double? balance,
    int? accTorque,
    int? crankRevs,
    int? crankTime,
    int? maxForce,
    int? minForce,
    int? maxTorque,
    int? minTorque, {
    int? topAngle,
    int? bottomAngle,
  }) {
    return PowerData(
      instantaneousPower: power,
      pedalBalance: balance,
      accumulatedTorque: accTorque,
      crankRevolutions: crankRevs,
      lastCrankEventTime: crankTime,
      maxForceMagnitude: maxForce,
      minForceMagnitude: minForce,
      maxTorqueMagnitude: maxTorque,
      minTorqueMagnitude: minTorque,
      topDeadSpotAngle: topAngle,
      bottomDeadSpotAngle: bottomAngle,
    );
  }
}
