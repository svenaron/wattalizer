import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/autolap_detector.dart';

/// A minimal config for deterministic tests.
AutoLapConfig _cfg({
  double startDelta = 200,
  int startConfirm = 2,
  int startDropout = 0,
  double endDelta = 100,
  int endConfirm = 3,
  int minEffort = 3,
  int preWindow = 5,
  int inWindow = 5,
}) =>
    AutoLapConfig(
      id: 1,
      name: 'Test',
      startDeltaWatts: startDelta,
      startConfirmSeconds: startConfirm,
      startDropoutTolerance: startDropout,
      endDeltaWatts: endDelta,
      endConfirmSeconds: endConfirm,
      minEffortSeconds: minEffort,
      preEffortBaselineWindow: preWindow,
      inEffortTrailingWindow: inWindow,
    );

SensorReading _r(int t, {double? power}) => SensorReading(
      timestamp: Duration(seconds: t),
      power: power,
    );

void main() {
  group('AutoLapDetector — clean sprint', () {
    test('clean sprint: emits EffortStarted then EffortEnded', () {
      final detector = AutoLapDetector(_cfg());

      // Feed baseline: 100W for 5 readings
      for (var t = 0; t < 5; t++) {
        final ev = detector.processReading(_r(t, power: 100));
        expect(ev, isNull);
      }
      expect(detector.currentState, AutoLapState.idle);

      // 1st sprint reading at t=5: enters pendingStart, confirmCount=1
      var ev = detector.processReading(_r(5, power: 400));
      expect(ev, isNull);
      expect(detector.currentState, AutoLapState.pendingStart);

      // 2nd sprint reading at t=6: confirmCount=2 >= startConfirmSeconds=2
      ev = detector.processReading(_r(6, power: 400));
      expect(ev, isA<EffortStartedEvent>());
      final started = ev! as EffortStartedEvent;
      expect(started.startOffset, 5); // backdated to tentative start
      expect(started.isManual, false);
      expect(detector.currentState, AutoLapState.inEffort);

      // In-effort: high power readings feeding trailing baseline
      for (var t = 7; t < 12; t++) {
        ev = detector.processReading(_r(t, power: 400));
        expect(ev, isNull);
      }

      // End: power drops to 90 (below trailing avg ~400 - endDelta 100 = 300)
      ev = detector.processReading(_r(12, power: 90));
      expect(ev, isNull);
      expect(detector.currentState, AutoLapState.pendingEnd);

      ev = detector.processReading(_r(13, power: 90));
      expect(ev, isNull);

      ev = detector.processReading(_r(14, power: 90));
      expect(ev, isA<EffortEndedEvent>());
      final ended = ev! as EffortEndedEvent;
      expect(ended.startOffset, 5);
      expect(ended.endOffset, 11); // last high-power reading (drop at t=12)
      expect(ended.wasTooShort, false);
      expect(ended.isManual, false);
      expect(detector.currentState, AutoLapState.idle);
    });
  });

  group('AutoLapDetector — noisy sprint', () {
    test(
      'one dropout during pendingStart within tolerance → still confirms',
      () {
        final detector = AutoLapDetector(
          _cfg(startConfirm: 3, startDropout: 1),
        );

        for (var t = 0; t < 5; t++) {
          detector.processReading(_r(t, power: 100));
        }

        detector.processReading(_r(5, power: 400)); // pendingStart, confirm=1
        // Dropout: 150W (not above baseline+200=300)
        var ev = detector.processReading(
          _r(6, power: 150),
        ); // dropout=1, within tolerance
        expect(ev, isNull);
        expect(detector.currentState, AutoLapState.pendingStart);

        detector.processReading(_r(7, power: 400)); // confirm=2
        ev = detector.processReading(_r(8, power: 400)); // confirm=3
        expect(ev, isA<EffortStartedEvent>());
      },
    );

    test('too many dropouts in pendingStart → back to idle', () {
      final detector = AutoLapDetector(_cfg());

      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // pendingStart
      // One dropout → exceeds tolerance=0
      final ev = detector.processReading(_r(6, power: 150));
      expect(ev, isNull);
      expect(detector.currentState, AutoLapState.idle);
    });

    test('false end during inEffort: power bounces back → stays inEffort', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1));

      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → inEffort

      for (var t = 6; t < 12; t++) {
        detector.processReading(_r(t, power: 400));
      }
      // Low reading → pendingEnd
      detector.processReading(_r(12, power: 90));
      expect(detector.currentState, AutoLapState.pendingEnd);

      // Power bounces back → returns to inEffort
      final ev = detector.processReading(_r(13, power: 400));
      expect(ev, isNull);
      expect(detector.currentState, AutoLapState.inEffort);
    });
  });

  group('AutoLapDetector — too-short spike', () {
    test('effort shorter than minEffortSeconds → wasTooShort=true', () {
      // minEffort=10, but effort ends at t=8-5=3 < 10
      final detector = AutoLapDetector(
        _cfg(startConfirm: 1, endConfirm: 1, minEffort: 10),
      );

      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      var ev = detector.processReading(
        _r(5, power: 400),
      ); // → inEffort (confirm=1)
      expect(ev, isA<EffortStartedEvent>());

      for (var t = 6; t < 8; t++) {
        detector.processReading(_r(t, power: 400));
      }
      ev = detector.processReading(
        _r(8, power: 90),
      ); // end immediately (endConfirm=1)
      expect(ev, isA<EffortEndedEvent>());
      expect((ev! as EffortEndedEvent).wasTooShort, true);
    });
  });

  group('AutoLapDetector — back-to-back efforts', () {
    test('second effort detected after first ends', () {
      final detector = AutoLapDetector(
        _cfg(startConfirm: 1, endConfirm: 1, minEffort: 1),
      );

      for (var t = 0; t < 3; t++) {
        detector.processReading(_r(t, power: 100));
      }

      var ev = detector.processReading(
        _r(3, power: 400),
      ); // first effort starts
      expect(ev, isA<EffortStartedEvent>());

      for (var t = 4; t < 7; t++) {
        detector.processReading(_r(t, power: 400));
      }
      ev = detector.processReading(_r(7, power: 90)); // first effort ends
      expect(ev, isA<EffortEndedEvent>());
      expect(detector.currentState, AutoLapState.idle);

      // Recovery
      for (var t = 8; t < 11; t++) {
        detector.processReading(_r(t, power: 100));
      }

      ev = detector.processReading(_r(11, power: 400)); // second sprint
      expect(ev, isA<EffortStartedEvent>());
      expect((ev! as EffortStartedEvent).startOffset, 11);
    });
  });

  group('AutoLapDetector — cold start', () {
    test('baseline=0 at start, power above delta triggers immediately', () {
      // preWindow=5 but no readings yet → baseline=0
      // startDelta=200: any power > 200 triggers
      final detector = AutoLapDetector(_cfg(startConfirm: 1));

      final ev = detector.processReading(_r(0, power: 300));
      expect(ev, isA<EffortStartedEvent>());
    });
  });

  group('AutoLapDetector — gradual ramp', () {
    test(
      'gradual increase does not trigger if never exceeds baseline+delta',
      () {
        // Each step = 5W, baseline adapts quickly, delta=200 never breached
        final detector = AutoLapDetector(_cfg());

        for (var t = 0; t < 20; t++) {
          final ev = detector.processReading(_r(t, power: 100.0 + t * 5));
          expect(ev, isNull);
        }
        expect(detector.currentState, AutoLapState.idle);
      },
    );
  });

  group('AutoLapDetector — sensor dropout mid-effort', () {
    test('null readings during inEffort do not end the effort', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1));

      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → inEffort

      for (var t = 6; t < 10; t++) {
        final ev = detector.processReading(_r(t));
        expect(ev, isNull);
      }
      expect(detector.currentState, AutoLapState.inEffort);
    });

    test('null readings during pendingStart are neutral', () {
      final detector = AutoLapDetector(_cfg());

      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // pendingStart, confirm=1

      // Null — should not count as dropout
      var ev = detector.processReading(_r(6));
      expect(ev, isNull);
      expect(detector.currentState, AutoLapState.pendingStart);

      // Second confirm
      ev = detector.processReading(_r(7, power: 400));
      expect(ev, isA<EffortStartedEvent>());
    });
  });

  group('AutoLapDetector — endRide in each state', () {
    test('endRide in idle → null', () {
      final detector = AutoLapDetector(_cfg());
      expect(detector.endRide(10), isNull);
    });

    test('endRide in pendingStart → null, discards tentative', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 3));
      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → pendingStart

      final ev = detector.endRide(6);
      expect(ev, isNull);
      expect(detector.currentState, AutoLapState.idle);
    });

    test('endRide in inEffort → EffortEndedEvent', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1));
      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → inEffort

      final ev = detector.endRide(10);
      expect(ev, isA<EffortEndedEvent>());
      final ended = ev! as EffortEndedEvent;
      expect(ended.startOffset, 5);
      expect(ended.endOffset, 10);
      expect(ended.wasTooShort, false); // endRide skips min duration check
    });

    test(
      'endRide in pendingEnd → EffortEndedEvent with tentative end offset',
      () {
        final detector = AutoLapDetector(_cfg(startConfirm: 1, endConfirm: 5));
        for (var t = 0; t < 5; t++) {
          detector.processReading(_r(t, power: 100));
        }
        detector.processReading(_r(5, power: 400)); // → inEffort
        for (var t = 6; t < 10; t++) {
          detector.processReading(_r(t, power: 400));
        }
        detector.processReading(
          _r(10, power: 90),
        ); // → pendingEnd, tentativeEnd=10

        final ev = detector.endRide(15);
        expect(ev, isA<EffortEndedEvent>());
        // last high-power reading (drop at t=10)
        expect((ev! as EffortEndedEvent).endOffset, 9);
      },
    );
  });

  group('AutoLapDetector — manualLap in each state', () {
    test('manualLap in idle → EffortStartedEvent', () {
      final detector = AutoLapDetector(_cfg());
      final events = detector.manualLap(5);

      expect(events.length, 1);
      expect(events[0], isA<EffortStartedEvent>());
      expect((events[0] as EffortStartedEvent).startOffset, 5);
      expect((events[0] as EffortStartedEvent).isManual, true);
      expect(detector.currentState, AutoLapState.inEffort);
    });

    test(
      'manualLap in pendingStart → EffortStartedEvent (confirm immediately)',
      () {
        final detector = AutoLapDetector(_cfg(startConfirm: 5));
        for (var t = 0; t < 5; t++) {
          detector.processReading(_r(t, power: 100));
        }
        detector.processReading(_r(5, power: 400)); // pendingStart

        final events = detector.manualLap(6);
        expect(events.length, 1);
        expect(events[0], isA<EffortStartedEvent>());
        expect((events[0] as EffortStartedEvent).startOffset, 5); // backdated
        expect(detector.currentState, AutoLapState.inEffort);
      },
    );

    test('manualLap in inEffort → EffortEnded + EffortStarted', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1));
      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → inEffort

      final events = detector.manualLap(10);
      expect(events.length, 2);
      expect(events[0], isA<EffortEndedEvent>());
      expect(events[1], isA<EffortStartedEvent>());
      final ended = events[0] as EffortEndedEvent;
      expect(ended.startOffset, 5);
      expect(ended.endOffset, 10);
      expect(ended.isManual, true);
      expect(ended.wasTooShort, false);
      final started = events[1] as EffortStartedEvent;
      expect(started.startOffset, 10);
      expect(detector.currentState, AutoLapState.inEffort);
    });

    test('manualLap in pendingEnd → EffortEnded immediately', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1, endConfirm: 5));
      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → inEffort
      for (var t = 6; t < 10; t++) {
        detector.processReading(_r(t, power: 400));
      }
      detector.processReading(_r(10, power: 90)); // → pendingEnd

      final events = detector.manualLap(15);
      expect(events.length, 1);
      expect(events[0], isA<EffortEndedEvent>());
      final ended = events[0] as EffortEndedEvent;
      expect(ended.endOffset, 9); // last high-power reading (drop at t=10)
      expect(ended.isManual, true);
      expect(detector.currentState, AutoLapState.idle);
    });
  });

  group('AutoLapDetector — 90s cap', () {
    test('power stays high for exactly 90s → effort ends at offset 90', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1, endConfirm: 5));

      // Cold start: offset 0 starts effort immediately
      var ev = detector.processReading(_r(0, power: 400));
      expect(ev, isA<EffortStartedEvent>());
      expect((ev! as EffortStartedEvent).startOffset, 0);

      // Readings t=1..89: high power, no end
      for (var t = 1; t < 90; t++) {
        ev = detector.processReading(_r(t, power: 400));
        expect(ev, isNull, reason: 'should not end at t=$t');
      }
      expect(detector.currentState, AutoLapState.inEffort);

      // t=90: elapsed = 90-0 = 90 → force end
      ev = detector.processReading(_r(90, power: 400));
      expect(ev, isA<EffortEndedEvent>());
      final ended = ev! as EffortEndedEvent;
      expect(ended.startOffset, 0);
      expect(ended.endOffset, 90);
      expect(ended.wasTooShort, false);
      expect(ended.isManual, false);
      expect(detector.currentState, AutoLapState.idle);
    });

    test('power stays high for 91s → effort ends at offset 90, not 91', () {
      // Use endConfirm=5 to ensure natural end-detection never fires.
      final detector = AutoLapDetector(_cfg(startConfirm: 1, endConfirm: 5));

      for (var t = 0; t < 90; t++) {
        detector.processReading(_r(t, power: 400));
      }

      // Cap fires at t=90; endOffset must be 90, not 91
      final ev = detector.processReading(_r(90, power: 400));
      expect(ev, isA<EffortEndedEvent>());
      expect((ev! as EffortEndedEvent).endOffset, 90);
    });

    test('natural end before 90s still works normally', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1, endConfirm: 1));

      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → inEffort

      for (var t = 6; t < 30; t++) {
        detector.processReading(_r(t, power: 400));
      }
      // Power drops well before 90s
      final ev = detector.processReading(_r(30, power: 90));
      expect(ev, isA<EffortEndedEvent>());
      expect((ev! as EffortEndedEvent).endOffset, 29);
      expect(detector.currentState, AutoLapState.idle);
    });
  });

  group('AutoLapDetector — reset', () {
    test('reset returns to idle and clears all state', () {
      final detector = AutoLapDetector(_cfg(startConfirm: 1));
      for (var t = 0; t < 5; t++) {
        detector.processReading(_r(t, power: 100));
      }
      detector.processReading(_r(5, power: 400)); // → inEffort
      expect(detector.currentState, AutoLapState.inEffort);

      detector.reset();

      expect(detector.currentState, AutoLapState.idle);
      expect(detector.currentBaseline, 0.0);
    });
  });
}
