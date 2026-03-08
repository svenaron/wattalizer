/// Hard cap on effort duration in seconds. MAP curve only covers 1–90s,
/// so any effort longer than this provides no additional data.
const int kMaxEffortSeconds = 90;

/// MAP curve duration range: 1 to 90 seconds inclusive.
const List<int> kMapDurations = [
  1,
  2,
  3,
  4,
  5,
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
  32,
  33,
  34,
  35,
  36,
  37,
  38,
  39,
  40,
  41,
  42,
  43,
  44,
  45,
  46,
  47,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  58,
  59,
  60,
  61,
  62,
  63,
  64,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
];

/// Number of duration buckets in a MAP curve.
const int kMapDurationCount = 90;

// --- Default AutoLap config values (spec §6.5) ---

const double kDefaultStartDeltaWatts = 300;
const int kDefaultStartConfirmSeconds = 2;
const int kDefaultStartDropoutTolerance = 1;
const double kDefaultEndDeltaWatts = 200;
const int kDefaultEndConfirmSeconds = 5;
const int kDefaultMinEffortSeconds = 3;
const int kDefaultPreEffortBaselineWindow = 15;
const int kDefaultInEffortTrailingWindow = 10;
const double? kDefaultMinPeakWatts = null;

// --- UI / BLE timing constants ---

const double kDefaultMaxPowerWatts = 1500;
const int kStopButtonHoldMs = 1500;
const int kBleReconnectTimeoutMinutes = 2;
const int kBleBackoffCapMs = 30000;
