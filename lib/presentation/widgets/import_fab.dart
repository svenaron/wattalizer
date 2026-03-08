import 'dart:async';

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
      final results = await importFileFromPath(
        ref,
        file.path!,
        displayName: file.name,
      );
      if (mounted) showImportResultsDialog(context, results);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
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
