import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';

enum SensorType { power, heartRate, cadence }

class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.displayName,
    required this.supportedServices,
    required this.lastConnected,
    this.autoConnect = true,
  });

  factory DeviceInfo.fromRow(DeviceRow row) {
    final services = (jsonDecode(row.supportedServices) as List)
        .map((s) => SensorType.values.byName(s as String))
        .toSet();
    return DeviceInfo(
      deviceId: row.deviceId,
      displayName: row.displayName,
      supportedServices: services,
      lastConnected: row.lastConnected,
      autoConnect: row.autoConnect,
    );
  }

  DeviceInfo copyWith({String? displayName, bool? autoConnect}) {
    return DeviceInfo(
      deviceId: deviceId,
      displayName: displayName ?? this.displayName,
      supportedServices: supportedServices,
      lastConnected: lastConnected,
      autoConnect: autoConnect ?? this.autoConnect,
    );
  }

  DevicesCompanion toCompanion() {
    return DevicesCompanion.insert(
      deviceId: deviceId,
      displayName: displayName,
      supportedServices: jsonEncode(
        supportedServices.map((s) => s.name).toList(),
      ),
      lastConnected: lastConnected,
      autoConnect: Value(autoConnect),
    );
  }

  final String deviceId;
  final String displayName;
  final Set<SensorType> supportedServices;
  final DateTime lastConnected;
  final bool autoConnect;
}
