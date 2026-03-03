import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/connected_device_provider.dart';

/// Provides the merged [RawSensorData] stream for the connected device.
/// Returns an empty stream when no device is connected.
/// keepAlive — the stream must not drop during navigation.
///
/// Note: this returns the [Stream] object itself (not a StreamProvider value).
/// [RideSessionManager.start()] subscribes to it directly.
final sensorStreamProvider = Provider<Stream<RawSensorData>>((ref) {
  final deviceId = ref.watch(connectedDeviceProvider);
  if (deviceId == null) return const Stream.empty();
  return ref.read(bleServiceProvider).sensorStream(deviceId);
});
