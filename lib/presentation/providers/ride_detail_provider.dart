import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// Loads a single ride by ID, including tags, efforts, and map curves.
/// autoDispose + family — each detail screen gets its own cached instance.
// ignore: specify_nonobvious_property_types
final rideDetailProvider = FutureProvider.autoDispose.family<Ride?, String>((
  ref,
  rideId,
) async {
  final repo = ref.read(rideRepositoryProvider);
  return repo.getRide(rideId);
});
