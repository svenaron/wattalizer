import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/export_service_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_override_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';
import 'package:wattalizer/presentation/providers/theme_mode_provider.dart';
import 'package:wattalizer/presentation/screens/autolap_config_screen.dart';
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
            const _ImportSection(),
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
        MaterialPageRoute<void>(builder: (_) => const AutoLapConfigScreen()),
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

    if (isManual && _ctrl.text.isEmpty) {
      _ctrl.text = override.round().toString();
    }

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
                    final val = current ?? 1500.0;
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
// Import
// ---------------------------------------------------------------------------

class _ImportSection extends ConsumerStatefulWidget {
  const _ImportSection();

  @override
  ConsumerState<_ImportSection> createState() => _ImportSectionState();
}

class _ImportSectionState extends ConsumerState<_ImportSection> {
  bool _importing = false;

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['tcx', 'zip'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _importing = true);

    try {
      final export = ref.read(exportServiceProvider);
      final configAsync = ref.read(autoLapConfigProvider);
      final config = configAsync.value ?? AutoLapConfig.shortSprint();
      final ioFile = File(file.path!);
      final ext = file.path!.split('.').last.toLowerCase();

      if (ext == 'zip') {
        final results = await export.importZip(ioFile, config);
        if (mounted) {
          _showImportResults(
            results.where((r) => r.ride != null).length,
            results.where((r) => r.ride == null).length,
          );
        }
      } else {
        await export.importTcx(ioFile, config);
        if (mounted) _showImportResults(1, 0);
      }
      ref.invalidate(rideListProvider);
    } on Exception catch (e) {
      if (mounted) _showImportResults(0, 1, error: '$e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _showImportResults(int imported, int errors, {String? error}) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Import Results'),
          content: Text(
            error != null
                ? 'Error: $error'
                : '$imported imported, $errors errors',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.file_upload),
      title: const Text('Import Rides'),
      subtitle: const Text('TCX or ZIP files'),
      trailing: _importing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _importing ? null : _import,
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
