import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/data/tcx/tcx_parser.dart';
import 'package:wattalizer/data/tcx/tcx_serializer.dart';
import 'package:wattalizer/domain/interfaces/ride_repository.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/models/ride.dart';
import 'package:wattalizer/domain/models/sensor_reading.dart';
import 'package:wattalizer/domain/services/effort_manager.dart';
import 'package:wattalizer/domain/services/summary_calculator.dart';
import 'package:xml/xml.dart';

class ImportResult {
  // null on success

  const ImportResult({required this.fileName, this.ride, this.error});
  final String fileName;
  final Ride? ride; // null on failure
  final TcxImportError? error;
}

class ExportService {
  // 50 MB

  ExportService({
    required RideRepository repository,
    Directory? exportDirectory,
  })  : _repository = repository,
        _exportDirectory = exportDirectory;
  final RideRepository _repository;
  final Directory? _exportDirectory; // injectable for tests

  static const _uuid = Uuid();

  /// Export ride to TCX file. Returns the file path.
  /// Throws [ExportError] on failure.
  Future<String> exportTcx(Ride ride, List<SensorReading> readings) async {
    try {
      final xml = TcxSerializer.serialize(ride, readings);
      final dir = _exportDirectory ?? await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${ride.id}.tcx');
      await file.writeAsString(xml);
      return file.path;
    } catch (e) {
      throw ExportError(rideId: ride.id, reason: e.toString());
    }
  }

  /// Import a single TCX file. Returns a fully populated Ride with
  /// re-detected efforts.
  /// Throws [TcxImportError] on validation failure.
  Future<Ride> importTcx(File file, AutoLapConfig config) async {
    final fileName = file.path.split(Platform.pathSeparator).last;

    // Size check
    if (file.lengthSync() > 50 * 1024 * 1024) {
      throw TcxImportError(
        fileName: fileName,
        type: ImportErrorType.fileTooLarge,
        detail: 'File exceeds 50 MB limit',
      );
    }

    // Parse XML
    TcxParseResult result;
    try {
      result = TcxParser.parse(file.readAsStringSync());
    } on XmlException catch (e) {
      throw TcxImportError(
        fileName: fileName,
        type: ImportErrorType.malformedXml,
        detail: e.toString(),
      );
    } catch (e) {
      throw TcxImportError(
        fileName: fileName,
        type: ImportErrorType.malformedXml,
        detail: e.toString(),
      );
    }

    // Validate readings
    if (result.readings.isEmpty) {
      throw TcxImportError(
        fileName: fileName,
        type: ImportErrorType.noTrackpoints,
        detail: 'No trackpoints found in TCX file',
      );
    }

    if (result.readings.every((r) => r.power == null)) {
      throw TcxImportError(
        fileName: fileName,
        type: ImportErrorType.noPowerData,
        detail: 'No power data found in TCX file',
      );
    }

    // Duplicate check: look for rides within ±2 seconds of startTime
    final startTime = result.startTime;
    final candidates = await _repository.getRides(
      from: startTime.subtract(const Duration(seconds: 5)),
      to: startTime.add(const Duration(seconds: 5)),
    );

    final newCount = result.readings.length;
    for (final candidate in candidates) {
      final timeDiff =
          candidate.startTime.difference(startTime).inMilliseconds.abs();
      if (timeDiff <= 2000) {
        final existingCount = candidate.summary.readingCount;
        if (existingCount > 0) {
          final countRatio = (newCount - existingCount).abs() / existingCount;
          if (countRatio <= 0.05) {
            throw TcxImportError(
              fileName: fileName,
              type: ImportErrorType.duplicateRide,
              detail: 'Duplicate of ride ${candidate.id}',
            );
          }
        }
      }
    }

    // Re-detect efforts
    final rideId = _uuid.v4();
    final efforts = EffortManager().redetectEfforts(
      rideId: rideId,
      readings: result.readings,
      config: config,
    );

    // Compute summary
    final summary = SummaryCalculator.computeRideSummary(
      result.readings,
      efforts,
    );

    final ride = Ride(
      id: rideId,
      startTime: result.startTime,
      source: RideSource.importedTcx,
      efforts: efforts,
      summary: summary,
    );

    // Persist atomically
    await _repository.transaction(() async {
      await _repository.saveRide(ride);
      await _repository.insertReadings(rideId, result.readings);
      await _repository.saveEfforts(rideId, efforts);
      for (final effort in efforts) {
        await _repository.saveMapCurve(effort.id, effort.mapCurve);
      }
    });

    return ride;
  }

  /// Import a ZIP archive of TCX files.
  /// Returns results for each .tcx file (success or failure per file).
  /// Never throws — errors are collected per file.
  Future<List<ImportResult>> importZip(
    File file,
    AutoLapConfig config, {
    void Function(int done, int total)? onProgress,
  }) async {
    final fileName = file.path.split(Platform.pathSeparator).last;

    late Archive archive;
    InputFileStream? inputStream;
    try {
      inputStream = InputFileStream(file.path);
      archive = ZipDecoder().decodeStream(inputStream);
    } on Object catch (e) {
      inputStream?.closeSync();
      return [
        ImportResult(
          fileName: fileName,
          error: TcxImportError(
            fileName: fileName,
            type: ImportErrorType.malformedXml,
            detail: 'Could not decode ZIP: $e',
          ),
        ),
      ];
    }

    final tcxFiles = archive.files.where((f) {
      final n = f.name.toLowerCase();
      return f.isFile && (n.endsWith('.tcx') || n.endsWith('.tcx.gz'));
    }).toList();
    final total = tcxFiles.length;

    final results = <ImportResult>[];
    final tempDir = Directory.systemTemp.createTempSync('wattalizer_import_');

    try {
      onProgress?.call(0, total);
      for (var i = 0; i < tcxFiles.length; i++) {
        final entry = tcxFiles[i];
        final entryName = entry.name.split('/').last;
        final File tempFile;
        if (entryName.toLowerCase().endsWith('.gz')) {
          final bytes =
              const GZipDecoder().decodeBytes(entry.content as List<int>);
          final tempName = entryName.replaceAll('.gz', '');
          tempFile = File('${tempDir.path}/$tempName')..writeAsBytesSync(bytes);
        } else {
          final outStream = OutputFileStream('${tempDir.path}/$entryName');
          entry.writeContent(outStream);
          outStream.closeSync();
          tempFile = File('${tempDir.path}/$entryName');
        }

        try {
          final ride = await importTcx(tempFile, config);
          results.add(ImportResult(fileName: entryName, ride: ride));
        } on TcxImportError catch (e) {
          results.add(ImportResult(fileName: entryName, error: e));
        } on Object catch (e) {
          results.add(
            ImportResult(
              fileName: entryName,
              error: TcxImportError(
                fileName: entryName,
                type: ImportErrorType.malformedXml,
                detail: e.toString(),
              ),
            ),
          );
        }
        onProgress?.call(i + 1, total);
      }
    } finally {
      inputStream.closeSync();
      tempDir.deleteSync(recursive: true);
    }

    return results;
  }
}
