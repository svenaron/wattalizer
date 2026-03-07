import 'dart:async';

import 'package:wattalizer/domain/interfaces/ble_service.dart';

class FakeBleService implements BleService {
  final scanController = StreamController<List<DiscoveredDevice>>.broadcast();
  final Map<String, StreamController<BleConnectionState>>
      connectionStateControllers = {};
  final Map<String, StreamController<RawSensorData>> sensorControllers = {};

  final List<String> connectCalls = [];
  final List<String> disconnectCalls = [];

  StreamController<BleConnectionState> connectionController(String deviceId) {
    return connectionStateControllers.putIfAbsent(
      deviceId,
      StreamController<BleConnectionState>.broadcast,
    );
  }

  StreamController<RawSensorData> sensorController(String deviceId) {
    return sensorControllers.putIfAbsent(
      deviceId,
      StreamController<RawSensorData>.broadcast,
    );
  }

  @override
  Stream<List<DiscoveredDevice>> scanForDevices() => scanController.stream;

  @override
  void stopScan() {}

  @override
  Future<void> connect(String deviceId) async {
    connectCalls.add(deviceId);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    disconnectCalls.add(deviceId);
  }

  @override
  Stream<BleConnectionState> connectionState(String deviceId) {
    return connectionController(deviceId).stream;
  }

  @override
  Stream<RawSensorData> sensorStream(String deviceId) {
    return sensorController(deviceId).stream;
  }
}
