import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyPower = 'show_power_trace';
const _keyCadence = 'show_cadence_trace';
const _keyRollup = 'rollup_seconds';

final chartVisibilityProvider =
    NotifierProvider<ChartVisibilityNotifier, ChartVisibility>(
  ChartVisibilityNotifier.new,
);

class ChartVisibility {
  const ChartVisibility({
    this.showPower = false,
    this.showCadence = false,
    this.rollupSeconds = 0,
  });
  final bool showPower;
  final bool showCadence;
  final int rollupSeconds;

  ChartVisibility copyWith({
    bool? showPower,
    bool? showCadence,
    int? rollupSeconds,
  }) =>
      ChartVisibility(
        showPower: showPower ?? this.showPower,
        showCadence: showCadence ?? this.showCadence,
        rollupSeconds: rollupSeconds ?? this.rollupSeconds,
      );
}

class ChartVisibilityNotifier extends Notifier<ChartVisibility> {
  @override
  ChartVisibility build() {
    unawaited(_load());
    return const ChartVisibility();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ChartVisibility(
      showPower: prefs.getBool(_keyPower) ?? false,
      showCadence: prefs.getBool(_keyCadence) ?? false,
      rollupSeconds: prefs.getInt(_keyRollup) ?? 0,
    );
  }

  Future<void> togglePower() async {
    final next = !state.showPower;
    state = state.copyWith(showPower: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPower, next);
  }

  Future<void> toggleCadence() async {
    final next = !state.showCadence;
    state = state.copyWith(showCadence: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCadence, next);
  }

  Future<void> setRollup(int seconds) async {
    state = state.copyWith(rollupSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRollup, seconds);
  }
}
