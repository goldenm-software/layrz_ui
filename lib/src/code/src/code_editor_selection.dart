import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/selection/selection.dart';

/// Builds the Material-free selection context menu for [LayrzCodeEditor]'s
/// [EditableText], mirroring how `LayrzEditableField`
/// (`lib/src/inputs/src/shared/editable_field.dart`) builds its own.
///
/// Split out of `code_editor.dart` as a top-level function (rather than an
/// instance method) since it needs nothing from `_LayrzCodeEditorState`
/// beyond [readOnly] — the flag that decides whether cut/paste belong in the
/// menu for a read-only field (a defensive no-op today, since the editable
/// branch that uses this builder is never reached when [LayrzCodeEditor] is
/// read-only, but kept for parity with the actions [LayrzEditableField]
/// filters).
Widget buildCodeEditorContextMenu(
  BuildContext context,
  EditableTextState editableTextState, {
  required bool readOnly,
}) {
  final tokens = context.tokens;
  final anchors = editableTextState.contextMenuAnchors;

  final actionSet = LayrzSelectableAction.defaults.where((action) {
    if (readOnly && (action.type == 'cut' || action.type == 'paste')) {
      return false;
    }
    return true;
  }).toSet();

  final toolbar = LayrzSelectionToolbar(
    actions: actionSet,
    anchorAbove: anchors.primaryAnchor,
    anchorBelow: anchors.secondaryAnchor,
    tokens: tokens,
    onActionPressed: (actionType) {
      switch (actionType) {
        case 'copy':
          editableTextState.copySelection(SelectionChangedCause.toolbar);
        case 'cut':
          editableTextState.cutSelection(SelectionChangedCause.toolbar);
        case 'paste':
          editableTextState.pasteText(SelectionChangedCause.toolbar);
        case 'selectAll':
          editableTextState.selectAll(SelectionChangedCause.toolbar);
      }
    },
  );

  return CustomSingleChildLayout(
    delegate: TextSelectionToolbarLayoutDelegate(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? Offset.zero,
    ),
    child: toolbar,
  );
}

/// Threads [LayrzCodeEditor.onTap] through the selection gesture recognizer.
///
/// Mirrors `LayrzEditableFieldSelectionGestureDetectorBuilder`
/// (`lib/src/inputs/src/shared/editable_field.dart`) — overriding [onUserTap]
/// is the documented extension point [TextSelectionGestureDetectorBuilder]
/// provides for a caller-supplied tap callback, and is the only way to
/// receive taps once [EditableText.rendererIgnoresPointer] hands pointer
/// handling to this builder's own gesture detector.
class CodeEditorGestureDetectorBuilder extends TextSelectionGestureDetectorBuilder {
  /// Resolves the current `LayrzCodeEditor.onTap` callback at tap time.
  ///
  /// A callback-returning-callback (rather than a plain `VoidCallback?`) so
  /// this builder — constructed once in the owning state's `initState` and
  /// never rebuilt — always reads the *current* widget's tap callback, even
  /// after a `didUpdateWidget` swap changes it.
  final VoidCallback? Function() _resolveOnTap;

  /// Creates a gesture detector builder that forwards user taps to whatever
  /// [_resolveOnTap] currently returns.
  CodeEditorGestureDetectorBuilder({
    required super.delegate,
    required VoidCallback? Function() onUserTapCallback,
  }) : _resolveOnTap = onUserTapCallback;

  @override
  void onUserTap() {
    super.onUserTap();
    _resolveOnTap()?.call();
  }
}
