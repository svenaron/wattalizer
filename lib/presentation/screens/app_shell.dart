import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/presentation/layout/breakpoints.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';
import 'package:wattalizer/presentation/screens/history_screen.dart';
import 'package:wattalizer/presentation/screens/pdc_screen.dart';
import 'package:wattalizer/presentation/screens/ride_screen.dart';
import 'package:wattalizer/presentation/screens/settings_screen.dart';
import 'package:wattalizer/presentation/utils/import_utils.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _ch = MethodChannel('wattalizer/file_intents');

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _ch.setMethodCallHandler(_onFileIntent);
    unawaited(_checkPendingFile());
  }

  @override
  void dispose() {
    _ch.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _checkPendingFile() async {
    try {
      final path = await _ch.invokeMethod<String>('getPendingFile');
      if (path != null && mounted) await _handleFile(path);
    } on PlatformException {
      // Not implemented on this platform — ignore.
    }
  }

  Future<void> _onFileIntent(MethodCall call) async {
    if (call.method == 'openFile' && mounted) {
      await _handleFile(call.arguments as String);
    }
  }

  Future<void> _handleFile(String path) async {
    setState(() => _selectedIndex = 1); // navigate to History
    final results = await importFileFromPath(ref, path);
    if (mounted) showImportResultsDialog(context, results);
  }

  static const _screens = <Widget>[
    RideScreen(),
    HistoryScreen(),
    PdcScreen(),
    SettingsScreen(),
  ];

  static const _destinations = <NavigationDestination>[
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
  ];

  static const _railDestinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.pedal_bike_outlined),
      selectedIcon: Icon(Icons.pedal_bike),
      label: Text('Ride'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: Text('History'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.show_chart_outlined),
      selectedIcon: Icon(Icons.show_chart),
      label: Text('PDC'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final rideState = ref.watch(rideSessionProvider);

    // During active ride, show RideScreen full-screen with no nav.
    if (rideState is RideStateActive) {
      return const RideScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = layoutSizeOf(constraints.maxWidth);

        final Widget child;
        if (layout == LayoutSize.compact) {
          child = Scaffold(
            key: const ValueKey('compact'),
            body: IndexedStack(index: _selectedIndex, children: _screens),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              destinations: _destinations,
            ),
          );
        } else {
          // Medium or Expanded: NavigationRail on the left.
          child = Scaffold(
            key: const ValueKey('rail'),
            body: Row(
              children: [
                NavigationRail(
                  minWidth: 64,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: _railDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _screens,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: child,
        );
      },
    );
  }
}
