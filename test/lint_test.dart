@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart format reports no changes needed', () {
    final result = Process.runSync(
      'dart',
      ['format', '--set-exit-if-changed', '--output=none', '.'],
      workingDirectory: Directory.current.path,
    );

    if (result.exitCode != 0) {
      fail(
        'Some files need formatting. Run "dart format ." to fix.\n'
        '${result.stdout}',
      );
    }
  });

  test('dart analyze reports no issues', () {
    final result = Process.runSync(
      'dart',
      ['analyze', '--fatal-infos'],
      workingDirectory: Directory.current.path,
    );

    if (result.exitCode != 0) {
      fail(
        'dart analyze found issues:\n'
        '${result.stdout}',
      );
    }
  });
}
