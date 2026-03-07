import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/core/constants.dart';
import 'package:wattalizer/domain/events/autolap_events.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/screens/ride_screen.dart';

// ---------------------------------------------------------------------------
// Focus mode — animated background + pulse at >95%
// ---------------------------------------------------------------------------

class RideFocusMode extends StatefulWidget {
  const RideFocusMode({required this.state, required this.ref, super.key});

  final RideStateActive state;
  final WidgetRef ref;

  @override
  State<RideFocusMode> createState() => _RideFocusModeState();
}

class _RideFocusModeState extends State<RideFocusMode>
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
    final maxPower = widget.ref.watch(maxPowerProvider).asData?.value ??
        kDefaultMaxPowerWatts;
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
                  RideModeSegmentedControl(ref: widget.ref),
                  RideSensorStatusBar(ref: widget.ref),
                  const Spacer(),
                  if (isInEffort) ...[
                    Text(
                      formatRideDuration(
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
                      RideLastEffortCard(
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
                      '${formatRideDuration(recoverySeconds(widget.state))}',
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
                        SmallStat(
                          label: 'HR',
                          value: latest?.heartRate?.toString() ?? '--',
                        ),
                        SmallStat(
                          label: 'RPM',
                          value: latest?.cadence?.round().toString() ?? '--',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  RideControls(
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
// SmallStat — only used by RideFocusMode
// ---------------------------------------------------------------------------

class SmallStat extends StatelessWidget {
  const SmallStat({
    required this.label,
    required this.value,
    super.key,
  });

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
