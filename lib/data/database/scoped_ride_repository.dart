import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

/// Thin wrapper around [LocalRideRepository] that scopes all
/// athlete-sensitive operations to a fixed athlete ID.
/// Non-scoped operations (by global ID) delegate directly.
class ScopedRideRepository implements RideRepository {
  ScopedRideRepository(this._inner, this._athleteId);
  final LocalRideRepository _inner;
  final String _athleteId;

  @override
  Future<void> transaction(Future<void> Function() work) =>
      _inner.transaction(work);

  @override
  Future<int> getRideCount() => _inner.getRideCountForAthlete(_athleteId);

  @override
  Future<void> saveRide(Ride ride) =>
      _inner.saveRideForAthlete(ride, _athleteId);

  @override
  Future<void> updateRide(Ride ride) => _inner.updateRide(ride);

  @override
  Future<Ride?> getRide(String id) => _inner.getRide(id);

  @override
  Future<List<RideSummaryRow>> getRides({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
    int? limit,
    int offset = 0,
  }) =>
      _inner.getRidesForAthlete(
        _athleteId,
        from: from,
        to: to,
        tags: tags,
        limit: limit,
        offset: offset,
      );

  @override
  Future<void> deleteRide(String id) => _inner.deleteRide(id);

  @override
  Future<List<SensorReading>> getReadings(
    String rideId, {
    int? startOffset,
    int? endOffset,
  }) =>
      _inner.getReadings(
        rideId,
        startOffset: startOffset,
        endOffset: endOffset,
      );

  @override
  Future<void> insertReadings(
    String rideId,
    List<SensorReading> readings,
  ) =>
      _inner.insertReadings(rideId, readings);

  @override
  Future<List<Effort>> getEfforts(String rideId) => _inner.getEfforts(rideId);

  @override
  Future<void> saveEfforts(String rideId, List<Effort> efforts) =>
      _inner.saveEfforts(rideId, efforts);

  @override
  Future<void> deleteEfforts(String rideId) => _inner.deleteEfforts(rideId);

  @override
  Future<void> saveMapCurve(String entityId, MapCurve curve) =>
      _inner.saveMapCurve(entityId, curve);

  @override
  Future<MapCurve?> getMapCurve(String entityId) =>
      _inner.getMapCurve(entityId);

  @override
  Future<List<MapCurve>> getMapCurvesForRide(String rideId) =>
      _inner.getMapCurvesForRide(rideId);

  @override
  Future<List<MapCurveWithProvenance>> getAllEffortCurves({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
  }) =>
      _inner.getAllEffortCurvesForAthlete(
        _athleteId,
        from: from,
        to: to,
        tags: tags,
      );

  @override
  Future<List<String>> getAllTags() => _inner.getAllTagsForAthlete(_athleteId);

  @override
  Future<void> saveRidePdc(String rideId, MapCurve curve) =>
      _inner.saveRidePdc(rideId, curve);

  @override
  Future<MapCurve?> getRidePdc(String rideId) => _inner.getRidePdc(rideId);

  @override
  Future<List<AutoLapConfig>> getAutoLapConfigs() =>
      _inner.getAutoLapConfigsForAthlete(_athleteId);

  @override
  Future<AutoLapConfig> getDefaultConfig() =>
      _inner.getDefaultConfigForAthlete(_athleteId);

  @override
  Future<int> saveAutoLapConfig(AutoLapConfig config) =>
      _inner.saveAutoLapConfigForAthlete(config, _athleteId);

  @override
  Future<bool> deleteAutoLapConfig(int id) => _inner.deleteAutoLapConfig(id);

  @override
  Future<List<DeviceInfo>> getRememberedDevices() =>
      _inner.getRememberedDevicesForAthlete(_athleteId);

  @override
  Future<void> saveDevice(DeviceInfo device) =>
      _inner.saveDeviceForAthlete(device, _athleteId);

  @override
  Future<void> deleteDevice(String deviceId) => _inner.deleteDevice(deviceId);

  @override
  Future<List<DeviceInfo>> getAutoConnectDevices() =>
      _inner.getAutoConnectDevicesForAthlete(_athleteId);
}
