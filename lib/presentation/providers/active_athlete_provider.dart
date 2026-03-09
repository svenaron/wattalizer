import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'active_athlete_id';
const defaultAthleteId = 'me';

final activeAthleteProvider = NotifierProvider<ActiveAthleteNotifier, String>(
  ActiveAthleteNotifier.new,
);

class ActiveAthleteNotifier extends Notifier<String> {
  @override
  String build() {
    unawaited(_load());
    return defaultAthleteId;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) state = value;
  }

  Future<void> setAthlete(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }
}
