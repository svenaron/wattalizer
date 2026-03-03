import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/data/ble/ble_service_impl.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';

/// Singleton BLE service. keepAlive — BLE subscriptions persist app-wide.
final bleServiceProvider = Provider<BleService>((ref) {
  return BleServiceImpl();
});
