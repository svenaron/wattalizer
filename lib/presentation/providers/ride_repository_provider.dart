import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';

/// Provides the [RideRepository] singleton.
/// **Must be overridden** in [ProviderScope] before use.
/// The database is opened in [main()] and injected as a provider override,
/// ensuring async DB setup is complete before any provider reads it.
final rideRepositoryProvider = Provider<RideRepository>(
  (ref) => throw UnimplementedError(
    'rideRepositoryProvider must be overridden in ProviderScope',
  ),
);
