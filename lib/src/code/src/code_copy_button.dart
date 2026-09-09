import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

/// A small, Material-free "copy to clipboard" affordance for code widgets.
///
/// Tapping the button writes [text] to the system clipboard and shows a
/// transient "copied" affordance — the glyph swaps from a clipboard icon to a
/// checkmark for about a second and a half before reverting.
///
/// **Icon choice**: this repo already depends on `flutter_material_design_icons`
/// for its glyph needs elsewhere (e.g. `MdiIcons.check` in
/// `lib/src/inputs/src/checkbox/checkbox_input.dart` and
/// `lib/src/inputs/src/select/select_input_surface.dart`), and `Icon`/`IconData`
/// themselves live in `package:flutter/widgets.dart`, not Material. Reusing
/// `MdiIcons.contentCopy` / `MdiIcons.check` keeps this button on-brand with the
/// rest of the design system and avoids hand-rolled `CustomPaint` glyphs or a
/// new dependency.
class LayrzCodeCopyButton extends StatefulWidget {
  /// The text copied to the clipboard when this button is tapped.
  final String text;

  /// The icon color. Defaults to a light, semi-transparent white — legible on
  /// the always-dark code surface this button is designed to sit on.
  final Color? color;

  /// The semantics/tooltip label announced for this button.
  ///
  /// Defaults to `'Copy'` when omitted.
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
/// a near-white tone legible on the dark code surface.
const Color _kDefaultCopyIconColor = Color(0xB3FFFFFF);

class _LayrzCodeCopyButtonState extends State<LayrzCodeCopyButton> {
  /// Whether the "copied" affordance is currently showing.
  bool _copied = false;

  /// Whether the pointer currently hovers this button.
  bool _hovered = false;

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
    final baseColor = widget.color ?? _kDefaultCopyIconColor;
    final iconColor = _hovered ? baseColor.withValues(alpha: 1.0) : baseColor;
    final label = widget.tooltipText ?? 'Copy';

    return Semantics(
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _handleTap,
          child: Icon(
            _copied ? MdiIcons.check : MdiIcons.contentCopy,
            color: iconColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}
