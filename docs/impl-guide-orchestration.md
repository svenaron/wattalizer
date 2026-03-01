# Sprint Power Analyzer – Implementation Guide IG17–IG19

---

## IG17. RideSessionManager — Complete Implementation

This is the central orchestrator. It owns the 1Hz timer, BLE stream subscription, reading buffer, and coordinates AutoLapDetector, MapCurveCalculator, and EffortManager.

```dart
class RideSessionManager {
  final RideRepository _repository;
  final AutoLapConfig _config;
  final void Function(RideState) _onStateChanged;

  // --- Ride state ---
  late final String _rideId;
  late final DateTime _startTime;
  final List<SensorReading> _readings = [];
  final List<Effort> _efforts = [];

  // --- Components ---
  late final AutoLapDetector _detector;
  final EffortManager _effortManager = EffortManager();
  MapCurveCalculator? _liveEffortCalc; // non-null only during an active effort

  // --- 1Hz bin accumulator ---
  final List<RawSensorData> _currentBin = [];
  Timer? _tickTimer;
  int _currentOffsetSeconds = 0;

  // --- BLE ---
  StreamSubscription? _bleSub;

  RideSessionManager({
    required RideRepository repository,
    required AutoLapConfig config,
    required void Function(RideState) onStateChanged,
  })  : _repository = repository,
        _config = config,
        _onStateChanged = onStateChanged;

  void start(Stream<RawSensorData> sensorStream) {
    _rideId = const Uuid().v4();
    _startTime = DateTime.now();
    _detector = AutoLapDetector(_config);

    // Subscribe to raw BLE data — accumulates into current 1s bin
    _bleSub = sensorStream.listen((data) {
      _currentBin.add(data);
    });

    // 1Hz tick — processes the bin every second
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processTick();
    });

    WakelockPlus.enable();
    _emitState();
  }

  void _processTick() {
    final reading = _mergeBin(_currentBin, _currentOffsetSeconds);
    _currentBin.clear();
    _readings.add(reading);
    _currentOffsetSeconds++;

    // Feed detector
    final event = _detector.processReading(reading);
    _handleEvent(event);

    // Feed live effort calculator if active
    if (_liveEffortCalc != null) {
      _liveEffortCalc!.updateLive(reading, 'live');
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
    final avgPower = powers.isEmpty ? null : powers.reduce((a, b) => a + b) / powers.length;

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
          _liveEffortCalc!.updateLive(r, 'live');
        }
      }
    } else if (event is EffortEndedEvent) {
      _liveEffortCalc = null; // dispose — batch replaces it

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
    final events = _detector.manualLap(_currentOffsetSeconds);
    for (final e in events) {
      _handleEvent(e);
    }
    _emitState();
  }

  Future<Ride> end() async {
    _tickTimer?.cancel();
    _bleSub?.cancel();

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
      await _repository.saveEfforts(_rideId, _efforts);
      for (final effort in _efforts) {
        await _repository.saveMapCurve(effort.id, effort.mapCurve);
      }
    });

    await WakelockPlus.disable();
    return ride;
  }

  void _emitState() {
    _onStateChanged(RideStateActive(
      rideId: _rideId,
      startTime: _startTime,
      readings: _readings,
      completedEfforts: _efforts,
      autoLapState: _detector.currentState,
      currentBaseline: _detector.currentBaseline,
      liveEffortCurve: _liveEffortCalc != null
          ? _liveEffortCalc!.updateLive(
              _readings.last, 'live') // returns current state
          : null,
      activeEffortStartOffset: _detector.currentState == AutoLapState.inEffort ||
              _detector.currentState == AutoLapState.pendingEnd
          ? _detector._tentativeStartOffset
          : null,
    ));
  }
}
```

### IG17.1 Note on `_emitState` and Live Curve

The `_emitState` call at the end of `_processTick` already has the latest live curve from the `updateLive` call earlier in the tick. The approach above calls `updateLive` twice in the effort path — once in `_processTick` and once in `_emitState`. To avoid this, cache the result:

