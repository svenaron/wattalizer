import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'max_power_override';

/// Manual max-power override. null = auto mode (derived from data).
final maxPowerOverrideProvider =
    NotifierProvider<MaxPowerOverrideNotifier, double?>(
  MaxPowerOverrideNotifier.new,
);

class MaxPowerOverrideNotifier extends Notifier<double?> {
  @override
  double? build() {
    unawaited(_load());
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_key);
    if (value != null) state = value;
  }

  Future<void> set(double? value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_key);
    } else {
      await prefs.setDouble(_key, value);
    }
  }
}
