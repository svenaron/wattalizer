// App entry point — ProviderScope wraps MaterialApp
// See docs/spec.md §2 for architecture overview
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/data/debug/debug_seeder.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/providers/theme_mode_provider.dart';
import 'package:wattalizer/presentation/screens/app_shell.dart';

void main() async {
  // Suppress a known Flutter macOS embedding bug where modifier keys (Meta/Cmd)
  // get stuck in "pressed" state after the app loses focus mid-keypress (e.g.
  // Cmd+Tab to another app). Flutter never receives the key-up, so when Cmd is
  // pressed again on return it fires an assertion in HardwareKeyboard.
  //
  // The assertion only fires in debug builds and the app recovers correctly, so
  // this is purely console noise. Filtering by string is fragile but it's the
  // only app-level workaround available without using @visibleForTesting APIs.
  // Track: https://github.com/flutter/flutter/issues/131674
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isStuckKeyAssertion = details.exception is AssertionError &&
        details.exceptionAsString().contains('KeyDownEvent is dispatched');
    if (!isStuckKeyAssertion) originalOnError?.call(details);
  };

  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();
  final repo = LocalRideRepository(db);

  if (kDebugMode) {
    final count = await repo.getRideCount();
    if (count == 0) {
      debugPrint('[DebugSeeder] Empty database — seeding...');
      await DebugSeeder(repo).seed();
      debugPrint('[DebugSeeder] Done.');
    }
  }

  runApp(
    ProviderScope(
      overrides: [rideRepositoryProvider.overrideWithValue(repo)],
      child: const SprintPowerAnalyzerApp(),
    ),
  );
}

class SprintPowerAnalyzerApp extends ConsumerWidget {
  const SprintPowerAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Wattalizer',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