```dart
MapCurve? _latestLiveCurve;

void _processTick() {
  // ... merge, append, detector ...
  
  if (_liveEffortCalc != null) {
    _latestLiveCurve = _liveEffortCalc!.updateLive(reading, 'live');
  }
  
  _emitState();
}

void _handleEvent(AutoLapEvent? event) {
  if (event is EffortStartedEvent) {
    // ... backfill ...
  } else if (event is EffortEndedEvent) {
    _liveEffortCalc = null;
    _latestLiveCurve = null; // clear on effort end
    // ...
  }
}

void _emitState() {
  _onStateChanged(RideStateActive(
    // ...
    liveEffortCurve: _latestLiveCurve,
    // ...
  ));
}
```

---

## IG18. BleServiceImpl — Connection and Subscription Patterns

The tricky parts: connection state machine, multi-characteristic subscription, and reconnection. Scanning is straightforward — omitted.

```dart
class BleServiceImpl implements BleService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // --- Known BLE UUIDs ---
  static final _powerServiceUuid = Uuid.parse('00001818-0000-1000-8000-00805f9b34fb');
  static final _hrServiceUuid = Uuid.parse('0000180d-0000-1000-8000-00805f9b34fb');
  static final _cscServiceUuid = Uuid.parse('00001816-0000-1000-8000-00805f9b34fb');
  static final _powerMeasurementUuid = Uuid.parse('00002a63-0000-1000-8000-00805f9b34fb');
  static final _hrMeasurementUuid = Uuid.parse('00002a37-0000-1000-8000-00805f9b34fb');
  static final _cscMeasurementUuid = Uuid.parse('00002a5b-0000-1000-8000-00805f9b34fb');

  // --- Per-device state ---
  final Map<String, StreamSubscription> _connectionSubs = {};
  final Map<String, StreamController<BleConnectionState>> _stateControllers = {};
  final Map<String, StreamController<RawSensorData>> _sensorControllers = {};
  final Map<String, CscParser> _cscParsers = {}; // stateful, per-device
  final Map<String, Timer?> _reconnectTimers = {};
  final Map<String, int> _reconnectAttempts = {};

  @override
  Stream<List<DiscoveredDevice>> scanForDevices() {
    return _ble.scanForDevices(
      withServices: [_powerServiceUuid, _hrServiceUuid, _cscServiceUuid],
    ).map((device) => [
      DiscoveredDevice(
        deviceId: device.id,
        name: device.name.isNotEmpty ? device.name : 'Unknown',
        rssi: device.rssi,
        advertisedServices: _parseServices(device.serviceUuids),
      ),
    ]);
    // Note: scanForDevices emits one device at a time from flutter_reactive_ble.
    // The provider layer should accumulate into a list with dedup by deviceId.
  }

  @override
  Future<void> connect(String deviceId) async {
    _stateControllers[deviceId] ??= StreamController.broadcast();
    _sensorControllers[deviceId] ??= StreamController.broadcast();
    _cscParsers[deviceId] ??= CscParser();
    _reconnectAttempts[deviceId] = 0;

    _stateControllers[deviceId]!.add(BleConnectionState.connecting);

    _connectionSubs[deviceId]?.cancel();
    _connectionSubs[deviceId] = _ble
        .connectToDevice(
          id: deviceId,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
      (update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            _reconnectAttempts[deviceId] = 0;
            await _discoverAndSubscribe(deviceId);
            _stateControllers[deviceId]?.add(BleConnectionState.connected);

          case DeviceConnectionState.disconnected:
            _handleDisconnect(deviceId);

          default:
            break;
        }
      },
      onError: (e) {
        _handleDisconnect(deviceId);
      },
    );
  }

  /// After connection established: discover services, subscribe to all
  /// supported characteristics, and merge into a single RawSensorData stream.
  Future<void> _discoverAndSubscribe(String deviceId) async {
    final services = await _ble.getDiscoveredServices(deviceId);
    final serviceUuids = services.map((s) => s.id).toSet();

    // Subscribe to each supported characteristic
    if (serviceUuids.contains(_powerServiceUuid)) {
      _subscribeCharacteristic(
        deviceId,
        _powerServiceUuid,
        _powerMeasurementUuid,
        (bytes) {
          final power = PowerParser.parse(bytes);
          if (power != null) {
            _sensorControllers[deviceId]?.add(RawSensorData(
              receivedAt: DateTime.now(),
              power: power,
            ));
          }
        },
      );
    }

    if (serviceUuids.contains(_hrServiceUuid)) {
      _subscribeCharacteristic(
        deviceId,
        _hrServiceUuid,
        _hrMeasurementUuid,
        (bytes) {
          final hr = HrParser.parse(bytes);
          if (hr != null) {
            _sensorControllers[deviceId]?.add(RawSensorData(
              receivedAt: DateTime.now(),
              hr: hr,
            ));
          }
        },
      );
    }

    if (serviceUuids.contains(_cscServiceUuid)) {
      _subscribeCharacteristic(
        deviceId,
        _cscServiceUuid,
        _cscMeasurementUuid,
        (bytes) {
          final cad = _cscParsers[deviceId]!.parse(bytes);
          if (cad != null) {
            _sensorControllers[deviceId]?.add(RawSensorData(
              receivedAt: DateTime.now(),
              cadence: cad,
            ));
          }
        },
      );
    }
  }

  void _subscribeCharacteristic(
    String deviceId,
    Uuid serviceUuid,
    Uuid charUuid,
    void Function(List<int>) onData,
  ) {
    final char = QualifiedCharacteristic(
      characteristicId: charUuid,
      serviceId: serviceUuid,
      deviceId: deviceId,
    );
    _ble.subscribeToCharacteristic(char).listen(
      onData,
      onError: (e) {
        // Characteristic-level error — log but don't disconnect.
        // The connection-level listener handles full disconnects.
      },
    );
  }

  /// Reconnection with exponential backoff: 1s, 2s, 4s, 8s... capped at 30s.
  /// Gives up after 2 minutes total.
  void _handleDisconnect(String deviceId) {
    final attempts = _reconnectAttempts[deviceId] ?? 0;
    final elapsed = _backoffTotal(attempts);

    if (elapsed > const Duration(minutes: 2).inMilliseconds) {
      // Give up
      _stateControllers[deviceId]?.add(BleConnectionState.disconnected);
      _cscParsers[deviceId]?.reset();
      return;
    }

    _stateControllers[deviceId]?.add(BleConnectionState.reconnecting);
    _cscParsers[deviceId]?.reset(); // avoid bogus deltas after reconnect

    final delay = Duration(
      milliseconds: math.min(1000 * math.pow(2, attempts).toInt(), 30000),
    );
    _reconnectTimers[deviceId]?.cancel();
    _reconnectTimers[deviceId] = Timer(delay, () {
      _reconnectAttempts[deviceId] = attempts + 1;
      connect(deviceId); // retry
    });
  }

  int _backoffTotal(int attempts) {
    int total = 0;
    for (int i = 0; i < attempts; i++) {
      total += math.min(1000 * math.pow(2, i).toInt(), 30000);
    }
    return total;
  }

  @override
  Stream<BleConnectionState> connectionState(String deviceId) {
    _stateControllers[deviceId] ??= StreamController.broadcast();
    return _stateControllers[deviceId]!.stream;
  }

  @override
  Stream<RawSensorData> sensorStream(String deviceId) {
    _sensorControllers[deviceId] ??= StreamController.broadcast();
    return _sensorControllers[deviceId]!.stream;
  }

  @override
  Future<void> disconnect(String deviceId) async {
    _reconnectTimers[deviceId]?.cancel();
    _connectionSubs[deviceId]?.cancel();
    _stateControllers[deviceId]?.add(BleConnectionState.disconnected);
    _cscParsers[deviceId]?.reset();
  }

  @override
  void stopScan() {
    // flutter_reactive_ble scan is stopped by cancelling the stream subscription.
    // The provider layer handles this by cancelling its subscription.
  }

  Set<SensorType> _parseServices(List<Uuid> uuids) {
    final s = <SensorType>{};
    for (final u in uuids) {
      if (u == _powerServiceUuid) s.add(SensorType.power);
      if (u == _hrServiceUuid) s.add(SensorType.heartRate);
      if (u == _cscServiceUuid) s.add(SensorType.cadence);
    }
    return s;
  }
}
```

