// App entry point — ProviderScope wraps MaterialApp
// See docs/spec.md §2 for architecture overview
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/data/database/database.dart';
import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/screens/ride_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await AppDatabase.open();
  final repo = LocalRideRepository(db);
  runApp(
    ProviderScope(
      overrides: [rideRepositoryProvider.overrideWithValue(repo)],
      child: const SprintPowerAnalyzerApp(),
    ),
  );
}

class SprintPowerAnalyzerApp extends StatelessWidget {
  const SprintPowerAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wattalizer',
      theme: ThemeData.dark(useMaterial3: true),
      home: const RideScreen(),
    );
  }
}
