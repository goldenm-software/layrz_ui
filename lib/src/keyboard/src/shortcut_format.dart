import 'package:flutter/services.dart';
import 'package:layrz_ui/src/platform/platform.dart';

/// Formats a keyboard shortcut for display, using platform-native key names and glyphs.
///
/// Converts a set of [LogicalKeyboardKey] modifiers and keys into a human-readable
/// shortcut hint. Each key is rendered with its platform-specific glyph or name:
///
/// | Key | macOS | Windows/Linux |
/// |---|---|---|
/// | `meta` | `⌘` | `Win` |
/// | `control` | `⌃` | `Ctrl` |
/// | `alt` | `⌥` | `Alt` |
/// | `shift` | `⇧` | `Shift` |
/// | other | keyLabel (uppercase) | same |
///
/// **Important:** layrz_ui does not substitute one modifier for another. The application
/// is responsible for deciding which modifier keys to include in the set — pass different
/// sets per platform if you want platform-specific shortcuts. For example, if you want
/// Cmd+S on macOS and Ctrl+S on Windows, pass `{meta, keyS}` on macOS and
/// `{control, keyS}` on Windows from your app code.
///
/// **Canonical ordering:** Since [Set] is unordered, modifiers are sorted canonically:
/// - **macOS**: `⌃⌥⇧⌘` (control, option, shift, command), then the non-modifier key,
///   concatenated with no separator, e.g. `⇧⌘S`.
/// - **Windows/Linux**: `Ctrl`, `Alt`, `Shift`, `Win`, then the key, joined with `+`,
///   e.g. `Shift+Ctrl+S`.
///
/// Left/right variants (e.g. `controlLeft`, `shiftRight`) are normalized to their base
/// modifier so callers are not caught out by keyboard variance.
///
/// Returns an empty string if [keys] is null, empty, or contains only non-modifier keys
/// that Flutter does not recognize.
///
/// [platform] defaults to [LayrzPlatform.current]. Pass an explicit platform for testing
/// or cross-platform string generation.
String formatLayrzShortcut(
  Set<LogicalKeyboardKey>? keys, {
  LayrzPlatform? platform,
}) {
  if (keys == null || keys.isEmpty) {
    return '';
  }

  final effectivePlatform = platform ?? LayrzPlatform.current;
  bool hasControl = false;
  bool hasAlt = false;
  bool hasShift = false;
  bool hasMeta = false;
  LogicalKeyboardKey? nonModifierKey;

  for (final key in keys) {
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      hasControl = true;
    } else if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      hasAlt = true;
    } else if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      hasShift = true;
    } else if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      hasMeta = true;
    } else {
      // Store the first non-modifier key (arbitrary, since Set is unordered)
      nonModifierKey ??= key;
    }
  }

  if (effectivePlatform == LayrzPlatform.macOS) {
    // macOS: canonical order ⌃⌥⇧⌘ + key
    final buffer = StringBuffer();
    if (hasControl) buffer.write('⌃');
    if (hasAlt) buffer.write('⌥');
    if (hasShift) buffer.write('⇧');
    if (hasMeta) buffer.write('⌘');
    if (nonModifierKey != null) {
      buffer.write(nonModifierKey.keyLabel.toUpperCase());
    }
    return buffer.toString();
  }

  // Windows/Linux: canonical order Ctrl+Alt+Shift+Win+ + key
  final parts = <String>[];
  if (hasControl) parts.add('Ctrl');
  if (hasAlt) parts.add('Alt');
  if (hasShift) parts.add('Shift');
  if (hasMeta) parts.add('Win');
  if (nonModifierKey != null) {
    parts.add(nonModifierKey.keyLabel.toUpperCase());
  }
  return parts.join('+');
}
