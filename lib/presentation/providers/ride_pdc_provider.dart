import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// Loads the ride-level PDC (power duration curve) for a single ride.
/// autoDispose — released when no widget needs it (e.g. card scrolled off).
// ignore: specify_nonobvious_property_types
final ridePdcProvider =
    FutureProvider.autoDispose.family<MapCurve?, String>((ref, rideId) async {
  final repo = ref.read(rideRepositoryProvider);
  return repo.getRidePdc(rideId);
});
