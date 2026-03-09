import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wattalizer/presentation/providers/active_athlete_provider.dart';

const _legacyKey = 'max_power_override';
String _keyFor(String athleteId) => 'max_power_override_$athleteId';

/// Manual max-power override. null = auto mode (derived from data).
final maxPowerOverrideProvider =
    NotifierProvider<MaxPowerOverrideNotifier, double?>(
  MaxPowerOverrideNotifier.new,
);

class MaxPowerOverrideNotifier extends Notifier<double?> {
  @override
  double? build() {
    final athleteId = ref.watch(activeAthleteProvider);
    unawaited(_load(athleteId));
    return null;
  }

  Future<void> _load(String athleteId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(athleteId);
    // Migrate legacy keyless value once (only for the default athlete)
    if (athleteId == defaultAthleteId && !prefs.containsKey(key)) {
      final legacy = prefs.getDouble(_legacyKey);
      if (legacy != null) {
        await prefs.setDouble(key, legacy);
        await prefs.remove(_legacyKey);
      }
    }
    final value = prefs.getDouble(key);
    if (value != null) state = value;
  }

  Future<void> set(double? value) async {
    state = value;
    final athleteId = ref.read(activeAthleteProvider);
    final prefs = await SharedPreferences.getInstance();
    final key = _keyFor(athleteId);
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setDouble(key, value);
    }
  }
}
