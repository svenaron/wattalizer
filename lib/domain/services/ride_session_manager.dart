import 'dart:async';
import 'dart:io' show Platform;

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/ride_state.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/autolap_detector.dart';
import 'package:wattalizer/domain/services/effort_manager.dart';
import 'package:wattalizer/domain/services/map_curve_calculator.dart';
import 'package:wattalizer/domain/services/summary_calculator.dart';

class RideSessionManager {
  RideSessionManager({
    required RideRepository repository,
    required AutoLapConfig config,
    required void Function(RideState) onStateChanged,
    @visibleForTesting Future<void> Function()? enableWakelock,
    @visibleForTesting Future<void> Function()? disableWakelock,
  })  : _repository = repository,
        _config = config,
        _onStateChanged = onStateChanged,
        _enableWakelock = enableWakelock ??
            (Platform.isLinux ? () async {} : WakelockPlus.enable),
        _disableWakelock = disableWakelock ??
            (Platform.isLinux ? () async {} : WakelockPlus.disable);
  final RideRepository _repository;
  final AutoLapConfig _config;
  final void Function(RideState) _onStateChanged;

  // --- Ride state ---
  late String _rideId;
  late DateTime _startTime;
  final List<SensorReading> _readings = [];
  final List<Effort> _efforts = [];

  // --- Components ---
  late AutoLapDetector _detector;
  final EffortManager _effortManager = EffortManager();
  MapCurveCalculator? _liveEffortCalc; // non-null only during an active effort
  MapCurve? _latestLiveCurve;

  // --- 1Hz bin accumulator ---
  final List<RawSensorData> _currentBin = [];
  Timer? _tickTimer;
  int _currentOffsetSeconds = 0;

  // --- BLE ---
  StreamSubscription<RawSensorData>? _bleSub;

  // Wakelock callbacks — overridable for testing
  final Future<void> Function() _enableWakelock;
  final Future<void> Function() _disableWakelock;

