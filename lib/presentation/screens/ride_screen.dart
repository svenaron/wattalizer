import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/core/constants.dart';
import 'package:wattalizer/domain/interfaces/ble_service.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/presentation/layout/breakpoints.dart';
import 'package:wattalizer/presentation/layout/keyboard_shortcuts.dart';
import 'package:wattalizer/presentation/providers/ble_connection_provider.dart';
import 'package:wattalizer/presentation/providers/ride_mode_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/screens/ride_screen_chart.dart';
import 'package:wattalizer/presentation/screens/ride_screen_focus.dart';
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
                    RideSensorStatusBar(ref: ref),
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
                        child: RideFocusMode(state: widget.state, ref: ref),
                      ),
                      Expanded(
                        flex: 3,
                        child: RideChartMode(
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
                    child = RideChartMode(
                      key: const ValueKey('landscape'),
                      state: widget.state,
                      ref: ref,
                      isLandscape: true,
                    );
                  } else {
                    final mode = ref.watch(rideModeProvider);
                    child = mode == RideMode.focus
                        ? RideFocusMode(
                            key: const ValueKey('focus'),
                            state: widget.state,
                            ref: ref,
                          )
                        : RideChartMode(
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
// Ride controls — LAP + long-press STOP
// ---------------------------------------------------------------------------

class RideControls extends StatefulWidget {
  const RideControls({
    required this.onLap,
    required this.onStopConfirmed,
    super.key,
  });

  final VoidCallback onLap;
  final VoidCallback onStopConfirmed;

  @override
  State<RideControls> createState() => _RideControlsState();
}

class _RideControlsState extends State<RideControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stopProgress;

  @override
  void initState() {
    super.initState();
    _stopProgress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kStopButtonHoldMs),
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
// Shared helper widgets
// ---------------------------------------------------------------------------

class RideModeSegmentedControl extends StatelessWidget {
  const RideModeSegmentedControl({required this.ref, super.key});

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

class RideSensorStatusBar extends StatelessWidget {
  const RideSensorStatusBar({required this.ref, super.key});

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

class RideLastEffortCard extends StatelessWidget {
  const RideLastEffortCard({required this.effort, super.key});

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
            formatRideDuration(s.durationSeconds),
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
              '${formatRideDuration(s.activeDurationSeconds)}',
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

String formatRideDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

int recoverySeconds(RideStateActive state) {
  if (state.completedEfforts.isEmpty) return 0;
  final lastEnd = state.completedEfforts.last.endOffset;
  return state.readings.length - lastEnd;
}
