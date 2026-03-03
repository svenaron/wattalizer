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
