import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/screens/autolap_config_list_screen.dart';

import '../fixtures/fake_repository.dart';

const _standing = AutoLapConfig(
  id: 1,
  name: 'Standing Start',
  startDeltaWatts: 350,
  endDeltaWatts: 250,
  isDefault: true,
);
const _flying = AutoLapConfig(
  id: 2,
  name: 'Flying Start',
  startDeltaWatts: 150,
  endDeltaWatts: 150,
);

void main() {
  late FakeRepository repo;

  setUp(() {
    repo = FakeRepository()
      ..autoLapConfigsToReturn = [_standing, _flying]
      ..defaultConfigToReturn = _standing;
  });

  Widget buildScreen() => ProviderScope(
        overrides: [rideRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: AutoLapConfigListScreen()),
      );

  group('AutoLapConfigListScreen', () {
    testWidgets('renders all config names', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.text('Standing Start'), findsOneWidget);
      expect(find.text('Flying Start'), findsOneWidget);
    });

    testWidgets('tapping row opens edit screen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.text('Standing Start'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Config'), findsOneWidget);
    });

    testWidgets('default config shows check_circle icon', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('tapping leading icon on non-default saves it as default',
        (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.radio_button_unchecked));
      await tester.pump();

      expect(repo.savedAutoLapConfigs, isNotEmpty);
      expect(repo.savedAutoLapConfigs.last.name, 'Flying Start');
      expect(repo.savedAutoLapConfigs.last.isDefault, isTrue);
    });

    testWidgets('default config leading icon is not tappable', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pump();

      expect(repo.savedAutoLapConfigs, isEmpty);
    });
  });
}
