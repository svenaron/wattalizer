import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/core/constants.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_override_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/theme_mode_provider.dart';
import 'package:wattalizer/presentation/screens/autolap_config_list_screen.dart';
import 'package:wattalizer/presentation/widgets/device_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const _AutoLapSection(),
            const Divider(),
            const _MaxPowerSection(),
            const Divider(),
            const _DevicesSection(),
            const Divider(),
            const _AppearanceSection(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto-Lap
// ---------------------------------------------------------------------------

class _AutoLapSection extends ConsumerWidget {
  const _AutoLapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(autoLapConfigProvider);

    final subtitle = configAsync.when(
      loading: () => 'Loading...',
      error: (_, __) => 'Error',
      data: (cfg) => cfg.name,
    );

    return ListTile(
      leading: const Icon(Icons.auto_fix_high),
      title: const Text('Auto-Lap Configuration'),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const AutoLapConfigListScreen(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Max Power
// ---------------------------------------------------------------------------

class _MaxPowerSection extends ConsumerStatefulWidget {
  const _MaxPowerSection();

  @override
  ConsumerState<_MaxPowerSection> createState() => _MaxPowerSectionState();
}

class _MaxPowerSectionState extends ConsumerState<_MaxPowerSection> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final override = ref.read(maxPowerOverrideProvider);
    if (override != null) {
      _ctrl.text = override.round().toString();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final override = ref.watch(maxPowerOverrideProvider);
    final maxPowerAsync = ref.watch(maxPowerProvider);
    final isManual = override != null;

    final autoValue = maxPowerAsync.when(
      loading: () => '...',
      error: (_, __) => '?',
      data: (v) => '${v.round()} W',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.bolt),
          title: const Text('Max Power'),
          subtitle: Text(
            isManual ? 'Manual: ${override.round()} W' : 'Auto: $autoValue',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Auto')),
                  ButtonSegment(value: true, label: Text('Manual')),
                ],
                selected: {isManual},
                onSelectionChanged: (s) {
                  if (s.first) {
                    // Switch to manual with current auto value
                    final current = maxPowerAsync.value;
                    final val = current ?? kDefaultMaxPowerWatts;
                    _ctrl.text = val.round().toString();
                    unawaited(
                      ref.read(maxPowerOverrideProvider.notifier).set(val),
                    );
                  } else {
                    unawaited(
                      ref.read(maxPowerOverrideProvider.notifier).set(null),
                    );
                    _ctrl.clear();
                  }
                },
              ),
              if (isManual) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      suffixText: 'W',
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      final val = double.tryParse(v);
                      if (val != null && val > 0) {
                        unawaited(
                          ref.read(maxPowerOverrideProvider.notifier).set(val),
                        );
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Devices
// ---------------------------------------------------------------------------

class _DevicesSection extends StatelessWidget {
  const _DevicesSection();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bluetooth),
      title: const Text('Manage Devices'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showDeviceSheet(context),
    );
  }
}

// ---------------------------------------------------------------------------
// Appearance
// ---------------------------------------------------------------------------

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ListTile(leading: Icon(Icons.palette), title: Text('Appearance')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
