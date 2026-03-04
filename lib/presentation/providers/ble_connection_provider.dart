import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/connected_device_provider.dart';

/// Streams the BLE connection state for the currently selected device.
/// Emits [BleConnectionState.disconnected] when no device is selected.
/// keepAlive — BLE connection persists across all screens.
final bleConnectionProvider = StreamProvider<BleConnectionState>((ref) {
  ref.keepAlive();
  final deviceId = ref.watch(connectedDeviceProvider);
  if (deviceId == null) {
    return Stream.value(BleConnectionState.disconnected);
  }
  return ref.read(bleServiceProvider).connectionState(deviceId);
});
