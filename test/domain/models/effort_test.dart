import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/effort.dart';
import 'package:wattalizer/domain/models/effort_summary.dart';
import 'package:wattalizer/domain/models/map_curve.dart';

void main() {
  group('EffortType', () {
    test('has auto and manual values', () {
      expect(
        EffortType.values,
        containsAll([EffortType.auto, EffortType.manual]),
      );
    });
  });

  group('Effort', () {
    test('constructs with all required fields', () {
      final effort = Effort(
        id: 'e1',
        rideId: 'r1',
        effortNumber: 1,
        startOffset: 10,
        endOffset: 25,
        type: EffortType.auto,
        summary: _emptySummary(),
        mapCurve: _emptyMapCurve('e1'),
      );
      expect(effort.id, 'e1');
      expect(effort.effortNumber, 1);
      expect(effort.startOffset, 10);
      expect(effort.endOffset, 25);
      expect(effort.type, EffortType.auto);
    });
  });
}

EffortSummary _emptySummary() => const EffortSummary(
      durationSeconds: 15,
      avgPower: 0,
      peakPower: 0,
      totalKilojoules: 0,
    );

MapCurve _emptyMapCurve(String id) => MapCurve(
      entityId: id,
      values: List<double>.filled(90, 0),
      flags: List.generate(90, (_) => const MapCurveFlags()),
      computedAt: DateTime(2026, 3),
    );
