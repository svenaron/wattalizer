import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';
import 'package:wattalizer/presentation/screens/autolap_config_edit_screen.dart';

class AutoLapConfigListScreen extends ConsumerWidget {
  const AutoLapConfigListScreen({super.key});

  void _invalidateBoth(WidgetRef ref) {
    ref
      ..invalidate(autoLapConfigProvider)
      ..invalidate(autoLapConfigListProvider);
  }

  Future<void> _setDefault(
    WidgetRef ref,
    AutoLapConfig config,
  ) async {
    final repo = ref.read(rideRepositoryProvider);
    await repo.saveAutoLapConfig(config.copyWith(isDefault: true));
    _invalidateBoth(ref);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AutoLapConfig config,
    int totalCount,
  ) async {
    if (totalCount <= 1) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete config?'),
        content: Text('Delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final repo = ref.read(rideRepositoryProvider);
    await repo.deleteAutoLapConfig(config.id!);
    _invalidateBoth(ref);
  }

  Future<void> _reAddDefaults(WidgetRef ref) async {
    final repo = ref.read(rideRepositoryProvider);
    await repo.saveAutoLapConfig(AutoLapConfig.standingStart());
    await repo.saveAutoLapConfig(AutoLapConfig.flyingStart());
    await repo.saveAutoLapConfig(AutoLapConfig.broad());
    _invalidateBoth(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(autoLapConfigListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Lap Configs'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 're_add') unawaited(_reAddDefaults(ref));
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 're_add',
                child: Text('Re-add defaults'),
              ),
            ],
          ),
        ],
      ),
      body: configsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (configs) {
          if (configs.isEmpty) {
            return const Center(child: Text('No configs. Use + to add one.'));
          }
          return ListView.builder(
            itemCount: configs.length,
            itemBuilder: (context, i) {
              final cfg = configs[i];
              final peak = cfg.minPeakWatts;
              return ListTile(
                leading: IconButton(
                  tooltip: cfg.isDefault ? 'Default' : 'Set as default',
                  icon: cfg.isDefault
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked),
                  onPressed: cfg.isDefault ? null : () => _setDefault(ref, cfg),
                ),
                title: Text(cfg.name),
                subtitle: Text(
                  '↑${cfg.startDeltaWatts.toStringAsFixed(0)}W '
                  '↓${cfg.endDeltaWatts.toStringAsFixed(0)}W '
                  '${peak != null ? 'peak≥${peak.toStringAsFixed(0)}W' : ''}',
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => AutoLapConfigEditScreen(config: cfg),
                    ),
                  );
                  _invalidateBoth(ref);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: configs.length <= 1 ? Colors.grey : null,
                      ),
                      onPressed: configs.length <= 1
                          ? null
                          : () => _delete(context, ref, cfg, configs.length),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const AutoLapConfigEditScreen(config: null),
            ),
          );
          _invalidateBoth(ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
