enum AutoLapState { idle, pendingStart, inEffort, pendingEnd }

sealed class AutoLapEvent {}

class EffortStartedEvent extends AutoLapEvent {
  EffortStartedEvent({
    required this.startOffset,
    required this.isManual,
    required this.preEffortBaseline,
  });
  final int startOffset;
  final bool isManual;
  final double preEffortBaseline;
}

class EffortEndedEvent extends AutoLapEvent {
  EffortEndedEvent({
    required this.startOffset,
    required this.endOffset,
    required this.isManual,
    required this.wasTooShort,
    required this.preEffortBaseline,
    required this.peakTrailingAvg,
  });
  final int startOffset;
  final int endOffset;
  final bool isManual;
  final bool wasTooShort;
  final double preEffortBaseline;
  final double peakTrailingAvg;
}
