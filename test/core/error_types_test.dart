import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/core/error_types.dart';

void main() {
  group('AppError subtype instantiation', () {
    test('BleConnectionError carries deviceId and reason', () {
      final err = BleConnectionError(deviceId: 'dev1', reason: 'timeout');
      expect(err.deviceId, 'dev1');
      expect(err.reason, 'timeout');
      expect(err, isA<AppError>());
    });

    test('BleScanError carries reason', () {
      final err = BleScanError(reason: 'bluetooth_off');
      expect(err.reason, 'bluetooth_off');
      expect(err, isA<AppError>());
    });

    test('DatabaseError carries operation and detail', () {
      final err = DatabaseError(operation: 'save_ride', detail: 'disk full');
      expect(err.operation, 'save_ride');
      expect(err.detail, 'disk full');
      expect(err, isA<AppError>());
    });

    test('TcxImportError carries fileName, type, and optional detail', () {
      final err = TcxImportError(
        fileName: 'ride.tcx',
        type: ImportErrorType.noPowerData,
      );
      expect(err.fileName, 'ride.tcx');
      expect(err.type, ImportErrorType.noPowerData);
      expect(err.detail, isNull);
      expect(err, isA<AppError>());
    });

    test('TcxImportError detail may be provided', () {
      final err = TcxImportError(
        fileName: 'bad.tcx',
        type: ImportErrorType.malformedXml,
        detail: 'unclosed tag at line 42',
      );
      expect(err.detail, 'unclosed tag at line 42');
    });

    test('ExportError carries rideId and reason', () {
      final err = ExportError(rideId: 'r1', reason: 'write failed');
      expect(err.rideId, 'r1');
      expect(err.reason, 'write failed');
      expect(err, isA<AppError>());
    });

    test('InvalidConfigError carries field and reason', () {
      final err =
          InvalidConfigError(field: 'minEffortSeconds', reason: 'must be > 0');
      expect(err.field, 'minEffortSeconds');
      expect(err.reason, 'must be > 0');
      expect(err, isA<AppError>());
    });
  });

  group('ImportErrorType enum', () {
    test('has all expected values', () {
      expect(ImportErrorType.values, hasLength(5));
      expect(
        ImportErrorType.values,
        containsAll([
          ImportErrorType.malformedXml,
          ImportErrorType.noTrackpoints,
          ImportErrorType.noPowerData,
          ImportErrorType.duplicateRide,
          ImportErrorType.fileTooLarge,
        ]),
      );
    });
  });

  group('AppError sealed class pattern matching', () {
    test('switch exhaustiveness compiles for all subtypes', () {
      final AppError err = BleConnectionError(deviceId: 'x', reason: 'unknown');
      final label = switch (err) {
        BleConnectionError() => 'ble_connection',
        BleScanError() => 'ble_scan',
        DatabaseError() => 'database',
        TcxImportError() => 'tcx_import',
        ExportError() => 'export',
        InvalidConfigError() => 'invalid_config',
      };
      expect(label, 'ble_connection');
    });
  });
}
