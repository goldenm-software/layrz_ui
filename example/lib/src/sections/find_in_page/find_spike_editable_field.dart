import 'package:flutter/widgets.dart';

import 'package:layrz_ui/layrz_ui.dart';

/// A minimal, always-visible editable text field used by `LayrzFindSpike`
/// (see `find_spike.dart`) to prove `walkSemantics` sees an in-progress
/// [EditableText]'s live `value` — not just [Text] widgets' `label`.
class FindSpikeEditableField extends StatefulWidget {
  /// The active design tokens, for colour and typography.
  ///
  /// Unused directly by this widget (its `build` re-reads `context.tokens`
  /// instead, since a [StatefulWidget]'s `build` has its own [BuildContext]
  /// anyway) — kept as a constructor parameter purely so the call site in
  /// `LayrzFindSpike` reads consistently with its sibling widgets, all of
  /// which are handed `tokens` explicitly.
  final LayrzTokens tokens;

  /// Creates a [FindSpikeEditableField].
  const FindSpikeEditableField({super.key, required this.tokens});

  @override
  State<FindSpikeEditableField> createState() => _FindSpikeEditableFieldState();
}

class _FindSpikeEditableFieldState extends State<FindSpikeEditableField> {
  /// Seeds the field with a searchable word ("mango") so the spike harness
  /// has something to find inside an editable field's live value, not just
  /// its (empty, at rest) label.
  late final TextEditingController _controller = TextEditingController(
    text: 'An editable field already containing the word mango.',
  );

  /// Focus node for this field. Not shared with the top bar's query field —
  /// this is separate content under test, not part of the find UI itself.
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return EditableText(
      controller: _controller,
      focusNode: _focusNode,
      style: tokens.typography.body.copyWith(color: tokens.colors.fg1),
      cursorColor: tokens.colors.primary.shade500,
      backgroundCursorColor: tokens.colors.fg4,
      // Material-free EditableText has no TextSelectionTheme ancestor to
      // fall back on, so without an explicit selectionColor a Ctrl+A/drag
      // selection paints fully transparent — invisible, not merely subtle.
      // Matches the tonal selection tint already used by the frozen shared
      // input chrome (`inputs/src/shared/editable_field.dart`) and
      // `pickers/src/shared/time_fields_panel.dart`.
      selectionColor: tokens.colors.primary.withValues(alpha: tokens.colors.tonalOpacity),
    );
  }
}
