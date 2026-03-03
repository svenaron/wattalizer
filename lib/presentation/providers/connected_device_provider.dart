import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';

/// Tracks the device ID that the app is currently connected/connecting to.
/// null = no device selected. keepAlive — survives navigation.
final connectedDeviceProvider =
    NotifierProvider<ConnectedDeviceNotifier, String?>(
  ConnectedDeviceNotifier.new,
);

class ConnectedDeviceNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Connect to [deviceId] via BLE. Updates state to the device ID.
  Future<void> connect(String deviceId) async {
    state = deviceId;
    final ble = ref.read(bleServiceProvider);
    await ble.connect(deviceId);
  }

  /// Disconnect from the current device and clear state.
  Future<void> disconnect() async {
    final current = state;
    if (current == null) return;
    final ble = ref.read(bleServiceProvider);
    await ble.disconnect(current);
    state = null;
  }
}
