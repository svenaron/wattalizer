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
