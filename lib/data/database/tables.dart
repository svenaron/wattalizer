import 'package:drift/drift.dart';

@DataClassName('RideRow')
class Rides extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get source => text()(); // 'recorded' or 'imported_tcx'
  TextColumn get autoLapConfigId =>
      text().nullable().references(AutolapConfigs, #id)();
  IntColumn get durationSeconds => integer()();
  IntColumn get activeDurationSeconds => integer()();
  RealColumn get avgPower => real()();
  RealColumn get maxPower => real()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();
  RealColumn get avgCadence => real().nullable()();
  RealColumn get avgLeftRightBalance => real().nullable()();
  IntColumn get readingCount => integer()();
  IntColumn get effortCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RideTagRow')
class RideTags extends Table {
  TextColumn get rideId => text().references(Rides, #id)();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {rideId, tag};
}

@DataClassName('EffortRow')
class Efforts extends Table {
  TextColumn get id => text()();
  TextColumn get rideId => text().references(Rides, #id)();
  IntColumn get effortNumber => integer()();
  IntColumn get startOffset => integer()();
  IntColumn get endOffset => integer()();
  TextColumn get type => text()(); // 'auto' or 'manual'
  IntColumn get durationSeconds => integer()();
  RealColumn get avgPower => real()();
  RealColumn get peakPower => real()();
  IntColumn get avgHeartRate => integer().nullable()();
  IntColumn get maxHeartRate => integer().nullable()();
  RealColumn get avgCadence => real().nullable()();
  RealColumn get avgLeftRightBalance => real().nullable()();
  IntColumn get restSincePrevious => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MapCurveRow')
class MapCurves extends Table {
  TextColumn get effortId => text().references(Efforts, #id)();
  IntColumn get durationSeconds => integer()();
  RealColumn get bestAvgPower => real()();
  BoolColumn get hadNulls => boolean().withDefault(const Constant(false))();
  BoolColumn get wasEnforced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {effortId, durationSeconds};
}

@DataClassName('ReadingRow')
class Readings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rideId => text().references(Rides, #id)();
  IntColumn get offsetSeconds => integer()();
  RealColumn get power => real().nullable()();
  RealColumn get leftRightBalance => real().nullable()();
  RealColumn get leftPower => real().nullable()();
  RealColumn get rightPower => real().nullable()();
  IntColumn get heartRate => integer().nullable()();
  RealColumn get cadence => real().nullable()();
  RealColumn get crankTorque => real().nullable()();
  IntColumn get accumulatedTorque => integer().nullable()();
  IntColumn get crankRevolutions => integer().nullable()();
  IntColumn get lastCrankEventTime => integer().nullable()();
  IntColumn get maxForceMagnitude => integer().nullable()();
  IntColumn get minForceMagnitude => integer().nullable()();
  IntColumn get maxTorqueMagnitude => integer().nullable()();
  IntColumn get minTorqueMagnitude => integer().nullable()();
  IntColumn get topDeadSpotAngle => integer().nullable()();
  IntColumn get bottomDeadSpotAngle => integer().nullable()();
  TextColumn get rrIntervals => text().nullable()(); // JSON: "[710, 690]"
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DataClassName('DeviceRow')
class Devices extends Table {
  TextColumn get deviceId => text()();
  TextColumn get displayName => text()();
  TextColumn get supportedServices => text()(); // JSON: '["power","heartRate"]'
  DateTimeColumn get lastConnected => dateTime()();
  BoolColumn get autoConnect => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

@DataClassName('AutolapConfigRow')
class AutolapConfigs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get startDeltaWatts => real()();
  IntColumn get startConfirmSeconds =>
      integer().withDefault(const Constant(2))();
  IntColumn get startDropoutTolerance =>
      integer().withDefault(const Constant(1))();
  RealColumn get endDeltaWatts => real()();
  IntColumn get endConfirmSeconds => integer().withDefault(const Constant(5))();
  IntColumn get minEffortSeconds => integer().withDefault(const Constant(3))();
  IntColumn get preEffortBaselineWindow =>
      integer().withDefault(const Constant(15))();
  IntColumn get inEffortTrailingWindow =>
      integer().withDefault(const Constant(10))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
