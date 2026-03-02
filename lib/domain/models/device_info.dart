enum SensorType { power, heartRate, cadence }

class DeviceInfo {
  const DeviceInfo({
    required this.deviceId,
    required this.displayName,
    required this.supportedServices,
    required this.lastConnected,
    this.autoConnect = true,
  });

  DeviceInfo copyWith({String? displayName, bool? autoConnect}) {
    return DeviceInfo(
      deviceId: deviceId,
      displayName: displayName ?? this.displayName,
      supportedServices: supportedServices,
      lastConnected: lastConnected,
      autoConnect: autoConnect ?? this.autoConnect,
    );
  }

  final String deviceId;
  final String displayName;
  final Set<SensorType> supportedServices;
  final DateTime lastConnected;
  final bool autoConnect;
}
