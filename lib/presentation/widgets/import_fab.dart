import 'dart:async';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/presentation/utils/import_utils.dart';

class ImportFab extends ConsumerStatefulWidget {
  const ImportFab({super.key});

  @override
  ConsumerState<ImportFab> createState() => _ImportFabState();
}

class _ImportFabState extends ConsumerState<ImportFab> {
  bool _importing = false;
  int _importDone = 0;
  int _importTotal = 0;

  Future<void> _import() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['tcx', 'fit', 'zip', 'gz', 'json'],
        withData: true,
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e')),
        );
      }
      return;
    }

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;

    var importPath = file.path;
    io.Directory? tempDir;

    if (importPath == null) {
      if (file.bytes == null) return;
      tempDir = await io.Directory.systemTemp.createTemp('wattalizer_import_');
      final tmp = io.File('${tempDir.path}/${file.name}');
      await tmp.writeAsBytes(file.bytes!);
      importPath = tmp.path;
    }

    setState(() => _importing = true);
    try {
      final results = await importFileFromPath(
        ref,
        importPath,
        displayName: file.name,
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _importDone = done;
              _importTotal = total;
            });
          }
        },
      );
      if (mounted) showImportResultsDialog(context, results);
    } finally {
      if (mounted) {
        setState(() {
          _importing = false;
          _importDone = 0;
          _importTotal = 0;
        });
      }
      await tempDir?.delete(recursive: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_importing && _importTotal > 1) {
      return FloatingActionButton.extended(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text('$_importDone / $_importTotal'),
      );
    }
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
