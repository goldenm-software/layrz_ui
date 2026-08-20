// ignore_for_file: avoid_print

/// Guard script to verify all @Preview annotations declare a bounded size parameter.
///
/// Usage: dart tool/check_preview_sizes.dart
///
/// Exits with code 1 if any violations are found, 0 otherwise.
library;

import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final violations = <String>[];

  _walkDirectory(libDir, (file) {
    if (!file.path.endsWith('.dart')) return;

    final content = file.readAsStringSync();
    final lines = content.split('\n');

    // Find all @Preview lines followed by a Widget function declaration
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('@Preview(')) continue;

      // Check if the next few lines contain a Widget function (real @Preview annotation)
      bool isFunctionPreview = false;
      for (int k = i + 1; k < lines.length && k < i + 15; k++) {
        if (lines[k].contains('Widget ') && (lines[k].contains('()') || lines[k].contains('() {'))) {
          isFunctionPreview = true;
          break;
        }
      }

      if (!isFunctionPreview) continue; // Skip non-function comments

      // Found a real @Preview. Look ahead up to 15 lines for 'size:'
      bool foundSize = false;
      int j = i;

      while (j < lines.length && j < i + 15) {
        if (lines[j].contains('size:') && lines[j].contains('Size(')) {
          foundSize = true;
          break;
        }
        // Stop searching when we hit the Widget function declaration
        if (lines[j].contains('Widget ') && lines[j].contains('()')) {
          break;
        }
        j++;
      }

      if (!foundSize) {
        violations.add('${file.path}:${i + 1}');
      }
    }
  });

  if (violations.isNotEmpty) {
    stderr.writeln('❌ The following @Preview annotations are missing a `size:` parameter:');
    for (final violation in violations) {
      stderr.writeln('   $violation');
    }
    stderr.writeln(
      '\nAdd `size: Size(width, height)` to each @Preview annotation to constrain '
      'the preview to bounded dimensions.\n',
    );
    exitCode = 1;
  } else {
    print('✓ All @Preview annotations declare a `size:` parameter');
    exitCode = 0;
  }
}

/// Recursively walks a directory and calls [callback] for each File found.
void _walkDirectory(Directory dir, Function(File) callback) {
  try {
    for (final entity in dir.listSync()) {
      if (entity is File) {
        callback(entity);
      } else if (entity is Directory && !entity.path.contains('/.')) {
        _walkDirectory(entity, callback);
      }
    }
  } catch (e) {
    // Ignore permission errors and other issues
  }
}
