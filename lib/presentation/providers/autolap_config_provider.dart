import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// Loads the default [AutoLapConfig] from the repository on startup.
/// keepAlive — needed by rideSessionProvider at all times.
// (brackets omitted: importing ride_session_provider here would be circular)
final autoLapConfigProvider = FutureProvider<AutoLapConfig>((ref) async {
  final repo = ref.read(rideRepositoryProvider);
  return repo.getDefaultConfig();
});

/// Loads all saved [AutoLapConfig]s sorted by name.
/// keepAlive — consistent with autoLapConfigProvider.
final autoLapConfigListProvider =
    FutureProvider<List<AutoLapConfig>>((ref) async {
  final repo = ref.read(rideRepositoryProvider);
  final configs = await repo.getAutoLapConfigs();
  configs.sort((a, b) => a.name.compareTo(b.name));
  return configs;
});
