import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:layrz_ui/src/buttons/buttons.dart';

/// A small, Material-free "copy to clipboard" affordance for code widgets.
///
/// Tapping the button writes [text] to the system clipboard and shows a
/// transient "copied" affordance — the glyph swaps from a clipboard icon to a
/// checkmark for about a second and a half before reverting.
///
/// Built on [LayrzButton] in its [LayrzButtonStyle.textFab] variant (icon-only,
/// no fill or border), so it inherits the design system's hover/press/focus
/// states, tooltip, and button semantics rather than hand-rolling them.
///
/// **Icon choice**: this repo already depends on `flutter_material_design_icons`
/// for its glyph needs elsewhere (e.g. `MdiIcons.check` in
/// `lib/src/inputs/src/checkbox/checkbox_input.dart` and
/// `lib/src/inputs/src/select/select_input_surface.dart`). Reusing
/// `MdiIcons.contentCopy` / `MdiIcons.check` keeps this button on-brand with the
/// rest of the design system and avoids hand-rolled `CustomPaint` glyphs or a
/// new dependency.
class LayrzCodeCopyButton extends StatefulWidget {
  /// The text copied to the clipboard when this button is tapped.
  final String text;

  /// The icon color. Defaults to opaque white — legible on the always-dark
  /// code surface this button is designed to sit on.
  final Color? color;

  /// The semantics/tooltip label announced for this button.
  ///
  /// Defaults to `'Copy'` when omitted. [LayrzButton]'s Fab styles always show
  /// a tooltip composed from this label, since a Fab has no visible text.
  final String? tooltipText;

  /// Creates a [LayrzCodeCopyButton] that copies [text] to the clipboard.
  const LayrzCodeCopyButton({
    super.key,
    required this.text,
    this.color,
    this.tooltipText,
  });

  @override
  State<LayrzCodeCopyButton> createState() => _LayrzCodeCopyButtonState();
}

/// The default icon color used when [LayrzCodeCopyButton.color] is omitted —
/// opaque white, legible on the dark code surface.
const Color _kDefaultCopyIconColor = Color(0xFFFFFFFF);

class _LayrzCodeCopyButtonState extends State<LayrzCodeCopyButton> {
  /// Whether the "copied" affordance is currently showing.
  bool _copied = false;

  /// Reverts [_copied] back to `false` after the transient window elapses.
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  /// Copies [LayrzCodeCopyButton.text] to the clipboard and flips [_copied]
  /// on for a transient window before reverting it.
  Future<void> _handleTap() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;

    setState(() => _copied = true);
    _revertTimer?.cancel();
    _revertTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _kDefaultCopyIconColor;
    final label = widget.tooltipText ?? 'Copy';

    return LayrzButton(
      labelText: label,
      icon: _copied ? MdiIcons.check : MdiIcons.contentCopy,
      color: color,
      style: LayrzButtonStyle.textFab,
      onTap: _handleTap,
    );
  }
}
