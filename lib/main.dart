// App entry point — ProviderScope wraps MaterialApp
// See docs/spec-v1.1.md §2 for architecture overview
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

void main() {
  runApp(const ProviderScope(child: SprintPowerAnalyzerApp()));
}

class SprintPowerAnalyzerApp extends StatelessWidget {
  const SprintPowerAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sprint Power Analyzer",
      theme: ThemeData.dark(useMaterial3: true),
      // home: const RideScreen(),
    );
  }
}
