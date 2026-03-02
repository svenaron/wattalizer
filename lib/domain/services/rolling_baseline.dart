/// A rolling average over a fixed-size window of power readings.
/// Supports freeze (stop updating), unfreeze (resume), and clear (reset).
class RollingBaseline {
  RollingBaseline(this.windowSize);
  final int windowSize;
  final List<double> _buffer = [];
  int _writeIndex = 0;
  bool _isFull = false;
  bool _frozen = false;

  /// Add a reading. Ignored if frozen or value is null.
  void add(double? value) {
    if (_frozen || value == null) return;
    if (_buffer.length < windowSize) {
      _buffer.add(value);
    } else {
      _buffer[_writeIndex] = value;
    }
    _writeIndex = (_writeIndex + 1) % windowSize;
    if (_buffer.length == windowSize) _isFull = true;
  }

  /// Current average. Returns 0.0 if buffer is empty.
  double get average {
    if (_buffer.isEmpty) return 0;
    var sum = 0.0;
    for (final v in _buffer) {
      sum += v;
    }
    return sum / _buffer.length;
  }

  /// Stop accepting new values. Average stays at last computed value.
  void freeze() => _frozen = true;

  /// Resume accepting new values.
  void unfreeze() => _frozen = false;

  /// Reset to empty state. Also unfreezes.
  void clear() {
    _buffer.clear();
    _writeIndex = 0;
    _isFull = false;
    _frozen = false;
  }

  bool get isFrozen => _frozen;
  bool get isEmpty => _buffer.isEmpty;
  bool get isFull => _isFull;
}
