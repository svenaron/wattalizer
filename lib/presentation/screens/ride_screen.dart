import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/presentation/providers/ble_connection_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_mode_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';

// ---------------------------------------------------------------------------
// Root screen
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Idle view
// ---------------------------------------------------------------------------

class _IdleView extends StatelessWidget {
  const _IdleView({required this.lastRide, required this.ref});

  final Ride? lastRide;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(bleConnectionProvider);
    final isConnected = connState.asData?.value == BleConnectionState.connected;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (lastRide != null) ...[
                _LastRideCard(ride: lastRide!),
                const SizedBox(height: 32),
              ],
              _SensorStatusBar(ref: ref),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isConnected
                      ? () => ref.read(rideSessionProvider.notifier).startRide()
                      : null,
                  child: Text(
                    isConnected ? 'Start Ride' : 'Connect a sensor to start',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active view — swipe + orientation routing
// ---------------------------------------------------------------------------

class _ActiveView extends StatelessWidget {
  const _ActiveView({required this.state, required this.ref});

  final RideStateActive state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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

// ---------------------------------------------------------------------------
// Focus mode
// ---------------------------------------------------------------------------

class _FocusMode extends StatelessWidget {
  const _FocusMode({required this.state, required this.ref});

  final RideStateActive state;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final latest = state.readings.isNotEmpty ? state.readings.last : null;
    final power = latest?.power;
    final maxPower = ref.watch(maxPowerProvider).asData?.value ?? 1500;
    final pct = power != null ? (power / maxPower).clamp(0.0, 1.2) : 0.0;
    final isInEffort = state.autoLapState == AutoLapState.inEffort ||
        state.autoLapState == AutoLapState.pendingEnd;

    return Scaffold(
      backgroundColor: _bgColor(pct),
      body: SafeArea(
        child: Column(
          children: [
            _ModeSegmentedControl(ref: ref),
            _SensorStatusBar(ref: ref),
            const Spacer(),
            if (isInEffort) ...[
              Text(
                _formatDuration(
                  state.readings.length - (state.activeEffortStartOffset ?? 0),
                ),
                style: const TextStyle(fontSize: 24, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                power?.round().toString() ?? '---',
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: pct > 0.95
                      ? [
                          const Shadow(
                            color: Colors.white54,
                            blurRadius: 20,
                          ),
                        ]
                      : null,
                ),
              ),
              const Text(
                'watts',
                style: TextStyle(fontSize: 18, color: Colors.white60),
              ),
            ] else ...[
              if (state.completedEfforts.isNotEmpty)
                _LastEffortCard(effort: state.completedEfforts.last)
              else
                const Text(
                  'Waiting for effort…',
                  style: TextStyle(fontSize: 20, color: Colors.white54),
                ),
              const SizedBox(height: 16),
              Text(
                'Recovery: ${_formatDuration(_recoverySeconds(state))}',
                style: const TextStyle(fontSize: 18, color: Colors.white54),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SmallStat(
                    label: 'HR',
                    value: latest?.heartRate?.toString() ?? '--',
                  ),
                  _SmallStat(
                    label: 'RPM',
                    value: latest?.cadence?.round().toString() ?? '--',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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

  Color _bgColor(double pct) {
    if (pct < 0.30) return const Color(0xFF1A237E);
    if (pct < 0.60) {
      return Color.lerp(
        const Color(0xFF1A237E),
        const Color(0xFF6A1B9A),
        (pct - 0.3) / 0.3,
      )!;
    }
    if (pct < 0.80) {
      return Color.lerp(
        const Color(0xFF6A1B9A),
        const Color(0xFFF9A825),
        (pct - 0.6) / 0.2,
      )!;
    }
    if (pct < 0.95) {
      return Color.lerp(
        const Color(0xFFF9A825),
        const Color(0xFFE65100),
        (pct - 0.8) / 0.15,
      )!;
    }
    return const Color(0xFFB71C1C);
  }
}

// ---------------------------------------------------------------------------
// Chart mode stub
// ---------------------------------------------------------------------------

class _ChartMode extends StatelessWidget {
  const _ChartMode({
    required this.state,
    required this.ref,
    required this.isLandscape,
  });

  final RideStateActive state;
  final WidgetRef ref;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!isLandscape) _ModeSegmentedControl(ref: ref),
            const Expanded(
              child: Center(
                child: Text(
                  'Chart mode\n(coming soon)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white54),
                ),
              ),
            ),
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
}

// ---------------------------------------------------------------------------
// Ride controls — LAP + long-press STOP
// ---------------------------------------------------------------------------

class _RideControls extends StatefulWidget {
  const _RideControls({
    required this.onLap,
    required this.onStopConfirmed,
  });

  final VoidCallback onLap;
  final VoidCallback onStopConfirmed;

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
        SizedBox(
          width: 72,
          height: 72,
          child: ElevatedButton(
            onPressed: widget.onLap,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.white24,
            ),
            child: const Text(
              'LAP',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
        GestureDetector(
          onLongPressStart: (_) => _stopProgress.forward(from: 0),
          onLongPressEnd: (_) {
            if (_stopProgress.status != AnimationStatus.completed) {
              _stopProgress.reset();
            }
          },
          child: SizedBox(
            width: 72,
            height: 72,
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

// ---------------------------------------------------------------------------
// Small helper widgets
// ---------------------------------------------------------------------------

class _ModeSegmentedControl extends StatelessWidget {
  const _ModeSegmentedControl({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(rideModeProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModeButton(
            label: 'Focus',
            selected: mode == RideMode.focus,
            onTap: () => ref.read(rideModeProvider.notifier).setFocus(),
          ),
          const SizedBox(width: 8),
          _ModeButton(
            label: 'Chart',
            selected: mode == RideMode.chart,
            onTap: () => ref.read(rideModeProvider.notifier).setChart(),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white38),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SensorStatusBar extends StatelessWidget {
  const _SensorStatusBar({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(bleConnectionProvider);
    final label = switch (connState) {
      AsyncData(:final value) => switch (value) {
          BleConnectionState.connected => '● Connected',
          BleConnectionState.connecting => '◌ Connecting…',
          BleConnectionState.reconnecting => '◌ Reconnecting…',
          BleConnectionState.disconnected => '○ No sensor',
        },
      AsyncLoading() => '◌ …',
      _ => '○ No sensor',
    };
    final color = connState.asData?.value == BleConnectionState.connected
        ? Colors.greenAccent
        : Colors.white54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(label, style: TextStyle(fontSize: 13, color: color)),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}

class _LastEffortCard extends StatelessWidget {
  const _LastEffortCard({required this.effort});

  final Effort effort;

  @override
  Widget build(BuildContext context) {
    final s = effort.summary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Effort ${effort.effortNumber}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.avgPower.round()} W avg  •  '
            '${s.peakPower.round()} W peak',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          Text(
            _formatDuration(s.durationSeconds),
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _LastRideCard extends StatelessWidget {
  const _LastRideCard({required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final s = ride.summary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last ride — ${_formatDate(ride.startTime)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${s.avgPower.round()} W avg  •  '
              '${s.effortCount} efforts  •  '
              '${_formatDuration(s.activeDurationSeconds)}',
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pure helpers
// ---------------------------------------------------------------------------

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
