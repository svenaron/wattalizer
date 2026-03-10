import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/core/error_types.dart';
import 'package:wattalizer/domain/models/autolap_config.dart';
import 'package:wattalizer/domain/services/export_service.dart';
import 'package:wattalizer/presentation/providers/autolap_config_provider.dart';
import 'package:wattalizer/presentation/providers/export_service_provider.dart';
import 'package:wattalizer/presentation/providers/historical_range_provider.dart';
import 'package:wattalizer/presentation/providers/max_power_provider.dart';
import 'package:wattalizer/presentation/providers/ride_list_provider.dart';

/// Routes [filePath] to importFit, importGcJson, importTcx, or importZip based
/// on
/// extension. Invalidates list/range/power providers on success.
/// Never throws — errors are captured as [ImportResult] entries.
Future<List<ImportResult>> importFileFromPath(
  WidgetRef ref,
  String filePath, {
  String? displayName,
}) async {
  final fileName = displayName ?? filePath.split(Platform.pathSeparator).last;
  final name = fileName.toLowerCase();
  final file = File(filePath);

  try {
    final export = ref.read(exportServiceProvider);
    final configAsync = ref.read(autoLapConfigProvider);
    final config = configAsync.value ?? AutoLapConfig.standingStart();

    List<ImportResult> results;
    if (name.endsWith('.zip')) {
      results = await export.importZip(file, config);
    } else {
      try {
        final ride = name.endsWith('.fit') || name.endsWith('.fit.gz')
            ? await export.importFit(file, config)
            : name.endsWith('.json')
                ? await export.importGcJson(file, config)
                : await export.importTcx(file, config);
        results = [ImportResult(fileName: fileName, ride: ride)];
      } on ImportError catch (e) {
        results = [ImportResult(fileName: fileName, error: e)];
      }
    }

    ref
      ..invalidate(rideListProvider)
      ..invalidate(historicalRangeProvider)
      ..invalidate(maxPowerProvider);

    return results;
  } on Exception catch (e) {
    return [
      ImportResult(
        fileName: fileName,
        error: ImportError(
          fileName: fileName,
          type: ImportErrorType.malformedFile,
          detail: e.toString(),
        ),
      ),
    ];
  }
}

String errorLabel(ImportErrorType type) => switch (type) {
      ImportErrorType.malformedFile => 'Invalid file format',
      ImportErrorType.noTrackpoints => 'No trackpoints',
      ImportErrorType.noPowerData => 'No power data',
      ImportErrorType.duplicateRide => 'Duplicate (already imported)',
      ImportErrorType.fileTooLarge => 'File too large (>50 MB)',
    };

void showImportResultsDialog(
  BuildContext context,
  List<ImportResult> results,
) {
  final imported = results.where((r) => r.ride != null).length;
  final errors = results.where((r) => r.error != null).length;

  unawaited(
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (results.length > 1)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final r = results[i];
                        final success = r.ride != null;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            success ? Icons.check_circle : Icons.error_outline,
                            color: success ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          title: Text(
                            r.fileName,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: success
                              ? null
                              : Text(
                                  errorLabel(r.error!.type),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade300,
                                  ),
                                ),
                        );
                      },
                    ),
                  )
                else if (results.length == 1) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        results.first.ride != null
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: results.first.ride != null
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          results.first.error != null
                              ? errorLabel(results.first.error!.type)
                              : 'Imported successfully',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  '$imported imported, '
                  '$errors error${errors == 1 ? '' : 's'}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}
