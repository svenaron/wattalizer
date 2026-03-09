import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wattalizer/presentation/providers/active_athlete_provider.dart';

import '../fixtures/test_container.dart';

Future<void> _pump() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  group('activeAthleteProvider', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await _pump();
      container.dispose();
    });

    test('initial state is defaultAthleteId', () {
      container = createTestContainer();
      expect(
        container.read(activeAthleteProvider),
        defaultAthleteId,
      );
    });

    test('setAthlete persists to SharedPreferences', () async {
      container = createTestContainer();
      await container.read(activeAthleteProvider.notifier).setAthlete('alice');
      expect(container.read(activeAthleteProvider), 'alice');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('active_athlete_id'), 'alice');
    });

    test('loads persisted value on rebuild', () async {
      container = createTestContainer();
      await container.read(activeAthleteProvider.notifier).setAthlete('alice');

      container
        ..invalidate(activeAthleteProvider)
        ..read(activeAthleteProvider);
      await _pump();

      expect(container.read(activeAthleteProvider), 'alice');
    });
  });
}
