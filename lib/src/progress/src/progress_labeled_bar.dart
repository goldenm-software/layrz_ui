import 'package:flutter/widgets.dart';

import 'package:layrz_ui/src/extensions/extensions.dart';
import 'package:layrz_ui/src/tokens/tokens.dart';

import 'progress_label_painter.dart';
import 'progress_style_spec.dart';
import 'progress_value_format.dart';

/// Composes a painted progress [bar] with its value-percentage label on top,
/// via a [Stack] rather than folding text painting into
/// `LayrzProgressPainter` itself — that painter's concern is track/fill
/// geometry only, shared by both the linear and circular formats, and label
/// painting is a linear-only, opt-in concern layered above it.
///
/// The label is painted by [LayrzProgressLabelPainter], right-aligned inside
/// the filled (indicator) region by default, flipping to just outside it —
/// onto the track — when the fill is too narrow to hold the label; see that
/// painter's doc for the exact placement rule and the near-100% edge case.
/// Both contrast colors are derived from `Color.contrastColor`
/// (`lib/src/extensions/src/color.dart`), the same primitive already used by
/// `LayrzChip`, `LayrzAlert`, and `LayrzButton` to pick legible text against
/// an arbitrary accent — not a one-off computation invented here, and
/// derived (never hardcoded) so a future change to a semantic accent's shade
/// is picked up automatically.
///
/// The label text itself is produced by [formatLayrzProgressValue], which
/// never lets a genuinely-started value read as `'0%'` nor a genuinely-
/// incomplete one read as `'100%'` — see that function's doc for the exact
/// rounding rule. `LayrzProgressBar`'s `Semantics.value` announcement calls
/// the same function, so the visible label and what assistive technology
/// hears never disagree.
///
/// Extracted out of `LayrzProgressBar`'s own state class: this composition
/// needs only its constructor arguments, no access to the enclosing widget's
/// state, so keeping it as a separate, stateless widget here keeps
/// `progress_bar.dart` under this repository's file-size guidance.
class LayrzLabeledProgressBar extends StatelessWidget {
  /// The already-painted track/indicator bar to stack the label on top of.
  final Widget bar;

  /// The determinate progress fraction, in `[0.0, 1.0]`, used both to format
  /// the label text and to resolve the label's placement.
  final double value;

  /// The number of decimal places shown in the formatted label (e.g. `0` for
  /// `'42%'`, `1` for `'42.0%'`). Mirrors `LayrzProgressBar.decimals`.
  final int decimals;

  /// The resolved track/indicator colors, used to derive both of the
  /// label's contrast colors and to format the label text's base style.
  final LayrzProgressStyleSpec style;

  /// The current design tokens, used for the label's typography and its
  /// inset from the fill boundary.
  final LayrzTokens tokens;

  /// Creates a new [LayrzLabeledProgressBar].
  const LayrzLabeledProgressBar({
    super.key,
    required this.bar,
    required this.value,
    required this.decimals,
    required this.style,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final text = formatLayrzProgressValue(value, decimals);
    final labelStyle = tokens.typography.label.copyWith(fontWeight: FontWeight.w600);

    return Stack(
      alignment: Alignment.center,
      children: [
        bar,
        Positioned.fill(
          child: CustomPaint(
            painter: LayrzProgressLabelPainter(
              text: text,
              style: labelStyle,
              value: value,
              indicatorContrastColor: style.indicatorColor.contrastColor,
              trackContrastColor: style.trackColor.contrastColor,
              inset: tokens.spacing.sp1,
            ),
          ),
        ),
      ],
    );
  }
}
