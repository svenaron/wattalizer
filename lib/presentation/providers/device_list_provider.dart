import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// Remembered devices from the database. autoDispose — only alive while the
/// Device sheet is open. Invalidate after saving/deleting a device.
final FutureProvider<List<DeviceInfo>> deviceListProvider =
    FutureProvider.autoDispose<List<DeviceInfo>>((ref) {
  return ref.read(rideRepositoryProvider).getRememberedDevices();
});
