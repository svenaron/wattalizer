import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/screens/history_screen.dart';
import 'package:wattalizer/presentation/screens/pdc_screen.dart';
import 'package:wattalizer/presentation/screens/ride_screen.dart';
import 'package:wattalizer/presentation/screens/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideSessionProvider);

    // During active ride, show RideScreen full-screen with no nav bar.
    if (rideState is RideStateActive) {
      return const RideScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          RideScreen(),
          HistoryScreen(),
          PdcScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pedal_bike_outlined),
            selectedIcon: Icon(Icons.pedal_bike),
            label: 'Ride',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'PDC',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
