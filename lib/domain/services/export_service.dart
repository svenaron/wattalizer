import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:fit_sdk/fit_sdk.dart' show FitException;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/data/fit/fit_parser.dart';
import 'package:wattalizer/data/json/gc_json_parser.dart';
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
  final ImportError? error;
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
  static const int _maxFileSizeBytes = 50 * 1024 * 1024;

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
  /// Throws [ImportError] on validation failure.
  Future<Ride> importTcx(File file, AutoLapConfig config) async {
    final fileName = file.path.split(Platform.pathSeparator).last;

    if (file.lengthSync() > _maxFileSizeBytes) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.fileTooLarge,
        detail: 'File exceeds 50 MB limit',
      );
    }

    final String xmlContent;
    try {
      if (fileName.toLowerCase().endsWith('.gz')) {
        final compressed = file.readAsBytesSync();
        final decompressed = const GZipDecoder().decodeBytes(compressed);
        xmlContent = String.fromCharCodes(decompressed);
      } else {
        xmlContent = file.readAsStringSync();
      }
    } catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: e.toString(),
      );
    }

    TcxParseResult result;
    try {
      result = TcxParser.parse(xmlContent);
    } on XmlException catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: e.toString(),
      );
    } catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: e.toString(),
      );
    }

    return _importParsedReadings(
      fileName: fileName,
      startTime: result.startTime,
      readings: result.readings,
      source: RideSource.importedTcx,
      config: config,
    );
  }

  /// Import a single FIT file. Returns a fully populated Ride with
  /// re-detected efforts.
  /// Throws [ImportError] on validation failure.
  Future<Ride> importFit(File file, AutoLapConfig config) async {
    final fileName = file.path.split(Platform.pathSeparator).last;

    if (file.lengthSync() > _maxFileSizeBytes) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.fileTooLarge,
        detail: 'File exceeds 50 MB limit',
      );
    }

    final List<int> fitBytes;
    try {
      if (fileName.toLowerCase().endsWith('.gz')) {
        final compressed = file.readAsBytesSync();
        fitBytes = const GZipDecoder().decodeBytes(compressed);
      } else {
        fitBytes = file.readAsBytesSync();
      }
    } catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: 'Read error: $e',
      );
    }

    FitParseResult result;
    try {
      result = FitParser.parse(fitBytes);
    } on FitException catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: 'FitException: $e',
      );
    } catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: '${e.runtimeType}: $e',
      );
    }

    return _importParsedReadings(
      fileName: fileName,
      startTime: result.startTime,
      readings: result.readings,
      source: RideSource.importedFit,
      config: config,
    );
  }

  /// Import a single GoldenCheetah JSON file. Returns a fully populated
  /// Ride with re-detected efforts.
  /// Throws [ImportError] on validation failure.
  Future<Ride> importGcJson(File file, AutoLapConfig config) async {
    final fileName = file.path.split(Platform.pathSeparator).last;

    if (file.lengthSync() > _maxFileSizeBytes) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.fileTooLarge,
        detail: 'File exceeds 50 MB limit',
      );
    }

    final String content;
    try {
      content = file.readAsStringSync();
    } catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: 'Read error: $e',
      );
    }

    GcJsonParseResult result;
    try {
      result = GcJsonParser.parse(content);
    } on FormatException catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: e.message,
      );
    } catch (e) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.malformedFile,
        detail: '${e.runtimeType}: $e',
      );
    }

    return _importParsedReadings(
      fileName: fileName,
      startTime: result.startTime,
      readings: result.readings,
      source: RideSource.importedGcJson,
      config: config,
    );
  }

  /// Returns true for macOS resource-fork and metadata files that ZIP tools
  /// include automatically. These are binary AppleDouble files, not valid
  /// activity data, so they must be excluded before import parsing.
  bool _isMacOsMetadataFile(String archivePath) {
    final lower = archivePath.toLowerCase();
    final basename = lower.split('/').last;
    return basename.startsWith('._') || lower.startsWith('__macosx/');
  }

  /// Import a ZIP archive of TCX and/or FIT files.
  /// Returns results for each importable file (success or failure per file).
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
          error: ImportError(
            fileName: fileName,
            type: ImportErrorType.malformedFile,
            detail: 'Could not decode ZIP: $e',
          ),
        ),
      ];
    }

    final importableFiles = archive.files.where((f) {
      final n = f.name.toLowerCase();
      return f.isFile &&
          !_isMacOsMetadataFile(f.name) &&
          (n.endsWith('.tcx') ||
              n.endsWith('.tcx.gz') ||
              n.endsWith('.fit') ||
              n.endsWith('.fit.gz') ||
              n.endsWith('.json'));
    }).toList();
    final total = importableFiles.length;

    final results = <ImportResult>[];
    final tempDir = Directory.systemTemp.createTempSync('wattalizer_import_');

    try {
      onProgress?.call(0, total);
      for (var i = 0; i < importableFiles.length; i++) {
        final entry = importableFiles[i];
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

        final lowerName = entryName.toLowerCase();
        try {
          final Ride ride;
          if (lowerName.endsWith('.fit') || lowerName.endsWith('.fit.gz')) {
            ride = await importFit(tempFile, config);
          } else if (lowerName.endsWith('.json')) {
            ride = await importGcJson(tempFile, config);
          } else {
            ride = await importTcx(tempFile, config);
          }
          results.add(ImportResult(fileName: entryName, ride: ride));
        } on ImportError catch (e) {
          results.add(ImportResult(fileName: entryName, error: e));
        } on Object catch (e) {
          results.add(
            ImportResult(
              fileName: entryName,
              error: ImportError(
                fileName: entryName,
                type: ImportErrorType.malformedFile,
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

  /// Shared post-parse logic: validate, deduplicate, redetect, persist.
  Future<Ride> _importParsedReadings({
    required String fileName,
    required DateTime startTime,
    required List<SensorReading> readings,
    required RideSource source,
    required AutoLapConfig config,
  }) async {
    if (readings.isEmpty) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.noTrackpoints,
        detail: 'No trackpoints found in file',
      );
    }

    if (readings.every((r) => r.power == null)) {
      throw ImportError(
        fileName: fileName,
        type: ImportErrorType.noPowerData,
        detail: 'No power data found in file',
      );
    }

    // Duplicate check: look for rides within ±5 seconds of startTime
    final candidates = await _repository.getRides(
      from: startTime.subtract(const Duration(seconds: 5)),
      to: startTime.add(const Duration(seconds: 5)),
    );

    final newCount = readings.length;
    for (final candidate in candidates) {
      final timeDiff =
          candidate.startTime.difference(startTime).inMilliseconds.abs();
      if (timeDiff <= 2000) {
        final existingCount = candidate.summary.readingCount;
        if (existingCount > 0) {
          final countRatio = (newCount - existingCount).abs() / existingCount;
          if (countRatio <= 0.05) {
            throw ImportError(
              fileName: fileName,
              type: ImportErrorType.duplicateRide,
              detail: 'Duplicate of ride ${candidate.id}',
            );
          }
        }
      }
    }

    final rideId = _uuid.v4();
    final efforts = EffortManager().redetectEfforts(
      rideId: rideId,
      readings: readings,
      config: config,
    );

    final summary = SummaryCalculator.computeRideSummary(readings, efforts);

    final ride = Ride(
      id: rideId,
      startTime: startTime,
      source: source,
      efforts: efforts,
      summary: summary,
    );

    await _repository.transaction(() async {
      await _repository.saveRide(ride);
      await _repository.insertReadings(rideId, readings);
      // saveEfforts inserts effort rows + their map_curves in one go
      await _repository.saveEfforts(rideId, efforts);
    });

    return ride;
  }
}
