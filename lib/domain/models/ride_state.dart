import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';

sealed class RideState {}

class RideStateIdle extends RideState {
  RideStateIdle({this.lastRide});
  final Ride? lastRide;
}

class RideStateActive extends RideState {
  // non-null during inEffort/pendingEnd

  RideStateActive({
    required this.rideId,
    required this.startTime,
    required this.readings,
    required this.completedEfforts,
    required this.autoLapState,
    required this.currentBaseline,
    this.liveEffortCurve,
    this.activeEffortStartOffset,
  });
  final String rideId;
  final DateTime startTime;
  final List<SensorReading> readings;
  final List<Effort> completedEfforts;
  final AutoLapState autoLapState;
  final double currentBaseline;
  final MapCurve? liveEffortCurve;
  final int? activeEffortStartOffset;
}

class RideStateError extends RideState {
  RideStateError({required this.message});
  final String message;
}
