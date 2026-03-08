import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

class ImportFab extends ConsumerStatefulWidget {
  const ImportFab({super.key});

  @override
  ConsumerState<ImportFab> createState() => _ImportFabState();
}

class _ImportFabState extends ConsumerState<ImportFab> {
  bool _importing = false;

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['tcx', 'fit', 'zip', 'gz'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() => _importing = true);

    try {
      final export = ref.read(exportServiceProvider);
      final configAsync = ref.read(autoLapConfigProvider);
      final config = configAsync.value ?? AutoLapConfig.standingStart();
      final ioFile = File(file.path!);
      final name = file.name.toLowerCase();

      if (name.endsWith('.zip')) {
        final results = await export.importZip(
          ioFile,
          config,
        );
        if (mounted) _showDetailedResults(results);
      } else {
        try {
          final ride = name.endsWith('.fit') || name.endsWith('.fit.gz')
              ? await export.importFit(ioFile, config)
              : await export.importTcx(ioFile, config);

          if (mounted) {
            _showDetailedResults(
              [ImportResult(fileName: file.name, ride: ride)],
            );
          }
        } on ImportError catch (e) {
          if (mounted) {
            _showDetailedResults([ImportResult(fileName: file.name, error: e)]);
          }
        }
      }
      ref
        ..invalidate(rideListProvider)
        ..invalidate(historicalRangeProvider)
        ..invalidate(maxPowerProvider);
    } on Exception catch (e) {
      if (mounted) {
        _showDetailedResults([
          ImportResult(
            fileName: file.path!.split(Platform.pathSeparator).last,
            error: ImportError(
              fileName: file.path!.split(Platform.pathSeparator).last,
              type: ImportErrorType.malformedFile,
              detail: e.toString(),
            ),
          ),
        ]);
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  String _errorLabel(ImportErrorType type) => switch (type) {
        ImportErrorType.malformedFile => 'Invalid file format',
        ImportErrorType.noTrackpoints => 'No trackpoints',
        ImportErrorType.noPowerData => 'No power data',
        ImportErrorType.duplicateRide => 'Duplicate (already imported)',
        ImportErrorType.fileTooLarge => 'File too large (>50 MB)',
      };

  void _showDetailedResults(List<ImportResult> results) {
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
                              success
                                  ? Icons.check_circle
                                  : Icons.error_outline,
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
                                    _errorLabel(r.error!.type),
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
                                ? _errorLabel(results.first.error!.type)
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

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      tooltip: 'Import rides',
      onPressed: _importing ? null : _import,
      child: _importing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.upload_file_outlined),
    );
  }
}
