import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RideMode { focus, chart }

/// Controls the Focus ↔ Chart toggle on the active ride screen.
/// keepAlive — survives navigation during an active ride.
final rideModeProvider =
    NotifierProvider<RideModeNotifier, RideMode>(RideModeNotifier.new);

class RideModeNotifier extends Notifier<RideMode> {
  @override
  RideMode build() => RideMode.focus;

  void toggle() =>
      state = state == RideMode.focus ? RideMode.chart : RideMode.focus;

  void setFocus() => state = RideMode.focus;
  void setChart() => state = RideMode.chart;
}
