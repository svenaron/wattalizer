import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';

enum EffortType { auto, manual }

class Effort {
  const Effort({
    required this.id,
    required this.rideId,
    required this.effortNumber,
    required this.startOffset,
    required this.endOffset,
    required this.type,
    required this.summary,
    required this.mapCurve,
  });

  final String id;
  final String rideId;
  final int effortNumber;
  final int startOffset;
  final int endOffset;
  final EffortType type;
  final EffortSummary summary;
  final MapCurve mapCurve;
}
