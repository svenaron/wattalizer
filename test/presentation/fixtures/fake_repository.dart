import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/device_info.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

class GetRidesCall {
  GetRidesCall({this.from, this.to, this.tags});
  final DateTime? from;
  final DateTime? to;
  final Set<String>? tags;
}

class GetAllEffortCurvesCall {
  GetAllEffortCurvesCall({this.from, this.to, this.tags});
  final DateTime? from;
  final DateTime? to;
  final Set<String>? tags;
}

class FakeRepository implements RideRepository {
  // Configurable return values
  List<RideSummaryRow> ridesToReturn = [];
  List<MapCurveWithProvenance> effortCurvesToReturn = [];
  List<String> tagsToReturn = [];
  List<DeviceInfo> devicesToReturn = [];
  Map<String, Ride> ridesById = {};
  Map<String, MapCurve> ridePdcs = {};
  AutoLapConfig defaultConfigToReturn = const AutoLapConfig(
    id: 'default',
    name: 'Default',
    startDeltaWatts: 200,
    endDeltaWatts: 100,
  );

  // Call tracking
  List<GetRidesCall> getRidesCalls = [];
  List<GetAllEffortCurvesCall> getAllEffortCurvesCalls = [];
  List<Ride> savedRides = [];
  Map<String, List<SensorReading>> insertedReadingsByRide = {};
  Map<String, List<Effort>> savedEffortsByRide = {};
  Map<String, MapCurve> savedCurves = {};
  int transactionCount = 0;

  @override
  Future<int> getRideCount() async => savedRides.length;

  @override
  Future<void> transaction(Future<void> Function() work) async {
    transactionCount++;
    await work();
  }

  @override
  Future<void> saveRide(Ride ride) async => savedRides.add(ride);

  @override
  Future<void> updateRide(Ride ride) async {}

  @override
  Future<Ride?> getRide(String id) async => ridesById[id];

  @override
  Future<List<RideSummaryRow>> getRides({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
    int? limit,
    int offset = 0,
  }) async {
    getRidesCalls.add(GetRidesCall(from: from, to: to, tags: tags));
    return ridesToReturn;
  }

  @override
  Future<void> deleteRide(String id) async {}

  @override
  Future<List<SensorReading>> getReadings(
    String rideId, {
    int? startOffset,
    int? endOffset,
  }) async =>
      [];

  @override
  Future<void> insertReadings(
    String rideId,
    List<SensorReading> readings,
  ) async {
    insertedReadingsByRide[rideId] = readings;
  }

  @override
  Future<List<Effort>> getEfforts(String rideId) async => [];

  @override
  Future<void> saveEfforts(String rideId, List<Effort> efforts) async {
    savedEffortsByRide[rideId] = efforts;
  }

  @override
  Future<void> deleteEfforts(String rideId) async {}

  @override
  Future<void> saveMapCurve(String entityId, MapCurve curve) async {
    savedCurves[entityId] = curve;
  }

  @override
  Future<MapCurve?> getMapCurve(String entityId) async => savedCurves[entityId];

  @override
  Future<List<MapCurve>> getMapCurvesForRide(String rideId) async => [];

  @override
  Future<List<MapCurveWithProvenance>> getAllEffortCurves({
    DateTime? from,
    DateTime? to,
    Set<String>? tags,
  }) async {
    getAllEffortCurvesCalls
        .add(GetAllEffortCurvesCall(from: from, to: to, tags: tags));
    return effortCurvesToReturn;
  }

  @override
  Future<List<String>> getAllTags() async => tagsToReturn;

  @override
  Future<void> saveRidePdc(String rideId, MapCurve curve) async {
    ridePdcs[rideId] = curve;
  }

  @override
  Future<MapCurve?> getRidePdc(String rideId) async => ridePdcs[rideId];

  @override
  Future<List<AutoLapConfig>> getAutoLapConfigs() async => [];

  @override
  Future<AutoLapConfig> getDefaultConfig() async => defaultConfigToReturn;

  @override
  Future<void> saveAutoLapConfig(AutoLapConfig config) async {}

  @override
  Future<List<DeviceInfo>> getRememberedDevices() async => devicesToReturn;

  @override
  Future<void> saveDevice(DeviceInfo device) async {}

  @override
  Future<void> deleteDevice(String deviceId) async {}

  @override
  Future<List<DeviceInfo>> getAutoConnectDevices() async => [];
}
