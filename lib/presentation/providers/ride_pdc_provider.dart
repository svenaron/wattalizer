import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/map_curve.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// Computes the ride-level PDC on demand by taking the max power at each
/// duration across all stored effort curves.
/// autoDispose — released when no widget needs it (e.g. card scrolled off).
// ignore: specify_nonobvious_property_types
final ridePdcProvider =
    FutureProvider.autoDispose.family<MapCurve?, String>((ref, rideId) async {
  final repo = ref.read(rideRepositoryProvider);
  final efforts = await repo.getEfforts(rideId);
  if (efforts.isEmpty) return null;

  final values = List<double>.filled(90, 0);
  final flags = List<MapCurveFlags>.filled(90, const MapCurveFlags());

  for (final effort in efforts) {
    final curve = effort.mapCurve;
    for (var i = 0; i < 90; i++) {
      if (curve.values[i] > values[i]) {
        values[i] = curve.values[i];
        flags[i] = curve.flags[i];
      }
    }
  }

  // Enforce monotonicity (sweep right-to-left)
  for (var i = 88; i >= 0; i--) {
    if (values[i] < values[i + 1]) {
      values[i] = values[i + 1];
    }
  }

  if (values.every((v) => v == 0.0)) return null;

  return MapCurve(
    entityId: rideId,
    values: values,
    flags: flags,
    computedAt: DateTime.now().toUtc(),
  );
});