  void start(Stream<RawSensorData> sensorStream) {
    _rideId = const Uuid().v4();
    _startTime = DateTime.now();
    _detector = AutoLapDetector(_config);

    // Subscribe to raw BLE data — accumulates into current 1s bin
    _bleSub = sensorStream.listen(_currentBin.add);

    // 1Hz tick — processes the bin every second
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processTick();
    });

    unawaited(_enableWakelock());
    _emitState();
  }

  @visibleForTesting
  void processTick() => _processTick();

  @visibleForTesting
  List<RawSensorData> get currentBin => _currentBin;

  void _processTick() {
    final reading = _mergeBin(_currentBin, _currentOffsetSeconds);
    _currentBin.clear();
    _readings.add(reading);
    _currentOffsetSeconds++;

    // Feed detector
    final event = _detector.processReading(reading);
    final calcBeforeEvent = _liveEffortCalc;
    _handleEvent(event);

    // Feed live effort calculator if active (IG17.1 optimization).
    // Skip if _handleEvent just started a new effort — backfill
    // already included this reading, feeding again double-counts.
    if (_liveEffortCalc != null && _liveEffortCalc == calcBeforeEvent) {
      _latestLiveCurve = _liveEffortCalc!.updateLive(reading, 'live');
    }

    _emitState();
  }

  /// Merge raw BLE notifications from one 1-second bin into a SensorReading.
  SensorReading _mergeBin(List<RawSensorData> bin, int offsetSeconds) {
    if (bin.isEmpty) {
      return SensorReading(
        timestamp: Duration(seconds: offsetSeconds),
        // all fields null — dropout
      );
    }

    // Power: average all non-null values
    final powers = bin
        .where((d) => d.power != null)
        .map((d) => d.power!.instantaneousPower.toDouble())
        .toList();
    final avgPower =
        powers.isEmpty ? null : powers.reduce((a, b) => a + b) / powers.length;

    // HR, cadence, and all other fields: last non-null value in bin
    HeartRateData? lastHr;
    CadenceData? lastCad;
    PowerData? lastPower;
    for (final d in bin) {
      if (d.hr != null) lastHr = d.hr;
      if (d.cadence != null) lastCad = d.cadence;
      if (d.power != null) lastPower = d.power;
    }

    return SensorReading(
      timestamp: Duration(seconds: offsetSeconds),
      power: avgPower,
      heartRate: lastHr?.heartRate,
      cadence: lastCad?.rpm,
      leftRightBalance: lastPower?.pedalBalance,
      crankTorque: lastPower != null && lastPower.accumulatedTorque != null
          ? lastPower.accumulatedTorque! / 32.0
          : null,
      accumulatedTorque: lastPower?.accumulatedTorque,
      crankRevolutions: lastPower?.crankRevolutions,
      lastCrankEventTime: lastPower?.lastCrankEventTime,
      maxForceMagnitude: lastPower?.maxForceMagnitude,
      minForceMagnitude: lastPower?.minForceMagnitude,
      maxTorqueMagnitude: lastPower?.maxTorqueMagnitude,
      minTorqueMagnitude: lastPower?.minTorqueMagnitude,
      topDeadSpotAngle: lastPower?.topDeadSpotAngle,
      bottomDeadSpotAngle: lastPower?.bottomDeadSpotAngle,
      accumulatedEnergy: lastPower?.accumulatedEnergy,
      rrIntervals: lastHr?.rrIntervals,
    );
  }

  void _handleEvent(AutoLapEvent? event) {
    if (event == null) return;

    if (event is EffortStartedEvent) {
      _liveEffortCalc = MapCurveCalculator();
      // Backfill: feed readings from startOffset to now into live calc
      for (final r in _readings) {
        if (r.timestamp.inSeconds >= event.startOffset) {
          _latestLiveCurve = _liveEffortCalc!.updateLive(r, 'live');
        }
      }
    } else if (event is EffortEndedEvent) {
      _liveEffortCalc = null; // dispose — batch replaces it
      _latestLiveCurve = null;

      if (event.wasTooShort) return;

      final effort = _effortManager.createEffort(
        rideId: _rideId,
        effortNumber: _efforts.length + 1,
        startOffset: event.startOffset,
        endOffset: event.endOffset,
        type: event.isManual ? EffortType.manual : EffortType.auto,
        rideReadings: _readings,
        previousEffort: _efforts.isNotEmpty ? _efforts.last : null,
      );
      _efforts.add(effort);
    }
  }

  void manualLap() {
    _detector.manualLap(_currentOffsetSeconds).forEach(_handleEvent);
    _emitState();
  }

  Future<Ride> end() async {
    _tickTimer?.cancel();
    await _bleSub?.cancel();

    // Finalize any in-progress effort
    final finalEvent = _detector.endRide(_currentOffsetSeconds);
    _handleEvent(finalEvent);

    final endTime = DateTime.now();
    final summary = SummaryCalculator.computeRideSummary(_readings, _efforts);

    final ride = Ride(
      id: _rideId,
      startTime: _startTime,
      endTime: endTime,
      source: RideSource.recorded,
      autoLapConfigId: _config.id,
      efforts: _efforts,
      summary: summary,
    );

    // Single transaction persist
    await _repository.transaction(() async {
      await _repository.saveRide(ride);
      await _repository.insertReadings(_rideId, _readings);
      // saveEfforts inserts effort rows + their map_curves in one go
      await _repository.saveEfforts(_rideId, _efforts);
    });

    await _disableWakelock();
    return ride;
  }

  void _emitState() {
    _onStateChanged(
      RideStateActive(
        rideId: _rideId,
        startTime: _startTime,
        readings: List.unmodifiable(_readings),
        completedEfforts: List.unmodifiable(_efforts),
        autoLapState: _detector.currentState,
        currentBaseline: _detector.currentBaseline,
        liveEffortCurve: _latestLiveCurve,
        activeEffortStartOffset:
            _detector.currentState == AutoLapState.inEffort ||
                    _detector.currentState == AutoLapState.pendingEnd
                ? _detector.tentativeStartOffset
                : null,
      ),
    );
  }
}
