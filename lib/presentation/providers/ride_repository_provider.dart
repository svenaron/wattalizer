import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/data/database/local_ride_repository.dart';
import 'package:wattalizer/data/database/scoped_ride_repository.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/presentation/providers/active_athlete_provider.dart';

/// Internal hook for the raw LocalRideRepository.
/// **Must be overridden** in [ProviderScope] before use.
final localRideRepositoryProvider = Provider<LocalRideRepository>(
  (ref) => throw UnimplementedError(
    'localRideRepositoryProvider must be overridden in ProviderScope',
  ),
);

/// Public provider — derived, scoped to the active athlete.
/// Existing tests using [rideRepositoryProvider.overrideWithValue(fakeRepo)]
/// continue to work: Riverpod overrides take precedence over the derived body.
final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final athleteId = ref.watch(activeAthleteProvider);
  final inner = ref.watch(localRideRepositoryProvider);
  return ScopedRideRepository(inner, athleteId);
});