### IG18.1 Platform Configuration

**iOS — `ios/Runner/Info.plist`:**
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Sprint Power Analyzer connects to your power meter and heart rate sensor to record training data.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Sprint Power Analyzer connects to your power meter and heart rate sensor to record training data.</string>
<key>UIBackgroundModes</key>
<array>
  <string>bluetooth-central</string>
</array>
```

**Android — `android/app/src/main/AndroidManifest.xml`:**
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<!-- For Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<!-- Foreground service for background BLE during active ride -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

**Note on permissions at runtime:** `flutter_reactive_ble` handles permission requests internally on scan. If permissions are denied, the scan stream emits an error — catch it and surface as `BleScanError(reason: 'permission_denied')`.

---

## IG19. Ride Screen Reference — Active Focus Mode

One complete screen widget showing provider consumption, power color scaling, swipe gesture, and button layout. Other screens follow the same patterns.

```dart
class RideScreen extends ConsumerWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideSessionProvider);

    return switch (rideState) {
      RideStateIdle(:final lastRide) => _IdleView(lastRide: lastRide, ref: ref),
      RideStateActive() => _ActiveView(state: rideState, ref: ref),
      RideStateError(:final message) => _ErrorView(message: message),
    };
  }
}

class _ActiveView extends StatelessWidget {
  final RideStateActive state;
  final WidgetRef ref;

