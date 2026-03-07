import 'dart:async';
import 'dart:math' as math;

import 'package:universal_ble/universal_ble.dart';
import 'package:wattalizer/core/constants.dart';
import 'package:wattalizer/data/ble/csc_parser.dart';
import 'package:wattalizer/data/ble/hr_parser.dart';
import 'package:wattalizer/data/ble/power_parser.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart' as domain;
import 'package:wattalizer/domain/models/device_info.dart';

class BleServiceImpl implements domain.BleService {
  // --- Known BLE UUIDs (128-bit lowercase, as universal_ble normalises) ---
  static const _powerServiceUuid = '00001818-0000-1000-8000-00805f9b34fb';
  static const _hrServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
  static const _cscServiceUuid = '00001816-0000-1000-8000-00805f9b34fb';
  static const _powerMeasurementUuid = '00002a63-0000-1000-8000-00805f9b34fb';
  static const _hrMeasurementUuid = '00002a37-0000-1000-8000-00805f9b34fb';
  static const _cscMeasurementUuid = '00002a5b-0000-1000-8000-00805f9b34fb';

  // --- Per-device state ---
  final Map<String, StreamSubscription<bool>> _connectionSubs = {};
  final Map<String, StreamController<domain.BleConnectionState>>
      _stateControllers = {};
  final Map<String, StreamController<domain.RawSensorData>> _sensorControllers =
      {};
  final Map<String, List<StreamSubscription<List<int>>>> _charSubs = {};
  final Map<String, CscParser> _cscParsers = {};
  final Map<String, Timer?> _reconnectTimers = {};
  final Map<String, int> _reconnectAttempts = {};

  @override
  Stream<List<domain.DiscoveredDevice>> scanForDevices() {
    unawaited(
      UniversalBle.startScan(
        scanFilter: ScanFilter(
          withServices: [_powerServiceUuid, _hrServiceUuid, _cscServiceUuid],
        ),
      ).catchError((_) {
        // BLE not available (e.g. iOS simulator) — silently ignore.
      }),
    );
    // universal_ble emits one device at a time. The provider layer
    // accumulates into a list with dedup by deviceId.
    return UniversalBle.scanStream.map((device) => [_mapScanResult(device)]);
  }

  domain.DiscoveredDevice _mapScanResult(BleDevice device) {
    return domain.DiscoveredDevice(
      deviceId: device.deviceId,
      name: device.name?.isNotEmpty == true ? device.name! : 'Unknown',
      rssi: device.rssi ?? 0,
      advertisedServices: _parseServices(device.services),
    );
  }

  @override
  void stopScan() {
    unawaited(UniversalBle.stopScan());
  }

  @override
  Future<void> connect(String deviceId) async {
    _stateControllers[deviceId] ??= StreamController.broadcast();
    _sensorControllers[deviceId] ??= StreamController.broadcast();
    _cscParsers[deviceId] ??= CscParser();
    _reconnectAttempts[deviceId] = 0;

    _stateControllers[deviceId]!.add(domain.BleConnectionState.connecting);

    await _connectionSubs[deviceId]?.cancel();
    _connectionSubs[deviceId] = UniversalBle.connectionStream(deviceId).listen(
      (connected) async {
        if (connected) {
          _reconnectAttempts[deviceId] = 0;
          await _discoverAndSubscribe(deviceId);
          _stateControllers[deviceId]?.add(domain.BleConnectionState.connected);
        } else {
          _handleDisconnect(deviceId);
        }
      },
      onError: (Object e) {
        _handleDisconnect(deviceId);
      },
    );

    await UniversalBle.connect(deviceId, timeout: const Duration(seconds: 10));
  }

  /// After connection established: discover services, subscribe to all
  /// supported characteristics, and merge into a single RawSensorData stream.
  Future<void> _discoverAndSubscribe(String deviceId) async {
    await _cancelCharSubs(deviceId);

    final services = await UniversalBle.discoverServices(deviceId);
    final serviceMap = {for (final s in services) s.uuid: s};

    if (serviceMap.containsKey(_powerServiceUuid)) {
      await _subscribeCharacteristic(
        deviceId,
        _powerServiceUuid,
        _powerMeasurementUuid,
        (bytes) {
          final power = PowerParser.parse(bytes);
          if (power != null) {
            _sensorControllers[deviceId]?.add(
              domain.RawSensorData(receivedAt: DateTime.now(), power: power),
            );
          }
        },
      );
    }

    if (serviceMap.containsKey(_hrServiceUuid)) {
      await _subscribeCharacteristic(
        deviceId,
        _hrServiceUuid,
        _hrMeasurementUuid,
        (bytes) {
          final hr = HrParser.parse(bytes);
          if (hr != null) {
            _sensorControllers[deviceId]?.add(
              domain.RawSensorData(receivedAt: DateTime.now(), hr: hr),
            );
          }
        },
      );
    }

    if (serviceMap.containsKey(_cscServiceUuid)) {
      await _subscribeCharacteristic(
        deviceId,
        _cscServiceUuid,
        _cscMeasurementUuid,
        (bytes) {
          final cad = _cscParsers[deviceId]!.parse(bytes);
          if (cad != null) {
            _sensorControllers[deviceId]?.add(
              domain.RawSensorData(receivedAt: DateTime.now(), cadence: cad),
            );
          }
        },
      );
    }
  }

