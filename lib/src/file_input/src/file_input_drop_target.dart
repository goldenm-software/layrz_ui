import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';

import 'file_input_result.dart';

/// Wraps [child] with drag-and-drop file acceptance, using `desktop_drop`'s
/// [DropTarget].
///
/// [DropTarget] is safe to use unconditionally across every platform this
/// package targets: its native implementation registers per-platform (web via
/// DOM drag events, desktop via each OS's own drag-and-drop APIs), and on a
/// platform with no registered implementation (there is currently no iOS/Android
/// native side) its `MethodChannel` simply never receives drop events -- the
/// wrapped [child] renders exactly as if undecorated. This is why
/// [LayrzFileInput] has no separate conditional-export split for this file:
/// unlike `register_web_font.dart`'s web-vs-native API surface difference,
/// `DropTarget` itself is the single cross-platform entry point, and the
/// per-platform branching already lives inside `desktop_drop`.
///
/// Drag-and-drop is additive here, per the confirmed v1 scope -- click-to-browse
/// (via `file_picker`, wired by [LayrzFileInput] itself) is the primary
/// affordance; this widget only supplies the bonus drop-zone behavior. Reading
/// bytes from each dropped [DropItem] is inherently async ([XFile.readAsBytes]
/// hits disk or a blob URL), so [onFilesDropped] is invoked with a fully
/// resolved [List<LayrzFileInputResult>] rather than a stream of items.
class LayrzFileInputDropTarget extends StatelessWidget {
  /// The wrapped drop-zone content.
  final Widget child;

  /// Whether drag-and-drop is currently accepted.
  ///
  /// When false, drag callbacks are never invoked -- mirrors [DropTarget.enable].
  /// Set this to the disabled state of the surrounding [LayrzFileInput].
  final bool enabled;

  /// Called when the pointer carrying a drag enters the drop-zone's bounds.
  final VoidCallback? onDragEntered;

  /// Called when the pointer carrying a drag leaves the drop-zone's bounds
  /// without dropping.
  final VoidCallback? onDragExited;

  /// Called once files have been dropped and their bytes read.
  ///
  /// Receives the fully decoded [LayrzFileInputResult] list -- filtering by
  /// accepted type and reporting rejections is [LayrzFileInput]'s
  /// responsibility, not this widget's; this callback reports every dropped
  /// file, unfiltered.
  final void Function(List<LayrzFileInputResult>)? onFilesDropped;

  /// Creates a new [LayrzFileInputDropTarget] wrapping [child].
  const LayrzFileInputDropTarget({
    super.key,
    required this.child,
    this.enabled = true,
    this.onDragEntered,
    this.onDragExited,
    this.onFilesDropped,
  });

  /// Reads every dropped [DropItem]'s bytes and reports the resulting
  /// [LayrzFileInputResult] list via [onFilesDropped].
  ///
  /// A file that fails to read (e.g. a promise file whose temp copy vanished)
  /// is silently skipped rather than failing the whole drop -- the remaining
  /// files still reach the caller.
  Future<void> _handleDropDone(DropDoneDetails details) async {
    final results = <LayrzFileInputResult>[];
    for (final item in details.files) {
      try {
        final bytes = await item.readAsBytes();
        final mimeType = item.mimeType ?? mimeTypeForExtension(_extensionOf(item.name));
        results.add(
          LayrzFileInputResult(
            name: item.name,
            mimeType: mimeType,
            bytes: bytes,
          ),
        );
      } catch (_) {
        // Skip unreadable items; see the method doc.
        continue;
      }
    }
    onFilesDropped?.call(results);
  }

  /// Extracts the lowercase extension (without the dot) from [name], or null
  /// when [name] has none.
  String? _extensionOf(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return null;
    return name.substring(dotIndex + 1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      enable: enabled,
      onDragEntered: (_) => onDragEntered?.call(),
      onDragExited: (_) => onDragExited?.call(),
      onDragDone: _handleDropDone,
      child: child,
    );
  }
}