  const _ActiveView({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Swipe to toggle Focus ↔ Chart (minimum 80px)
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0).abs() > 200) {
          ref.read(rideModeProvider.notifier).toggle();
        }
      },
      child: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _ChartMode(state: state, ref: ref, isLandscape: true);
          }
          final mode = ref.watch(rideModeProvider);
          return mode == RideMode.focus
              ? _FocusMode(state: state, ref: ref)
              : _ChartMode(state: state, ref: ref, isLandscape: false);
        },
      ),
    );
  }
}

/// Focus mode: big power number, color-coded background.
class _FocusMode extends StatelessWidget {
  final RideStateActive state;
  final WidgetRef ref;

  const _FocusMode({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final latest = state.readings.isNotEmpty ? state.readings.last : null;
    final power = latest?.power;
    final maxPower = ref.watch(maxPowerProvider).valueOrNull ?? 1500;
    final pct = power != null ? (power / maxPower).clamp(0.0, 1.2) : 0.0;
    final isInEffort = state.autoLapState == AutoLapState.inEffort ||
        state.autoLapState == AutoLapState.pendingEnd;

    return Scaffold(
      backgroundColor: _bgColor(pct),
      body: SafeArea(
        child: Column(
          children: [
            // --- Mode toggle pills ---
            _ModeSegmentedControl(ref: ref),

            // --- Connection status ---
            _SensorStatusBar(ref: ref),

            const Spacer(),

            // --- Main content ---
            if (isInEffort) ...[
              // Effort duration
              Text(
                _formatDuration(state.readings.length -
                    (state.activeEffortStartOffset ?? 0)),
                style: const TextStyle(
                    fontSize: 24, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              // Big power number
              Text(
                power?.round().toString() ?? '---',
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: pct > 0.95
                      ? [Shadow(color: Colors.white54, blurRadius: 20)]
                      : null,
                ),
              ),
              const Text('watts',
                  style: TextStyle(fontSize: 18, color: Colors.white60)),
            ] else ...[
              // Between efforts: last effort summary
              if (state.completedEfforts.isNotEmpty)
                _LastEffortCard(effort: state.completedEfforts.last)
              else
                const Text('Waiting for effort…',
                    style: TextStyle(fontSize: 20, color: Colors.white54)),
              const SizedBox(height: 16),
              // Recovery timer
              Text(
                'Recovery: ${_formatDuration(_recoverySeconds(state))}',
                style: const TextStyle(
                    fontSize: 18, color: Colors.white54),
              ),
            ],

            const Spacer(),

            // --- HR / Cadence corners ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SmallStat(
                      label: 'HR',
                      value: latest?.heartRate?.toString() ?? '--'),
                  _SmallStat(
                      label: 'RPM',
                      value: latest?.cadence?.round().toString() ?? '--'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- LAP / STOP buttons ---
            _RideControls(
              onLap: () => ref.read(rideSessionProvider.notifier).manualLap(),
              onStopConfirmed: () =>
                  ref.read(rideSessionProvider.notifier).endRide(),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Background color from % of max power.
  Color _bgColor(double pct) {
    if (pct < 0.30) return const Color(0xFF1A237E); // deep blue
    if (pct < 0.60) return Color.lerp(
        const Color(0xFF1A237E), const Color(0xFF6A1B9A), (pct - 0.3) / 0.3)!;
    if (pct < 0.80) return Color.lerp(
        const Color(0xFF6A1B9A), const Color(0xFFF9A825), (pct - 0.6) / 0.2)!;
    if (pct < 0.95) return Color.lerp(
        const Color(0xFFF9A825), const Color(0xFFE65100), (pct - 0.8) / 0.15)!;
    return const Color(0xFFB71C1C); // red, pulse handled by animation
  }
}

/// Long-press stop with circular progress.
class _RideControls extends StatefulWidget {
  final VoidCallback onLap;
  final VoidCallback onStopConfirmed;

  const _RideControls({required this.onLap, required this.onStopConfirmed});

  @override
  State<_RideControls> createState() => _RideControlsState();
}

class _RideControlsState extends State<_RideControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stopProgress;

  @override
  void initState() {
    super.initState();
    _stopProgress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          widget.onStopConfirmed();
        }
      });
  }

  @override
  void dispose() {
    _stopProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // LAP button — large touch target
        SizedBox(
          width: 72, height: 72,
          child: ElevatedButton(
            onPressed: widget.onLap,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.white24,
            ),
            child: const Text('LAP',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),

        // STOP button — long press with progress ring
        GestureDetector(
          onLongPressStart: (_) => _stopProgress.forward(from: 0),
          onLongPressEnd: (_) {
            if (_stopProgress.status != AnimationStatus.completed) {
              _stopProgress.reset();
            }
          },
          child: SizedBox(
            width: 72, height: 72,
            child: AnimatedBuilder(
              animation: _stopProgress,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _stopProgress.value,
                      strokeWidth: 4,
                      color: Colors.redAccent,
                      backgroundColor: Colors.white24,
                    ),
                    const Icon(Icons.stop, color: Colors.white, size: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple focus/chart toggle at top of screen.
enum RideMode { focus, chart }

final rideModeProvider = StateProvider<RideMode>((ref) => RideMode.focus);

extension on RideModeNotifier {
  void toggle() {
    state = state == RideMode.focus ? RideMode.chart : RideMode.focus;
  }
}

// Helpers
String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

int _recoverySeconds(RideStateActive state) {
  if (state.completedEfforts.isEmpty) return 0;
  final lastEnd = state.completedEfforts.last.endOffset;
  return state.readings.length - lastEnd;
}
```

### IG19.1 Chart Mode — Key Patterns Only

The chart mode uses `fl_chart` for the MAP curve. Only the data-binding pattern is shown — layout and styling follow the same Scaffold structure as focus mode.

```dart
/// Build fl_chart LineChartData from effort MapCurves + historical range.
LineChartData buildChartData({
  required MapCurve? liveCurve,
  required List<Effort> completedEfforts,
  required HistoricalRange? historicalRange,
}) {
  final lines = <LineChartBarData>[];

  // Historical band (best/worst) as two lines with betweenBarsData
  if (historicalRange != null) {
    lines.add(_envelopeLine(
      historicalRange.best.map((r) => r.power).toList(),
      Colors.green.withOpacity(0.2),
    ));
    lines.add(_envelopeLine(
      historicalRange.worst.map((r) => r.power).toList(),
      Colors.green.withOpacity(0.2),
    ));
  }

  // Previous efforts — faded
  for (final effort in completedEfforts) {
    lines.add(_curveLine(
      effort.mapCurve.values,
      Colors.white.withOpacity(0.3),
      strokeWidth: 1.5,
    ));
  }

  // Live effort — bold gradient
  if (liveCurve != null) {
    lines.add(_curveLine(
      liveCurve.values,
      null, // uses gradient instead
      strokeWidth: 3,
      gradient: const LinearGradient(
        colors: [Colors.red, Colors.yellow, Colors.blue],
      ),
    ));
  }

  return LineChartData(
    lineBarsData: lines,
    // X axis: duration 1-90s (log scale looks better for sprint data)
    // Y axis: power in watts, auto-scaled
    titlesData: FlTitlesData(/* ... */),
    gridData: FlGridData(show: true),
    borderData: FlBorderData(show: false),
    // Fill between best/worst envelopes
    betweenBarsData: historicalRange != null
        ? [BetweenBarsData(fromIndex: 0, toIndex: 1,
            color: Colors.green.withOpacity(0.08))]
        : [],
  );
}

LineChartBarData _curveLine(
  List<double> values,
  Color? color, {
  double strokeWidth = 2,
  Gradient? gradient,
}) {
  return LineChartBarData(
    spots: List.generate(90, (i) => FlSpot((i + 1).toDouble(), values[i])),
    isCurved: true,
    color: color,
    gradient: gradient,
    barWidth: strokeWidth,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: false),
  );
}
```