  Future<void> _subscribeCharacteristic(
    String deviceId,
    String serviceUuid,
    String charUuid,
    void Function(List<int>) onData,
  ) async {
    await UniversalBle.subscribeNotifications(deviceId, serviceUuid, charUuid);
    final sub =
        UniversalBle.characteristicValueStream(deviceId, charUuid).listen(
      onData,
      onError: (Object e) {
        // Characteristic-level error — log but don't disconnect.
        // The connection-level listener handles full disconnects.
      },
    );
    _charSubs.putIfAbsent(deviceId, () => []).add(sub);
  }

  /// Reconnection with exponential backoff: 1s, 2s, 4s, 8s... capped at 30s.
  /// Gives up after 2 minutes total.
  void _handleDisconnect(String deviceId) {
    final attempts = _reconnectAttempts[deviceId] ?? 0;
    final elapsed = _backoffTotal(attempts);

    final timeoutMs =
        const Duration(minutes: kBleReconnectTimeoutMinutes).inMilliseconds;
    if (elapsed > timeoutMs) {
      _stateControllers[deviceId]?.add(domain.BleConnectionState.disconnected);
      unawaited(_stateControllers[deviceId]?.close() ?? Future.value());
      _stateControllers.remove(deviceId);
      unawaited(_sensorControllers[deviceId]?.close() ?? Future.value());
      _sensorControllers.remove(deviceId);
      _cscParsers[deviceId]?.reset();
      _cscParsers.remove(deviceId);
      _reconnectAttempts.remove(deviceId);
      return;
    }

    _stateControllers[deviceId]?.add(domain.BleConnectionState.reconnecting);
    _cscParsers[deviceId]?.reset(); // avoid bogus deltas after reconnect

    final delay = Duration(
      milliseconds:
          math.min(1000 * math.pow(2, attempts).toInt(), kBleBackoffCapMs),
    );
    _reconnectTimers[deviceId]?.cancel();
    _reconnectTimers[deviceId] = Timer(delay, () {
      _reconnectAttempts[deviceId] = attempts + 1;
      unawaited(connect(deviceId));
    });
  }

  int _backoffTotal(int attempts) {
    var total = 0;
    for (var i = 0; i < attempts; i++) {
      total += math.min(1000 * math.pow(2, i).toInt(), kBleBackoffCapMs);
    }
    return total;
  }

  @override
  Stream<domain.BleConnectionState> connectionState(String deviceId) {
    // ??= is intentional: if disconnect() removed the controller, a subsequent
    // connect() call will re-create it properly. Any watch() after disconnect
    // that fires before connect() gets an idle broadcast stream with no events.
    _stateControllers[deviceId] ??= StreamController.broadcast();
    return _stateControllers[deviceId]!.stream;
  }

  @override
  Stream<domain.RawSensorData> sensorStream(String deviceId) {
    // Same intentional ??= pattern as connectionState().
    _sensorControllers[deviceId] ??= StreamController.broadcast();
    return _sensorControllers[deviceId]!.stream;
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _reconnectTimers[deviceId]?.cancel();
    _reconnectTimers.remove(deviceId);
    await _cancelCharSubs(deviceId);
    await _connectionSubs[deviceId]?.cancel();
    _connectionSubs.remove(deviceId);
    await UniversalBle.disconnect(deviceId);
    _stateControllers[deviceId]?.add(domain.BleConnectionState.disconnected);
    await _stateControllers[deviceId]?.close();
    _stateControllers.remove(deviceId);
    await _sensorControllers[deviceId]?.close();
    _sensorControllers.remove(deviceId);
    _cscParsers.remove(deviceId);
    _reconnectAttempts.remove(deviceId);
  }

  Future<void> _cancelCharSubs(String deviceId) async {
    final subs = _charSubs.remove(deviceId);
    if (subs != null) {
      for (final sub in subs) {
        await sub.cancel();
      }
    }
  }

  Set<SensorType> _parseServices(List<String> uuids) {
    final s = <SensorType>{};
    for (final u in uuids) {
      if (u == _powerServiceUuid) s.add(SensorType.power);
      if (u == _hrServiceUuid) s.add(SensorType.heartRate);
      if (u == _cscServiceUuid) s.add(SensorType.cadence);
    }
    return s;
  }
}
