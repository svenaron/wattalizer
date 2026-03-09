import 'dart:math';

import 'package:wattalizer/core/constants.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/rolling_baseline.dart';

class AutoLapDetector {
  AutoLapDetector(this.config) {
    _preEffortBaseline = RollingBaseline(config.preEffortBaselineWindow);
    _inEffortTrailing = RollingBaseline(config.inEffortTrailingWindow);
  }
  final AutoLapConfig config;
  AutoLapState _state = AutoLapState.idle;

  late RollingBaseline _preEffortBaseline;
  late RollingBaseline _inEffortTrailing;

  int _tentativeStartOffset = 0;
  int _tentativeEndOffset = 0;
  int _confirmCount = 0;
  int _dropoutCount = 0;
  double? _peakWatts;

  AutoLapState get currentState => _state;
  double get currentBaseline => _preEffortBaseline.average;

  /// The offset (seconds) at which the current effort started.
  /// Only meaningful when [currentState] is pendingStart, inEffort,
  /// or pendingEnd.
  int? get tentativeStartOffset => _tentativeStartOffset;

  AutoLapEvent? processReading(SensorReading reading) {
    final power = reading.power;
    final offset = reading.timestamp.inSeconds;

    switch (_state) {
      case AutoLapState.idle:
        // Check before adding so the sprint reading does not contaminate
        // the baseline, and so cold-start (empty baseline = 0W) works.
        if (power != null &&
            power > _preEffortBaseline.average + config.startDeltaWatts) {
          _tentativeStartOffset = offset;
          _confirmCount = 1;
          _dropoutCount = 0;
          _preEffortBaseline.freeze();

          // Immediately confirm if startConfirmSeconds == 1.
          if (_confirmCount >= config.startConfirmSeconds) {
            _state = AutoLapState.inEffort;
            _peakWatts = power;
            _inEffortTrailing
              ..clear()
              ..add(power);
            return EffortStartedEvent(
              startOffset: _tentativeStartOffset,
              isManual: false,
              preEffortBaseline: _preEffortBaseline.average,
            );
          }
          _state = AutoLapState.pendingStart;
        } else {
          _preEffortBaseline.add(power);
        }
        return null;

      case AutoLapState.pendingStart:
        if (power == null) return null;

        if (power > _preEffortBaseline.average + config.startDeltaWatts) {
          _confirmCount++;
        } else {
          _dropoutCount++;
        }

        if (_dropoutCount > config.startDropoutTolerance) {
          _state = AutoLapState.idle;
          _preEffortBaseline.unfreeze();
          _confirmCount = 0;
          _dropoutCount = 0;
          return null;
        }

        if (_confirmCount >= config.startConfirmSeconds) {
          _state = AutoLapState.inEffort;
          _peakWatts = power;
          _inEffortTrailing
            ..clear()
            ..add(power);
          return EffortStartedEvent(
            startOffset: _tentativeStartOffset,
            isManual: false,
            preEffortBaseline: _preEffortBaseline.average,
          );
        }
        return null;

      case AutoLapState.inEffort:
        if (power != null) _peakWatts = max(_peakWatts ?? 0, power);
        _inEffortTrailing.add(power);

        final elapsed = offset - _tentativeStartOffset;
        if (elapsed >= kMaxEffortSeconds) {
          _state = AutoLapState.idle;
          final preEffortBaselineCap = _preEffortBaseline.average;
          final peakTrailingAvgCap = _inEffortTrailing.average;
          final peakCap = _peakWatts ?? 0;
          _preEffortBaseline.clear();
          _inEffortTrailing.clear();
          _peakWatts = null;
          return EffortEndedEvent(
            startOffset: _tentativeStartOffset,
            endOffset: offset,
            isManual: false,
            wasTooShort: false,
            wasTooWeak:
                config.minPeakWatts != null && peakCap < config.minPeakWatts!,
            peakWatts: peakCap,
            preEffortBaseline: preEffortBaselineCap,
            peakTrailingAvg: peakTrailingAvgCap,
          );
        }

        if (power != null &&
            power < _inEffortTrailing.average - config.endDeltaWatts) {
          _tentativeEndOffset = offset;
          _confirmCount = 1;
          _inEffortTrailing.freeze();

          // Immediately confirm if endConfirmSeconds == 1.
          if (_confirmCount >= config.endConfirmSeconds) {
            _state = AutoLapState.idle;
            final preEffortBaseline = _preEffortBaseline.average;
            final peakTrailingAvg = _inEffortTrailing.average;
            final peak = _peakWatts ?? 0;
            _preEffortBaseline.clear();
            _inEffortTrailing.clear();
            _peakWatts = null;

            final duration = _tentativeEndOffset - _tentativeStartOffset;
            return EffortEndedEvent(
              startOffset: _tentativeStartOffset,
              endOffset: _tentativeEndOffset,
              isManual: false,
              wasTooShort: duration < config.minEffortSeconds,
              wasTooWeak:
                  config.minPeakWatts != null && peak < config.minPeakWatts!,
              peakWatts: peak,
              preEffortBaseline: preEffortBaseline,
              peakTrailingAvg: peakTrailingAvg,
            );
          }
          _state = AutoLapState.pendingEnd;
        }
        return null;

      case AutoLapState.pendingEnd:
        if (power == null) return null;

        if (power < _inEffortTrailing.average - config.endDeltaWatts) {
          _confirmCount++;
        } else {
          // Power came back up — not a real end
          _state = AutoLapState.inEffort;
          _inEffortTrailing
            ..unfreeze()
            ..add(power);
          return null;
        }

        if (_confirmCount >= config.endConfirmSeconds) {
          _state = AutoLapState.idle;
          final preEffortBaseline = _preEffortBaseline.average;
          final peakTrailingAvg = _inEffortTrailing.average;
          final peak = _peakWatts ?? 0;
          _preEffortBaseline.clear();
          _inEffortTrailing.clear();
          _peakWatts = null;

          final duration = offset - _tentativeStartOffset;
          return EffortEndedEvent(
            startOffset: _tentativeStartOffset,
            endOffset: offset,
            isManual: false,
            wasTooShort: duration < config.minEffortSeconds,
            wasTooWeak:
                config.minPeakWatts != null && peak < config.minPeakWatts!,
            peakWatts: peak,
            preEffortBaseline: preEffortBaseline,
            peakTrailingAvg: peakTrailingAvg,
          );
        }
        return null;
    }
  }

