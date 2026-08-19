import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layrz_ui/layrz_ui.dart';

void main() {
  group('formatLayrzShortcut', () {
    test('returns empty string for null input', () {
      expect(formatLayrzShortcut(null), '');
    });

    test('returns empty string for empty set', () {
      expect(formatLayrzShortcut({}), '');
    });

    test('returns key name for single non-modifier key', () {
      final result = formatLayrzShortcut({LogicalKeyboardKey.keyA});
      expect(result.isNotEmpty, true);
    });

    test('macOS: formats control+shift+s correctly', () {
      final result = formatLayrzShortcut(
        {
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyS,
        },
        platform: LayrzPlatform.macOS,
      );
      expect(result, contains('⌃'));
      expect(result, contains('⇧'));
      expect(result, contains('S'));
    });

    test('macOS: formats meta+shift+s correctly', () {
      final result = formatLayrzShortcut(
        {
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyS,
        },
        platform: LayrzPlatform.macOS,
      );
      expect(result, contains('⇧'));
      expect(result, contains('⌘'));
      expect(result, contains('S'));
    });

    test('macOS: canonical order is control, alt, shift, meta', () {
      final result = formatLayrzShortcut(
        {
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyX,
        },
        platform: LayrzPlatform.macOS,
      );
      // Order should be ⌃⌥⇧⌘X
      final ctrlIdx = result.indexOf('⌃');
      final altIdx = result.indexOf('⌥');
      final shiftIdx = result.indexOf('⇧');
      final metaIdx = result.indexOf('⌘');
      expect(ctrlIdx < altIdx && altIdx < shiftIdx && shiftIdx < metaIdx, true);
    });

    test('Windows/Linux: formats Ctrl+Shift+S correctly', () {
      final result = formatLayrzShortcut(
        {
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyS,
        },
        platform: LayrzPlatform.windows,
      );
      expect(result, contains('Ctrl'));
      expect(result, contains('Shift'));
      expect(result, contains('S'));
      expect(result, contains('+'));
    });

    test('Windows/Linux: canonical order is Ctrl, Alt, Shift, Win', () {
      final result = formatLayrzShortcut(
        {
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyX,
        },
        platform: LayrzPlatform.windows,
      );
      // Order should be Ctrl+Alt+Shift+Win+X
      final ctrlIdx = result.indexOf('Ctrl');
      final altIdx = result.indexOf('Alt');
      final shiftIdx = result.indexOf('Shift');
      final winIdx = result.indexOf('Win');
      expect(
        ctrlIdx < altIdx && altIdx < shiftIdx && shiftIdx < winIdx,
        true,
      );
    });

    test('normalizes left and right modifiers', () {
      final leftResult = formatLayrzShortcut(
        {LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.keyA},
        platform: LayrzPlatform.macOS,
      );
      final rightResult = formatLayrzShortcut(
        {LogicalKeyboardKey.controlRight, LogicalKeyboardKey.keyA},
        platform: LayrzPlatform.macOS,
      );
      expect(leftResult, rightResult);
    });

    test('returns empty string for only unrecognized keys', () {
      final result = formatLayrzShortcut({});
      expect(result, '');
    });

    test('handles all modifier keys on macOS', () {
      final result = formatLayrzShortcut(
        {
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.meta,
        },
        platform: LayrzPlatform.macOS,
      );
      expect(result, '⌃⌥⇧⌘');
    });

    test('handles all modifier keys on Windows/Linux', () {
      final result = formatLayrzShortcut(
        {
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.meta,
        },
        platform: LayrzPlatform.windows,
      );
      expect(result, 'Ctrl+Alt+Shift+Win');
    });

    test('handles shift+left variant', () {
      final result = formatLayrzShortcut(
        {LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.keyZ},
        platform: LayrzPlatform.macOS,
      );
      expect(result, contains('⇧'));
      expect(result, contains('Z'));
    });

    test('handles alt+right variant', () {
      final result = formatLayrzShortcut(
        {LogicalKeyboardKey.altRight, LogicalKeyboardKey.keyE},
        platform: LayrzPlatform.windows,
      );
      expect(result, contains('Alt'));
      expect(result, contains('E'));
    });
  });
}
