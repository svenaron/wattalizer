import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_summary.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

/// Carries a MapCurve together with its provenance (which effort/ride it came from).
/// Used by HistoricalRangeCalculator and RideRepository.getAllEffortCurves().
class MapCurveWithProvenance {
  const MapCurveWithProvenance({
    required this.effortId,
    required this.rideId,
    required this.rideDate,
    required this.effortNumber,
    required this.curve,
  });
  final String effortId;
  final String rideId;
  final DateTime rideDate;
  final int effortNumber;
  final MapCurve curve;
}

/// Lightweight row used for list display — no readings or efforts loaded.
class RideSummaryRow {
  const RideSummaryRow({
    required this.id,
    required this.startTime,
    required this.tags,
    required this.summary,
  });

  final String id;
  final DateTime startTime;
  final List<String> tags;
  final RideSummary summary;
}

abstract class RideRepository {
  // --- Ride CRUD ---
  Future<void> saveRide(Ride ride);

  /// Updates tags and notes only.
  Future<void> updateRide(Ride ride);

  Future<Ride?> getRide(String id);

  /// Returns lightweight summary rows for list display.
  /// Supports optional date range, tag filter (AND logic), limit, and offset.
  Future<List<RideSummaryRow>> getRides({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
    int? limit,
    int offset = 0,
  });

  /// Cascades delete to efforts, readings, map_curves, ride_tags.
  Future<void> deleteRide(String id);

  // --- Readings ---

  /// Lazy-loaded. Returns readings in [startOffset, endOffset] inclusive.
  Future<List<SensorReading>> getReadings(
    String rideId, {
    int? startOffset,
    int? endOffset,
  });

  /// Batch insert in a single transaction. Used on ride save and TCX import.
  Future<void> insertReadings(String rideId, List<SensorReading> readings);

  // --- Efforts ---
  Future<List<Effort>> getEfforts(String rideId);

  /// Replaces all efforts for the ride.
  Future<void> saveEfforts(String rideId, List<Effort> efforts);

  Future<void> deleteEfforts(String rideId);

  // --- MAP Curves ---
  Future<void> saveMapCurve(String entityId, MapCurve curve);
  Future<MapCurve?> getMapCurve(String entityId);
  Future<List<MapCurve>> getMapCurvesForRide(String rideId);

  /// Returns all effort-level curves within date range and matching tag filter.
  /// Joins through efforts → rides for filtering.
  Future<List<MapCurveWithProvenance>> getAllEffortCurves({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
  });

  // --- Tags ---

  /// Returns all distinct tags across all rides, sorted alphabetically.
  Future<List<String>> getAllTags();

  // --- Ride-level PDC ---

  /// Best power for each duration (1–90s) across ALL readings in the ride.
  Future<void> saveRidePdc(String rideId, MapCurve curve);
  Future<MapCurve?> getRidePdc(String rideId);

  // --- AutoLap Config ---
  Future<List<AutoLapConfig>> getAutoLapConfigs();
  Future<AutoLapConfig> getDefaultConfig();
  Future<void> saveAutoLapConfig(AutoLapConfig config);

  // --- Devices ---
  Future<List<DeviceInfo>> getRememberedDevices();
  Future<void> saveDevice(DeviceInfo device);
  Future<void> deleteDevice(String deviceId);
  Future<List<DeviceInfo>> getAutoConnectDevices();
}