  List<AutoLapEvent> manualLap(int currentOffset) {
    switch (_state) {
      case AutoLapState.idle:
        _preEffortBaseline.freeze();
        _inEffortTrailing.clear();
        _tentativeStartOffset = currentOffset;
        _state = AutoLapState.inEffort;
        return [
          EffortStartedEvent(
            startOffset: currentOffset,
            isManual: true,
            preEffortBaseline: _preEffortBaseline.average,
          ),
        ];

      case AutoLapState.pendingStart:
        _state = AutoLapState.inEffort;
        _inEffortTrailing.clear();
        return [
          EffortStartedEvent(
            startOffset: _tentativeStartOffset,
            isManual: true,
            preEffortBaseline: _preEffortBaseline.average,
          ),
        ];

      case AutoLapState.inEffort:
        final endEvent = EffortEndedEvent(
          startOffset: _tentativeStartOffset,
          endOffset: currentOffset,
          isManual: true,
          wasTooShort: false,
          wasTooWeak: false,
          peakWatts: _peakWatts ?? 0,
          preEffortBaseline: _preEffortBaseline.average,
          peakTrailingAvg: _inEffortTrailing.average,
        );
        _preEffortBaseline.clear();
        _inEffortTrailing.clear();
        _peakWatts = null;
        _tentativeStartOffset = currentOffset;
        final startEvent = EffortStartedEvent(
          startOffset: currentOffset,
          isManual: true,
          preEffortBaseline: 0,
        );
        return [endEvent, startEvent];

      case AutoLapState.pendingEnd:
        _state = AutoLapState.idle;
        final peakTrailingAvg = _inEffortTrailing.average;
        final preEffortBaseline = _preEffortBaseline.average;
        final peak = _peakWatts ?? 0;
        _preEffortBaseline.clear();
        _inEffortTrailing.clear();
        _peakWatts = null;
        return [
          EffortEndedEvent(
            startOffset: _tentativeStartOffset,
            endOffset: currentOffset,
            isManual: true,
            wasTooShort: false,
            wasTooWeak: false,
            peakWatts: peak,
            preEffortBaseline: preEffortBaseline,
            peakTrailingAvg: peakTrailingAvg,
          ),
        ];
    }
  }

  AutoLapEvent? endRide(int currentOffset) {
    switch (_state) {
      case AutoLapState.idle:
        return null;
      case AutoLapState.pendingStart:
        _state = AutoLapState.idle;
        return null;
      case AutoLapState.inEffort:
        _state = AutoLapState.idle;
        final peakEnd = _peakWatts ?? 0;
        _peakWatts = null;
        return EffortEndedEvent(
          startOffset: _tentativeStartOffset,
          endOffset: currentOffset,
          isManual: false,
          wasTooShort: false,
          wasTooWeak:
              config.minPeakWatts != null && peakEnd < config.minPeakWatts!,
          peakWatts: peakEnd,
          preEffortBaseline: _preEffortBaseline.average,
          peakTrailingAvg: _inEffortTrailing.average,
        );
      case AutoLapState.pendingEnd:
        _state = AutoLapState.idle;
        final peakPend = _peakWatts ?? 0;
        _peakWatts = null;
        return EffortEndedEvent(
          startOffset: _tentativeStartOffset,
          endOffset: currentOffset,
          isManual: false,
          wasTooShort: false,
          wasTooWeak:
              config.minPeakWatts != null && peakPend < config.minPeakWatts!,
          peakWatts: peakPend,
          preEffortBaseline: _preEffortBaseline.average,
          peakTrailingAvg: _inEffortTrailing.average,
        );
    }
  }

  void reset() {
    _state = AutoLapState.idle;
    _preEffortBaseline.clear();
    _inEffortTrailing.clear();
    _confirmCount = 0;
    _dropoutCount = 0;
    _peakWatts = null;
  }
}
