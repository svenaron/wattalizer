import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/historical_range.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/presentation/layout/breakpoints.dart';
import 'package:wattalizer/presentation/layout/keyboard_shortcuts.dart';
import 'package:wattalizer/presentation/providers/ble_connection_provider.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_mode_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/widgets/device_sheet.dart';

// ---------------------------------------------------------------------------
// Root screen
// ---------------------------------------------------------------------------

class RideScreen extends ConsumerWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideState = ref.watch(rideSessionProvider);
    return switch (rideState) {
      RideStateIdle(:final lastRide) => _IdleView(lastRide: lastRide),
      RideStateActive() => _ActiveView(state: rideState),
      RideStateError(:final message) => _ErrorView(message: message),
    };
  }
}

// ---------------------------------------------------------------------------
// Idle view
// ---------------------------------------------------------------------------

class _IdleView extends ConsumerStatefulWidget {
  const _IdleView({required this.lastRide});

  final Ride? lastRide;

  @override
  ConsumerState<_IdleView> createState() => _IdleViewState();
}

class _IdleViewState extends ConsumerState<_IdleView> {
  @override
  Widget build(BuildContext context) {
    final connState = ref.watch(bleConnectionProvider);
    final isConnected = connState.asData?.value == BleConnectionState.connected;

    return Shortcuts(
      shortcuts: idleRideShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          StartRideIntent: CallbackAction<StartRideIntent>(
            onInvoke: (_) {
              if (isConnected) {
                unawaited(ref.read(rideSessionProvider.notifier).startRide());
              } else {
                showDeviceSheet(context);
              }
              return null;
            },
          ),
          OpenDeviceSheetIntent: CallbackAction<OpenDeviceSheetIntent>(
            onInvoke: (_) {
              showDeviceSheet(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.lastRide != null) ...[
                      _LastRideCard(ride: widget.lastRide!),
                      const SizedBox(height: 32),
                    ],
                    _SensorStatusBar(ref: ref),
                    const SizedBox(height: 32),
                    Tooltip(
                      message: 'Start ride (Enter)',
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isConnected
                              ? () => ref
                                  .read(rideSessionProvider.notifier)
                                  .startRide()
                              : () => showDeviceSheet(context),
                          child: Text(
                            isConnected
                                ? 'Start Ride'
                                : 'Connect a sensor to start',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Active view — swipe + orientation routing
// ---------------------------------------------------------------------------

class _ActiveView extends ConsumerStatefulWidget {
  const _ActiveView({required this.state});

  final RideStateActive state;

  @override
  ConsumerState<_ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends ConsumerState<_ActiveView> {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: activeRideShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          SetFocusModeIntent: CallbackAction<SetFocusModeIntent>(
            onInvoke: (_) {
              ref.read(rideModeProvider.notifier).setFocus();
              return null;
            },
          ),
          SetChartModeIntent: CallbackAction<SetChartModeIntent>(
            onInvoke: (_) {
              ref.read(rideModeProvider.notifier).setChart();
              return null;
            },
          ),
          ManualLapIntent: CallbackAction<ManualLapIntent>(
            onInvoke: (_) {
              ref.read(rideSessionProvider.notifier).manualLap();
              return null;
            },
          ),
          StopRideIntent: CallbackAction<StopRideIntent>(
            onInvoke: (_) {
              unawaited(_showStopConfirmation());
              return null;
            },
          ),
          OpenDeviceSheetIntent: CallbackAction<OpenDeviceSheetIntent>(
            onInvoke: (_) {
              showDeviceSheet(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0).abs() > 200) {
                ref.read(rideModeProvider.notifier).toggle();
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = layoutSizeOf(constraints.maxWidth);

                final Widget child;
                if (layout == LayoutSize.expanded) {
                  child = Row(
                    key: const ValueKey('expanded'),
                    children: [
                      Expanded(
                        flex: 2,
                        child: _FocusMode(state: widget.state, ref: ref),
                      ),
                      Expanded(
                        flex: 3,
                        child: _ChartMode(
                          state: widget.state,
                          ref: ref,
                          isLandscape: false,
                        ),
                      ),
                    ],
                  );
                } else {
                  final orientation = MediaQuery.orientationOf(context);
                  if (orientation == Orientation.landscape) {
                    child = _ChartMode(
                      key: const ValueKey('landscape'),
                      state: widget.state,
                      ref: ref,
                      isLandscape: true,
                    );
                  } else {
                    final mode = ref.watch(rideModeProvider);
                    child = mode == RideMode.focus
                        ? _FocusMode(
                            key: const ValueKey('focus'),
                            state: widget.state,
                            ref: ref,
                          )
                        : _ChartMode(
                            key: const ValueKey('chart'),
                            state: widget.state,
                            ref: ref,
                            isLandscape: false,
                          );
                  }
                }

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showStopConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Ride?'),
        content: const Text('Are you sure you want to end this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      unawaited(ref.read(rideSessionProvider.notifier).endRide());
    }
    if (mounted) {
      FocusScope.of(context).requestFocus();
    }
  }
}

// ---------------------------------------------------------------------------
// Focus mode — animated background + pulse at >95%
// ---------------------------------------------------------------------------

class _FocusMode extends StatefulWidget {
  const _FocusMode({required this.state, required this.ref, super.key});

  final RideStateActive state;
  final WidgetRef ref;

  @override
  State<_FocusMode> createState() => _FocusModeState();
}

class _FocusModeState extends State<_FocusMode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    unawaited(_pulse.repeat(reverse: true));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latest =
        widget.state.readings.isNotEmpty ? widget.state.readings.last : null;
    final power = latest?.power;
    final maxPower = widget.ref.watch(maxPowerProvider).asData?.value ?? 1500;
    final pct = power != null ? (power / maxPower).clamp(0.0, 1.2) : 0.0;
    final isInEffort = widget.state.autoLapState == AutoLapState.inEffort ||
        widget.state.autoLapState == AutoLapState.pendingEnd;
    final atMax = pct > 0.95;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: _bgColor(pct),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Pulse overlay when at max power
          if (atMax)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => ColoredBox(
                color: Colors.white.withValues(alpha: _pulse.value * 0.10),
              ),
            ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                children: [
                  _ModeSegmentedControl(ref: widget.ref),
                  _SensorStatusBar(ref: widget.ref),
                  const Spacer(),
                  if (isInEffort) ...[
                    Text(
                      _formatDuration(
                        widget.state.readings.length -
                            (widget.state.activeEffortStartOffset ?? 0),
                      ),
                      style:
                          const TextStyle(fontSize: 24, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: atMax
                            ? [
                                const Shadow(
                                  color: Colors.white54,
                                  blurRadius: 20,
                                ),
                                const Shadow(
                                  color: Colors.white30,
                                  blurRadius: 40,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(power?.round().toString() ?? '---'),
                    ),
                    const Text(
                      'watts',
                      style: TextStyle(fontSize: 18, color: Colors.white60),
                    ),
                  ] else ...[
                    if (widget.state.completedEfforts.isNotEmpty)
                      _LastEffortCard(
                        effort: widget.state.completedEfforts.last,
                      )
                    else
                      const Text(
                        'Waiting for effort…',
                        style: TextStyle(fontSize: 20, color: Colors.white54),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Recovery: '
                      '${_formatDuration(_recoverySeconds(widget.state))}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white54,
                      ),
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
                    onLap: () => widget.ref
                        .read(rideSessionProvider.notifier)
                        .manualLap(),
                    onStopConfirmed: () =>
                        widget.ref.read(rideSessionProvider.notifier).endRide(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _bgColor(double pct) {
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
// Chart mode — live MAP curve with historical band + record highlights
// ---------------------------------------------------------------------------

class _ChartMode extends StatelessWidget {
  const _ChartMode({
    required this.state,
    required this.ref,
    required this.isLandscape,
    super.key,
  });

  final RideStateActive state;
  final WidgetRef ref;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final historicalAsync = ref.watch(historicalRangeProvider);
    final histRange = historicalAsync.asData?.value;
    final liveCurve = state.liveEffortCurve;
    final completedEfforts = state.completedEfforts;
    final latest = state.readings.isNotEmpty ? state.readings.last : null;

    final chartData = _buildChartData(
      context: context,
      liveCurve: liveCurve,
      completedEfforts: completedEfforts,
      histRange: histRange,
    );

    return Scaffold(
      body: SafeArea(
        child: isLandscape
            ? Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: _ChartSidePanel(
                      state: state,
                      latest: latest,
                      liveCurve: liveCurve,
                      ref: ref,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                      child: LineChart(chartData),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _ModeSegmentedControl(ref: ref),
                  _ChartHeader(latest: latest),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: LineChart(chartData),
                    ),
                  ),
                  _KeyDurationStats(liveCurve: liveCurve),
                  _RideControls(
                    onLap: () =>
                        ref.read(rideSessionProvider.notifier).manualLap(),
                    onStopConfirmed: () =>
                        ref.read(rideSessionProvider.notifier).endRide(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  LineChartData _buildChartData({
    required BuildContext context,
    required MapCurve? liveCurve,
    required List<Effort> completedEfforts,
    required HistoricalRange? histRange,
  }) {
    final cs = Theme.of(context).colorScheme;
    final lines = <LineChartBarData>[];
    final betweenBars = <BetweenBarsData>[];

    // Historical band — best/worst envelope
    if (histRange != null) {
      lines
        ..add(
          _envelopeLine(
            histRange.best.map((r) => r.power).toList(),
            cs.onSurface.withValues(alpha: 0),
          ),
        )
        ..add(
          _envelopeLine(
            histRange.worst.map((r) => r.power).toList(),
            cs.onSurface.withValues(alpha: 0),
          ),
        );
      betweenBars.add(
        BetweenBarsData(
          fromIndex: 0,
          toIndex: 1,
          color: Colors.green.withValues(alpha: 0.12),
        ),
      );
    }

    // Previous session efforts — faded
    for (final effort in completedEfforts) {
      lines.add(
        _curveLine(
          effort.mapCurve.values,
          cs.onSurface.withValues(alpha: 0.25),
          strokeWidth: 1.5,
        ),
      );
    }

    // Live curve — bold gradient + record-breaking dots
    if (liveCurve != null) {
      lines.add(
        _liveCurveLine(
          liveCurve: liveCurve,
          histRange: histRange,
        ),
      );
    }

    // Compute Y max across all data
    var maxY = 100.0;
    if (histRange != null) {
      for (final r in histRange.best) {
        if (r.power > maxY) maxY = r.power;
      }
    }
    for (final e in completedEfforts) {
      for (final v in e.mapCurve.values) {
        if (v > maxY) maxY = v;
      }
    }
    if (liveCurve != null) {
      for (final v in liveCurve.values) {
        if (v > maxY) maxY = v;
      }
    }
    maxY = (maxY * 1.1).ceilToDouble();

    return LineChartData(
      lineBarsData: lines,
      betweenBarsData: betweenBars,
      minX: 1,
      maxX: 90,
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) => FlLine(
          color: cs.onSurface.withValues(alpha: 0.08),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 15,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}s',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      lineTouchData: const LineTouchData(enabled: false),
    );
  }

  LineChartBarData _envelopeLine(List<double> values, Color color) {
    return LineChartBarData(
      spots: List.generate(
        values.length,
        (i) => FlSpot((i + 1).toDouble(), values[i]),
      ),
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: 0,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(),
    );
  }

  LineChartBarData _curveLine(
    List<double> values,
    Color color, {
    double strokeWidth = 2,
  }) {
    return LineChartBarData(
      spots: List.generate(
        values.length,
        (i) => FlSpot((i + 1).toDouble(), values[i]),
      ),
      isCurved: true,
      curveSmoothness: 0.2,
      color: color,
      barWidth: strokeWidth,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(),
    );
  }

  LineChartBarData _liveCurveLine({
    required MapCurve liveCurve,
    required HistoricalRange? histRange,
  }) {
    return LineChartBarData(
      spots: List.generate(
        90,
        (i) => FlSpot((i + 1).toDouble(), liveCurve.values[i]),
      ),
      isCurved: true,
      curveSmoothness: 0.2,
      gradient: const LinearGradient(
        // amber instead of yellow: readable on both dark and light surfaces
        colors: [Colors.red, Colors.amber, Colors.blue],
      ),
      barWidth: 3,
      dotData: FlDotData(
        show: histRange != null,
        checkToShowDot: (spot, _) {
          if (histRange == null) return false;
          final idx = spot.x.toInt() - 1;
          if (idx < 0 || idx >= histRange.best.length) return false;
          // Show glow dot where live curve exceeds historical best (PR!)
          return spot.y > histRange.best[idx].power && spot.y > 0;
        },
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 5,
          color: Colors.amber,
          strokeColor: Colors.deepOrange,
          strokeWidth: 2,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.08),
            Colors.blue.withValues(alpha: 0.02),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chart mode sub-widgets
// ---------------------------------------------------------------------------

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.latest});

  final SensorReading? latest;

  @override
  Widget build(BuildContext context) {
    final power = latest?.power;
    final hr = latest?.heartRate;
    final cad = latest?.cadence;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _HeaderStat(
            value: power?.round().toString() ?? '---',
            label: 'W',
            large: true,
            color: cs.primary,
          ),
          _HeaderStat(
            value: hr?.toString() ?? '--',
            label: 'bpm',
            color: cs.error,
          ),
          _HeaderStat(
            value: cad?.round().toString() ?? '--',
            label: 'rpm',
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.value,
    required this.label,
    required this.color,
    this.large = false,
  });

  final String value;
  final String label;
  final bool large;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 28 : 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _KeyDurationStats extends StatelessWidget {
  const _KeyDurationStats({required this.liveCurve});

  final MapCurve? liveCurve;

  static const _durations = [1, 5, 15, 30, 60, 90];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _durations.map((d) {
          final val = liveCurve != null ? liveCurve!.values[d - 1] : 0.0;
          final label = d >= 60 ? '${d ~/ 60}m' : '${d}s';
          return Column(
            children: [
              Text(
                val > 0 ? val.round().toString() : '--',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ChartSidePanel extends StatelessWidget {
  const _ChartSidePanel({
    required this.state,
    required this.latest,
    required this.liveCurve,
    required this.ref,
  });

  final RideStateActive state;
  final SensorReading? latest;
  final MapCurve? liveCurve;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final power = latest?.power;
    final hr = latest?.heartRate;
    final cad = latest?.cadence;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            power?.round().toString() ?? '---',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
            ),
          ),
          Text(
            'watts',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (hr != null)
            Text(
              '$hr bpm',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          if (cad != null)
            Text(
              '${cad.round()} rpm',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          const Spacer(),
          _KeyDurationStats(liveCurve: liveCurve),
          const SizedBox(height: 8),
          _RideControls(
            onLap: () => ref.read(rideSessionProvider.notifier).manualLap(),
            onStopConfirmed: () =>
                ref.read(rideSessionProvider.notifier).endRide(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ride controls — LAP + long-press STOP
// ---------------------------------------------------------------------------

class _RideControls extends StatefulWidget {
  const _RideControls({required this.onLap, required this.onStopConfirmed});

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
        Tooltip(
          message: 'Manual lap (Space)',
          child: SizedBox(
            width: 72,
            height: 72,
            child: ElevatedButton(
              onPressed: widget.onLap,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.24),
              ),
              child: Text(
                'LAP',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'Stop ride (hold 1.5s or Esc)',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
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
                          color: Theme.of(context).colorScheme.error,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.24),
                        ),
                        Icon(
                          Icons.stop,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 32,
                        ),
                      ],
                    );
                  },
                ),
              ),
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
            tooltip: 'Focus mode (\u2190)',
          ),
          const SizedBox(width: 8),
          _ModeButton(
            label: 'Chart',
            selected: mode == RideMode.chart,
            onTap: () => ref.read(rideModeProvider.notifier).setChart(),
            tooltip: 'Chart mode (\u2192)',
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
    required this.tooltip,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.24)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
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
        ? Colors.green
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Tooltip(
      message: 'Manage devices (D)',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => showDeviceSheet(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(label, style: TextStyle(fontSize: 13, color: color)),
          ),
        ),
      ),
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
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Effort ${effort.effortNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.avgPower.round()} W avg  •  '
            '${s.peakPower.round()} W peak',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            _formatDuration(s.durationSeconds),
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
