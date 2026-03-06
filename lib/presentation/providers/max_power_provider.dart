import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/services/historical_range_calculator.dart';
import 'package:wattalizer/presentation/providers/max_power_override_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// Max power for Focus Mode background colour scaling.
/// If a manual override is set, returns that. Otherwise auto-derived
/// from the all-time 1s best across all effort curves.
/// Falls back to 1500W on first launch (no rides yet).
/// keepAlive — invalidated by rideSessionProvider when a new ride is saved.
// (brackets omitted: importing ride_session_provider here would be circular)
final FutureProvider<double> maxPowerProvider = FutureProvider<double>((
  ref,
) async {
  final override = ref.watch(maxPowerOverrideProvider);
  if (override != null) return override;
  final repo = ref.read(rideRepositoryProvider);
  final curves = await repo.getAllEffortCurves();
  if (curves.isEmpty) return 1500.0;
  final range = HistoricalRangeCalculator().compute(curves);
  return range.best[0].power; // index 0 = 1s best
});
