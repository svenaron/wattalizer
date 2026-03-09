import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/domain/models/athlete_profile.dart';
import 'package:wattalizer/presentation/providers/active_athlete_provider.dart';
import 'package:wattalizer/presentation/providers/athlete_list_provider.dart';
import 'package:wattalizer/presentation/providers/athlete_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ride_session_provider.dart';

class AthleteListScreen extends ConsumerWidget {
  const AthleteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletesAsync = ref.watch(athleteListProvider);
    final activeId = ref.watch(activeAthleteProvider);
    final rideState = ref.watch(rideSessionProvider);
    final isRiding = rideState is RideStateActive;

    return Scaffold(
      appBar: AppBar(title: const Text('Athletes')),
      body: athletesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (athletes) => ListView.builder(
          itemCount: athletes.length,
          itemBuilder: (context, index) {
            final athlete = athletes[index];
            final isActive = athlete.id == activeId;
            return Dismissible(
              key: ValueKey(athlete.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                if (isRiding) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cannot delete athlete during a ride',
                      ),
                    ),
                  );
                  return false;
                }
                return _confirmDelete(context, athlete.name);
              },
              onDismissed: (_) =>
                  _deleteAthlete(context, ref, athlete, activeId),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                leading: isActive
                    ? const Icon(
                        Icons.check,
                        color: Colors.green,
                      )
                    : const SizedBox(width: 24),
                title: Text(athlete.name),
                onTap: isRiding
                    ? null
                    : () {
                        unawaited(
                          ref
                              .read(activeAthleteProvider.notifier)
                              .setAthlete(athlete.id),
                        );
                        Navigator.pop(context);
                      },
                onLongPress: () => _renameAthlete(context, ref, athlete),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createAthlete(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    String name,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Athlete'),
        content: Text(
          'Delete "$name"? All their rides will be '
          'permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteAthlete(
    BuildContext context,
    WidgetRef ref,
    AthleteProfile athlete,
    String activeId,
  ) async {
    try {
      await ref.read(athleteRepositoryProvider).deleteAthlete(athlete.id);
      ref.invalidate(athleteListProvider);
      // If deleted athlete was active, switch to first remaining
      if (athlete.id == activeId) {
        final remaining =
            await ref.read(athleteRepositoryProvider).getAthletes();
        if (remaining.isNotEmpty) {
          await ref
              .read(activeAthleteProvider.notifier)
              .setAthlete(remaining.first.id);
        }
      }
    } on AthleteDeleteRefused {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete the last athlete'),
          ),
        );
      }
    }
  }

  Future<void> _renameAthlete(
    BuildContext context,
    WidgetRef ref,
    AthleteProfile athlete,
  ) async {
    final ctrl = TextEditingController(text: athlete.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Athlete'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) {
      await ref
          .read(athleteRepositoryProvider)
          .updateAthlete(athlete.copyWith(name: name));
      ref.invalidate(athleteListProvider);
    }
  }

  Future<void> _createAthlete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Athlete'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) {
      final id = 'athlete_${DateTime.now().millisecondsSinceEpoch}';
      final athlete = AthleteProfile(
        id: id,
        name: name,
        createdAt: DateTime.now(),
      );
      await ref.read(athleteRepositoryProvider).saveAthlete(athlete);
      ref.invalidate(athleteListProvider);
    }
  }
}
