import 'package:wattalizer/domain/models/device_info.dart';

// --- BLE parsed data types ---

class PowerData {
  // kJ

  const PowerData({
    required this.instantaneousPower,
    this.pedalBalance,
    this.accumulatedTorque,
    this.crankRevolutions,
    this.lastCrankEventTime,
    this.maxForceMagnitude,
    this.minForceMagnitude,
    this.maxTorqueMagnitude,
    this.minTorqueMagnitude,
    this.topDeadSpotAngle,
    this.bottomDeadSpotAngle,
    this.accumulatedEnergy,
  });
  final int instantaneousPower; // Watts, signed 16-bit
  final double? pedalBalance; // left leg %, 0-100
  final int? accumulatedTorque; // raw value (1/32 Nm resolution)
  final int? crankRevolutions; // cumulative
  final int? lastCrankEventTime; // 1/1024 seconds
  final int? maxForceMagnitude; // Newtons
  final int? minForceMagnitude;
  final int? maxTorqueMagnitude; // Nm × 32
  final int? minTorqueMagnitude;
  final int? topDeadSpotAngle; // degrees
  final int? bottomDeadSpotAngle;
  final int? accumulatedEnergy;
}

class HeartRateData {
  // milliseconds

  const HeartRateData({required this.heartRate, this.rrIntervals});
  final int heartRate; // BPM
  final List<int>? rrIntervals;
}

class CadenceData {
  const CadenceData({required this.rpm});
  final double rpm;
}

class RawSensorData {
  // from 0x2A5B

  const RawSensorData({
    required this.receivedAt,
    this.power,
    this.hr,
    this.cadence,
  });
  final DateTime receivedAt;
  final PowerData? power; // from 0x2A63
  final HeartRateData? hr; // from 0x2A37
  final CadenceData? cadence;
}

// --- BLE service supporting types ---

enum BleConnectionState { disconnected, connecting, connected, reconnecting }

class DiscoveredDevice {
  const DiscoveredDevice({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.advertisedServices,
  });
  final String deviceId;
  final String name;
  final int rssi; // signal strength in dBm
  final Set<SensorType> advertisedServices;
}

// --- Abstract BLE service interface ---

abstract class BleService {
  /// Scan for nearby BLE devices advertising supported services.
  /// Emits discovered devices continuously until stopScan() is called.
  Stream<List<DiscoveredDevice>> scanForDevices();
  void stopScan();

  /// Connect to a specific device. Throws BleConnectionException on failure.
  Future<void> connect(String deviceId);
  Future<void> disconnect(String deviceId);

  /// Connection state stream for a specific device.
  Stream<BleConnectionState> connectionState(String deviceId);

  /// Merged sensor data stream. Emits RawSensorData combining all
  /// subscribed characteristics. Only emits while connected.
  Stream<RawSensorData> sensorStream(String deviceId);
}
