// TODO: Implement abstract RideRepository interface — see S1.2

import 'package:wattalizer/domain/models/map_curve.dart';

/// Carries a MapCurve together with its provenance (which effort/ride it came from).
/// Used by HistoricalRangeCalculator and RideRepository.getAllEffortCurves().
class MapCurveWithProvenance {
  const MapCurveWithProvenance({
    required this.effortId,
    required this.rideId,
    required this.rideDate,
    required this.effortNumber,
    required this.curve,
  });
  final String effortId;
  final String rideId;
  final DateTime rideDate;
  final int effortNumber;
  final MapCurve curve;
}
