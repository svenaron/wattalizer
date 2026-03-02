import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:wattalizer/data/database/database.dart';

class SensorReading {
  const SensorReading({
    required this.timestamp,
    this.power,
    this.leftRightBalance,
    this.leftPower,
    this.rightPower,
    this.heartRate,
    this.cadence,
    this.crankTorque,
    this.accumulatedTorque,
    this.crankRevolutions,
    this.lastCrankEventTime,
    this.maxForceMagnitude,
    this.minForceMagnitude,
    this.maxTorqueMagnitude,
    this.minTorqueMagnitude,
    this.topDeadSpotAngle,
    this.bottomDeadSpotAngle,
    this.accumulatedEnergy,
    this.rrIntervals,
  });

  factory SensorReading.fromRow(ReadingRow row) {
    return SensorReading(
      timestamp: Duration(seconds: row.offsetSeconds),
      power: row.power,
      leftRightBalance: row.leftRightBalance,
      leftPower: row.leftPower,
      rightPower: row.rightPower,
      heartRate: row.heartRate,
      cadence: row.cadence,
      crankTorque: row.crankTorque,
      accumulatedTorque: row.accumulatedTorque,
      crankRevolutions: row.crankRevolutions,
      lastCrankEventTime: row.lastCrankEventTime,
      maxForceMagnitude: row.maxForceMagnitude,
      minForceMagnitude: row.minForceMagnitude,
      maxTorqueMagnitude: row.maxTorqueMagnitude,
      minTorqueMagnitude: row.minTorqueMagnitude,
      topDeadSpotAngle: row.topDeadSpotAngle,
      bottomDeadSpotAngle: row.bottomDeadSpotAngle,
      accumulatedEnergy: row.accumulatedEnergy,
      rrIntervals: row.rrIntervals != null
          ? (jsonDecode(row.rrIntervals!) as List).cast<int>()
          : null,
    );
  }

  ReadingsCompanion toCompanion(String rideId) {
    return ReadingsCompanion.insert(
      rideId: rideId,
      offsetSeconds: timestamp.inSeconds,
      power: Value.absentIfNull(power),
      leftRightBalance: Value.absentIfNull(leftRightBalance),
      leftPower: Value.absentIfNull(leftPower),
      rightPower: Value.absentIfNull(rightPower),
      heartRate: Value.absentIfNull(heartRate),
      cadence: Value.absentIfNull(cadence),
      crankTorque: Value.absentIfNull(crankTorque),
      accumulatedTorque: Value.absentIfNull(accumulatedTorque),
      crankRevolutions: Value.absentIfNull(crankRevolutions),
      lastCrankEventTime: Value.absentIfNull(lastCrankEventTime),
      maxForceMagnitude: Value.absentIfNull(maxForceMagnitude),
      minForceMagnitude: Value.absentIfNull(minForceMagnitude),
      maxTorqueMagnitude: Value.absentIfNull(maxTorqueMagnitude),
      minTorqueMagnitude: Value.absentIfNull(minTorqueMagnitude),
      topDeadSpotAngle: Value.absentIfNull(topDeadSpotAngle),
      bottomDeadSpotAngle: Value.absentIfNull(bottomDeadSpotAngle),
      accumulatedEnergy: Value.absentIfNull(accumulatedEnergy),
      rrIntervals: Value.absentIfNull(
        rrIntervals != null ? jsonEncode(rrIntervals) : null,
      ),
    );
  }

  SensorReading copyWith({
    Duration? timestamp,
    Object? power = _sentinel,
    Object? leftRightBalance = _sentinel,
    Object? leftPower = _sentinel,
    Object? rightPower = _sentinel,
    Object? heartRate = _sentinel,
    Object? cadence = _sentinel,
    Object? crankTorque = _sentinel,
    Object? accumulatedTorque = _sentinel,
    Object? crankRevolutions = _sentinel,
    Object? lastCrankEventTime = _sentinel,
    Object? maxForceMagnitude = _sentinel,
    Object? minForceMagnitude = _sentinel,
    Object? maxTorqueMagnitude = _sentinel,
    Object? minTorqueMagnitude = _sentinel,
    Object? topDeadSpotAngle = _sentinel,
    Object? bottomDeadSpotAngle = _sentinel,
    Object? accumulatedEnergy = _sentinel,
    Object? rrIntervals = _sentinel,
  }) {
    return SensorReading(
      timestamp: timestamp ?? this.timestamp,
      power: power == _sentinel ? this.power : power as double?,
      leftRightBalance: leftRightBalance == _sentinel
          ? this.leftRightBalance
          : leftRightBalance as double?,
      leftPower: leftPower == _sentinel ? this.leftPower : leftPower as double?,
      rightPower:
          rightPower == _sentinel ? this.rightPower : rightPower as double?,
      heartRate: heartRate == _sentinel ? this.heartRate : heartRate as int?,
      cadence: cadence == _sentinel ? this.cadence : cadence as double?,
      crankTorque:
          crankTorque == _sentinel ? this.crankTorque : crankTorque as double?,
      accumulatedTorque: accumulatedTorque == _sentinel
          ? this.accumulatedTorque
          : accumulatedTorque as int?,
      crankRevolutions: crankRevolutions == _sentinel
          ? this.crankRevolutions
          : crankRevolutions as int?,
      lastCrankEventTime: lastCrankEventTime == _sentinel
          ? this.lastCrankEventTime
          : lastCrankEventTime as int?,
      maxForceMagnitude: maxForceMagnitude == _sentinel
          ? this.maxForceMagnitude
          : maxForceMagnitude as int?,
      minForceMagnitude: minForceMagnitude == _sentinel
          ? this.minForceMagnitude
          : minForceMagnitude as int?,
      maxTorqueMagnitude: maxTorqueMagnitude == _sentinel
          ? this.maxTorqueMagnitude
          : maxTorqueMagnitude as int?,
      minTorqueMagnitude: minTorqueMagnitude == _sentinel
          ? this.minTorqueMagnitude
          : minTorqueMagnitude as int?,
      topDeadSpotAngle: topDeadSpotAngle == _sentinel
          ? this.topDeadSpotAngle
          : topDeadSpotAngle as int?,
      bottomDeadSpotAngle: bottomDeadSpotAngle == _sentinel
          ? this.bottomDeadSpotAngle
          : bottomDeadSpotAngle as int?,
      accumulatedEnergy: accumulatedEnergy == _sentinel
          ? this.accumulatedEnergy
          : accumulatedEnergy as int?,
      rrIntervals: rrIntervals == _sentinel
          ? this.rrIntervals
          : rrIntervals as List<int>?,
    );
  }

  final Duration timestamp; // offset from ride start
  final double? power;
  final double? leftRightBalance;
  final double? leftPower;
  final double? rightPower;
  final int? heartRate;
  final double? cadence;
  final double? crankTorque;
  final int? accumulatedTorque;
  final int? crankRevolutions;
  final int? lastCrankEventTime;
  final int? maxForceMagnitude;
  final int? minForceMagnitude;
  final int? maxTorqueMagnitude;
  final int? minTorqueMagnitude;
  final int? topDeadSpotAngle;
  final int? bottomDeadSpotAngle;
  final int? accumulatedEnergy;
  final List<int>? rrIntervals;
}

const _sentinel = Object();
