/// All domain-level errors. Presentation layer maps these
/// to user-facing messages.
sealed class AppError {}

// --- BLE ---

class BleConnectionError extends AppError {
  BleConnectionError({required this.deviceId, required this.reason});

  final String deviceId;
  final String reason; // "timeout", "not_found", "rejected", "unknown"
}

class BleScanError extends AppError {
  BleScanError({required this.reason});

  final String reason; // "permission_denied", "bluetooth_off", "unknown"
}

// --- Database ---

class DatabaseError extends AppError {
  DatabaseError({required this.operation, required this.detail});

  final String operation; // e.g. "save_ride", "query_rides"
  final String detail;
}

// --- Import / Export ---

enum ImportErrorType {
  malformedXml,
  noTrackpoints,
  noPowerData,
  duplicateRide,
  fileTooLarge,
}

class TcxImportError extends AppError {
  TcxImportError({required this.fileName, required this.type, this.detail});

  final String fileName;
  final ImportErrorType type;
  final String? detail;
}

class ExportError extends AppError {
  ExportError({required this.rideId, required this.reason});

  final String rideId;
  final String reason;
}

// --- Domain ---

class InvalidConfigError extends AppError {
  InvalidConfigError({required this.field, required this.reason});

  final String field;
  final String reason;
}
